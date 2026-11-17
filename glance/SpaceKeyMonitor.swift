//
//  SpaceKeyMonitor.swift
//  glance
//
//  Detects the space key on the lock screen via raw IOKit HID reads — Secure Event Input suppresses every other keyboard tap there.
//
//  glance never appears under Input Monitoring: TCC resolves that gate against Accessibility first, and glance already requires
//  Accessibility to type the password, so `IOHIDCheckAccess` grants without ever registering it there. Correct, not a bug.
//
//  Graceful degradation: if access isn't granted or `IOHIDManagerOpen` fails, `start()` no-ops rather than crashing.
//
//  Only the spacebar is queued. Keep the device open before locking, and act only while the screen is authoritatively locked.
//

import Foundation
import IOKit.hid
import OSLog

@MainActor
final class SpaceKeyMonitor {
    /// Traces the Input Monitoring handshake, otherwise invisible since TCC decisions happen out of process.
    static let log = Logger(subsystem: "com.perryles.glance", category: "inputmonitoring")

    /// Fires on key-down only, not release or auto-repeat.
    var onSpaceKeyDown: (() -> Void)?

    private var manager: IOHIDManager?
    private var generation = 0
    private var keyState = SpaceKeyState()

    // MARK: - Input Monitoring permission (static — callable without an instance)

    /// `denied` matters on its own: once set, no API can re-prompt — only System Settings can undo it.
    enum InputMonitoringAccess {
        case granted
        case denied
        case notDetermined
    }

    static var inputMonitoringAccess: InputMonitoringAccess {
        let raw = IOHIDCheckAccess(kIOHIDRequestTypeListenEvent)
        let state: InputMonitoringAccess
        switch raw {
        case kIOHIDAccessTypeGranted: state = .granted
        case kIOHIDAccessTypeDenied: state = .denied
        default: state = .notDetermined
        }
        log.info("checkAccess -> \(String(describing: state), privacy: .public) (raw \(raw.rawValue)), xcodeLaunched=\(isLaunchedByXcode, privacy: .public)")
        return state
    }

    /// Never prompts. True whenever Accessibility is granted (see file header), so it tracks `KeystrokeInjector.isAccessibilityTrusted()`.
    static func hasInputMonitoringAccess() -> Bool {
        inputMonitoringAccess == .granted
    }

    /// True when launched by Xcode's Run button, which makes TCC decisions attribute to Xcode, not glance — test permission
    /// behavior from an independently launched copy instead (`open /path/to/glance.app`, or a build in /Applications).
    static var isLaunchedByXcode: Bool {
        ProcessInfo.processInfo.environment["__XCODE_BUILT_PRODUCTS_DIR_PATHS"] != nil
    }

    /// Near-always a no-op: already satisfied through Accessibility. Skipped under Xcode, where it would attribute to Xcode instead.
    @discardableResult
    static func requestInputMonitoringAccess() -> Bool {
        guard !isLaunchedByXcode else {
            log.error("requestAccess SKIPPED — launched by Xcode, request would be attributed to Xcode")
            return hasInputMonitoringAccess()
        }
        let granted = IOHIDRequestAccess(kIOHIDRequestTypeListenEvent)
        log.info("requestAccess -> \(granted, privacy: .public)")
        return granted
    }

    // MARK: - Lifecycle

    /// Idempotent; fails closed if access was revoked between the caller's check and here.
    func start() {
        guard manager == nil else { return }

        let mgr = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        // Match physical keyboards only, not every HID device.
        let match: [String: Int] = [
            kIOHIDDeviceUsagePageKey: kHIDPage_GenericDesktop,
            kIOHIDDeviceUsageKey: kHIDUsage_GD_Keyboard,
        ]
        IOHIDManagerSetDeviceMatching(mgr, match as CFDictionary)

        IOHIDManagerSetInputValueMatching(mgr, [
            kIOHIDElementUsagePageKey: kHIDPage_KeyboardOrKeypad,
            kIOHIDElementUsageKey: kHIDUsage_KeyboardSpacebar,
        ] as CFDictionary)
        generation &+= 1
        let callback = SpaceKeyCallbackContext(monitor: self, generation: generation)
        let context = Unmanaged.passRetained(callback).toOpaque()
        IOHIDManagerRegisterInputValueCallback(mgr, { context, result, _, value in
            guard let context, result == kIOReturnSuccess else { return }
            MainActor.assumeIsolated {
                let callback = Unmanaged<SpaceKeyCallbackContext>.fromOpaque(context).takeUnretainedValue()
                guard let monitor = callback.monitor, callback.generation == monitor.generation else { return }
                let element = IOHIDValueGetElement(value)
                guard IOHIDElementGetUsagePage(element) == UInt32(kHIDPage_KeyboardOrKeypad),
                      IOHIDElementGetUsage(element) == UInt32(kHIDUsage_KeyboardSpacebar) else { return }
                let device = IOHIDElementGetDevice(element)
                let id = UInt(bitPattern: Unmanaged.passUnretained(device).toOpaque())
                let pressed = monitor.keyState.receive(device: id, isDown: IOHIDValueGetIntegerValue(value) != 0)
                guard pressed else { return }
                monitor.onSpaceKeyDown?()
            }
        }, context)
        IOHIDManagerRegisterDeviceRemovalCallback(mgr, { context, _, _, device in
            guard let context else { return }
            MainActor.assumeIsolated {
                let callback = Unmanaged<SpaceKeyCallbackContext>.fromOpaque(context).takeUnretainedValue()
                let id = UInt(bitPattern: Unmanaged.passUnretained(device).toOpaque())
                guard let monitor = callback.monitor, callback.generation == monitor.generation else { return }
                monitor.keyState.remove(device: id)
            }
        }, context)
        IOHIDManagerSetDispatchQueue(mgr, .main)
        // IOKit requires the manager and callback context to survive until cancellation completes.
        let retainedManager = Unmanaged.passRetained(mgr)
        IOHIDManagerSetCancelHandler(mgr) {
            Unmanaged<SpaceKeyCallbackContext>.fromOpaque(context).release()
            retainedManager.release()
        }
        let result = IOHIDManagerOpen(mgr, IOOptionBits(kIOHIDOptionsTypeNone))
        IOHIDManagerActivate(mgr)
        guard result == kIOReturnSuccess else {
            Self.log.error("IOHIDManagerOpen failed (0x\(String(result, radix: 16), privacy: .public))")
            IOHIDManagerCancel(mgr)
            return
        }
        manager = mgr
        Self.log.info("space-only HID queue started before lock")
    }

    func resetKeyState() { keyState.reset() }

    func stop() {
        generation &+= 1
        keyState.reset()
        guard let mgr = manager else { return }
        manager = nil
        IOHIDManagerClose(mgr, IOOptionBits(kIOHIDOptionsTypeNone))
        IOHIDManagerCancel(mgr)
    }

    deinit {
        if let manager {
            IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
            IOHIDManagerCancel(manager)
        }
    }
}

@MainActor
private final class SpaceKeyCallbackContext {
    weak var monitor: SpaceKeyMonitor?
    let generation: Int

    init(monitor: SpaceKeyMonitor, generation: Int) {
        self.monitor = monitor
        self.generation = generation
    }
}
