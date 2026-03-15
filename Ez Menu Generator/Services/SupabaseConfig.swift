//
// SupabaseConfig.swift
// Ez Menu Generator
//

import Foundation

struct SupabaseConfig {
    static let url = "https://hfskzexeonphhlljomms.supabase.co"
    static let baseURL = URL(string: url)
    static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhmc2t6ZXhlb25waGhsbGpvbW1zIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA3NDI2OTEsImV4cCI6MjA4NjMxODY5MX0.OMVIMkvGdKc1X8Vjytd-JxLKQV9PhIgaRES7z9PjMhc"

    static var healthURL: URL? {
        baseURL?.appendingPathComponent("auth/v1/health")
    }

    static var functionsURL: URL? {
        baseURL?.appendingPathComponent("functions/v1/household-auth")
    }

    static var restBaseURL: URL? {
        baseURL?.appendingPathComponent("rest/v1")
    }
}
