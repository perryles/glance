import Foundation

@main
struct KeychainMigrationSelfTest {
    static func main() {
        let legacy = Data("legacy ciphertext".utf8)
        var removed = false
        var written = false
        KeychainManager.migrateLegacyData(legacy,
            readDestination: { throw KeychainError.osStatus(-34018) },
            writeDestination: { _ in written = true }, deleteLegacy: { removed = true })
        precondition(!removed && !written, "Missing entitlements must preserve the legacy copy")
        var destination: Data?
        KeychainManager.migrateLegacyData(legacy,
            readDestination: {
                guard let destination else { throw KeychainError.itemNotFound }
                return destination
            }, writeDestination: { destination = $0 }, deleteLegacy: { removed = true })
        precondition(destination == legacy && removed)
        removed = false
        KeychainManager.migrateLegacyData(legacy,
            readDestination: { Data("newer ciphertext".utf8) },
            writeDestination: { _ in fatalError("Must preserve existing destination") },
            deleteLegacy: { removed = true })
        precondition(removed)
        removed = false
        var reads = 0
        KeychainManager.migrateLegacyData(legacy,
            readDestination: {
                reads += 1
                if reads == 1 { throw KeychainError.itemNotFound }
                throw KeychainError.osStatus(-25291)
            }, writeDestination: { _ in }, deleteLegacy: { removed = true })
        precondition(!removed, "Failed read-back must preserve the legacy copy")
        print("PASS: keychain migration preserves source on query/read errors and verifies destination before deletion")
    }
}
