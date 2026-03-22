//
//  AddTransformationPhotoSetView.swift
//  FitComp
//
//  Created by Jeffery Erhunse on 2/27/26.
//

import SwiftUI
import PhotosUI

struct AddTransformationPhotoSetView: View {
    @ObservedObject var viewModel: TransformationPhotoViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var frontImage: UIImage?
    @State private var sideImage: UIImage?
    @State private var backImage: UIImage?
    
    @State private var showingFrontPicker = false
    @State private var showingSidePicker = false
    @State private var showingBackPicker = false
    
    @State private var frontPhotoItem: PhotosPickerItem?
    @State private var sidePhotoItem: PhotosPickerItem?
    @State private var backPhotoItem: PhotosPickerItem?
    
    @State private var showingFrontCamera = false
    @State private var showingSideCamera = false
    @State private var showingBackCamera = false
    
    private var allPhotosSelected: Bool {
        frontImage != nil && sideImage != nil && backImage != nil
    }
    
    private var cardBackground: Color {
        colorScheme == .dark ? Color(hex: "1a1a1a") : .white
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                FitCompColors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        Text("Add all three angles to track your transformation progress")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(FitCompColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .padding(.top, 10)
                        
                        VStack(spacing: 16) {
                            PhotoUploadCard(
                                title: "Front",
                                image: frontImage,
                                onCameraPress: { showingFrontCamera = true },
                                onLibraryPress: { showingFrontPicker = true }
                            )
                            
                            PhotoUploadCard(
                                title: "Side",
                                image: sideImage,
                                onCameraPress: { showingSideCamera = true },
                                onLibraryPress: { showingSidePicker = true }
                            )
                            
                            PhotoUploadCard(
                                title: "Back",
                                image: backImage,
                                onCameraPress: { showingBackCamera = true },
                                onLibraryPress: { showingBackPicker = true }
                            )
                        }
                        .padding(.horizontal, 20)
                        
                        Button(action: savePhotoSet) {
                            Text("Save Photo Set")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(allPhotosSelected ? .black : FitCompColors.textSecondary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(allPhotosSelected ? FitCompColors.primary : FitCompColors.textSecondary.opacity(0.2))
                                .cornerRadius(28)
                        }
                        .disabled(!allPhotosSelected)
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Transformation Photos")
                        .font(.headline)
                        .foregroundColor(colorScheme == .light ? .black : .white)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            // Front photo pickers
            .photosPicker(isPresented: $showingFrontPicker, selection: $frontPhotoItem, matching: .images)
            .onChange(of: frontPhotoItem) { oldValue, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        frontImage = image
                    }
                }
            }
            .fullScreenCover(isPresented: $showingFrontCamera) {
                TransformationCameraView(capturedImage: $frontImage)
            }
            
            // Side photo pickers
            .photosPicker(isPresented: $showingSidePicker, selection: $sidePhotoItem, matching: .images)
            .onChange(of: sidePhotoItem) { oldValue, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        sideImage = image
                    }
                }
            }
            .fullScreenCover(isPresented: $showingSideCamera) {
                TransformationCameraView(capturedImage: $sideImage)
            }
            
            // Back photo pickers
            .photosPicker(isPresented: $showingBackPicker, selection: $backPhotoItem, matching: .images)
            .onChange(of: backPhotoItem) { oldValue, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        backImage = image
                    }
                }
            }
            .fullScreenCover(isPresented: $showingBackCamera) {
                TransformationCameraView(capturedImage: $backImage)
            }
        }
    }
    
    private func savePhotoSet() {
        guard let front = frontImage,
              let side = sideImage,
              let back = backImage else { return }
        
        viewModel.addPhotoSet(frontImage: front, sideImage: side, backImage: back)
        HapticManager.shared.success()
        dismiss()
    }
}

struct PhotoUploadCard: View {
    let title: String
    let image: UIImage?
    let onCameraPress: () -> Void
    let onLibraryPress: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var cardBackground: Color {
        colorScheme == .dark ? Color(hex: "1a1a1a") : .white
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Title bar
            HStack {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(FitCompColors.textPrimary)
                Spacer()
                
                if image != nil {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.green)
                }
            }
            .padding(16)
            .background(cardBackground)
            
            // Image preview or placeholder
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 200)
                    .clipped()
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "photo")
                        .font(.system(size: 48))
                        .foregroundColor(.gray.opacity(0.3))
                    
                    Text("No photo selected")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(FitCompColors.textSecondary)
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .background(FitCompColors.background)
            }
            
            // Action buttons
            HStack(spacing: 0) {
                Button(action: onCameraPress) {
                    HStack(spacing: 6) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 16))
                        Text("Camera")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(FitCompColors.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                }
                .buttonStyle(.plain)
                
                Rectangle()
                    .fill(FitCompColors.background)
                    .frame(width: 1)
                
                Button(action: onLibraryPress) {
                    HStack(spacing: 6) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 16))
                        Text("Library")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(FitCompColors.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                }
                .buttonStyle(.plain)
            }
            .background(cardBackground)
        }
        .background(cardBackground)
        .cornerRadius(16)
        .shadow(color: FitCompColors.shadowSecondary, radius: 8, x: 0, y: 2)
    }
}

struct TransformationCameraView: UIViewControllerRepresentable {
    @Binding var capturedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: TransformationCameraView
        
        init(_ parent: TransformationCameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.capturedImage = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
