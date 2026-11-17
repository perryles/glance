//
//  SystemAuthenticationPromptPolicy.swift
//  glance
//
//  Decides whether a focused password field belongs to a macOS authentication
//  prompt that Glance is allowed to assist. Every check is deliberately paired
//  with the allowlist below: a bundle ID alone is spoofable by third-party apps.
//

import Foundation

/// The immutable snapshot passed to the trust policy. The reader supplies real
/// Accessibility values; tests construct descriptors directly.
struct SystemAuthenticationPromptDescriptor: Equatable {
    var bundleIdentifier: String?
    var executablePath: String?
    var focusedElementRole: String?
    var focusedElementSubrole: String? = nil
    var isFocusedElementEnabled: Bool
}

enum SystemAuthenticationPromptPolicy {
    /// System-owned agents that ask for the Mac user's login password, including
    /// LocalAuthentication fallback during passkey and app authorization flows.
    private static let allowedBundleIdentifiers: Set<String> = [
        "com.apple.SecurityAgent",
        "com.apple.LocalAuthentication.UIAgent",
    ]

    /// A focused field is trusted only when its owning executable is Apple system
    /// software. Path + bundle ID prevents a third-party app from impersonating a
    /// system prompt merely by claiming the same bundle identifier.
    static func isTrusted(_ descriptor: SystemAuthenticationPromptDescriptor?) -> Bool {
        guard let descriptor,
              descriptor.isFocusedElementEnabled,
              descriptor.focusedElementRole == "AXTextField",
              descriptor.focusedElementSubrole == "AXSecureTextField",
              let bundleIdentifier = descriptor.bundleIdentifier,
              allowedBundleIdentifiers.contains(bundleIdentifier),
              let executablePath = descriptor.executablePath
        else { return false }

        let path = URL(fileURLWithPath: executablePath).standardizedFileURL.path
        return path == "/System" || path == "/usr/libexec" || path.hasPrefix("/System/") || path.hasPrefix("/usr/libexec/")
    }

    static func signingRequirement(for descriptor: SystemAuthenticationPromptDescriptor) -> String? {
        guard isTrusted(descriptor), let bundleIdentifier = descriptor.bundleIdentifier else { return nil }
        return "anchor apple and identifier \"\(bundleIdentifier)\""
    }
}
