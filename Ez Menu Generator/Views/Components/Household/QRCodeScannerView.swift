//
// QRCodeScannerView.swift
// Ez Menu Generator
//
// Purpose: Scan QR codes from camera using Vision framework
//

import SwiftUI
import AVFoundation
import Vision

struct QRCodeScannerView: UIViewControllerRepresentable {
    var onScanned: (String) -> Void
    var onCancel: () -> Void
    
    func makeUIViewController(context: Context) -> QRCodeScannerViewController {
        let controller = QRCodeScannerViewController()
        controller.onScanned = onScanned
        controller.onCancel = onCancel
        return controller
    }
    
    func updateUIViewController(_ uiViewController: QRCodeScannerViewController, context: Context) {}
}

// MARK: - QR Code Scanner Controller

class QRCodeScannerViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    var onScanned: (String) -> Void = { _ in }
    var onCancel: () -> Void = {}
    
    private let captureSession = AVCaptureSession()
    private let videoPreviewLayer = AVCaptureVideoPreviewLayer()
    private var isScanning = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .dark
        
        view.backgroundColor = .black
        setupCamera()
        setupUI()
    }
    
    private func setupCamera() {
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            showError("Camera not available")
            return
        }
        
        let videoInput: AVCaptureDeviceInput
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            showError("Could not create video input")
            return
        }
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        }
        
        let videoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        
        if captureSession.canAddOutput(videoDataOutput) {
            captureSession.addOutput(videoDataOutput)
        }
        
        videoPreviewLayer.session = captureSession
        videoPreviewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(videoPreviewLayer)
        
        DispatchQueue.global(qos: .background).async {
            self.captureSession.startRunning()
        }
    }
    
    private func setupUI() {
        videoPreviewLayer.frame = view.bounds
        
        // Cancel button
        let cancelButton = UIButton(type: .system)
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        cancelButton.setTitleColor(.white, for: .normal)
        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        cancelButton.layer.cornerRadius = 8
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.addTarget(self, action: #selector(cancelScanning), for: .touchUpInside)
        
        view.addSubview(cancelButton)
        
        NSLayoutConstraint.activate([
            cancelButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            cancelButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cancelButton.widthAnchor.constraint(equalToConstant: 120),
            cancelButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        // Info label
        let infoLabel = UILabel()
        infoLabel.text = "Point at QR code"
        infoLabel.textColor = .white
        infoLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        infoLabel.textAlignment = .center
        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(infoLabel)
        
        NSLayoutConstraint.activate([
            infoLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            infoLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard isScanning else { return }
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let request = VNDetectBarcodesRequest { [weak self] request, error in
            guard let results = request.results as? [VNBarcodeObservation] else { return }
            
            for barcode in results {
                if barcode.symbology == .qr, let payload = barcode.payloadStringValue {
                    self?.handleQRCode(payload)
                }
            }
        }
        
        request.symbologies = [.qr]
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        try? handler.perform([request])
    }
    
    private func handleQRCode(_ payload: String) {
        isScanning = false
        
        // Extract household ID from "household:{uuid}" format
        let components = payload.split(separator: ":", maxSplits: 1)
        if components.count == 2 && components[0] == "household", let uuid = UUID(uuidString: String(components[1])) {
            DispatchQueue.main.async {
                self.captureSession.stopRunning()
                self.onScanned(uuid.uuidString)
            }
        } else {
            // Not a valid household QR code, resume scanning
            isScanning = true
        }
    }
    
    @objc private func cancelScanning() {
        captureSession.stopRunning()
        onCancel()
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.onCancel()
        })
        present(alert, animated: true)
    }
    
    deinit {
        captureSession.stopRunning()
    }
}
