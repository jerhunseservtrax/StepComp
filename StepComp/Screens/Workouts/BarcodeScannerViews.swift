//
//  BarcodeScannerViews.swift
//  FitComp
//

import SwiftUI
import AVFoundation
import UIKit

// MARK: - Barcode Scanner

struct BarcodeScannerSheet: View {
    let onScanned: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            BarcodeScannerCameraView { code in
                onScanned(code)
                dismiss()
            }
            .navigationTitle("Scan Barcode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

struct BarcodeScannerCameraView: UIViewControllerRepresentable {
    let onScanned: (String) -> Void

    func makeUIViewController(context: Context) -> BarcodeScannerViewController {
        let vc = BarcodeScannerViewController()
        vc.onScanned = onScanned
        return vc
    }

    func updateUIViewController(_ uiViewController: BarcodeScannerViewController, context: Context) {}
}

final class BarcodeScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var onScanned: ((String) -> Void)?

    private let captureSession = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var hasScanned = false
    private let overlayLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        configureOverlayLabel()
        checkCameraPermissionAndConfigure()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !captureSession.isRunning {
            captureSession.startRunning()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }

    private func configureOverlayLabel() {
        overlayLabel.translatesAutoresizingMaskIntoConstraints = false
        overlayLabel.text = "Point the camera at a barcode"
        overlayLabel.textColor = .white
        overlayLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        overlayLabel.textAlignment = .center
        overlayLabel.numberOfLines = 2
        overlayLabel.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        overlayLabel.layer.cornerRadius = 10
        overlayLabel.clipsToBounds = true
        overlayLabel.layoutMargins = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)

        view.addSubview(overlayLabel)
        NSLayoutConstraint.activate([
            overlayLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            overlayLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            overlayLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            overlayLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 48)
        ])
    }

    private func checkCameraPermissionAndConfigure() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCaptureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.setupCaptureSession()
                    } else {
                        self?.overlayLabel.text = "Camera access is required to scan barcodes."
                    }
                }
            }
        default:
            overlayLabel.text = "Enable camera access in Settings to scan barcodes."
        }
    }

    private func setupCaptureSession() {
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video),
              let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice),
              captureSession.canAddInput(videoInput) else {
            overlayLabel.text = "Unable to access camera."
            return
        }
        captureSession.addInput(videoInput)

        let metadataOutput = AVCaptureMetadataOutput()
        guard captureSession.canAddOutput(metadataOutput) else {
            overlayLabel.text = "Barcode scanning is unavailable."
            return
        }
        captureSession.addOutput(metadataOutput)

        metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        metadataOutput.metadataObjectTypes = [
            .ean8, .ean13, .upce, .code39, .code93, .code128, .pdf417, .qr
        ]

        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.layer.bounds
        view.layer.insertSublayer(previewLayer, at: 0)
        self.previewLayer = previewLayer

        captureSession.startRunning()
    }

    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard !hasScanned,
              let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let value = object.stringValue,
              !value.isEmpty else { return }

        hasScanned = true
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        onScanned?(value)
    }
}
