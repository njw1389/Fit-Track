//
//  BarcodeScannerView.swift
//  FitTrack
//
//  Created by Nolan Wira on 11/28/24.
//

import SwiftUI
import AVFoundation

struct BarcodeScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var scannerViewModel = BarcodeScannerViewModel()
    let onFoodFound: (FoodScanResult) -> Void
    
    var body: some View {
        ZStack {
            // Camera view
            if scannerViewModel.isSessionReady {
                CameraPreview(session: scannerViewModel.session)
                    .background(Color.black)
                    .ignoresSafeArea()
            } else {
                Color.black
                    .ignoresSafeArea()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            }
            
            // Scanner overlay
            VStack {
                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    .padding()
                    .disabled(scannerViewModel.isLoading)
                    .foregroundColor(.white)
                    
                    Spacer()
                }
                
                Spacer()
                
                if scannerViewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(2)
                        .padding()
                }
                
                Spacer()
                
                Text("Align barcode within frame")
                    .foregroundColor(.white)
                    .padding(.bottom)
            }
        }
        .alert("Error", isPresented: $scannerViewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(scannerViewModel.errorMessage)
        }
        .onAppear {
            print("BarcodeScannerView appeared")
            Task {
                await scannerViewModel.startScanning { result in
                    onFoodFound(result)
                    dismiss()
                }
            }
        }
        .onDisappear {
            print("BarcodeScannerView disappeared")
            scannerViewModel.stopScanning()
        }
    }
}

// Camera preview using UIViewRepresentable
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        print("Creating camera preview view")
        let view = UIView(frame: UIScreen.main.bounds)
        
        DispatchQueue.main.async {
            let previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer.frame = view.bounds
            previewLayer.videoGravity = .resizeAspectFill
            view.layer.addSublayer(previewLayer)
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        print("Updating camera preview view")
        guard let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer else {
            return
        }
        
        previewLayer.frame = uiView.bounds
        
        if let connection = previewLayer.connection {
            let currentDevice = UIDevice.current
            let orientation = currentDevice.orientation
            
            let rotationAngle: CGFloat
            switch orientation {
            case .portrait:
                rotationAngle = 0
            case .landscapeRight:
                rotationAngle = -.pi / 2
            case .landscapeLeft:
                rotationAngle = .pi / 2
            case .portraitUpsideDown:
                rotationAngle = .pi
            default:
                rotationAngle = 0
            }
            
            if #available(iOS 17.0, *) {
                if connection.isVideoRotationAngleSupported(rotationAngle) {
                    connection.videoRotationAngle = rotationAngle
                }
            } else {
                if connection.isVideoOrientationSupported {
                    let videoOrientation: AVCaptureVideoOrientation
                    switch orientation {
                    case .portrait:
                        videoOrientation = .portrait
                    case .landscapeRight:
                        videoOrientation = .landscapeLeft
                    case .landscapeLeft:
                        videoOrientation = .landscapeRight
                    case .portraitUpsideDown:
                        videoOrientation = .portraitUpsideDown
                    default:
                        videoOrientation = .portrait
                    }
                    connection.videoOrientation = videoOrientation
                }
            }
        }
    }
}

// ViewModel for handling barcode scanning and API calls
class BarcodeScannerViewModel: NSObject, ObservableObject {
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var isSessionReady = false
    
    let session = AVCaptureSession()
    private var foundCode: ((FoodScanResult) -> Void)?
    
    func startScanning(completion: @escaping (FoodScanResult) -> Void) async {
        print("Starting camera session...")
        self.foundCode = completion
        
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else {
                    continuation.resume()
                    return
                }
                
                self.configureSession()
                
                // Start the session
                if !self.session.isRunning {
                    self.session.startRunning()
                }
                
                DispatchQueue.main.async {
                    print("Session running status: \(self.session.isRunning)")
                    self.isSessionReady = true
                    continuation.resume()
                }
            }
        }
    }
    
    private func configureSession() {
        print("Configuring camera session...")
        print("Initial session running status: \(session.isRunning)")
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            print("Camera not available")
            showError(message: "Camera not available")
            return
        }
        
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            print("Could not initialize camera: \(error)")
            showError(message: "Could not initialize camera")
            return
        }
        
        if session.canAddInput(videoInput) {
            session.addInput(videoInput)
        } else {
            print("Could not add camera input")
            showError(message: "Could not add camera input")
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.ean8, .ean13, .upce]
        } else {
            print("Could not add metadata output")
            showError(message: "Could not add metadata output")
            return
        }
        
        print("Session configured successfully")
        print("Post-configuration session running status: \(session.isRunning)")
    }
    
    func stopScanning() {
        print("Stopping camera session...")
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            if self?.session.isRunning == true {
                self?.session.stopRunning()
            }
        }
    }
    
    private func showError(message: String) {
        DispatchQueue.main.async { [weak self] in
            self?.errorMessage = message
            self?.showError = true
        }
    }
    
    private func fetchFoodInfo(barcode: String) async throws -> FoodScanResult {
        print("Fetching food info for barcode: \(barcode)")
        let urlString = "https://world.openfoodfacts.org/api/v0/product/\(barcode).json"
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(OpenFoodFactsResponse.self, from: data)
        
        guard let product = response.product else {
            return FoodScanResult.emptyResult()
        }
        
        return FoodScanResult(
            name: product.productName ?? "Unknown Product",
            calories: Double(product.nutriments.energyKcal ?? 0),
            protein: Double(product.nutriments.proteins ?? 0),
            carbs: Double(product.nutriments.carbohydrates ?? 0),
            fat: Double(product.nutriments.fat ?? 0),
            sugar: Double(product.nutriments.sugars ?? 0),
            fiber: Double(product.nutriments.fiber ?? 0),
            sodium: Double(product.nutriments.sodium ?? 0),
            isEmptyResult: false
        )
    }
}

// AVCaptureMetadataOutputObjectsDelegate implementation
extension BarcodeScannerViewModel: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard !isLoading,
              let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let stringValue = metadataObject.stringValue else {
            return
        }
        
        print("Barcode detected: \(stringValue)")
        isLoading = true
        
        Task {
            do {
                let result = try await fetchFoodInfo(barcode: stringValue)
                await MainActor.run {
                    self.foundCode?(result)
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.showError(message: "Could not find product: \(error.localizedDescription)")
                }
            }
        }
    }
}

// Models for OpenFoodFacts API
struct OpenFoodFactsResponse: Codable {
    let product: Product?
}

struct Product: Codable {
    let productName: String?
    let nutriments: Nutriments
    
    enum CodingKeys: String, CodingKey {
        case productName = "product_name"
        case nutriments
    }
}

struct Nutriments: Codable {
    let energyKcal: Double?
    let proteins: Double?
    let carbohydrates: Double?
    let fat: Double?
    let sugars: Double?
    let fiber: Double?
    let sodium: Double?
    
    enum CodingKeys: String, CodingKey {
        case energyKcal = "energy-kcal_100g"
        case proteins = "proteins_100g"
        case carbohydrates = "carbohydrates_100g"
        case fat = "fat_100g"
        case sugars = "sugars_100g"
        case fiber = "fiber_100g"
        case sodium = "sodium_100g"
    }
}

struct FoodScanResult {
    let name: String
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let sugar: Double
    let fiber: Double
    let sodium: Double
    let isEmptyResult: Bool
    
    static func emptyResult() -> FoodScanResult {
        return FoodScanResult(
            name: "",
            calories: 0,
            protein: 0,
            carbs: 0,
            fat: 0,
            sugar: 0,
            fiber: 0,
            sodium: 0,
            isEmptyResult: true
        )
    }
}
