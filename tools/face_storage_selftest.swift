// Runs the real credential crypto and face store against an in-memory Keychain.
// Run each scenario with CFFIXED_USER_HOME pointing to a fresh temporary directory.
import Foundation
import LocalAuthentication
import Security

enum KeychainManager {
    private static var items: [String: Data] = [:]

    static func exists(account: String) -> Bool { items[account] != nil }

    static func read(account: String, context: LAContext? = nil) throws -> Data {
        guard let data = items[account] else { throw CocoaError(.fileNoSuchFile) }
        return data
    }

    static func save(account: String, data: Data, accessControl: SecAccessControl? = nil) throws {
        items[account] = data
    }

    static func delete(account: String) throws { items[account] = nil }

    static func makeUserPresenceAccessControl() throws -> SecAccessControl {
        SecAccessControlCreateWithFlags(nil, kSecAttrAccessibleWhenUnlockedThisDeviceOnly, .userPresence, nil)!
    }
}

private func check(_ condition: Bool, _ message: String = "Storage assertion failed") {
    precondition(condition, message)
}

@main
struct FaceStorageSelftest {
    @MainActor
    static func main() throws {
        guard let home = ProcessInfo.processInfo.environment["CFFIXED_USER_HOME"],
              home.hasPrefix("/tmp/"), CommandLine.arguments.count == 2 else {
            fatalError("Run with a fresh CFFIXED_USER_HOME under /tmp and a scenario argument")
        }
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        check(support.path.hasPrefix(home))
        let legacy = support.appendingPathComponent("glance/face-identities.enc")
        let scoped = support.appendingPathComponent("com.perryles.glance/face-identities.enc")
        try FileManager.default.createDirectory(at: legacy.deletingLastPathComponent(), withIntermediateDirectories: true)

        switch CommandLine.arguments[1] {
        case "foreign":
            let foreignData = Data("encrypted by another app's key".utf8)
            try foreignData.write(to: legacy)
            check(!SecureCredentialManager.hasSessionEncryptedData, "Foreign face data must not block a fresh session")
            try SecureCredentialManager.unlockSession(reason: "Selftest")
            try check(SecureFaceStore.load().isEmpty)
            try SecureFaceStore.save([])
            check(FileManager.default.fileExists(atPath: scoped.path))
            try check(Data(contentsOf: legacy) == foreignData)
            SecureCredentialManager.lockSession()
            try SecureCredentialManager.unlockSession(reason: "Selftest")
            try check(SecureFaceStore.load().isEmpty)
            try Data("corrupt current store".utf8).write(to: scoped)
            do {
                _ = try SecureFaceStore.load()
                fatalError("An unreadable current store must report an error")
            } catch SecureCredentialError.decryptionFailed { }

        case "migration":
            try SecureCredentialManager.unlockSession(reason: "Selftest")
            let identity = FaceIdentity(
                id: UUID(), name: "Test", samples: [], modelIdentifier: "test",
                embeddingDimension: 0, createdAt: Date(timeIntervalSince1970: 100)
            )
            let ciphertext = try SecureCredentialManager.encrypt(JSONEncoder().encode([identity]))
            try ciphertext.write(to: legacy)
            let loaded = try SecureFaceStore.load()
            check(loaded == [identity], "Readable legacy enrollment must migrate")
            try check(Data(contentsOf: scoped) == ciphertext)
            try check(Data(contentsOf: legacy) == ciphertext)
            try SecureFaceStore.deleteAll()
            check(!SecureFaceStore.exists)
            try check(SecureFaceStore.load().isEmpty, "Deleted enrollment must not be reimported")
            try check(Data(contentsOf: legacy) == ciphertext)

        case "missing-key":
            try FileManager.default.createDirectory(at: scoped.deletingLastPathComponent(), withIntermediateDirectories: true)
            try Data("current encrypted data".utf8).write(to: scoped)
            do {
                try SecureCredentialManager.unlockSession(reason: "Selftest")
                fatalError("A missing key for current data must still block setup")
            } catch SecureCredentialError.sessionKeyUnavailable { }

        default:
            fatalError("Unknown scenario")
        }
        print("face storage selftest passed — \(CommandLine.arguments[1])")
    }
}
