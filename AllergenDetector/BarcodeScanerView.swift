import SwiftUI
import AVFoundation

struct BarcodeScannerView: UIViewRepresentable {
    var completion: (String) -> Void

    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.accessibilityViewIsModal = true
        view.accessibilityLabel = "Barcode scanner"

        // Configure preview layer on the main thread
        let previewLayer = AVCaptureVideoPreviewLayer(session: context.coordinator.captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.layer.bounds
        view.layer.addSublayer(previewLayer)

        // Add a "Scanning..." overlay label at the bottom
        let scanningLabel = UILabel()
        scanningLabel.text = "Scanning..."
        scanningLabel.font = UIFont.preferredFont(forTextStyle: .body)
        scanningLabel.adjustsFontForContentSizeCategory = true
        scanningLabel.textColor = .label
        scanningLabel.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.6)
        scanningLabel.textAlignment = .center
        scanningLabel.accessibilityLabel = "Scanning for barcode"
        scanningLabel.translatesAutoresizingMaskIntoConstraints = false
        scanningLabel.tag = 999
        view.addSubview(scanningLabel)

        // Constraints for the label
        NSLayoutConstraint.activate([
            scanningLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            scanningLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
            scanningLabel.widthAnchor.constraint(equalToConstant: 150),
            scanningLabel.heightAnchor.constraint(equalToConstant: 40)
        ])

        // Check camera permissions before starting the session
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            context.coordinator.startSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        context.coordinator.startSession()
                    } else {
                        showPermissionDeniedMessage(on: view)
                    }
                }
            }
        default:
            showPermissionDeniedMessage(on: view)
        }

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // If you need to adjust preview layer’s frame on rotation or layout changes:
        DispatchQueue.main.async {
            if let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
                previewLayer.frame = uiView.bounds
            }
        }
    }

    private func showPermissionDeniedMessage(on view: UIView) {
        if let existing = view.viewWithTag(999) {
            existing.removeFromSuperview()
        }
        let label = UILabel()
        label.text = "Camera access is required to scan barcodes. Please enable camera in Settings."
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .label
        label.numberOfLines = 0
        label.textAlignment = .center
        label.accessibilityLabel = label.text
        label.translatesAutoresizingMaskIntoConstraints = false
        label.tag = 998
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            label.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -16)
        ])
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        let parent: BarcodeScannerView
        let captureSession = AVCaptureSession()
        private let sessionQueue = DispatchQueue(label: "BarcodeScannerSessionQueue")

        /// Keep a reference so we can draw a bounding box on top of it
        var previewLayer: AVCaptureVideoPreviewLayer?

        /// A shape layer to draw the bounding box
        private let boundingBoxLayer: CAShapeLayer = {
            let layer = CAShapeLayer()
            layer.strokeColor = UIColor.green.cgColor
            layer.lineWidth = 2
            layer.fillColor = UIColor.clear.cgColor
            layer.lineJoin = .round
            layer.lineDashPattern = [4, 2]  // dashed outline
            return layer
        }()
        
        init(parent: BarcodeScannerView) {
            self.parent = parent
            super.init()

            configureSession()
        }

        /// 1) Configure inputs/outputs on the sessionQueue
        private func configureSession() {
            sessionQueue.async { [weak self] in
                guard let self = self else { return }

                // 1a) Video input
                guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                                for: .video,
                                                                position: .back),
                      let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
                      self.captureSession.canAddInput(videoInput) else {
                    return
                }
                self.captureSession.addInput(videoInput)

                // 1b) Metadata output
                let metadataOutput = AVCaptureMetadataOutput()
                guard self.captureSession.canAddOutput(metadataOutput) else { return }
                self.captureSession.addOutput(metadataOutput)

                metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                metadataOutput.metadataObjectTypes = [.ean8, .ean13, .pdf417]
            }
        }

        /// 2) Public method to start the session (called from makeUIView)
        func startSession() {
            sessionQueue.async { [weak self] in
                guard let self = self else { return }
                if !self.captureSession.isRunning {
                    self.captureSession.startRunning()
                    
                    DispatchQueue.main.async {
                        if let preview = self.previewLayer {
                            // Make sure we only add it once
                            if self.boundingBoxLayer.superlayer == nil {
                                preview.addSublayer(self.boundingBoxLayer)
                            }
                            self.boundingBoxLayer.frame = preview.bounds
                        }
                    }
                }
            }
        }

        /// 3) Public method to stop the session (if/when you need it)
        func stopSession() {
            sessionQueue.async { [weak self] in
                guard let self = self else { return }
                if self.captureSession.isRunning {
                    self.captureSession.stopRunning()
                }
            }
        }

        // MARK: AVCaptureMetadataOutputObjectsDelegate

        func metadataOutput(_ output: AVCaptureMetadataOutput,
                            didOutput metadataObjects: [AVMetadataObject],
                            from connection: AVCaptureConnection) {
            if let firstObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
               let barcode = firstObject.stringValue {
                // Once we get a code, we pass it up to the SwiftUI closure:
                parent.completion(barcode)

                // If you only want one read per scan, you can also call stopSession() here,
                // then restart later (not strictly required).
            }
        }
        
        // Draw a green dashed rectangle around the detected barcode
        private func drawBoundingBox(for rect: CGRect) {
            boundingBoxLayer.path = UIBezierPath(rect: rect).cgPath
        }

        // Clear the overlay if no barcode is in frame
        private func clearBoundingBox() {
            boundingBoxLayer.path = nil
        }
    }
}
