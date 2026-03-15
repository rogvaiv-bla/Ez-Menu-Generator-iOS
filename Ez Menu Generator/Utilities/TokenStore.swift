//
// TokenStore.swift
// Ez Menu Generator
//

import Foundation
import Security

final class TokenStore {
    static let shared = TokenStore()

    private let service = "home-SRL.Ez-Menu-Generator"
    private let account = "supabase.access.token"
    private let expirationAccount = "supabase.token.expiration"

    func save(token: String, expiresIn: Int = 3600) -> Bool {
        guard let data = token.data(using: .utf8) else { return false }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        SecItemDelete(query as CFDictionary)

        var attributes = query
        attributes[kSecValueData as String] = data

        let status = SecItemAdd(attributes as CFDictionary, nil)
        
        // Save expiration timestamp
        if status == errSecSuccess {
            saveExpiration(expiresIn: expiresIn)
            #if DEBUG
            print("✅ Token saved to Keychain with \(expiresIn)s TTL (expires at \(Date().addingTimeInterval(Double(expiresIn))))")
            #endif
        } else {
            #if DEBUG
            print("❌ Failed to save token to Keychain (status: \(status))")
            #endif
        }
        
        return status == errSecSuccess
    }

    func loadToken() -> String? {
        // First check if token is still valid
        guard isTokenValid() else {
            return nil
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    func isTokenValid() -> Bool {
        // If no expiration timestamp exists, check if token exists (migration from old code)
        guard let expirationDate = loadExpiration() else {
            // Token might exist from OLD code (before expiration tracking)
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: account,
                kSecReturnData as String: true,
                kSecMatchLimit as String: kSecMatchLimitOne
            ]
            var item: CFTypeRef?
            let status = SecItemCopyMatching(query as CFDictionary, &item)
            if status == errSecSuccess, let data = item as? Data, String(data: data, encoding: .utf8) != nil {
                // Token exists but no expiration - regenerate with 1-hour TTL
                print("🔧 Token exists but no expiration timestamp - regenerating with 1-hour TTL")
                saveExpiration(expiresIn: 3600)
                // Check again
                guard let newExpirationDate = loadExpiration() else { return false }
                return Date().addingTimeInterval(60) < newExpirationDate
            }
            return false
        }
        // Add 60-second buffer before expiration to prevent edge cases
        return Date().addingTimeInterval(60) < expirationDate
    }

    func clear() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
        
        let expirationQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: expirationAccount
        ]
        SecItemDelete(expirationQuery as CFDictionary)
    }

    private func saveExpiration(expiresIn: Int) {
        let expirationDate = Date().addingTimeInterval(Double(expiresIn))
        let expirationString = String(expirationDate.timeIntervalSince1970)
        
        guard let data = expirationString.data(using: .utf8) else { return }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: expirationAccount
        ]

        SecItemDelete(query as CFDictionary)

        var attributes = query
        attributes[kSecValueData as String] = data
        
        SecItemAdd(attributes as CFDictionary, nil)
    }

    private func loadExpiration() -> Date? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: expirationAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data,
              let expirationString = String(data: data, encoding: .utf8),
              let timestamp = Double(expirationString) else {
            return nil
        }
        return Date(timeIntervalSince1970: timestamp)
    }
}
