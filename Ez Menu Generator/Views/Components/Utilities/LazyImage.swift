import SwiftUI

struct LazyImage: View {
    let image: UIImage?
    let recipeId: UUID
    let displayType: DisplayType
    let supabaseImagePath: String?
    
    enum DisplayType {
        case thumbnail  // Small, cached
        case full       // Large, display size
        case inline     // Medium, flexible
    }
    
    @State private var cloudImage: UIImage?
    @State private var isLoading = false
    
    var body: some View {
        Group {
            if let image = image {
                // If local image is provided, use it directly
                Image(uiImage: displayType == .thumbnail ? 
                    ImageCacheManager.shared.generateThumbnail(from: image) :
                    ImageCacheManager.shared.optimizeDisplayImage(from: image))
                    .resizable()
                    .scaledToFill()
            } else if let cloudImage = cloudImage {
                // Use downloaded cloud image
                Image(uiImage: cloudImage)
                    .resizable()
                    .scaledToFill()
            } else {
                // Check cache
                if let cachedImage = ImageCacheManager.shared.getThumbnail(for: recipeId) {
                    Image(uiImage: cachedImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    // Placeholder with loading state
                    ZStack {
                        EzColors.Background.tertiary.opacity(0.1)
                        VStack(spacing: 8) {
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(displayType == .thumbnail ? 0.7 : 1)
                            } else {
                                Image(systemName: "photo")
                                    .font(.system(size: displayType == .thumbnail ? 24 : 40))
                                    .foregroundColor(EzColors.Text.tertiary)
                                if displayType != .thumbnail {
                                    Text("Nicio imagine")
                                        .font(.caption)
                                        .foregroundColor(EzColors.Text.tertiary)
                                }
                            }
                        }
                    }
                    .onAppear {
                        // Try to download from cloud if path available
                        if let supabasePath = supabaseImagePath {
                            loadFromCloud(supabasePath)
                        }
                    }
                }
            }
        }
        .onChange(of: image) {
            // Clear cloud image when local image changes
            cloudImage = nil
        }
        .onChange(of: supabaseImagePath) { _, newPath in
            // Reset when path changes (including when set to nil)
            cloudImage = nil
            if let newPath = newPath {
                loadFromCloud(newPath)
            }
        }
    }
    
    private func loadFromCloud(_ imagePath: String) {
        isLoading = true
        Task {
            do {
                let service = SupabaseImageService.shared
                if let downloadedImage = try await service.downloadImage(from: imagePath) {
                    cloudImage = downloadedImage
                    // Cache for future use
                    let cached = ImageCacheManager.shared
                    let thumbnail = cached.generateThumbnail(from: downloadedImage)
                    cached.cacheThumbnail(thumbnail, for: recipeId)
                }
            } catch {
                print("⚠️ Failed to load cloud image: \(error)")
            }
            isLoading = false
        }
    }
}

#Preview {
    LazyImage(
        image: UIImage(systemName: "photo.fill"),
        recipeId: UUID(),
        displayType: .thumbnail,
        supabaseImagePath: nil
    )
    .frame(width: 100, height: 100)
}
