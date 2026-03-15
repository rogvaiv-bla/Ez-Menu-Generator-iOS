//
// BarcodeScannerView.swift
// Ez Menu Generator
//
// MARK: - Purpose
// SwiftUI wrapper for AVFoundation-based barcode scanning
// Uses Vision framework for barcode detection
// Supports EAN-8, EAN-13, EAN-14, and other barcode formats
//
// MARK: - Key Components
// - BarcodeScannerView: SwiftUI wrapper with camera preview
// - BarcodeScannerViewController: UIViewController with AVFoundation setup
// - CaptureSession: Manages camera input and output
//
// MARK: - Usage
// ```swift
// @State private var scannedCode: String?
// @State private var showScanner = true
//
// BarcodeScannerView(scannedCode: $scannedCode, showScanner: $showScanner)
// ```
//
// MARK: - Permissions
// Requires NSCameraUsageDescription in Info.plist
//

import SwiftUI
import AVFoundation
import Vision
import os.log

// Logging via system os_log

struct BarcodeScannerView: UIViewControllerRepresentable {
    @Binding var scannedCode: String?
    @Binding var showScanner: Bool
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> BarcodeScannerViewController {
        let controller = BarcodeScannerViewController()
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: BarcodeScannerViewController, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(scannedCode: $scannedCode, showScanner: $showScanner, dismiss: dismiss)
    }
    
    class Coordinator: NSObject, BarcodeScannerDelegate {
        @Binding var scannedCode: String?
        @Binding var showScanner: Bool
        let dismiss: DismissAction
        
        init(scannedCode: Binding<String?>, showScanner: Binding<Bool>, dismiss: DismissAction) {
            self._scannedCode = scannedCode
            self._showScanner = showScanner
            self.dismiss = dismiss
        }
        
        func didFindBarcode(_ barcode: String) {
            // logger.info("✅ Barcode scanned: \(barcode)")
            DispatchQueue.main.async {
                self.scannedCode = barcode
                // Give UI time to update before closing
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.showScanner = false
                    self.dismiss()
                }
            }
        }
        
        func didFailWithError(_ error: String) {
            // logger.error("❌ Barcode scanner error: \(error)")
        }
    }
}

// MARK: - Protocol

protocol BarcodeScannerDelegate: AnyObject {
    func didFindBarcode(_ barcode: String)
    func didFailWithError(_ error: String)
}

// MARK: - UIViewController Implementation

class BarcodeScannerViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    weak var delegate: BarcodeScannerDelegate?
    
    private let captureSession = AVCaptureSession()
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private let videoPreviewLayer = AVCaptureVideoPreviewLayer()
    private let sequenceHandler = VNSequenceRequestHandler()
    private var lastBarcodeValue: String?
    private var lastBarcodeTime: Date?

    deinit {
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .dark
        
        setupCamera()
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if !captureSession.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession.startRunning()
                // logger.info("📹 Camera session started")
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if captureSession.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession.stopRunning()
                // logger.info("📹 Camera session stopped")
            }
        }
    }
    
    // MARK: - Camera Setup
    
    private func setupCamera() {
        // Request camera authorization
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCaptureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.setupCaptureSession()
                    } else {
                        self?.delegate?.didFailWithError("Camera permission denied")
                        // logger.error("❌ Camera permission denied by user")
                    }
                }
            }
        case .denied, .restricted:
            delegate?.didFailWithError("Camera access denied. Enable in Settings.")
            // logger.error("❌ Camera access denied or restricted")
        @unknown default:
            delegate?.didFailWithError("Unknown camera authorization status")
        }
    }
    
    private func setupCaptureSession() {
        captureSession.sessionPreset = .high
        
        // Configure camera input
        guard let videoCaptureDevice = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: .back
        ) else {
            delegate?.didFailWithError("Camera not available")
            // logger.error("❌ No camera available")
            return
        }
        
        do {
            let videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
                // logger.info("✅ Camera input added")
            } else {
                delegate?.didFailWithError("Cannot add video input to capture session")
                // logger.error("❌ Cannot add video input")
                return
            }
        } catch {
            delegate?.didFailWithError("Cannot create video input: \(error.localizedDescription)")
            // logger.error("❌ Video input error: \(error.localizedDescription)")
            return
        }
        
        // Configure video output
        videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "VideoQueue"))
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32BGRA)]
        
        if captureSession.canAddOutput(videoDataOutput) {
            captureSession.addOutput(videoDataOutput)
            // logger.info("✅ Video output added")
        } else {
            delegate?.didFailWithError("Cannot add video output to capture session")
            // logger.error("❌ Cannot add video output")
            return
        }
        
        // Configure video preview
        videoPreviewLayer.session = captureSession
        videoPreviewLayer.videoGravity = .resizeAspectFill
        
        DispatchQueue.main.async {
            if let connection = self.videoDataOutput.connection(with: .video) {
                if #available(iOS 17.0, *) {
                    connection.videoRotationAngle = 0.0
                } else {
                    connection.videoOrientation = .portrait
                }
            }
            
            self.view.layer.addSublayer(self.videoPreviewLayer)
            self.videoPreviewLayer.frame = self.view.bounds
            
            self.captureSession.startRunning()
            // logger.info("📹 Capture session started")
        }
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = .black
        
        // Close button
        let closeButton = UIButton(type: .system)
        closeButton.setTitle("✕", for: .normal)
        closeButton.titleLabel?.font = UIFont.systemFont(ofSize: 24, weight: .semibold)
        closeButton.tintColor = .white
        closeButton.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        closeButton.layer.cornerRadius = 22
        closeButton.clipsToBounds = true
        closeButton.addTarget(self, action: #selector(closeScanner), for: .touchUpInside)
        
        view.addSubview(closeButton)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        // Scanning indicator
        let scannerIndicator = UIView()
        scannerIndicator.backgroundColor = UIColor(red: 1.0, green: 0.420, blue: 0.420, alpha: 0.7)
        scannerIndicator.layer.cornerRadius = 2
        
        view.addSubview(scannerIndicator)
        scannerIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scannerIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            scannerIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            scannerIndicator.widthAnchor.constraint(equalToConstant: 300),
            scannerIndicator.heightAnchor.constraint(equalToConstant: 100)
        ])
        
        // Instruction label
        let instructionLabel = PaddedLabel()
        instructionLabel.text = "Alinează codul de bare în cadru"
        instructionLabel.textColor = .white
        instructionLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        instructionLabel.textAlignment = .center
        instructionLabel.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        instructionLabel.layer.cornerRadius = 8
        instructionLabel.clipsToBounds = true
        instructionLabel.numberOfLines = 2
        instructionLabel.contentInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        
        view.addSubview(instructionLabel)
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            instructionLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -32),
            instructionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            instructionLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 16),
            instructionLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -16)
        ])
    }
    
    @objc private func closeScanner() {
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
        dismiss(animated: true)
    }
    
    // MARK: - Barcode Detection
    
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        let request = VNDetectBarcodesRequest { [weak self] request, _ in
            guard let self = self else { return }
            
            if let results = request.results as? [VNBarcodeObservation] {
                for barcode in results {
                    if let payload = barcode.payloadStringValue {
                        // Debounce: only report if different or enough time has passed
                        let now = Date()
                        let isDifferent = payload != self.lastBarcodeValue
                        let isTimePassed = self.lastBarcodeTime.map { now.timeIntervalSince($0) > 0.5 } ?? true
                        
                        if isDifferent || isTimePassed {
                            self.lastBarcodeValue = payload
                            self.lastBarcodeTime = now
                            
                            // logger.info("✅ Detected barcode: \(payload)")
                            DispatchQueue.main.async {
                                self.delegate?.didFindBarcode(payload)
                            }
                        }
                    }
                }
            }
        }
        
        // Configure supported symbologies
        request.symbologies = [
            VNBarcodeSymbology.ean8,
            VNBarcodeSymbology.ean13,
            VNBarcodeSymbology.code128,
            VNBarcodeSymbology.code39,
            VNBarcodeSymbology.code39Checksum,
            VNBarcodeSymbology.code93,
            VNBarcodeSymbology.code93i,
            VNBarcodeSymbology.upce,
            VNBarcodeSymbology.pdf417,
            VNBarcodeSymbology.dataMatrix
        ]
        
        do {
            try sequenceHandler.perform([request], on: pixelBuffer)
        } catch {
            // logger.error("❌ Failed to perform barcode detection: \(error.localizedDescription)")
        }
    }
}

// MARK: - Padded Label

final class PaddedLabel: UILabel {
    var contentInsets: UIEdgeInsets = .zero {
        didSet {
            invalidateIntrinsicContentSize()
            setNeedsDisplay()
        }
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: contentInsets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(
            width: size.width + contentInsets.left + contentInsets.right,
            height: size.height + contentInsets.top + contentInsets.bottom
        )
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let fitted = super.sizeThatFits(
            CGSize(
                width: size.width - contentInsets.left - contentInsets.right,
                height: size.height - contentInsets.top - contentInsets.bottom
            )
        )
        return CGSize(
            width: fitted.width + contentInsets.left + contentInsets.right,
            height: fitted.height + contentInsets.top + contentInsets.bottom
        )
    }
}
