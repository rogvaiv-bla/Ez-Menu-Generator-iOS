//
// OpenFoodFactsService.swift
// Ez Menu Generator
//
// MARK: - Purpose
// URLSession-based networking service for Open Food Facts API
// Handles staging/production environments
// Manages authentication and headers per API requirements
// Provides READ-only access to product database
//
// MARK: - Configuration
// - STAGING: https://world.openfoodfacts.net (requires Basic auth: off:off)
// - PRODUCTION: https://world.openfoodfacts.org (no auth)
// - User-Agent: Required by Open Food Facts ToS
//
// MARK: - Usage
// let service = OpenFoodFactsService()
// let product = try await service.fetchProduct(barcode: "5411188000181")
//

import Foundation
import Combine
import os.log

// Logging via system os_log

// MARK: - Configuration

enum OpenFoodFactsEnvironment {
    case staging
    case production
    
    var baseURL: URL {
        switch self {
        case .staging:
            // Safe URL creation with fallback
            guard let url = URL(string: "https://world.openfoodfacts.net") else {
                fatalError("Invalid staging URL configuration - this should never happen")
            }
            return url
        case .production:
            guard let url = URL(string: "https://world.openfoodfacts.org") else {
                fatalError("Invalid production URL configuration - this should never happen")
            }
            return url
        }
    }
    
    var requiresAuth: Bool {
        switch self {
        case .staging:
            return true
        case .production:
            return false
        }
    }
}

// MARK: - Service

@MainActor
class OpenFoodFactsService: NSObject {
    // MARK: Singleton
    static let shared = OpenFoodFactsService(environment: .production)
    
    // MARK: Configuration
    
    /// API environment (staging or production)
    private let environment: OpenFoodFactsEnvironment
    
    /// URLSession for API calls
    private let urlSession: URLSession
    
    /// User-Agent string (required by API)
    private let userAgent = "EzMenuGenerator/1.0 (contact@example.com)"
    
    /// Authentication credentials for staging (off:off in base64)
    private let stagingAuthHeader: String? = {
        // Base64 encode "off:off"
        let credentials = "off:off"
        return credentials.data(using: .utf8)?.base64EncodedString()
    }()
    
    // MARK: Initialization
    
    /// Initialize service with environment configuration
    /// - Parameter environment: Staging or Production (default: staging for development)
    init(environment: OpenFoodFactsEnvironment = .staging) {
        self.environment = environment
        
        // Configure URLSession with reasonable defaults
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 30
        config.waitsForConnectivity = false  // Prevent eager nw_connection queries
        config.httpMaximumConnectionsPerHost = 2
        
        self.urlSession = URLSession(configuration: config)
        super.init()
        
        // logger.info("OpenFoodFactsService initialized with environment: \(String(describing: self.environment))")
    }
    
    // MARK: Public API
    
    /// Fetch product information by barcode
    /// - Parameter barcode: Product barcode/EAN (digits only)
    /// - Returns: OpenFoodFactsProduct with nutrition and metadata
    /// - Throws: OpenFoodFactsError with specific error case
    ///
    /// Example:
    /// ```swift
    /// let product = try await service.fetchProduct(barcode: "5411188000181")
    /// print("Found: \(product.productName ?? "Unknown")")
    /// print("Brands: \(product.brands ?? "Unknown")")
    /// print("Kcal/100g: \(product.nutriments?.energyKcal100g ?? 0)")
    /// ```
    func fetchProduct(barcode: String) async throws -> OpenFoodFactsProduct {
        // logger.info("🔍 Fetching product: \(barcode)")
        
        // Validate barcode format
        guard isValidBarcode(barcode) else {
            // logger.error("Invalid barcode format: \(barcode)")
            throw OpenFoodFactsError.invalidBarcode
        }
        
        // Construct request
        let request = try buildRequest(for: barcode)
        
        // Execute request
        let (data, response) = try await urlSession.data(for: request)
        
        // Validate HTTP response
        try validateResponse(response)
        
        // Decode JSON
        let apiResponse = try decodeResponse(data, for: barcode)
        
        // Validate product exists
        guard let product = apiResponse.product else {
            // logger.warning("Product not found: \(barcode)")
            throw OpenFoodFactsError.productNotFound(barcode: barcode)
        }
        
        // Validate required fields
        try validateRequiredFields(product)
        
        // logger.info("✅ Product fetched: \(product.productName ?? barcode)")
        return product
    }
    
    // MARK: Private Helpers
    
    /// Build HTTP request with proper headers and auth
    private func buildRequest(for barcode: String) throws -> URLRequest {
        // Construct URL
        let endpoint = "/api/v0/product/\(barcode).json"  // v0 not v2!
        guard let url = URL(string: endpoint, relativeTo: environment.baseURL) else {
            throw OpenFoodFactsError.invalidResponse
        }
        
        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10
        
        // Add User-Agent header (required by API ToS)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        
        // Add Authorization header for staging
        if environment.requiresAuth, let authHeader = stagingAuthHeader {
            request.setValue("Basic \(authHeader)", forHTTPHeaderField: "Authorization")
        }
        
        // Add Accept header
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        return request
    }
    
    /// Validate HTTP response status
    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenFoodFactsError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200:
            // Success
            break
        case 404:
            // Not found - will be caught by checking product == nil
            break
        case 400...499:
            // logger.error("HTTP Client Error: \(httpResponse.statusCode)")
            throw OpenFoodFactsError.serverError(
                statusCode: httpResponse.statusCode,
                message: HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
            )
        case 500...599:
            // logger.error("HTTP Server Error: \(httpResponse.statusCode)")
            throw OpenFoodFactsError.serverError(
                statusCode: httpResponse.statusCode,
                message: HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
            )
        default:
            // logger.error("Unexpected HTTP Status: \(httpResponse.statusCode)")
            throw OpenFoodFactsError.serverError(
                statusCode: httpResponse.statusCode,
                message: "Unexpected status code"
            )
        }
    }
    
    /// Decode JSON response
    private func decodeResponse(_ data: Data, for barcode: String) throws -> OpenFoodFactsResponse {
        let decoder = JSONDecoder()
        do {
            let response = try decoder.decode(OpenFoodFactsResponse.self, from: data)
            
            // Check API status flag (1 = found, 0 = not found)
            if let status = response.status, status == 0 {
                throw OpenFoodFactsError.productNotFound(barcode: barcode)
            }
            
            return response
        } catch let error as DecodingError {
            // logger.error("Decoding error: \(error.localizedDescription)")
            throw OpenFoodFactsError.decodingError(error)
        } catch let error as OpenFoodFactsError {
            throw error
        } catch {
            // logger.error("Unexpected error: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Validate required fields are present
    private func validateRequiredFields(_ product: OpenFoodFactsProduct) throws {
        var missingFields: [String] = []
        
        // These fields are typically important for our use case
        if product.productName?.trimmingCharacters(in: CharacterSet.whitespaces).isEmpty ?? true {
            missingFields.append("product_name")
        }
        
        // Brands are highly useful
        if product.brands?.trimmingCharacters(in: CharacterSet.whitespaces).isEmpty ?? true {
            missingFields.append("brands (recommended)")
        }
        
        // Image is helpful
        if product.imageFrontUrl?.isEmpty ?? true {
            missingFields.append("image_front_url (recommended)")
        }
        
        // Note: We don't throw for missing nutrition - many simple products lack it
        // But we log it
        if product.nutriments?.energyKcal100g == nil {
            // logger.debug("Nutrition data incomplete for product")
        }
        
        if !missingFields.isEmpty {
            // logger.warning("Missing fields: \(missingFields.joined(separator: ", "))")
        }
    }
    
    /// Validate barcode format (must be digits only)
    private func isValidBarcode(_ barcode: String) -> Bool {
        let trimmed = barcode.trimmingCharacters(in: .whitespaces)
        
        // Check not empty
        guard !trimmed.isEmpty else { return false }
        
        // Check contains only digits
        guard trimmed.allSatisfy({ $0.isNumber }) else { return false }
        
        // Check reasonable length (EAN/UPC is 8-14 digits)
        guard (8...14).contains(trimmed.count) else { return false }
        
        return true
    }
}

// MARK: - Convenience Extensions

extension OpenFoodFactsProduct {
    /// Format product info for display
    var displayName: String {
        let name = productName?.trimmingCharacters(in: .whitespaces) ?? "Unknown Product"
        let brand = brands?.trimmingCharacters(in: .whitespaces) ?? ""
        return brand.isEmpty ? name : "\(brand) - \(name)"
    }
    
    /// Get formatted nutrition info
    var nutritionSummary: String? {
        guard let nutriments = nutriments else { return nil }
        
        var summary: [String] = []
        if let kcal = nutriments.energyKcal100g {
            summary.append("\(Int(kcal)) kcal")
        }
        if let protein = nutriments.proteins100g {
            summary.append("\(String(format: "%.1f", protein))g protein")
        }
        if let fat = nutriments.fat100g {
            summary.append("\(String(format: "%.1f", fat))g fat")
        }
        if let carbs = nutriments.carbohydrates100g {
            summary.append("\(String(format: "%.1f", carbs))g carbs")
        }
        
        return summary.isEmpty ? nil : summary.joined(separator: " | ")
    }
}
