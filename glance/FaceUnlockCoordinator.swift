//
//  FaceUnlockCoordinator.swift
//  glance
//
//  Connects face recognition to the actual unlock path. Off by default; user opts in after validating accuracy in Face Lab.
//
//  Known limitation: LivenessAnalyzer defeats a photo but not a replayed video (real non-rigid motion looks live) — a successful spoof types the real macOS password.
//

import Foundation
import AppKit
import CoreGraphics
import Observation
import os

@Observable
@MainActor
final class FaceUnlockCoordinator {
    private let pocController: POCController
    let lockMonitor = LockMonitor()
    let camera = CameraManager()
    let pipeline = FaceRecognitionPipeline()

    /// Persisted via GlanceSettings. Setting to false cancels any in-flight scan and disarms the overlay immediately.
    var isEnabled: Bool {
        didSet {
            GlanceSettings.shared.isFaceUnlockEnabled = isEnabled
            if !isEnabled {
                cancelSpaceTrigger()
                disarmOverlay()
            }
        }
    }

    /// Kept independent from Face Lab's own `threshold` so tuning the debug tool never silently changes the real unlock gate.
    var matchThreshold: Float {
        didSet { GlanceSettings.shared.matchThreshold = matchThreshold }
    }
    /// Shares its setting with NotchOverlayController's scanning timeout, so the background loop stops in step with the UI collapsing.
    private var scanWindowDuration: TimeInterval {
        let configured = TimeInterval(GlanceSettings.shared.faceDetectionSeconds)
        return GlanceSettings.shared.requireInfrared ? max(configured, 10) : configured
    }
    /// A wake often catches the owner while they are still looking away from
    /// the camera. Require a sustained non-match rather than a few early
    /// frames before giving the failure animation.
    private let wrongFaceGraceDuration: Duration = .seconds(2)

    /// Numbers only (sizes, scores, timings) — no names, images or embeddings. Notice level so it persists in the unified log:
    /// `log show --predicate 'subsystem == "com.jonathan.glance" AND category == "faceunlock"'`.
    nonisolated private static let scanLog = Logger(subsystem: "com.jonathan.glance", category: "faceunlock")

    private(set) var statusMessage = "Idle"
    private(set) var lastOutcome: String?
    /// Numeric diagnostics for the latest scan only; no images or embeddings.
    private(set) var lastCheckDetails: String?
    private var diagnosticGeneration = 0

    private var hasArmedForCurrentLock = false
    /// One-shot per lock session — an auto-retry that could itself auto-retry would loop the camera for the whole lock session.
    private var hasAutoRetriedForCurrentLock = false
    private var scanTask: Task<Void, Never>?
    /// Bumped by every `startScanCycle()`; a cycle bails once superseded (see `runScanCycle(generation:)`).
    private var scanGeneration = 0
    /// When the last scan cycle was armed — collapses a single wake into a single arm (see `.wake` branch of `evaluateTrigger`).
    private var lastArmedAt: ContinuousClock.Instant?
    /// One lid-open fires several wake signals within a few hundred ms of each other; anything in this window counts as the same wake.
    private let rearmDebounce: Duration = .seconds(2)
    /// Held separately from `scanTask` since it's scheduled from inside the scan task it follows — reusing `scanTask` would self-cancel it.
    private var autoRetryTask: Task<Void, Never>?
    /// Gap between headless auto-retries, just to keep the camera from restarting in a tight loop.
    private let headlessRetryDelay: Duration = .seconds(1)

    /// When off, no notch/pill presence at all — every overlay call in this file is conditioned on this rather than just skipping the video.
    private var showsUI: Bool { GlanceSettings.shared.showUnlockAnimation }

    /// Reads the space key on the lock screen for the "On space" trigger; only runs while locked + opted in.
    private let spaceKeyMonitor = SpaceKeyMonitor()
    private var spaceTriggerTask: Task<Void, Never>?
    private var spaceRequestGeneration = 0

    init(pocController: POCController) {
        self.pocController = pocController
        self.isEnabled = GlanceSettings.shared.isFaceUnlockEnabled
        self.matchThreshold = GlanceSettings.shared.matchThreshold
        spaceKeyMonitor.onSpaceKeyDown = { [weak self] in self?.handleSpaceKeyPress() }
        observeLockAndWakeEvents()
        observeSpaceConfiguration()
        NotificationCenter.default.addObserver(forName: NSApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.updateSpaceMonitor() }
        }
        NotificationCenter.default.addObserver(forName: .secureCredentialSessionDidChange, object: nil, queue: nil) { [weak self] _ in
            Task { @MainActor [weak self] in self?.disarmOverlay() }
        }
    }

    /// Re-subscribes on every change — `withObservationTracking` only fires once per registration.
    private func observeLockAndWakeEvents() {
        withObservationTracking {
            _ = lockMonitor.isScreenLocked
            _ = lockMonitor.wakeEventCount
            _ = lockMonitor.isSleeping
            // Also tracked so screensaver-stop and display-only wakes still wake this up.
            _ = lockMonitor.eventCount
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.observeLockAndWakeEvents()
                let event = self.lockMonitor.eventCount
                // Start immediately when CGSession already confirms the lock.
                // If its state is still settling after wake, retry the same
                // event once; a newer event owns its own evaluation.
                await LockTriggerRetry.evaluate(event: event,
                    currentEvent: { self.lockMonitor.eventCount },
                    isArmed: { self.hasArmedForCurrentLock },
                    attempt: { self.evaluateTrigger() },
                    stopRequested: self.lockMonitor.lastEvent == .screenUnlocked || self.lockMonitor.lastEvent == .willSleep,
                    stop: {
                        self.cancelSpaceTrigger()
                        self.spaceKeyMonitor.resetKeyState()
                        self.hasArmedForCurrentLock = false
                        self.hasAutoRetriedForCurrentLock = false
                        self.lastArmedAt = nil
                        self.disarmOverlay(reason: self.lockMonitor.lastEvent == .willSleep
                            ? String(localized: "Face check stopped because the Mac is going to sleep.")
                            : String(localized: "Face check stopped when the screen unlocked."))
                    })
            }
        }
    }

    private func evaluateTrigger() {
        guard LockMonitor.isScreenActuallyLocked() else {
            hasArmedForCurrentLock = false
            hasAutoRetriedForCurrentLock = false
            disarmOverlay()
            return
        }
        guard !lockMonitor.isSleeping else { return }

        // `.wake` (sleep, display sleep, or screensaver stopping) is an explicit "let me back in," so clear the one-shot guard.
        // `isWithinRecentArmBurst` keeps the several wake signals from one lid-open from each re-arming and fighting over the camera.
        if lockMonitor.lastEvent == .wake, !isWithinRecentArmBurst {
            hasArmedForCurrentLock = false
        }

        // Runs before the hasArmedForCurrentLock guard — the space monitor's lifetime is tied to "locked + opted in," not to whether a scan already ran.
        updateSpaceMonitor()

        guard isEnabled, !hasArmedForCurrentLock else { return }
        guard let signal = requiredTrigger(for: lockMonitor.lastEvent) else { return }
        // A pinned display that isn't connected bails entirely rather than showing up elsewhere; "Main display" (nil) always resolves.
        guard NotchGeometry.preferredScreen() != nil else { return }

        guard SecureCredentialManager.isSessionUnlocked else {
            statusMessage = String(localized: "Face unlock is on, but the session is locked — authenticate once from Password settings first.")
            return
        }
        guard SecureCredentialManager.hasStoredPassword() else {
            statusMessage = String(localized: "Face unlock is on, but no password is stored yet.")
            return
        }

        // A deselected trigger means "don't auto-scan for this signal," not "do nothing" — the user can still opt in by hand.
        let shouldAutoScan = GlanceSettings.shared.unlockTriggers.contains(signal)

        // Headless has nothing to arm/hover, so if this signal isn't selected there's nothing to do — and hasArmedForCurrentLock
        // must stay false, or a later selected signal could never fire (nothing else calls arm() to reset it).
        guard showsUI || shouldAutoScan else { return }

        guard arm(autoScan: shouldAutoScan) else { return }
        hasArmedForCurrentLock = true
        lastArmedAt = .now
    }

    /// Whether the last arm was recent enough to be part of the same wake burst rather than a new one.
    private var isWithinRecentArmBurst: Bool {
        guard let lastArmedAt else { return false }
        return ContinuousClock.now - lastArmedAt < rearmDebounce
    }

    /// nil for signals that shouldn't arm anything — including a nil `lastEvent`, or the first observation would fire regardless of user selection.
    private func requiredTrigger(for event: LockEventKind?) -> UnlockTrigger? {
        switch event {
        case .wake: return .onWake
        case .screenLocked: return .onLock
        case .screenUnlocked, .willSleep, nil: return nil
        }
    }

    private func disarmOverlay(reason: String? = nil) {
        if scanTask != nil, lastOutcome == nil, let reason {
            lastOutcome = reason
            statusMessage = reason
        }
        scanTask?.cancel()
        scanTask = nil
        // Bumping makes any cycle still suspended at `await camera.start()` inert, rather than resuming and re-showing the overlay.
        scanGeneration &+= 1
        autoRetryTask?.cancel()
        autoRetryTask = nil
        camera.stop()
        NotchOverlayController.shared.disarm()
        // Covers isEnabled being switched off directly, keeping "disarmed" and "not listening for space" in lockstep.
        updateSpaceMonitor()
    }

    /// Idempotent and safe to call on every lock/wake event. Deliberately does not prompt for Input Monitoring — a missing grant just means "don't listen."
    private func observeSpaceConfiguration() {
        withObservationTracking {
            _ = isEnabled
            _ = GlanceSettings.shared.unlockTriggers
            _ = lockMonitor.isSleeping
        } onChange: { [weak self] in
            Task { @MainActor in self?.observeSpaceConfiguration() }
        }
        updateSpaceMonitor()
    }

    private func updateSpaceMonitor() {
        let shouldListen = SpaceKeyState.shouldListen(
            enabled: isEnabled,
            selected: GlanceSettings.shared.unlockTriggers.contains(.onSpace),
            sleeping: lockMonitor.isSleeping,
            permitted: SpaceKeyMonitor.hasInputMonitoringAccess()
        )
        if shouldListen {
            spaceKeyMonitor.start()
        } else {
            cancelSpaceTrigger()
            spaceKeyMonitor.stop()
        }
    }

    /// Runs the same gate chain as `evaluateTrigger`, then starts a scan. Independent of `LockMonitor` events, so doesn't touch `hasArmedForCurrentLock`.
    private func cancelSpaceTrigger() {
        spaceRequestGeneration &+= 1
        spaceTriggerTask?.cancel()
        spaceTriggerTask = nil
    }

    private func handleSpaceKeyPress() {
        guard isEnabled, GlanceSettings.shared.unlockTriggers.contains(.onSpace),
              LockMonitor.isScreenActuallyLocked() || lockMonitor.isSleeping || lockMonitor.isScreenLocked else { return }
        SpaceKeyMonitor.log.info("space trigger received, checking lock and wake state")
        cancelSpaceTrigger()
        let request = spaceRequestGeneration
        spaceTriggerTask = Task { [weak self] in
            guard let self else { return }
            defer {
                if self.spaceRequestGeneration == request { self.spaceTriggerTask = nil }
            }
            // The first key after sleep can precede the workspace wake signal or CGSession update.
            let deadline = ContinuousClock.now + .seconds(1)
            while !Task.isCancelled, request == self.spaceRequestGeneration {
                if !self.lockMonitor.isSleeping, LockMonitor.isScreenActuallyLocked() {
                    self.startSpaceScanIfAllowed()
                    return
                }
                guard ContinuousClock.now < deadline else { return }
                try? await Task.sleep(for: .milliseconds(20))
            }
        }
    }

    private func startSpaceScanIfAllowed() {
        guard isEnabled,
              GlanceSettings.shared.unlockTriggers.contains(.onSpace),
              LockMonitor.isScreenActuallyLocked(),
              NotchGeometry.preferredScreen() != nil,
              SecureCredentialManager.isSessionUnlocked,
              SecureCredentialManager.hasStoredPassword()
        else { return }

        hasArmedForCurrentLock = true
        lastArmedAt = .now
        SpaceKeyMonitor.log.info("space trigger accepted, starting face recognition")

        // Already looking — swallows auto-repeat/double-presses and lets "On wake"/"On lock" override "On space" with no special-casing.
        guard NotchOverlayController.shared.phase != .scanning else { return }

        guard showsUI else {
            // Headless: no overlay, just scan.
            startScanCycle()
            return
        }
        if NotchOverlayController.shared.isArmed {
            // Closed pill/notch already up — expand and scan, like a hover retry.
            startScanCycle()
        } else {
            arm(autoScan: true)
        }
    }

    /// Either way the overlay still arms — a deselected trigger only skips the automatic scan, leaving hover-to-start available.
    @discardableResult
    private func arm(autoScan: Bool) -> Bool {
        guard isEnabled, !lockMonitor.isSleeping,
              SecureCredentialManager.isSessionUnlocked, LockMonitor.isScreenActuallyLocked() else { return false }
        guard showsUI else {
            // Headless: evaluateTrigger() already guaranteed autoScan is true here, so this is just "start scanning."
            startScanCycle()
            return true
        }
        NotchOverlayController.shared.arm { [weak self] in
            self?.startScanCycle()
        }
        if autoScan {
            startScanCycle()
        }
        return true
    }

    /// Called on arm, and again whenever the overlay hover-activates.
    private func startScanCycle() {
        scanTask?.cancel()
        scanGeneration &+= 1
        let generation = scanGeneration
        scanTask = Task { [weak self] in
            await self?.runScanCycle(generation: generation)
        }
    }

    /// `generation` is what makes overlapping cycles safe: `Task.cancel()` is cooperative, so a superseded cycle still runs to the
    /// end of this function, and its global side effects (`camera.stop()` etc.) could otherwise land on the newer cycle instead
    /// of itself. This was a real bug — a superseded `camera.stop()` queued behind the newer cycle's `startRunning()` made the
    /// camera visibly switch on then die mid-warm-up, leaving the surviving cycle polling a dead session and never unlocking.
    private func runScanCycle(generation: Int) async {
        guard LockMonitor.isScreenActuallyLocked() else { return }

        diagnosticGeneration = generation
        statusMessage = String(localized: "Starting camera…")
        lastOutcome = nil
        lastCheckDetails = nil
        guard KeystrokeInjector.isAccessibilityTrusted() else {
            statusMessage = String(localized: "Accessibility permission required. Enable this app in System Settings → Privacy & Security → Accessibility.")
            lastOutcome = statusMessage
            return
        }
        let scanStarted = ContinuousClock.now
        await camera.start()
        guard generation == scanGeneration else { return }

        if let error = camera.errorMessage {
            statusMessage = error
            camera.stop()
            return
        }

        // Do not spend the liveness window
        // waiting for the first fresh frame; bound camera warmup separately.
        let warmupDeadline = ContinuousClock.now + .seconds(5)
        while camera.currentFrame.map({ $0.capturedAt >= scanStarted }) != true {
            guard !Task.isCancelled, generation == scanGeneration, isEnabled,
                  LockMonitor.isScreenActuallyLocked() else {
                if generation == scanGeneration { camera.stop() }
                return
            }
            guard ContinuousClock.now < warmupDeadline else {
                camera.stop()
                statusMessage = String(localized: "The camera did not provide a fresh frame. Try again.")
                lastOutcome = statusMessage
                return
            }
            try? await Task.sleep(for: .milliseconds(20))
        }

        let showsUI = self.showsUI
        if showsUI {
            NotchOverlayController.shared.beginScanning(timeout: .seconds(scanWindowDuration))
        }
        statusMessage = String(localized: "Looking for your face…")
        lastOutcome = nil
        lastCheckDetails = nil

        let outcome = await observeScanWindow(
            deadline: ContinuousClock.now + .seconds(scanWindowDuration),
            requireOverlayScanning: showsUI,
            generation: generation,
            scanStarted: scanStarted,
            cameraReadyAt: .now
        )

        // A newer cycle now owns the camera and overlay — leave both alone, and leave the auto-retry one-shot unspent.
        guard generation == scanGeneration else { return }

        camera.stop()
        Self.scanLog.notice("scan \(generation, privacy: .public) outcome: \(String(describing: outcome), privacy: .public)")

        switch outcome {
        case .matched:
            // The unlock already happened inside observeScanWindow — this only decides whether anything is shown about it.
            if showsUI {
                NotchOverlayController.shared.finish(success: true)
            }
        case .injectionFailed:
            statusMessage = pocController.statusMessage
            if showsUI { NotchOverlayController.shared.finish(success: false) }
        case .consistentlyWrongFace:
            statusMessage = String(localized: "Face not recognized.")
            if showsUI {
                NotchOverlayController.shared.finish(success: false)
                statusMessage = String(localized: "Face not recognized — hover the notch to try again.")
                scheduleAutoRetryIfEnabled(after: NotchOverlayController.shared.failureHoldDuration)
            } else {
                scheduleAutoRetryIfEnabled(after: headlessRetryDelay)
            }
        case .spoofSuspected:
            statusMessage = String(localized: "Couldn't confirm a live face.")
            if showsUI {
                NotchOverlayController.shared.finish(success: false)
                statusMessage = String(localized: "Couldn't confirm a live face — hover the notch to try again.")
                scheduleAutoRetryIfEnabled(after: NotchOverlayController.shared.failureHoldDuration)
            } else {
                scheduleAutoRetryIfEnabled(after: headlessRetryDelay)
            }
        case .livenessUnconfirmed:
            statusMessage = String(localized: "Face recognized, but the live-face check did not finish. Blink or gently turn your head and try again.")
            lastOutcome = statusMessage
            if showsUI { NotchOverlayController.shared.finish(success: false) }
        case .infraredFailed(let reason), .unlockFailed(let reason):
            statusMessage = reason
            lastOutcome = reason
            if showsUI { NotchOverlayController.shared.finish(success: false) }
        case .noResolution:
            statusMessage = String(localized: "No face detected.")
            if showsUI {
                // No explicit collapse call: NotchOverlayController's own scanning timeout fires on the same mark and collapses itself.
                statusMessage = String(localized: "No face detected — hover the notch to try again.")
                scheduleAutoRetryIfEnabled(after: NotchOverlayController.shared.collapseAnimationDuration)
            } else {
                scheduleAutoRetryIfEnabled(after: headlessRetryDelay)
            }
        }
    }

    /// `delay` waits out whatever the overlay is still showing so the retry doesn't start underneath the previous outcome.
    private func scheduleAutoRetryIfEnabled(after delay: Duration) {
        guard GlanceSettings.shared.autoRetryOnce, !hasAutoRetriedForCurrentLock else { return }
        hasAutoRetriedForCurrentLock = true
        autoRetryTask?.cancel()
        autoRetryTask = Task { [weak self] in
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled, let self else { return }
            // Re-check rather than trust the delay: the user may have unlocked by password or retried manually while this waited.
            guard LockMonitor.isScreenActuallyLocked(), self.isEnabled else { return }
            if self.showsUI {
                guard NotchOverlayController.shared.phase == .closed else { return }
            }
            self.startScanCycle()
        }
    }

    private enum ScanTarget {
        var requiresLockedScreen: Bool {
            if case .lockScreen = self { return true }
            return false
        }
        var prompt: SystemAuthenticationPrompt? {
            if case .systemAuthenticationPrompt(let prompt) = self { return prompt }
            return nil
        }
        case lockScreen
        case systemAuthenticationPrompt(SystemAuthenticationPrompt)

        var remainsValid: Bool {
            switch self {
            case .lockScreen:
                return LockMonitor.isScreenActuallyLocked()
            case .systemAuthenticationPrompt(let prompt):
                return GlanceSettings.shared.isSystemAuthenticationAssistEnabled &&
                    SystemAuthenticationPromptMonitor.shared.currentTrustedPrompt() == prompt
            }
        }
    }

    private enum ScanOutcome {
        case matched
        case injectionFailed
        case consistentlyWrongFace
        /// A deny cue (glare, device rectangle) fired — actively rejected as a spoof regardless of match. Same failure path as `.consistentlyWrongFace`.
        case spoofSuspected
        case livenessUnconfirmed
        case noResolution
        case infraredFailed(String)
        /// The face passed every check but the stored password couldn't be read or typed.
        case unlockFailed(String)
    }

    /// Manual hot-key entry for a trusted macOS password prompt. The shortcut is
    /// the user's consent; every later gate can still refuse to type anything.
    func startSystemAuthenticationAssist() {
        guard GlanceSettings.shared.isSystemAuthenticationAssistEnabled, isEnabled else { return }
        guard let prompt = SystemAuthenticationPromptMonitor.shared.currentTrustedPrompt() else {
            statusMessage = String(localized: "No supported system password prompt is focused.")
            return
        }
        guard SecureCredentialManager.isSessionUnlocked else {
            statusMessage = String(localized: "System prompt assist is on, but the session is locked.")
            return
        }
        guard SecureCredentialManager.hasStoredPassword() else {
            statusMessage = String(localized: "System prompt assist is on, but no password is stored yet.")
            return
        }

        scanTask?.cancel()
        scanGeneration &+= 1
        let generation = scanGeneration
        scanTask = Task { [weak self] in
            await self?.runSystemAuthenticationAssistScan(prompt: prompt, generation: generation)
        }
    }

    /// The nonactivating overlay keeps the system password field focused while
    /// showing the same scan and outcome feedback as lock-screen authentication.
    private func runSystemAuthenticationAssistScan(prompt: SystemAuthenticationPrompt, generation: Int) async {
        let showsUI = self.showsUI && NotchGeometry.preferredScreen() != nil
        if showsUI {
            await withCheckedContinuation { continuation in
                NotchOverlayController.shared.present(onPresented: { continuation.resume() })
            }
        }
        guard generation == scanGeneration, !Task.isCancelled else { return }
        let scanStarted = ContinuousClock.now
        diagnosticGeneration = generation
        await camera.start()
        guard generation == scanGeneration else { return }

        if let error = camera.errorMessage {
            statusMessage = error
            camera.stop()
            if showsUI { NotchOverlayController.shared.finish(success: false) }
            return
        }

        statusMessage = String(localized: "Looking for your face for the system prompt…")
        let outcome = await observeScanWindow(
            deadline: ContinuousClock.now + .seconds(scanWindowDuration),
            requireOverlayScanning: false,
            generation: generation,
            scanStarted: scanStarted,
            cameraReadyAt: .now,
            target: .systemAuthenticationPrompt(prompt)
        )
        guard generation == scanGeneration else { return }
        camera.stop()

        switch outcome {
        case .matched:
            if showsUI { NotchOverlayController.shared.finish(success: true) }
        case .injectionFailed:
            if showsUI { NotchOverlayController.shared.finish(success: false) }
        case .consistentlyWrongFace:
            statusMessage = String(localized: "Face not recognized for the system prompt.")
            if showsUI { NotchOverlayController.shared.finish(success: false) }
        case .spoofSuspected:
            statusMessage = String(localized: "Couldn't confirm a live face for the system prompt.")
            if showsUI { NotchOverlayController.shared.finish(success: false) }
        case .infraredFailed(let reason), .unlockFailed(let reason):
            statusMessage = reason
            if showsUI { NotchOverlayController.shared.finish(success: false) }
        case .livenessUnconfirmed:
            statusMessage = String(localized: "Couldn't confirm a live face for the system prompt.")
            if showsUI { NotchOverlayController.shared.finish(success: false) }
        case .noResolution:
            statusMessage = String(localized: "System password prompt is no longer focused, or no face was detected.")
            if showsUI { await NotchOverlayController.shared.collapse() }
        }
    }

    /// Only frames matching the same continuously observed identity contribute to liveness.
    /// Undecided liveness keeps scanning until `deadline`; required IR runs after both RGB gates pass.
    /// `requireOverlayScanning` bails early once the overlay's own timeout collapses the UI — only applied when there is an
    /// overlay, since headlessly `phase` never becomes `.scanning` at all.
    private func observeScanWindow(deadline: ContinuousClock.Instant, requireOverlayScanning: Bool, generation: Int, scanStarted: ContinuousClock.Instant, cameraReadyAt: ContinuousClock.Instant, target: ScanTarget = .lockScreen) async -> ScanOutcome {
        guard let credentialSession = SecureCredentialManager.sessionIdentifier else { return .noResolution }
        let rgbThreshold = matchThreshold
        let infraredRequired = GlanceSettings.shared.requireInfrared
        let configuredLiveness = GlanceSettings.shared.livenessChecksEnabled
        let configuredLivenessMode = GlanceSettings.shared.livenessMode
        let livenessEnabled = configuredLiveness || infraredRequired
        let liveness = LivenessAnalyzer(skipAbstainingGeometry: true)
        liveness.modeProvider = { infraredRequired ? .heavy : configuredLivenessMode }
        /// Set by the first consecutive non-match. A gap in face detection or
        /// a valid match clears it, so only a sustained wrong face resolves the scan.
        var wrongFaceStartedAt: ContinuousClock.Instant?

        /// Cleared the moment a detected face fails to match, so a latched match can't be handed to whoever steps in next.
        var readyMatch: ScoredIdentity?
        var livenessIdentity: FaceIdentity?
        var livenessConfirmedAt: ContinuousClock.Instant?
        /// Turning liveness off in Settings makes this half permanently ready.
        var livenessConfirmed = !livenessEnabled
        /// Last frame's selected face, passed back so `selectDominantFace` stays on the same person instead of flip-flopping.
        var lastFaceBoundingBox: CGRect?
        /// Cheap way to detect "no new camera frame yet" vs. "fresh frame" — without it a repeat frame would corrupt the liveness motion signal.
        var lastProcessedFrameID: UInt64?
        var recognizedFace = false
        var frameNumber = 0
        let identities = FaceEnrollmentStore.shared.activeIdentities
        Self.scanLog.notice("scan \(generation, privacy: .public) start: identities=\(identities.count, privacy: .public) stale=\(identities.filter { $0.isStale(comparedTo: self.pipeline.embedder) }.count, privacy: .public) threshold=\(rgbThreshold, privacy: .public) liveness=\(livenessEnabled, privacy: .public) ir=\(infraredRequired, privacy: .public) warmup=\(Self.seconds(scanStarted.duration(to: cameraReadyAt)), format: .fixed(precision: 2), privacy: .public)s")

        while ContinuousClock.now < deadline, !Task.isCancelled,
              !requireOverlayScanning || NotchOverlayController.shared.phase == .scanning {
            guard target.remainsValid, SecureCredentialManager.sessionIdentifier == credentialSession,
                  isEnabled, generation == scanGeneration, matchThreshold == rgbThreshold,
                  infraredRequired == GlanceSettings.shared.requireInfrared,
                  configuredLiveness == GlanceSettings.shared.livenessChecksEnabled,
                  configuredLivenessMode == GlanceSettings.shared.livenessMode else { return .noResolution }

            guard let frame = camera.currentFrame, frame.id != lastProcessedFrameID, frame.capturedAt >= scanStarted else {
                // 20ms keeps the liveness window's sample count high while staying close to the camera's native ~33ms cadence.
                try? await Task.sleep(nanoseconds: 20_000_000)
                continue
            }
            lastProcessedFrameID = frame.id

            let pipeline = self.pipeline
            let previousBoundingBox = lastFaceBoundingBox
            frameNumber += 1
            let frameAge = Self.seconds(cameraReadyAt.duration(to: .now))
            let processed = await Task.detached(priority: .userInitiated) { () -> (match: (FaceRecognitionResult, LivenessFrame)?, faces: Int, widest: Double) in
                guard let result = try? pipeline.recognize(in: frame, preferNear: previousBoundingBox, includeQuality: false) else {
                    // Diagnostics only: tells "nobody there" apart from "face smaller than the minimum width".
                    let faces = (try? FaceDetector.detectFaces(in: frame.image, includeQuality: false)) ?? []
                    return (nil, faces.count, Double(faces.map(\.normalizedBoundingBox.width).max() ?? 0))
                }
                let faceCrop = CameraManager.renderCrop(from: frame, imageRect: result.face.boundingBox)
                return ((result, LivenessFeatureExtractor.extract(from: result, frame: frame.image, faceCrop: faceCrop)), 1, Double(result.face.normalizedBoundingBox.width))
            }.value
            let outcome = processed.match

            guard !Task.isCancelled, isEnabled, target.remainsValid else { return .noResolution }
            guard let (result, livenessFrame) = outcome else {
                Self.scanLog.notice("scan \(generation, privacy: .public) frame \(frameNumber, privacy: .public) t=\(frameAge, format: .fixed(precision: 2), privacy: .public)s: no usable face (faces=\(processed.faces, privacy: .public) widest=\(processed.widest, format: .fixed(precision: 3), privacy: .public))")
                readyMatch = nil
                livenessIdentity = nil
                liveness.reset()
                livenessConfirmedAt = nil
                livenessConfirmed = !livenessEnabled
                wrongFaceStartedAt = nil
                lastFaceBoundingBox = nil
                try? await Task.sleep(nanoseconds: 20_000_000)
                continue
            }
            lastFaceBoundingBox = result.face.normalizedBoundingBox

            let scored = pipeline.score(result.embedding, against: FaceEnrollmentStore.shared.activeIdentities)
            let matched = pipeline.bestMatch(in: scored, threshold: rgbThreshold)
            Self.scanLog.notice("scan \(generation, privacy: .public) frame \(frameNumber, privacy: .public) t=\(frameAge, format: .fixed(precision: 2), privacy: .public)s: width=\(processed.widest, format: .fixed(precision: 3), privacy: .public) centroid=\(scored.first?.centroidSimilarity ?? -1, format: .fixed(precision: 3), privacy: .public) bestSample=\(scored.first?.maxSampleSimilarity ?? -1, format: .fixed(precision: 3), privacy: .public) yaw=\(result.face.yaw ?? 0, format: .fixed(precision: 2), privacy: .public) pitch=\(result.face.pitch ?? 0, format: .fixed(precision: 2), privacy: .public) matched=\(matched != nil, privacy: .public) wrongFaceFor=\(matched == nil ? wrongFaceStartedAt.map { Self.seconds($0.duration(to: .now)) } ?? 0 : 0, format: .fixed(precision: 2), privacy: .public)s")
            // Evidence belongs to one continuously observed identity, never a
            // previous face or a bystander who supplied a liveness cue.
            if matched?.identity != livenessIdentity || matched == nil {
                liveness.reset()
                livenessConfirmedAt = nil
                livenessConfirmed = !livenessEnabled
                livenessIdentity = matched?.identity
            }
            var confirmingCue: LivenessCue?
            if livenessEnabled, matched != nil {
                lastCheckDetails = String(localized: "Colour face matched.")
                if let glare = livenessFrame.glare {
                    let reading = LivenessCues.glossGlare(livenessFrame)
                    lastCheckDetails = String(format: String(localized: "Colour face matched. Bright pixels: %.2f%%; concentration: %.2f%%; glare score: %.3f (limit %.3f)."),
                        glare.specularFraction * 100, glare.specularClusterRatio * 100,
                        reading.level, LivenessTuning.default.glossLevel)
                }
                let snapshot = liveness.observe(livenessFrame)
                let blink = snapshot.cueStates[.blink]?.reading ?? .none
                let depth = snapshot.cueStates[.depthPose]?.reading ?? .none
                let shape = snapshot.cueStates[.flatVs3D]?.reading ?? .none
                lastCheckDetails = (lastCheckDetails ?? String(localized: "Colour face matched.")) + String(format:
                    String(localized: " Live-face frames: %d; blink: %.2f; head-depth: %.2f (confidence %.2f); 3D shape: %.2f (confidence %.2f)."),
                    snapshot.frameCount, blink.level, depth.level, depth.confidence, shape.level, shape.confidence)
                switch snapshot.decision {
                case .denied:
                    // Overrides everything, including a match and any confirmation that already happened.
                    lastOutcome = snapshot.decision.denialReason
                    return .spoofSuspected
                case .confirmed(let cue):
                    if !livenessConfirmed { livenessConfirmedAt = frame.capturedAt }
                    livenessConfirmed = true
                    confirmingCue = cue
                case .pending:
                    break
                }
            }

            if let matched {
                recognizedFace = true
                wrongFaceStartedAt = nil
                readyMatch = matched
            } else {
                readyMatch = nil
                if wrongFaceStartedAt == nil {
                    wrongFaceStartedAt = .now
                }
                if ContinuousClock.now - wrongFaceStartedAt! >= wrongFaceGraceDuration {
                    return .consistentlyWrongFace
                }
            }

            if let readyMatch, livenessConfirmed {
                guard !Task.isCancelled, generation == scanGeneration, isEnabled else { return .noResolution }
                if infraredRequired {
                    return await confirmInfrared(for: readyMatch.identity, generation: generation, rgbThreshold: rgbThreshold,
                        evidenceAt: min(frame.capturedAt, livenessConfirmedAt ?? frame.capturedAt), scanStarted: scanStarted, cameraReadyAt: cameraReadyAt, credentialSession: credentialSession, target: target)
                }
                statusMessage = "Recognized — unlocking…"
                let livenessNote = livenessEnabled
                    ? (confirmingCue.map { String(localized: "live via \($0.title)") } ?? String(localized: "liveness clear"))
                    : String(localized: "liveness off")
                lastOutcome = "Matched \(readyMatch.identity.name) at \(String(format: "%.3f", readyMatch.centroidSimilarity)), \(livenessNote)."
                let injected = await pocController.injectStoredPassword(
                    requireAuthoritativeLock: target.requiresLockedScreen,
                    systemAuthenticationPrompt: target.prompt
                ) { [weak self] in
                    guard let self else { return false }
                    return !Task.isCancelled && SecureCredentialManager.sessionIdentifier == credentialSession
                        && target.remainsValid && generation == self.scanGeneration && self.isEnabled && self.matchThreshold == rgbThreshold
                        && !GlanceSettings.shared.requireInfrared
                        && configuredLiveness == GlanceSettings.shared.livenessChecksEnabled
                        && configuredLivenessMode == GlanceSettings.shared.livenessMode
                        && FaceEnrollmentStore.shared.activeIdentities.contains(readyMatch.identity)
                }
                // Reporting this as `.noResolution` used to show "No face detected" for a face that had in fact matched.
                return injected ? .matched : .unlockFailed(String(localized: "Face recognized, but unlocking failed. ") + pocController.statusMessage)
            }

            try? await Task.sleep(nanoseconds: 20_000_000)
        }
        return recognizedFace && livenessEnabled && !livenessConfirmed ? .livenessUnconfirmed : .noResolution
    }
    private let infraredAnalyzer = InfraredFaceAnalyzer()

    private static func seconds(_ duration: Duration) -> Double {
        let parts = duration.components
        return Double(parts.seconds) + Double(parts.attoseconds) / 1e18
    }

    /// RGB identity + heavy liveness have succeeded for this exact snapshot.
    /// Stop AVFoundation before taking the BRIO's USB interfaces, then require
    /// a separate IR match. Missing hardware is a denial, never an RGB fallback.
    private func confirmInfrared(for identity: FaceIdentity, generation: Int, rgbThreshold: Float,
                                 evidenceAt started: ContinuousClock.Instant, scanStarted: ContinuousClock.Instant, cameraReadyAt: ContinuousClock.Instant, credentialSession: UUID, target: ScanTarget = .lockScreen) async -> ScanOutcome {
        let colourFinishedAt = ContinuousClock.now
        let threshold = GlanceSettings.shared.infraredThreshold
        guard let enrollment = identity.infrared, enrollment.isUsable else {
            return .infraredFailed(String(localized: "Infrared enrollment required for this identity. Open Your Face settings."))
        }
        let service = InfraredServiceManager()
        guard service.enabled else { return .infraredFailed(String(localized: "Infrared camera helper is unavailable or not approved.")) }
        if showsUI { NotchOverlayController.shared.beginScanning(timeout: .seconds(15)) }
        statusMessage = String(localized: "Checking infrared — keep looking at the BRIO…")
        await camera.stopAndWait()
        guard !Task.isCancelled, generation == scanGeneration else { return .noResolution }
        do {
            // Loading Core ML is independent of USB capture; overlap the cold
            // load rather than putting it on the path after the image arrives.
            async let prepared: Void = infraredAnalyzer.prepare()
            let captureStarted = ContinuousClock.now
            let result = try await InfraredServiceManager.capture(allowPermissionPrompt: false)
            let captureElapsed = captureStarted.duration(to: .now).components
            let captureSeconds = Double(captureElapsed.seconds) + Double(captureElapsed.attoseconds) / 1e18
            let analysisStarted = ContinuousClock.now
            try await prepared
            let sample = try await infraredAnalyzer.sample(from: result.image(), captureID: UUID())
            let analysisSeconds = Self.seconds(analysisStarted.duration(to: .now))
            let score = try enrollment.compare(sample)
            let scanElapsed = scanStarted.duration(to: .now).components
            let scanSeconds = Double(scanElapsed.seconds) + Double(scanElapsed.attoseconds) / 1e18
            lastCheckDetails = String(format: String(localized: "Colour identity and Heavy liveness passed. IR centroid: %.3f; lowest reference: %.3f; required: %.3f. IR capture: %.1fs; total face checks: %.1fs."),
                score.centroid, score.minimumReference, threshold, captureSeconds, scanSeconds)
            let authorized: @MainActor @Sendable () -> Bool = { [weak self] in
                guard let self else { return false }
                let elapsed = started.duration(to: .now).components
                let seconds = Double(elapsed.seconds) + Double(elapsed.attoseconds) / 1e18
                return !Task.isCancelled && GlanceSettings.shared.requireInfrared
                    && threshold == GlanceSettings.shared.infraredThreshold
                    && self.isEnabled && self.matchThreshold == rgbThreshold
                    && InfraredUnlockPolicy.permits(score: score, threshold: threshold, elapsed: seconds,
                        sameIdentityAndEnrollment: FaceEnrollmentStore.shared.activeIdentities.contains(identity),
                        sameScan: generation == self.scanGeneration,
                        sessionUnlocked: SecureCredentialManager.sessionIdentifier == credentialSession,
                        screenLocked: target.requiresLockedScreen && LockMonitor.isScreenActuallyLocked(),
                        systemPromptTrusted: target.prompt != nil && target.remainsValid, sleeping: self.lockMonitor.isSleeping,
                        livenessConfirmed: true, helperEnabled: service.isCurrentlyEnabled())
            }
            guard authorized() else { return .infraredFailed(String(localized: "Infrared check did not pass. Use your password or try again.")) }
            let injectionStarted = ContinuousClock.now
            let injected = await pocController.injectStoredPassword(
                requireAuthoritativeLock: target.requiresLockedScreen,
                systemAuthenticationPrompt: target.prompt, authorization: authorized)
            if diagnosticGeneration == generation {
                lastCheckDetails = (lastCheckDetails ?? "") + String(format:
                    String(localized: " Camera startup: %.2fs; colour/liveness: %.2fs; camera handoff: %.2fs; IR analysis: %.2fs; password submission: %.2fs; total to submission: %.2fs."),
                    Self.seconds(scanStarted.duration(to: cameraReadyAt)),
                    Self.seconds(cameraReadyAt.duration(to: colourFinishedAt)), Self.seconds(colourFinishedAt.duration(to: captureStarted)), analysisSeconds,
                    Self.seconds(injectionStarted.duration(to: .now)), Self.seconds(scanStarted.duration(to: .now)))
            }
            guard injected else {
                return .infraredFailed(String(localized: "Face checks passed. ") + pocController.statusMessage)
            }
            lastOutcome = String(localized: "RGB identity and liveness plus same-identity infrared match passed.")
            return .matched
        } catch {
            if Task.isCancelled { return .noResolution }
            return .infraredFailed(String(localized: "Infrared check failed: ") + error.localizedDescription)
        }
    }

}
