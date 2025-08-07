import SwiftUI
import AVFoundation

struct BarcodeScannerView: UIViewRepresentable {
    var completion: (String) -> Void

    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)

        // Configure preview layer on the main thread
        let previewLayer = AVCaptureVideoPreviewLayer(session: context.coordinator.captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.layer.bounds
        view.layer.addSublayer(previewLayer)

        // Finally, start the session on the sessionQueue:
        context.coordinator.startSession()

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
