import Foundation
import Security

// MARK: - Key enum

enum KeychainKey: String {
    /// The user's nsec (Nostr secret key), bech32-encoded.
    case nsec = "com.smcnamara.note.nsec"
}

// MARK: - Protocol

/// Abstraction over secure string storage.
/// Production code uses `KeychainService`; previews/tests use `InMemorySecureStorage`.
protocol SecureStorage {
    @discardableResult func save(key: KeychainKey, value: String) -> Bool
    func load(key: KeychainKey) -> String?
    @discardableResult func delete(key: KeychainKey) -> Bool
}

// MARK: - Keychain-backed storage

final class KeychainService: SecureStorage {
    static let shared = KeychainService()
    private init() {}

    private static let service = "com.smcnamara.note"

    @discardableResult
    func save(key: KeychainKey, value: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.service,
            kSecAttrAccount as String: key.rawValue,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]

        SecItemDelete(query as CFDictionary)
        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }

    func load(key: KeychainKey) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.service,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    @discardableResult
    func delete(key: KeychainKey) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.service,
            kSecAttrAccount as String: key.rawValue
        ]
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}

// MARK: - In-memory storage (previews + tests)

final class InMemorySecureStorage: SecureStorage {
    private var store: [String: String] = [:]

    @discardableResult
    func save(key: KeychainKey, value: String) -> Bool {
        store[key.rawValue] = value
        return true
    }

    func load(key: KeychainKey) -> String? {
        store[key.rawValue]
    }

    @discardableResult
    func delete(key: KeychainKey) -> Bool {
        store.removeValue(forKey: key.rawValue) != nil
    }
}
