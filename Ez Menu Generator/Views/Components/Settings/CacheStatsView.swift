import SwiftUI

struct CacheStatsView: View {
    @State private var cacheSize: String = "Calculating..."
    @State private var showClearAlert = false
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Image Cache")
                        .font(.headline)
                    Text(cacheSize)
                        .font(.caption)
                        .foregroundColor(EzColors.Text.tertiary)
                }
                Spacer()
            }
            
            Button(action: { showClearAlert = true }) {
                Label("Clear Cache", systemImage: "trash")
                    .font(.body)
                    .foregroundColor(EzColors.Accent.danger)
            }
            
            Divider()
        }
        .padding()
        .onAppear {
            updateCacheSize()
        }
        .alert("Clear Cache?", isPresented: $showClearAlert) {
            Button("Clear", role: .destructive) {
                ImageCacheManager.shared.clearMemoryCache()
                ImageCacheManager.shared.clearFileCache()
                updateCacheSize()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove all cached recipe images. Images will be regenerated when needed.")
        }
    }
    
    private func updateCacheSize() {
        let bytes = ImageCacheManager.shared.cacheSize()
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB]
        formatter.countStyle = .file
        cacheSize = formatter.string(fromByteCount: Int64(bytes))
    }
}

#Preview {
    CacheStatsView()
}
