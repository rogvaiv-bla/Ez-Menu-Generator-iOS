//
// QRCodeGenerator.swift
// Ez Menu Generator
//
// Purpose: Generate QR codes from text (e.g., invite keys)
//

import Foundation
import CoreImage
import UIKit

class QRCodeGenerator {
    /// Generate QR code image from string
    static func generateQRCode(from string: String, size: CGSize = CGSize(width: 300, height: 300)) -> UIImage? {
        // Create data from string
        guard let data = string.data(using: .utf8) else { return nil }
        
        // Create filter
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        
        // Set error correction level
        filter.setValue("M", forKey: "inputCorrectionLevel")
        
        // Get output image
        guard let outputImage = filter.outputImage else { return nil }
        
        // Scale up (QR code is small by default)
        let scale = size.width / outputImage.extent.size.width
        let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        
        // Convert to UIImage
        let context = CIContext()
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else { return nil }
        
        return UIImage(cgImage: cgImage)
    }
    
    /// Generate QR code for household invite
    static func generateInviteQRCode(householdId: UUID, size: CGSize = CGSize(width: 300, height: 300)) -> UIImage? {
        // Format: household:{uuid}
        let inviteString = "household:\(householdId.uuidString)"
        return generateQRCode(from: inviteString, size: size)
    }
}
