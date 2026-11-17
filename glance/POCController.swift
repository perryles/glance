//
//  POCController.swift
//  glance
//
//  Orchestration for credential storage: wires SecureCredentialManager to
//  KeystrokeInjector and exposes session/password status for Settings.
//

import Foundation
import Observation

@Observable
@MainActor
final class POCController {
    var accessibilityGranted: Bool = KeystrokeInjector.isAccessibilityTrusted()

    var hasStoredPassword: Bool = SecureCredentialManager.hasStoredPassword()
    var isSessionUnlocked: Bool = SecureCredentialManager.isSessionUnlocked
    var sessionError: String? = nil

    /// Bound to the setup SecureField. Cleared immediately after a successful save.
    var passwordInput: String = ""

    var statusMessage: String = String(localized: "Idle")

    func refreshAccessibilityStatus() {
        accessibilityGranted = KeystrokeInjector.isAccessibilityTrusted()
    }

    func requestAccessibility() {
        KeystrokeInjector.promptForAccessibility()
    }

    func refreshCredentialStatus() {
        hasStoredPassword = SecureCredentialManager.hasStoredPassword()
        isSessionUnlocked = SecureCredentialManager.isSessionUnlocked
    }

    // MARK: - Session (Touch ID gate)

    /// Must succeed before `savePassword()` or `injectStoredPassword()` will do anything.
    func unlockSession() async {
        sessionError = nil
        do {
            try await Task.detached(priority: .userInitiated) {
                try SecureCredentialManager.unlockSession(reason: String(localized: "Authenticate to set up or use glance"))
            }.value
            isSessionUnlocked = true
        } catch {
            isSessionUnlocked = false
            sessionError = error.localizedDescription
        }
    }

    func lockSession() {
        SecureCredentialManager.lockSession()
        isSessionUnlocked = false
    }

    // MARK: - Setup flow

    /// Encrypts and stores `passwordInput`. Requires the session to already
    /// be unlocked (Touch ID happens in `unlockSession()`, not here).
    func savePassword() async {
        guard !passwordInput.isEmpty else {
            statusMessage = String(localized: "Enter a password first.")
            return
        }
        let plaintext = passwordInput
        passwordInput = ""

        do {
            try await Task.detached(priority: .userInitiated) {
                guard var bytes = plaintext.data(using: .utf8) else {
                    throw SecureCredentialError.emptyPassword
                }
                defer { bytes.resetBytes(in: 0..<bytes.count) }
                try SecureCredentialManager.savePassword(bytes)
            }.value
            statusMessage = String(localized: "Password saved and encrypted.")
            hasStoredPassword = true
        } catch {
            statusMessage = String(localized: "Save failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Injection

    /// Reads + decrypts + injects the stored password, zeroing the plaintext
    /// buffer before returning. When `requireAuthoritativeLock` is true (the
    /// auto-trigger path), refuses to inject unless the CGSession dictionary
    /// confirms the screen is actually locked.
    @discardableResult
    func injectStoredPassword(
        requireAuthoritativeLock: Bool = false,
        systemAuthenticationPrompt: SystemAuthenticationPrompt? = nil
    ) async -> Bool {
        guard KeystrokeInjector.isAccessibilityTrusted() else {
            statusMessage = String(localized: "Accessibility not granted — open System Settings and enable glance.")
            return false
        }
        guard SecureCredentialManager.isSessionUnlocked else {
            statusMessage = String(localized: "Session locked — authenticate with Touch ID first.")
            return false
        }

        if requireAuthoritativeLock {
            guard LockMonitor.isScreenActuallyLocked() else {
                statusMessage = String(localized: "Skipped: CGSession reports screen is not actually locked.")
                return false
            }
        }
        if let systemAuthenticationPrompt {
            guard SystemAuthenticationPromptMonitor.shared.currentTrustedPrompt() == systemAuthenticationPrompt else {
                statusMessage = String(localized: "Skipped: the supported system password prompt is no longer focused.")
                return false
            }
        }

        statusMessage = String(localized: "Injecting…")
        do {
            if let systemAuthenticationPrompt {
                var bytes = try await Task.detached(priority: .userInitiated) {
                    try SecureCredentialManager.readPassword()
                }.value
                defer { bytes.resetBytes(in: 0..<bytes.count) }
                try Task.checkCancellation()
                guard SecureCredentialManager.isSessionUnlocked,
                      GlanceSettings.shared.isFaceUnlockEnabled,
                      GlanceSettings.shared.isSystemAuthenticationAssistEnabled else {
                    throw SystemAuthenticationPromptError.unavailable
                }
                try SystemAuthenticationPromptMonitor.shared.fillPassword(bytes, in: systemAuthenticationPrompt)
            } else {
                try await Task.detached(priority: .userInitiated) {
                    var bytes = try SecureCredentialManager.readPassword()
                    defer { bytes.resetBytes(in: 0..<bytes.count) }
                    try KeystrokeInjector.typeAndReturn(bytes)
                }.value
            }
            statusMessage = systemAuthenticationPrompt != nil
                ? String(localized: "Filled supported system password prompt at \(Date().formatted(date: .omitted, time: .standard))")
                : String(localized: "Injected stored password + Return at \(Date().formatted(date: .omitted, time: .standard))")
            return true
        } catch {
            statusMessage = String(localized: "Injection failed: \(error.localizedDescription)")
            return false
        }
    }
}
