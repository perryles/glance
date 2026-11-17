//
//  FaceLabView.swift
//  glance
//
//  Debug console: camera preview, face detection + alignment, enrollment,
//  and recognition — all in one tab, independent of the credential/unlock
//  POC in the other tab.
//

import SwiftUI
import Charts
import Foundation

struct FaceLabView: View {
    /// Retained only while the hidden debug tab is visible.
    @Bindable var controller: FaceLabController

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text(String(localized: "Face Lab — On-Device Face Recognition (Debug)"))
                        .font(.headline)
                    Spacer()
                    Button(String(localized: "Preview ✓")) {
                        NotchOverlayController.shared.present()
                        Task {
                            try? await Task.sleep(for: .seconds(1.5))
                            NotchOverlayController.shared.finish(success: true)
                        }
                    }
                    Button(String(localized: "Preview ✗")) {
                        NotchOverlayController.shared.present(onRetry: {
                            Task {
                                try? await Task.sleep(for: .seconds(1.5))
                                NotchOverlayController.shared.finish(success: false)
                            }
                        })
                        Task {
                            try? await Task.sleep(for: .seconds(1.5))
                            NotchOverlayController.shared.finish(success: false)
                        }
                    }
                    Button(String(localized: "Start Onboarding")) {
                        controller.startFullOnboarding()
                    }
                    .disabled(enrollmentFlowIsRunning)
                }

                modelStatusSection
                sessionLockSection
                previewSection
                InfraredLabView(beforeCapture: { controller.stop() })
                detectionSection
                livenessSection
                enrollSection
                identitiesSection
                recognizeSection
                calibrationSection
                logSection
            }
            .padding(20)
        }
        .onDisappear {
            controller.stop()
        }
        // Guided enrollment runs in the notch, outside this view hierarchy, so nothing else prompts a re-read once
        // it closes. Same trick YourFaceSettingsPage uses.
        .onChange(of: NotchOverlayController.shared.phase) { _, newPhase in
            guard newPhase == .closed else { return }
            controller.store.reloadIfUnlocked()
        }
    }

    /// True while the notch (a single shared panel) is already hosting an onboarding flow.
    private var enrollmentFlowIsRunning: Bool {
        NotchOverlayController.shared.phase == .onboarding
    }

    // MARK: - Which embedder is active

    private var modelStatusSection: some View {
        HStack {
            Circle()
                .fill(controller.pipeline.usingFallbackEmbedder ? .orange : .green)
                .frame(width: 8, height: 8)
            Text(String(localized: "Embedder: \(controller.pipeline.embedder.name)"))
                .font(.caption)
            if controller.pipeline.usingFallbackEmbedder {
                Text(String(localized: "(ArcFace unavailable — see log)"))
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
            Spacer()
        }
    }

    // MARK: - Session lock (face data is encrypted under the session key)

    private var sessionLockSection: some View {
        Group {
            if controller.store.isLocked {
                HStack {
                    Circle().fill(.red).frame(width: 8, height: 8)
                    Text(String(localized: "Session locked — enrolled faces are encrypted and can't be read or saved yet."))
                        .font(.caption)
                    Spacer()
                    Button(String(localized: "Unlock")) {
                        Task { await controller.unlockSession() }
                    }
                }
                if let error = controller.sessionError {
                    Text(error).font(.caption).foregroundStyle(.red)
                }
            }
        }
    }

    // MARK: - Preview

    private var previewSection: some View {
        GroupBox(String(localized: "Camera Preview")) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Circle()
                        .fill(controller.camera.isRunning ? .green : .gray)
                        .frame(width: 10, height: 10)
                    Text(controller.camera.isRunning ? String(localized: "Running") : String(localized: "Stopped"))
                    Spacer()
                    Button(controller.camera.isRunning ? String(localized: "Stop") : String(localized: "Start")) {
                        if controller.camera.isRunning {
                            controller.stop()
                        } else {
                            Task { await controller.start() }
                        }
                    }
                }

                if let error = controller.camera.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                CameraPreviewView(session: controller.camera.session, faces: controller.detectedFaces)
                    .frame(height: 300)
                    .background(Color.black.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Detection + alignment + embedding

    private var detectionSection: some View {
        GroupBox(String(localized: "Detection")) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(String(localized: "Faces detected: \(controller.detectedFaces.count)"))
                    if let quality = controller.currentResult?.quality {
                        Text(String(localized: "Capture quality: \(String(format: "%.0f%%", quality * 100))"))
                    } else {
                        Text(String(localized: "Capture quality: —"))
                            .foregroundStyle(.secondary)
                    }
                    if let result = controller.currentResult {
                        Text(String(localized: "Alignment: \(alignmentLabel(result.alignmentTier))"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(String(localized: "Embedding: \(result.embedding.count) numbers"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        // Calibration aid for onboarding's pose gating (see OnboardingController's poseMatches).
                        Text(String(localized: "Yaw: \(yawPitchString(result.face.yaw))  Pitch: \(yawPitchString(result.face.pitch))"))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                VStack(spacing: 4) {
                    Text(String(localized: "Aligned input")).font(.caption).foregroundStyle(.secondary)
                    if let aligned = controller.currentResult?.alignedImage {
                        Image(aligned, scale: 1, orientation: .up, label: Text(String(localized: "Aligned face")))
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 96, height: 96)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    } else {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray.opacity(0.15))
                            .frame(width: 96, height: 96)
                            .overlay(Text(String(localized: "No face")).font(.caption2).foregroundStyle(.secondary))
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Liveness

    /// All five cues, split by role (deny vs. confirm) rather than which checker they live in.
    private var livenessSection: some View {
        GroupBox(String(localized: "Liveness")) {
            VStack(alignment: .leading, spacing: 12) {
                decisionStrip

                Picker(String(localized: "Mode"), selection: $controller.livenessMode) {
                    ForEach(LivenessMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 220)

                Text(controller.livenessMode == .light
                     ? String(localized: "Light: only the deny cues run. Anything not actively rejected is treated as live.")
                     : String(localized: "Heavy: a deny cue fails the scan; at least one confirm cue must fire before it can pass."))
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Divider()

                cueGroup(
                    title: String(localized: "Deny — evidence of a spoof"),
                    caption: String(localized: "Either one firing fails face unlock outright, and overrides any confirmation."),
                    cues: LivenessCue.allCases.filter { $0.role == .deny }
                )

                cueGroup(
                    title: String(localized: "Confirm — evidence of a real face"),
                    caption: String(localized: "Any one firing passes liveness. None firing is not a failure — the scan just keeps looking."),
                    cues: LivenessCue.allCases.filter { $0.role == .confirm }
                )

                rawMeasurementsBlock
                geometryDiagnosticsBlock

                HStack {
                    Button(String(localized: "Reset cues")) { controller.resetLiveness() }
                    Text(String(localized: "Cue firing latches for the whole scan — reset to re-test."))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var decisionStrip: some View {
        let decision = controller.currentLiveness.decision
        let (color, label): (Color, String) = {
            switch decision {
            case .pending:
                return (.secondary, String(localized: "Pending — nothing decided yet"))
            case .confirmed(let cue):
                return (.green, cue.map { String(localized: "Live — confirmed by \($0.title)") } ?? String(localized: "Live — auto-confirmed (Light mode)"))
            case .denied(let cue):
                return (.red, String(localized: "Spoof — denied by \(cue.title)"))
            }
        }()
        return HStack(spacing: 10) {
            Circle().fill(color).frame(width: 10, height: 10)
            Text(label).font(.system(.body, design: .monospaced))
            Spacer()
            Text(String(localized: "\(controller.currentLiveness.frameCount) frames"))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func cueGroup(title: String, caption: String, cues: [LivenessCue]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption.weight(.semibold))
            ForEach(cues) { cue in
                cueRow(cue)
            }
            Text(caption)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(.top, 2)
        }
    }

    /// Level bar plus fire counter — the level only matters insofar as it crosses the fire threshold enough frames.
    private func cueRow(_ cue: LivenessCue) -> some View {
        let state = controller.currentLiveness.state(for: cue)
        let isEnabled = controller.isLivenessCueEnabled(cue)
        let threshold = controller.livenessTuning.level(for: cue)
        let framesNeeded = controller.livenessTuning.frames(for: cue)
        let hasEvidence = state.reading.confidence > 0

        return HStack(spacing: 8) {
            Toggle(String(localized: ""), isOn: Binding(
                get: { controller.isLivenessCueEnabled(cue) },
                set: { controller.setLivenessCue(cue, enabled: $0) }
            ))
            .toggleStyle(.checkbox)
            .labelsHidden()
            .help(cue.explanation)

            Text(cue.title)
                .font(.caption)
                .frame(width: 110, alignment: .leading)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2).fill(Color.gray.opacity(0.15))
                    RoundedRectangle(cornerRadius: 2)
                        .fill(hasEvidence ? (cue.role == .deny ? Color.orange : Color.accentColor) : Color.gray.opacity(0.3))
                        .frame(width: geometry.size.width * CGFloat(state.reading.level))
                    // Where this cue starts counting frames.
                    Rectangle()
                        .fill(Color.primary.opacity(0.45))
                        .frame(width: 1)
                        .offset(x: geometry.size.width * CGFloat(threshold))
                }
            }
            .frame(height: 8)

            Text(hasEvidence ? String(format: "%.0f%%", state.reading.level * 100) : "—")
                .font(.caption.monospacedDigit())
                .frame(width: 36, alignment: .trailing)

            Text(String(localized: "\(state.framesCounted)/\(framesNeeded)"))
                .font(.caption2.monospacedDigit())
                .frame(width: 40, alignment: .trailing)
                .foregroundStyle(.secondary)

            Text(state.hasFired ? String(localized: "FIRED") : "")
                .font(.caption2.weight(.bold))
                .foregroundStyle(cue.role == .deny ? Color.red : Color.green)
                .frame(width: 44, alignment: .leading)
        }
        .opacity(isEnabled ? 1 : 0.45)
    }

    /// The actual measurements each cue level is derived from.
    private var rawMeasurementsBlock: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let frame = controller.lastLivenessFrame {
                Text(String(localized: "Left EAR: \(ratioString(frame.leftEyeAspectRatio))  Right EAR: \(ratioString(frame.rightEyeAspectRatio))  Nose offset: \(ratioString(frame.noseOffsetRatio))"))
                Text(String(localized: "Device overlap: \(percentString(frame.deviceOverlapFraction))"))
                if let glare = frame.glare {
                    Text(String(localized: "Specular: \(String(format: "%.4f", glare.specularFraction))  Cluster: \(String(format: "%.2f", glare.specularClusterRatio))  Crop: \(Int(glare.cropPixelWidth))px"))
                } else {
                    Text(String(localized: "Specular: — (no native-resolution crop this frame)"))
                }
            } else {
                Text(String(localized: "No liveness frame yet."))
            }
        }
        .font(.caption2.monospacedDigit())
        .foregroundStyle(.secondary)
        .padding(.top, 4)
    }

    private var geometryDiagnosticsBlock: some View {
        let geo = controller.currentGeometry
        return VStack(alignment: .leading, spacing: 6) {
            Text(String(localized: "Flat vs 3D diagnostics"))
                .font(.caption.weight(.semibold))
            Text(String(localized: "Landmarks: \(geo.validLandmarkCount)   Pairs: \(geo.pairsAnalyzed)   Rejected: \(geo.rejectedPairCount)"))
            Text(String(localized: "Fit residual: \(ratioString(geo.medianFitResidual))  Probe residual: \(ratioString(geo.medianProbeResidual))  Excess: \(ratioString(geo.excessRatio))"))
            Text(String(localized: "Coherence: \(ratioString(geo.coherence))  Motion: \(ratioString(geo.motionMagnitude))"))
            if !geo.diagnosticRatios.isEmpty {
                Text(geo.diagnosticRatios.keys.sorted().map { key in
                    "\(diagnosticLabel(key)) \(ratioString(geo.diagnosticRatios[key]))"
                }.joined(separator: "  "))
            }
            if geo.planarConfidence == 0 {
                Text(String(localized: "Abstaining — not enough head rotation to tell a plane from a still 3D face."))
                    .foregroundStyle(.secondary)
            }
        }
        .font(.caption2.monospacedDigit())
        .foregroundStyle(.secondary)
        .padding(.top, 4)
    }

    private func ratioString(_ value: CGFloat?) -> String {
        guard let value else { return "—" }
        return String(format: "%+.3f", value)
    }

    private func percentString(_ value: CGFloat?) -> String {
        guard let value else { return "—" }
        return String(format: "%.0f%%", value * 100)
    }

    // MARK: - Enrollment

    private var enrollSection: some View {
        GroupBox(String(localized: "Enroll")) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    TextField(String(localized: "Name"), text: $controller.enrollName)
                        .textFieldStyle(.roundedBorder)
                    Button(String(localized: "Capture Sample")) {
                        controller.captureSample()
                    }
                    .disabled(controller.currentResult == nil || controller.store.isLocked)
                }

                if controller.store.identities.isEmpty {
                    Text(controller.store.isLocked ? String(localized: "Unlock the session to view enrolled identities.") : String(localized: "No identities enrolled yet."))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(controller.store.identities) { identity in
                        HStack {
                            Text(identity.name)
                            Text(identity.samples.count == 1
                                ? String(localized: "\(identity.samples.count) sample")
                                : String(localized: "\(identity.samples.count) samples"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if identity.isStale(comparedTo: controller.pipeline.embedder) {
                                Text(String(localized: "stale"))
                                    .font(.caption2.bold())
                                    .foregroundStyle(.orange)
                            }
                            Spacer()
                            Button(role: .destructive) {
                                controller.deleteIdentity(identity)
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Multi-identity enrollment

    private var identitiesSection: some View {
        GroupBox("Identities") {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(String(localized: "\(controller.store.identities.count) enrolled"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button(String(localized: "Add Identity")) {
                        controller.startAddIdentity()
                    }
                    .disabled(controller.store.isLocked || enrollmentFlowIsRunning)
                }

                if controller.store.identities.isEmpty {
                    Text(controller.store.isLocked
                         ? String(localized: "Unlock the session to view enrolled identities.")
                         : String(localized: "No identities enrolled yet — run the guided nine-pose capture with Add Identity."))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(controller.store.identities) { identity in
                        IdentityRow(
                            identity: identity,
                            isStale: identity.isStale(comparedTo: controller.pipeline.embedder),
                            lowQualityCount: controller.lowQualityCount(in: identity),
                            canStartFlow: !enrollmentFlowIsRunning,
                            recapture: { controller.startRecapture(of: identity) },
                            delete: { controller.deleteIdentity(identity) }
                        )
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Recognition

    private var recognizeSection: some View {
        GroupBox(String(localized: "Recognize")) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Button(String(localized: "Identify")) {
                        controller.recognize()
                    }
                    .disabled(controller.currentResult == nil || controller.store.identities.isEmpty)

                    Spacer()

                    Text(String(localized: "Threshold: \(String(format: "%.2f", controller.threshold))"))
                        .font(.caption)
                    Slider(value: $controller.threshold, in: -1...1)
                        .frame(width: 160)
                }

                if let best = controller.bestMatch {
                    HStack {
                        Circle().fill(.green).frame(width: 10, height: 10)
                        Text(String(localized: "Best match: \(best.name) — centroid \(String(format: "%.3f", best.centroidSimilarity)), max \(String(format: "%.3f", best.maxSampleSimilarity))"))
                        Text(String(localized: "MATCH")).font(.caption.bold()).foregroundStyle(.green)
                    }
                } else if let first = controller.recognitionResults.first {
                    HStack {
                        Circle().fill(.red).frame(width: 10, height: 10)
                        Text(String(localized: "Closest: \(first.name) — centroid \(String(format: "%.3f", first.centroidSimilarity)), max \(String(format: "%.3f", first.maxSampleSimilarity))"))
                        Text(String(localized: "NO MATCH")).font(.caption.bold()).foregroundStyle(.red)
                    }
                }

                if !controller.recognitionResults.isEmpty {
                    Divider()
                    ForEach(controller.recognitionResults) { result in
                        HStack {
                            Text(result.name)
                            if result.isStale {
                                Text(String(localized: "stale")).font(.caption2.bold()).foregroundStyle(.orange)
                            }
                            Spacer()
                            Text(String(localized: "centroid \(String(format: "%.3f", result.centroidSimilarity))"))
                                .foregroundStyle(.secondary)
                            Text(String(localized: "max \(String(format: "%.3f", result.maxSampleSimilarity))"))
                                .foregroundStyle(.secondary)
                        }
                        .font(.caption)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Threshold calibration

    private var calibrationSection: some View {
        GroupBox(String(localized: "Threshold Calibration")) {
            VStack(alignment: .leading, spacing: 8) {
                Text(String(localized: "Run Identify, then tag whether that was really you or someone else — do this across lighting, angle, and expression, and again with a different person, to see where the two score distributions actually fall."))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack {
                    Button(String(localized: "Mark Genuine (this is me)")) {
                        controller.recordCalibrationSample(isGenuine: true)
                    }
                    Button(String(localized: "Mark Impostor (not me)")) {
                        controller.recordCalibrationSample(isGenuine: false)
                    }
                    .disabled(controller.recognitionResults.isEmpty)
                    Spacer()
                    Button(String(localized: "Clear"), role: .destructive) {
                        controller.clearCalibrationSamples()
                    }
                    .disabled(controller.calibrationSamples.isEmpty)
                }
                .disabled(controller.recognitionResults.isEmpty && controller.calibrationSamples.isEmpty)

                if !controller.calibrationSamples.isEmpty {
                    Chart {
                        ForEach(controller.calibrationSamples) { sample in
                            PointMark(
                                x: .value(String(localized: "Similarity"), sample.centroidSimilarity),
                                y: .value(String(localized: "Type"), sample.isGenuine ? String(localized: "Genuine") : String(localized: "Impostor"))
                            )
                            .foregroundStyle(sample.isGenuine ? Color.green : Color.red)
                        }
                        RuleMark(x: .value(String(localized: "Threshold"), controller.threshold))
                            .foregroundStyle(.blue)
                            .lineStyle(StrokeStyle(lineWidth: 2, dash: [4, 4]))
                    }
                    .chartXScale(domain: -1...1)
                    .frame(height: 100)

                    if let suggested = controller.suggestedThreshold {
                        HStack {
                            Text(String(localized: "Suggested threshold: \(String(format: "%.3f", suggested))"))
                                .font(.caption)
                            Button(String(localized: "Use it")) {
                                controller.threshold = Double(suggested)
                            }
                            if controller.calibrationDistributionsOverlap {
                                Text(String(localized: "Distributions overlap — no single cutoff perfectly separates these samples yet."))
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }
                        }
                    } else {
                        Text(String(localized: "Record at least one genuine and one impostor sample to get a suggestion."))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Debug log

    private var logSection: some View {
        GroupBox(String(localized: "Log")) {
            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(Array(controller.logLines.enumerated()), id: \.offset) { _, line in
                        Text(line)
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 120)
        }
    }

    private func alignmentLabel(_ tier: AlignmentTier) -> String {
        switch tier {
        case .fivePoint: return String(localized: "5-point")
        case .twoPoint: return String(localized: "2-point (eyes only)")
        case .paddedCrop: return String(localized: "padded crop (no alignment)")
        }
    }

 private func diagnosticLabel(_ key: String) -> String {
        switch key {
        case "interocular": return String(localized: "interocular")
        case String(localized: "yaw range (deg)"): return String(localized: "yaw range (deg)")
        case "eye / faceW": return String(localized: "eye / faceW")
        case "nose-eye / faceH": return String(localized: "nose-eye / faceH")
        case "nose-mouth / faceH": return String(localized: "nose-mouth / faceH")
        case "mouthW / faceW": return String(localized: "mouthW / faceW")
        case "eye / nose-mouth": return String(localized: "eye / nose-mouth")
        default: return key
        }
    }

    private func yawPitchString(_ value: Float?) -> String {
        guard let value else { return "—" }
        return String(format: "%+.2f", value)
    }
}

/// One enrolled person: a summary line, actions, and a disclosure listing every stored sample's capture quality.
private struct IdentityRow: View {
    let identity: FaceIdentity
    let isStale: Bool
    let lowQualityCount: Int
    let canStartFlow: Bool
    let recapture: () -> Void
    let delete: () -> Void

    private func poseLabel(_ pose: String) -> String {
            switch pose {
            case "center": return String(localized: "center")
            case "left": return String(localized: "left")
            case "top_left": return String(localized: "top_left")
            case "top": return String(localized: "top")
            case "top_right": return String(localized: "top_right")
            case "right": return String(localized: "right")
            case "bottom_right": return String(localized: "bottom_right")
            case "bottom": return String(localized: "bottom")
            case "bottom_left": return String(localized: "bottom_left")
            default: return String(localized: "untagged")
            }
        }

    private var posesCaptured: Int {
        Set(identity.samples.compactMap(\.pose)).count
    }

    var body: some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(Array(identity.samples.enumerated()), id: \.offset) { index, sample in
                    HStack(spacing: 8) {
                        Text(String(format: "%2d", index + 1))
                            .foregroundStyle(.tertiary)
                        Text(poseLabel(sample.pose ?? "untagged"))
                            .frame(width: 90, alignment: .leading)
                        Text(FaceLabController.qualityLabel(sample.quality))
                            .frame(width: 44, alignment: .trailing)
                            .foregroundStyle(isLow(sample) ? .orange : .primary)
                        Text(sample.capturedAt.formatted(date: .omitted, time: .standard))
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .font(.caption.monospaced())
                }
            }
            .padding(.top, 4)
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(identity.name).bold()
                    if isStale {
                        Text(String(localized: "stale"))
                            .font(.caption2.bold())
                            .foregroundStyle(.orange)
                    }
                    Spacer()
                    Button(String(localized: "Recapture"), action: recapture)
                        .disabled(!canStartFlow)
                    Button(role: .destructive, action: delete) {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.plain)
                }

                Text(String(localized: "\(posesCaptured)/9 poses · \(identity.samples.count) samples · enrolled \(identity.createdAt.formatted(date: .abbreviated, time: .shortened))"))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if lowQualityCount > 0 {
                    Text(String(localized: "\(lowQualityCount) of \(identity.samples.count) samples are low quality"))
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
        }
    }

    private func isLow(_ sample: FaceSample) -> Bool {
        identity.qualityTier(of: sample) == .poor
    }
}

#Preview {
    FaceLabView(controller: FaceLabController())
}
