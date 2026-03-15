import UIKit
import Foundation

class ImageCacheManager {
    static let shared = ImageCacheManager()
    
    private let memoryCache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    // Thumbnail dimensions
    let thumbnailSize: CGSize = CGSize(width: 100, height: 100)
    let displaySize: CGSize = CGSize(width: 250, height: 250)
    
    private init() {
        let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        cacheDirectory = paths[0].appendingPathComponent("RecipeImages", isDirectory: true)
        
        // Create cache directory if needed
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        
        // Configure memory cache
        memoryCache.totalCostLimit = 100 * 1024 * 1024  // 100 MB
    }
    
    // MARK: - Thumbnail Cache
    
    func getThumbnail(for recipeId: UUID) -> UIImage? {
        let cacheKey = NSString(string: "thumb_\(recipeId.uuidString)")
        
        // Check memory cache first
        if let image = memoryCache.object(forKey: cacheKey) {
            return image
        }
        
        // Check file cache
        let fileURL = cacheDirectory.appendingPathComponent("thumb_\(recipeId.uuidString).jpg")
        if let imageData = try? Data(contentsOf: fileURL),
           let image = UIImage(data: imageData) {
            memoryCache.setObject(image, forKey: cacheKey, cost: estimateCost(image))
            return image
        }
        
        return nil
    }
    
    func cacheThumbnail(_ image: UIImage, for recipeId: UUID) {
        let cacheKey = NSString(string: "thumb_\(recipeId.uuidString)")
        
        // Store in memory cache
        memoryCache.setObject(image, forKey: cacheKey, cost: estimateCost(image))
        
        // Store in file cache
        if let thumbnailData = image.jpegData(compressionQuality: 0.6) {
            let fileURL = cacheDirectory.appendingPathComponent("thumb_\(recipeId.uuidString).jpg")
            try? thumbnailData.write(to: fileURL)
        }
    }
    
    func clearCache(for recipeId: UUID) {
        let cacheKey = NSString(string: "thumb_\(recipeId.uuidString)")
        memoryCache.removeObject(forKey: cacheKey)
        
        let fileURL = cacheDirectory.appendingPathComponent("thumb_\(recipeId.uuidString).jpg")
        try? fileManager.removeItem(at: fileURL)
    }
    
    // MARK: - Image Optimization
    
    func generateThumbnail(from image: UIImage) -> UIImage {
        return resizeImage(image, to: thumbnailSize)
    }
    
    func optimizeDisplayImage(from image: UIImage) -> UIImage {
        return resizeImage(image, to: displaySize)
    }
    
    private func resizeImage(_ image: UIImage, to size: CGSize) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = UIScreen.main.scale
        
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    // MARK: - Memory Management
    
    func clearMemoryCache() {
        memoryCache.removeAllObjects()
    }
    
    func clearFileCache() {
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    func estimateCost(_ image: UIImage) -> Int {
        guard let cgImage = image.cgImage else { return 0 }
        return cgImage.bytesPerRow * cgImage.height
    }
    
    // MARK: - Utility
    
    func cacheSize() -> UInt64 {
        guard let contents = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }
        
        var totalSize: UInt64 = 0
        for url in contents {
            if let attributes = try? fileManager.attributesOfItem(atPath: url.path) {
                if let size = attributes[.size] as? UInt64 {
                    totalSize += size
                }
            }
        }
        return totalSize
    }
}
