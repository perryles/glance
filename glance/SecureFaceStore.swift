//
//  SecureFaceStore.swift
//  glance
//
//  Low-level encrypted persistence for enrolled face identities — AES-GCM under the same session key SecureCredentialManager
//  uses for the Mac password, rather than a second key. `FaceEnrollmentStore` delegates its load/save here; no plaintext fallback.
//

import Foundation

enum SecureFaceStoreError: LocalizedError {
    case sessionLocked

    var errorDescription: String? {
        switch self {
        case .sessionLocked:
            return String(localized: "Session is locked. Authenticate with Touch ID to access enrolled faces.")
        }
    }
}

nonisolated enum SecureFaceStore {
    private static let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    // Match this app's credential namespace instead of sharing ciphertext with the upstream app.
    private static let directory = appSupport.appendingPathComponent(Bundle.main.bundleIdentifier ?? "com.perryles.glance", isDirectory: true)
    private static let fileURL = directory.appendingPathComponent("face-identities.enc")
    private static let legacyFileURL = appSupport.appendingPathComponent("glance/face-identities.enc")
    private static let legacyImportDisabledURL = directory.appendingPathComponent("legacy-face-import-disabled")

    /// True if a store exists on disk, regardless of whether the session is currently unlocked enough to read it.
    static var exists: Bool {
        FileManager.default.fileExists(atPath: fileURL.path)
    }

    /// Throws `.sessionLocked` rather than returning an empty array, so callers can distinguish "nothing enrolled" from "enrolled, but locked".
    static func load() throws -> [FaceIdentity] {
        guard SecureCredentialManager.isSessionUnlocked else { throw SecureFaceStoreError.sessionLocked }
        if !exists {
            guard !FileManager.default.fileExists(atPath: legacyImportDisabledURL.path),
                  FileManager.default.fileExists(atPath: legacyFileURL.path) else { return [] }
            let ciphertext = try Data(contentsOf: legacyFileURL)
            let plaintext: Data
            do {
                plaintext = try SecureCredentialManager.decrypt(ciphertext)
            } catch SecureCredentialError.decryptionFailed {
                // A different app's key owns this legacy file. Leave it available to that app.
                return []
            }
            let identities = try JSONDecoder().decode([FaceIdentity].self, from: plaintext)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try ciphertext.write(to: fileURL, options: .atomic)
            return identities
        }
        let ciphertext = try Data(contentsOf: fileURL)
        let plaintext = try SecureCredentialManager.decrypt(ciphertext)
        return try JSONDecoder().decode([FaceIdentity].self, from: plaintext)
    }

    static func save(_ identities: [FaceIdentity]) throws {
        guard SecureCredentialManager.isSessionUnlocked else { throw SecureFaceStoreError.sessionLocked }
        let plaintext = try JSONEncoder().encode(identities)
        let ciphertext = try SecureCredentialManager.encrypt(plaintext)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try ciphertext.write(to: fileURL, options: .atomic)
    }

    static func deleteAll() throws {
        // Record removal before deleting so a later load cannot restore legacy enrollment.
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Data().write(to: legacyImportDisabledURL, options: .atomic)
        if exists { try FileManager.default.removeItem(at: fileURL) }
    }
}
