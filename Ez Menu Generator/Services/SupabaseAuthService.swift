//
// SupabaseAuthService.swift
// Ez Menu Generator
//

import Foundation
import os.log

// Logging via system os_log

struct SupabaseSession: Decodable {
    let accessToken: String
    let tokenType: String
    let expiresIn: Int
    let user: SupabaseUser
    let household: SupabaseHousehold

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case user
        case household
    }
}

struct SupabaseUser: Decodable {
    let id: UUID
    let username: String
    let role: String
    let householdId: UUID

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case role
        case householdId = "household_id"
    }
}

struct SupabaseHousehold: Decodable {
    let id: UUID
    let name: String
    let inviteKey: UUID
    let ownerId: UUID

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case inviteKey = "invite_key"
        case ownerId = "owner_id"
    }
}

final class SupabaseAuthService {
    static let shared = SupabaseAuthService()

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func createHousehold(username: String, householdName: String) async throws -> SupabaseSession {
        let body = [
            "action": "create",
            "username": username,
            "household_name": householdName
        ]
        return try await performAuthRequest(body: body)
    }

    func joinHousehold(username: String, inviteKey: String) async throws -> SupabaseSession {
        let body = [
            "action": "join",
            "username": username,
            "invite_key": inviteKey
        ]
        return try await performAuthRequest(body: body)
    }

    private func performAuthRequest(body: [String: String]) async throws -> SupabaseSession {
        guard let url = SupabaseConfig.functionsURL else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")

        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? -1

        if !(200...299).contains(status) {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            // authLog.error("Auth request failed (\(status))")
            throw NSError(domain: "SupabaseAuth", code: status, userInfo: [NSLocalizedDescriptionKey: message])
        }

        let decoder = JSONDecoder()
        let session = try decoder.decode(SupabaseSession.self, from: data)
        // Save token with expiration time (default 3600 seconds = 1 hour)
        let saveSuccess = TokenStore.shared.save(token: session.accessToken, expiresIn: session.expiresIn)
        if saveSuccess {
            // authLog.info("✅ Auth successful - token saved to Keychain with \(session.expiresIn)s TTL")
        } else {
            // authLog.error("❌ Auth successful but failed to save token to Keychain")
        }
        return session
    }
}
