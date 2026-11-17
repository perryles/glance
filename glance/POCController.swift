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
    var unlocksAtLogin: Bool = SecureCredentialManager.unlocksAtLogin
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
        unlocksAtLogin = SecureCredentialManager.unlocksAtLogin
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

    /// Silent launch-time unlock for users who opted in to unlocking at login. Never prompts; stays locked otherwise.
    func unlockSessionAtLaunch() async {
        _ = await Task.detached(priority: .userInitiated) {
            SecureCredentialManager.unlockSessionFromLoginKey()
        }.value
        refreshCredentialStatus()
    }

    /// Throws so the toggle can revert itself; the state is re-read from the keychain either way.
    func setUnlockAtLogin(_ enabled: Bool) throws {
        defer { refreshCredentialStatus() }
        try SecureCredentialManager.setUnlockAtLogin(enabled)
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
        systemAuthenticationPrompt: SystemAuthenticationPrompt? = nil,
        authorization: @escaping @MainActor () -> Bool = { true }
    ) async -> Bool {
        guard KeystrokeInjector.isAccessibilityTrusted() else {
            statusMessage = String(localized: "Accessibility not granted — open System Settings and enable glance.")
            return false
        }
        let session = SecureCredentialManager.sessionIdentifier
        let authorized = {
            !Task.isCancelled && session != nil && SecureCredentialManager.sessionIdentifier == session && authorization()
                && (!requireAuthoritativeLock || LockMonitor.isScreenActuallyLocked())
                && (systemAuthenticationPrompt == nil || (
                    GlanceSettings.shared.isFaceUnlockEnabled
                    && GlanceSettings.shared.isSystemAuthenticationAssistEnabled
                    && SystemAuthenticationPromptMonitor.shared.currentTrustedPrompt() == systemAuthenticationPrompt))
        }
        guard authorized() else {
            statusMessage = String(localized: "Unlock authorization expired or was cancelled.")
            return false
        }
        statusMessage = String(localized: "Injecting…")
        do {
            var bytes = try await Task.detached(priority: .userInitiated) {
                try SecureCredentialManager.readPassword()
            }.value
            defer { bytes.resetBytes(in: 0..<bytes.count) }
            guard authorized() else { throw KeystrokeError.authorizationExpired }
            if let systemAuthenticationPrompt {
                try SystemAuthenticationPromptMonitor.shared.fillPassword(bytes, in: systemAuthenticationPrompt)
            } else {
                try await KeystrokeInjector.typeAndReturn(bytes, stillAuthorized: authorized)
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
