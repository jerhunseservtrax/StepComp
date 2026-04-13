//
//  KeychainStore.swift
//  FitComp
//

import Foundation
import Security

enum KeychainStore {
    private static let service = "com.je.fitcomp"

    @discardableResult
    static func save(_ data: Data, account: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
            kSecValueData as String: data
        ]

        let deleteStatus = SecItemDelete(query as CFDictionary)
        if deleteStatus != errSecSuccess && deleteStatus != errSecItemNotFound {
            #if DEBUG
            print("⚠️ Keychain delete before save returned \(deleteStatus) for \(account)")
            #endif
        }

        let addStatus = SecItemAdd(query as CFDictionary, nil)
        if addStatus != errSecSuccess {
            #if DEBUG
            print("❌ Keychain save failed with status \(addStatus) for \(account)")
            #endif
            return false
        }
        return true
    }

    static func load(account: String) -> Data? {
        let preferredQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        var status = SecItemCopyMatching(preferredQuery as CFDictionary, &item)

        if status == errSecItemNotFound {
            let fallbackQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: account,
                kSecReturnData as String: true,
                kSecMatchLimit as String: kSecMatchLimitOne
            ]
            status = SecItemCopyMatching(fallbackQuery as CFDictionary, &item)
        }

        // Last-resort: items saved before kSecAttrService was added
        if status == errSecItemNotFound {
            let legacyQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: account,
                kSecReturnData as String: true,
                kSecMatchLimit as String: kSecMatchLimitOne
            ]
            status = SecItemCopyMatching(legacyQuery as CFDictionary, &item)
        }

        guard status == errSecSuccess else {
            #if DEBUG
            if status != errSecItemNotFound {
                print("⚠️ Keychain load failed with status \(status) for \(account)")
            }
            #endif
            return nil
        }
        return item as? Data
    }

    @discardableResult
    static func delete(account: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let status = SecItemDelete(query as CFDictionary)

        // Also clean up any legacy entries without kSecAttrService
        let legacyQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(legacyQuery as CFDictionary)

        if status != errSecSuccess && status != errSecItemNotFound {
            #if DEBUG
            print("⚠️ Keychain delete failed with status \(status) for \(account)")
            #endif
            return false
        }
        return true
    }
}
