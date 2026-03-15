//
// SupabaseHouseholdService.swift
// Ez Menu Generator
//

import Foundation
import os.log

// Logging via system os_log

struct SupabaseHouseholdMember: Decodable {
    let id: UUID
    let householdId: UUID
    let username: String
    let role: String

    enum CodingKeys: String, CodingKey {
        case id
        case householdId = "household_id"
        case username
        case role
    }
}

struct SupabaseHouseholdMembersResponse: Decodable {
    let members: [SupabaseHouseholdMember]
}

final class SupabaseHouseholdService {
    static let shared = SupabaseHouseholdService()

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchMembers(householdId: UUID) async throws -> [SupabaseHouseholdMember] {
        // Use Edge Function to bypass RLS which causes stack depth errors
        guard let baseURL = URL(string: SupabaseConfig.url) else {
            throw URLError(.badURL)
        }
        
        let url = baseURL.appendingPathComponent("functions/v1/fetch-household-members")
        
        // householdLog.debug("📡 Fetching members for household: \(householdId.uuidString)")
        
        // Check if token exists and is valid
        guard TokenStore.shared.isTokenValid() else {
            // householdLog.warning("⚠️ Token missing or expired - clearing stale token")
            TokenStore.shared.clear()
            throw NSError(domain: "SupabaseHousehold", code: 401, userInfo: [NSLocalizedDescriptionKey: "Token expired - please re-authenticate"])
        }
        
        guard let token = TokenStore.shared.loadToken() else {
            throw NSError(domain: "SupabaseHousehold", code: 401, userInfo: [NSLocalizedDescriptionKey: "Missing access token"])
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 5
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        // Send householdId in request body
        let requestBody: [String: String] = ["householdId": householdId.uuidString]
        request.httpBody = try JSONEncoder().encode(requestBody)

        do {
            let (data, response) = try await session.data(for: request)
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1

            if !(200...299).contains(status) {
                let message = String(data: data, encoding: .utf8) ?? "Unknown error"
                // householdLog.error("📛 Fetch members failed (\(status)): \(message)")
                
                // Clear stale token on 401
                if status == 401 {
                    // householdLog.warning("🔑 Received 401 - clearing invalid token")
                    TokenStore.shared.clear()
                }
                
                throw NSError(domain: "SupabaseHousehold", code: status, userInfo: [NSLocalizedDescriptionKey: message])
            }

            let members = try JSONDecoder().decode([SupabaseHouseholdMember].self, from: data)
            // householdLog.info("✅ Fetched \(members.count) members from Supabase via Edge Function")
            return members
        } catch {
            // householdLog.error("🔴 Network error fetching members: \(error.localizedDescription)")
            throw error
        }
    }
}
