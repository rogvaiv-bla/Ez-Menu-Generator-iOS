//
// SupabaseService.swift
// Ez Menu Generator
//

import Foundation
import os.log

// Logging via system os_log

final class SupabaseService {
    static let shared = SupabaseService()

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func checkHealth() async -> Bool {
        guard let url = SupabaseConfig.healthURL else {
            // supaLog.error("Supabase health URL is invalid")
            return false
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")

        do {
            let (_, response) = try await session.data(for: request)
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            if (200...299).contains(status) {
                // supaLog.info("Supabase health check OK (\(status))")
                return true
            } else {
                // supaLog.error("Supabase health check failed (\(status))")
                return false
            }
        } catch {
            // supaLog.error("Supabase health check error: \(error.localizedDescription)")
            return false
        }
    }
}
