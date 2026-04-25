//
//  CameraCapture.swift
//  PageKeep
//
//  Created on November 4, 2025
//  Phase 6: Camera & OCR Implementation
//

import SwiftUI
import UIKit
import AVFoundation

// MARK: - Camera Capture SwiftUI View

/// SwiftUI wrapper for UIImagePickerController
/// Handles camera access for both photos and barcodes
/// Manages permissions and returns captured images to parent view
struct CameraCapture: UIViewControllerRepresentable {
    
    // MARK: - Bindings
    
    /// The captured image - parent view reads this after camera dismisses
    @Binding var image: UIImage?
    
    /// Controls whether camera is presented - parent sets to false to dismiss
    @Binding var isPresented: Bool
    
    // MARK: - Configuration
    
    /// Source type - can be .camera or .photoLibrary
    /// Defaults to .camera for taking new photos
    var sourceType: UIImagePickerController.SourceType = .camera
    
    // MARK: - UIViewControllerRepresentable Methods
    
    /// Creates the coordinator that handles UIImagePickerController delegate callbacks
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    /// Creates and configures the UIImagePickerController
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        
        // Only set camera-specific options if using camera
        if sourceType == .camera {
            // Allow user to edit/crop the photo if desired
            picker.allowsEditing = false  // We want the full image for OCR
            
            // Use rear camera (better quality for text capture)
            if UIImagePickerController.isCameraDeviceAvailable(.rear) {
                picker.cameraDevice = .rear
            }
        }
        
        return picker
    }
    
    /// Updates the view controller when SwiftUI state changes
    /// Not needed for camera capture, but required by protocol
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // No updates needed - camera is modal and doesn't change
    }
    
    // MARK: - Coordinator Class
    
    /// Coordinator handles UIImagePickerController delegate callbacks
    /// Bridges between UIKit (UIImagePickerController) and SwiftUI (CameraCapture)
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        
        let parent: CameraCapture
        
        init(_ parent: CameraCapture) {
            self.parent = parent
        }
        
        // MARK: - UIImagePickerControllerDelegate Methods
        
        /// Called when user captures/selects an image
        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
        ) {
            // Try to get the original image first (unedited)
            if let capturedImage = info[.originalImage] as? UIImage {
                // Successfully captured image
                parent.image = capturedImage
            } else if let editedImage = info[.editedImage] as? UIImage {
                // Fallback to edited image if original not available
                parent.image = editedImage
            } else {
                // Failed to get image
                parent.image = nil
            }
            
            // Dismiss the camera
            parent.isPresented = false
        }
        
        /// Called when user cancels the camera
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            // Clear any existing image
            parent.image = nil
            
            // Dismiss the camera
            parent.isPresented = false
        }
    }
}

// MARK: - Permission Status Enum

/// Represents the current camera permission state
enum CameraPermissionStatus {
    case authorized      // User granted camera access
    case denied          // User explicitly denied camera access
    case restricted      // Camera access restricted (e.g., parental controls)
    case notDetermined   // User hasn't been asked yet
    
    /// User-friendly description of the permission state
    var description: String {
        switch self {
        case .authorized:
            return "Camera access granted"
        case .denied:
            return "Camera access denied"
        case .restricted:
            return "Camera access restricted"
        case .notDetermined:
            return "Camera permission not yet requested"
        }
    }
}

// MARK: - Camera Permission Manager

/// Centralized camera permission handling
/// Use this to check and request camera permissions before presenting camera
class CameraPermissionManager {
    
    // MARK: - Permission Checking
    
    /// Checks current camera permission status
    /// Call this on view appear to update UI (grey out buttons if denied)
    /// - Returns: Current permission status
    static func checkPermission() -> CameraPermissionStatus {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            return .authorized
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        case .notDetermined:
            return .notDetermined
        @unknown default:
            // Future-proof: treat unknown status as denied
            return .denied
        }
    }
    
    /// Checks if camera is currently available
    /// Returns false if permission denied or camera not available on device
    /// - Returns: True if camera can be used
    static func isCameraAvailable() -> Bool {
        // Check if device has a camera
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            return false
        }
        
        // Check if we have permission
        let status = checkPermission()
        return status == .authorized
    }
    
    // MARK: - Permission Requesting
    
    /// Requests camera permission from the user
    /// Shows system alert asking for camera access
    /// - Parameter completion: Called with true if granted, false if denied
    static func requestPermission(completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            // Ensure completion runs on main thread for UI updates
            DispatchQueue.main.async {
                if granted {
                } else {
                }
                completion(granted)
            }
        }
    }
    
    // MARK: - Settings Navigation
    
    /// Opens iOS Settings app to the app's permission page
    /// Use this when user taps "Open Settings" in permission denied alert
    static func openSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        
        if UIApplication.shared.canOpenURL(settingsURL) {
            UIApplication.shared.open(settingsURL) { success in
                if success {
                } else {
                }
            }
        }
    }
}

// MARK: - Camera Permission Alert Helper

/// Helper struct to generate permission-related alerts
/// Use these in your views when camera permission is needed
struct CameraPermissionAlert {
    
    /// Alert shown when camera permission is denied
    /// Provides "Open Settings" button to help user fix the issue
    static func deniedAlert() -> Alert {
        Alert(
            title: Text("Camera Access Needed"),
            message: Text("PageKeep needs camera access to capture text from your physical books for annotations. Please enable it in Settings."),
            primaryButton: .default(Text("Open Settings")) {
                CameraPermissionManager.openSettings()
            },
            secondaryButton: .cancel()
        )
    }
    
    /// Alert shown when camera is restricted (e.g., parental controls)
    /// User cannot grant access themselves
    static func restrictedAlert() -> Alert {
        Alert(
            title: Text("Camera Access Restricted"),
            message: Text("Camera access is restricted on this device. This may be due to parental controls or device management policies."),
            dismissButton: .default(Text("OK"))
        )
    }
    
    /// Alert shown when camera is not available on device (e.g., simulator)
    static func unavailableAlert() -> Alert {
        Alert(
            title: Text("Camera Not Available"),
            message: Text("This device doesn't have a camera or the camera is not accessible. Please use a physical device to capture images."),
            dismissButton: .default(Text("OK"))
        )
    }
}

// MARK: - Usage Example (for reference)
/*
 
 // In your SwiftUI view (e.g., AddAnnotationView):
 
 @State private var showingCamera = false
 @State private var capturedImage: UIImage?
 @State private var showingPermissionAlert = false
 @State private var cameraPermissionGranted = false
 
 var body: some View {
     VStack {
         // Camera button
         Button(action: handleCameraButtonTap) {
             Image(systemName: "camera")
                 .font(.title3)
         }
         .disabled(!cameraPermissionGranted)
         .opacity(cameraPermissionGranted ? 1.0 : 0.5)
     }
     .onAppear {
         checkCameraPermission()
     }
     .sheet(isPresented: $showingCamera) {
         CameraCapture(image: $capturedImage, isPresented: $showingCamera)
     }
     .alert("Camera Access Needed", isPresented: $showingPermissionAlert) {
         Button("Cancel", role: .cancel) { }
         Button("Open Settings") {
             CameraPermissionManager.openSettings()
         }
     } message: {
         Text("Camera access is needed to capture text from your books. Please enable it in Settings.")
     }
     .onChange(of: capturedImage) { _, newImage in
         if let image = newImage {
             // Process the captured image (run OCR, etc.)
             processCapturedImage(image)
         }
     }
 }
 
 private func checkCameraPermission() {
     let status = CameraPermissionManager.checkPermission()
     cameraPermissionGranted = (status == .authorized)
 }
 
 private func handleCameraButtonTap() {
     let status = CameraPermissionManager.checkPermission()
     
     switch status {
     case .authorized:
         // Permission already granted - open camera
         showingCamera = true
         
     case .notDetermined:
         // Need to request permission
         CameraPermissionManager.requestPermission { granted in
             if granted {
                 cameraPermissionGranted = true
                 showingCamera = true
             } else {
                 showingPermissionAlert = true
             }
         }
         
     case .denied, .restricted:
         // Permission denied - show alert
         showingPermissionAlert = true
     }
 }
 
 */
