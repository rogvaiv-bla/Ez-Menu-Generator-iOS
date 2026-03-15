import SwiftUI
import UIKit
import PhotosUI

struct ImagePickerView: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Binding var isPresented: Bool
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .images
        config.selectionLimit = 1

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(selectedImage: $selectedImage, isPresented: $isPresented)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        @Binding var selectedImage: UIImage?
        @Binding var isPresented: Bool
        
        init(selectedImage: Binding<UIImage?>, isPresented: Binding<Bool>) {
            self._selectedImage = selectedImage
            self._isPresented = isPresented
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard let result = results.first else {
                DispatchQueue.main.async {
                    self.isPresented = false
                }
                return
            }

            let provider = result.itemProvider
            guard provider.canLoadObject(ofClass: UIImage.self) else {
                DispatchQueue.main.async {
                    self.isPresented = false
                }
                return
            }

            provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
                guard let self else { return }
                DispatchQueue.main.async {
                    if let image = object as? UIImage {
                        #if DEBUG
                        print("📷 PHPicker selected image: \(image.size)")
                        #endif
                        self.selectedImage = image
                    }
                    self.isPresented = false
                }
            }
        }
    }
}

#Preview {
    Text("ImagePickerView Preview")
}
