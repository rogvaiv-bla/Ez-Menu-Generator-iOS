import Foundation
import Combine
import UIKit

class SupabaseImageService: ObservableObject {
    static let shared = SupabaseImageService()
    
    @MainActor @Published var isUploading = false
    @MainActor @Published var uploadProgress: Double = 0
    
    private let bucket = "recipe-images"
    private let session: URLSession
    
    private init() {
        // Configure URLSession to avoid eager network path monitoring
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.waitsForConnectivity = false  // Prevent nw_connection queries
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Upload

    func uploadImageData(
        _ imageData: Data,
        for recipeId: UUID,
        mimeType: String,
        fileExtension: String
    ) async throws -> String {
        isUploading = true
        defer { isUploading = false }

        let filename = "\(recipeId.uuidString).\(fileExtension)"
        let filepath = "recipes/\(filename)"

        #if DEBUG
        print("📤 Uploading image data to Supabase: \(filepath) [\(mimeType)]")
        #endif

        guard let baseURL = SupabaseConfig.baseURL else {
            throw ImageUploadError.invalidURL
        }

        let uploadURL = baseURL
            .appendingPathComponent("storage/v1/object")
            .appendingPathComponent(bucket)
            .appendingPathComponent(filepath)

        var request = URLRequest(url: uploadURL)
        request.httpMethod = "POST"
        request.setValue(mimeType, forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = imageData

        let (responseData, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ImageUploadError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMsg = String(data: responseData, encoding: .utf8) ?? "Unknown error"

            if errorMsg.localizedCaseInsensitiveContains("bucket not found") || httpResponse.statusCode == 404 {
                throw ImageUploadError.bucketNotFound(bucket)
            }

            #if DEBUG
            print("❌ Upload failed: \(httpResponse.statusCode) - \(errorMsg)")
            #endif
            throw ImageUploadError.uploadFailed(httpResponse.statusCode)
        }

        #if DEBUG
        print("✅ Image data uploaded successfully: \(filepath)")
        #endif
        return filepath
    }
    
    func uploadImage(
        _ image: UIImage,
        for recipeId: UUID,
        mimeType: String = "image/jpeg"
    ) async throws -> String {
        // Compress image
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            throw ImageUploadError.compressionFailed
        }

        return try await uploadImageData(
            imageData,
            for: recipeId,
            mimeType: mimeType,
            fileExtension: "jpg"
        )
    }
    
    // MARK: - Download/Access
    
    func getPublicURL(for imagePath: String) -> URL? {
        guard let baseURL = SupabaseConfig.baseURL else {
            return nil
        }
        
        let publicURL = baseURL
            .appendingPathComponent("storage/v1/object/public")
            .appendingPathComponent(bucket)
            .appendingPathComponent(imagePath)
        
        #if DEBUG
        print("🔗 Image URL: \(publicURL.absoluteString)")
        #endif
        return publicURL
    }
    
    func downloadImage(from imagePath: String) async throws -> UIImage? {
        #if DEBUG
        print("📥 Downloading image from Supabase: \(imagePath)")
        #endif
        
        guard let baseURL = SupabaseConfig.baseURL else {
            throw ImageUploadError.invalidURL
        }
        
        let downloadURL = baseURL
            .appendingPathComponent("storage/v1/object")
            .appendingPathComponent(bucket)
            .appendingPathComponent(imagePath)
        
        var request = URLRequest(url: downloadURL)
        request.setValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ImageUploadError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw ImageUploadError.downloadFailed(httpResponse.statusCode)
        }
        
        guard let image = UIImage(data: data) else {
            throw ImageUploadError.invalidImageData
        }
        
        #if DEBUG
        print("✅ Image downloaded successfully")
        #endif
        return image
    }
    
    // MARK: - Delete
    
    func deleteImage(at imagePath: String) async throws {
        #if DEBUG
        print("🗑️ Deleting image from Supabase: \(imagePath)")
        #endif
        
        guard let baseURL = SupabaseConfig.baseURL else {
            throw ImageUploadError.invalidURL
        }
        
        let deleteURL = baseURL
            .appendingPathComponent("storage/v1/object")
            .appendingPathComponent(bucket)
            .appendingPathComponent(imagePath)
        
        var request = URLRequest(url: deleteURL)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
        
        let (responseData, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ImageUploadError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMsg = String(data: responseData, encoding: .utf8) ?? "Unknown error"
            #if DEBUG
            print("❌ Delete failed: \(httpResponse.statusCode) - \(errorMsg)")
            #endif
            throw ImageUploadError.deleteFailed(httpResponse.statusCode)
        }
        
        #if DEBUG
        print("✅ Image deleted from cloud")
        #endif
    }
    
    // MARK: - Error Handling
    
    enum ImageUploadError: LocalizedError {
        case compressionFailed
        case uploadFailed(Int)
        case bucketNotFound(String)
        case downloadFailed(Int)
        case deleteFailed(Int)
        case invalidImageData
        case networkUnavailable
        case invalidURL
        case invalidResponse
        
        var errorDescription: String? {
            switch self {
            case .compressionFailed:
                return "Failed to compress image"
            case .uploadFailed(let code):
                return "Upload failed with status \(code)"
            case .bucketNotFound(let bucketName):
                return "Supabase bucket '\(bucketName)' not found. Image was saved locally."
            case .downloadFailed(let code):
                return "Download failed with status \(code)"
            case .deleteFailed(let code):
                return "Delete failed with status \(code)"
            case .invalidImageData:
                return "Invalid image data received"
            case .invalidURL:
                return "Invalid URL for Supabase"
            case .invalidResponse:
                return "Invalid response from server"
            case .networkUnavailable:
                return "Network unavailable"
            }
        }
    }
}

// MARK: - Helper Extensions

extension UIImage {
    func compressed(quality: CGFloat = 0.7) -> Data? {
        return jpegData(compressionQuality: quality)
    }
}
