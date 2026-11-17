//
//  SystemAuthenticationPromptMonitor.swift
//  glance
//
//  Reads the focused Accessibility element and turns it into the policy's
//  descriptor. This is read-only: no text or password is ever read from the
//  focused field.
//

import AppKit
import ApplicationServices
import Carbon.HIToolbox
import Foundation
import Security

/// A trusted prompt snapshot. The process identity is retained so logging and
/// future diagnostics can distinguish SecurityAgent from System Settings.
struct SystemAuthenticationPrompt: Equatable {
    var descriptor: SystemAuthenticationPromptDescriptor
    var processIdentifier: pid_t
    var focusedElement: AXUIElement

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.descriptor == rhs.descriptor && lhs.processIdentifier == rhs.processIdentifier &&
            CFEqual(lhs.focusedElement, rhs.focusedElement)
    }
}

enum SystemAuthenticationPromptError: LocalizedError {
    case unavailable
    case notWritable

    var errorDescription: String? {
        switch self {
        case .unavailable:
            String(localized: "The system password prompt changed. Focus it and try the shortcut again.")
        case .notWritable:
            String(localized: "macOS refused to fill this password field. Enter your password manually.")
        }
    }
}

@MainActor
final class SystemAuthenticationPromptMonitor {
    static let shared = SystemAuthenticationPromptMonitor()

    /// Returns the currently focused prompt only when every policy gate passes.
    /// `nil` does not distinguish “no prompt” from “untrusted prompt”; callers
    /// should treat both as reasons not to type the password.
    func currentTrustedPrompt() -> SystemAuthenticationPrompt? {
        // The login-screen path owns locked-screen authentication. System prompt
        // assist is only for an unlocked session's foreground authorization UI.
        guard !LockMonitor.isScreenActuallyLocked() else { return nil }
        guard KeystrokeInjector.isAccessibilityTrusted() else { return nil }

        let systemWide = AXUIElementCreateSystemWide()
        var focusedApplicationValue: CFTypeRef?
        guard AXUIElementCopyAttributeValue(
            systemWide,
            kAXFocusedApplicationAttribute as CFString,
            &focusedApplicationValue
        ) == .success else { return nil }

        let focusedApplication = focusedApplicationValue as! AXUIElement
        var processIdentifier: pid_t = -1
        guard AXUIElementGetPid(focusedApplication, &processIdentifier) == .success,
              processIdentifier > 0 else { return nil }

        var focusedElementValue: CFTypeRef?
        guard AXUIElementCopyAttributeValue(
            focusedApplication,
            kAXFocusedUIElementAttribute as CFString,
            &focusedElementValue
        ) == .success else { return nil }

        let focusedElement = focusedElementValue as! AXUIElement
        var roleValue: CFTypeRef?
        var subroleValue: CFTypeRef?
        var enabledValue: CFTypeRef?

        guard AXUIElementCopyAttributeValue(focusedElement, kAXRoleAttribute as CFString, &roleValue) == .success,
              let role = roleValue as? String else { return nil }
        guard AXUIElementCopyAttributeValue(focusedElement, kAXSubroleAttribute as CFString, &subroleValue) == .success,
              let subrole = subroleValue as? String else { return nil }

        // An absent enabled value is treated as disabled; every usable system
        // password field observed so far exposes this attribute.
        let enabled = AXUIElementCopyAttributeValue(
            focusedElement,
            kAXEnabledAttribute as CFString,
            &enabledValue
        ) == .success && (enabledValue as? Bool == true)

        let runningApplication = NSRunningApplication(processIdentifier: processIdentifier)
        let bundleIdentifier = runningApplication?.bundleIdentifier

        let descriptor = SystemAuthenticationPromptDescriptor(
            bundleIdentifier: bundleIdentifier,
            executablePath: runningApplication?.executableURL?.path,
            focusedElementRole: role,
            focusedElementSubrole: subrole,
            isFocusedElementEnabled: enabled
        )
        guard let signingRequirement = SystemAuthenticationPromptPolicy.signingRequirement(for: descriptor) else { return nil }
        var code: SecCode?
        var requirement: SecRequirement?
        guard SecCodeCopyGuestWithAttributes(nil, [kSecGuestAttributePid: processIdentifier] as CFDictionary, [], &code) == errSecSuccess,
              let code,
              SecRequirementCreateWithString(signingRequirement as CFString, [], &requirement) == errSecSuccess,
              let requirement,
              SecCodeCheckValidity(code, [], requirement) == errSecSuccess else { return nil }
        return SystemAuthenticationPrompt(descriptor: descriptor, processIdentifier: processIdentifier, focusedElement: focusedElement)
    }

    /// Address the retained field directly so changing keyboard focus cannot send the password elsewhere.
    func fillPassword(_ bytes: Data, in prompt: SystemAuthenticationPrompt) throws {
        guard currentTrustedPrompt() == prompt else { throw SystemAuthenticationPromptError.unavailable }
        guard let password = String(data: bytes, encoding: .utf8),
              AXUIElementSetAttributeValue(prompt.focusedElement, kAXValueAttribute as CFString, password as CFString) == .success else {
            throw SystemAuthenticationPromptError.notWritable
        }
    }
}

/// A compact Carbon hot-key owner. Registration is idempotent and always undone
/// when the feature is disabled, so no global shortcut lingers after opt-out.
@MainActor
final class GlobalHotKeyMonitor {
    var handler: (() -> Void)?

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?

    init() {}

    deinit {
        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
        }
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }
    }

    func setEnabled(_ enabled: Bool) {
        if enabled {
            register()
        } else {
            unregister()
        }
    }

    private func register() {
        guard hotKeyRef == nil, eventHandlerRef == nil else { return }

        var eventSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))
        let hotKeyID = EventHotKeyID(signature: 0x474C4143, id: 1) // 'GLAC'

        let pointer = Unmanaged.passUnretained(self).toOpaque()
        let installStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData in
                var receivedID = EventHotKeyID()
                let status = GetEventParameter(
                    event,
                    OSType(kEventParamDirectObject),
                    OSType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &receivedID
                )
                guard status == noErr, receivedID.signature == 0x474C4143, receivedID.id == 1 else {
                    return OSStatus(eventNotHandledErr)
                }
                let monitor = Unmanaged<GlobalHotKeyMonitor>.fromOpaque(userData!).takeUnretainedValue()
                DispatchQueue.main.async { monitor.handler?() }
                return noErr
            },
            1,
            &eventSpec,
            pointer,
            &eventHandlerRef
        )
        guard installStatus == noErr else { return }

        // Control+Option+Command+F. It is intentionally not auto-filled: the
        // shortcut is the user's per-prompt consent to start a face scan.
        let registerStatus = RegisterEventHotKey(
            UInt32(kVK_ANSI_F),
            UInt32(controlKey | optionKey | cmdKey),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        if registerStatus != noErr, let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
            self.eventHandlerRef = nil
        }
    }

    private func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
            self.eventHandlerRef = nil
        }
    }
}
