//
//  AvatarSelectionView.swift
//  FitComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import SwiftUI
import Combine
import PhotosUI

struct AvatarSelectionOnboardingView: View {
    @ObservedObject var sessionViewModel: SessionViewModel
    @Binding var currentStep: OnboardingFlowView.OnboardingStep
    
    @State private var selectedAvatarIndex: Int = 0
    @State private var showingPhotoPicker = false
    @State private var showingCamera = false
    @State private var showingImageSourcePicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedPhotoData: Data?
    @State private var selectedImage: UIImage?
    
    
    // Emoji avatars matching the design (Custom option at the end)
    private let avatarOptions: [(emoji: String, name: String, color: Color)] = [
        ("🤖", "Botty", Color.blue),
        ("🐱", "Cat", Color.pink),
        ("👽", "Alien", Color.green),
        ("🥷", "Ninja", Color.purple),
        ("🦊", "Fox", Color.orange)
    ]
    
    var body: some View {
        OnboardingScreenBase(currentStep: currentStep.stepIndex) {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Text("Choose your walker")
                        .font(.system(size: 32, weight: .bold))
                    
                    Text("You can change this later.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 32)
                .padding(.bottom, 24)
                
                // Avatar Grid
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ], spacing: 16) {
                        // Emoji avatar options
                        ForEach(Array(avatarOptions.enumerated()), id: \.offset) { index, avatar in
                            AvatarOption(
                                emoji: avatar.emoji,
                                name: avatar.name,
                                backgroundColor: avatar.color,
                                isSelected: selectedAvatarIndex == index && selectedImage == nil,
                                onSelect: {
                                    withAnimation {
                                        selectedAvatarIndex = index
                                        selectedImage = nil
                                        selectedPhotoData = nil
                                    }
                                }
                            )
                        }
                        
                        // Custom photo upload option
                        CustomPhotoAvatarOption(
                            selectedImage: selectedImage,
                            isSelected: selectedImage != nil,
                            onSelect: {
                                showingImageSourcePicker = true
                            }
                        )
                    }
                    .padding(.horizontal, 24)
                }
                
                Spacer()
                
                // Fixed Bottom Button
                VStack(spacing: 0) {
                    LinearGradient(
                        colors: [
                            Color(.systemBackground),
                            Color(.systemBackground).opacity(0)
                        ],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                    .frame(height: 40)
                    
                    Button(action: {
                        saveAvatarAndContinue()
                    }) {
                        Text("Lookin' Good")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(FitCompColors.buttonTextOnPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(FitCompColors.primary)
                            .cornerRadius(999)
                            .shadow(color: FitCompColors.primary.opacity(0.3), radius: 16, x: 0, y: 8)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
        }
        .confirmationDialog("Choose Photo Source", isPresented: $showingImageSourcePicker) {
            Button("Take Photo") {
                showingCamera = true
            }
            Button("Choose from Library") {
                showingPhotoPicker = true
            }
            Button("Cancel", role: .cancel) { }
        }
        .photosPicker(isPresented: $showingPhotoPicker, selection: $selectedPhotoItem, matching: .images)
        .onChange(of: selectedPhotoItem) { oldValue, newValue in
            Task {
                if let item = newValue,
                   let data = try? await item.loadTransferable(type: Data.self) {
                    selectedPhotoData = data
                    selectedImage = UIImage(data: data)
                }
            }
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CameraView(selectedImage: $selectedImage, selectedPhotoData: $selectedPhotoData)
        }
    }
    
    private func saveAvatarAndContinue() {
        if let photoData = selectedPhotoData {
            // Store custom photo data for later upload when user signs in
            UserDefaults.standard.set(photoData, forKey: "selectedAvatarPhotoData")
            UserDefaults.standard.removeObject(forKey: "selectedAvatarEmoji")
        } else {
            // Store selected avatar emoji
            UserDefaults.standard.set(avatarOptions[selectedAvatarIndex].emoji, forKey: "selectedAvatarEmoji")
            UserDefaults.standard.removeObject(forKey: "selectedAvatarPhotoData")
        }
        
        // Move to first win step
        withAnimation {
            currentStep = .firstWin
        }
    }
}

// MARK: - Custom Photo Avatar Option

struct CustomPhotoAvatarOption: View {
    let selectedImage: UIImage?
    let isSelected: Bool
    let onSelect: () -> Void
    
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 0) {
                ZStack {
                    // Card background
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    isSelected ? FitCompColors.primary : Color.clear,
                                    lineWidth: 4
                                )
                        )
                        .shadow(
                            color: isSelected ? FitCompColors.primary.opacity(0.3) : Color.black.opacity(0.05),
                            radius: isSelected ? 20 : 8,
                            x: 0,
                            y: isSelected ? 8 : 2
                        )
                    
                    // Avatar circle with image or camera icon
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 96, height: 96)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 96, height: 96)
                            .overlay(
                                VStack(spacing: 4) {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 28))
                                        .foregroundColor(.gray)
                                    Text("Upload")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.gray)
                                }
                            )
                    }
                    
                    // Checkmark badge
                    if isSelected {
                        VStack {
                            HStack {
                                Spacer()
                                ZStack {
                                    Circle()
                                        .fill(FitCompColors.primary)
                                        .frame(width: 24, height: 24)
                                    
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(FitCompColors.buttonTextOnPrimary)
                                }
                                .padding(8)
                            }
                            Spacer()
                        }
                    }
                }
                .aspectRatio(1, contentMode: .fit)
                
                // Name label
                if isSelected {
                    Text("CUSTOM")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                        .tracking(2)
                        .padding(.top, 8)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Camera View

struct CameraView: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Binding var selectedPhotoData: Data?
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
                parent.selectedImage = image
                parent.selectedPhotoData = image.jpegData(compressionQuality: 0.8)
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

struct AvatarOption: View {
    let emoji: String
    let name: String
    let backgroundColor: Color
    let isSelected: Bool
    let onSelect: () -> Void
    
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 0) {
                ZStack {
                    // Card background
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    isSelected ? FitCompColors.primary : Color.clear,
                                    lineWidth: 4
                                )
                        )
                        .shadow(
                            color: isSelected ? FitCompColors.primary.opacity(0.3) : Color.black.opacity(0.05),
                            radius: isSelected ? 20 : 8,
                            x: 0,
                            y: isSelected ? 8 : 2
                        )
                    
                    // Avatar circle
                    Circle()
                        .fill(backgroundColor.opacity(0.2))
                        .frame(width: 96, height: 96)
                        .overlay(
                            Text(emoji)
                                .font(.system(size: 48))
                        )
                    
                    // Checkmark badge
                    if isSelected {
                        VStack {
                            HStack {
                                Spacer()
                                ZStack {
                                    Circle()
                                        .fill(FitCompColors.primary)
                                        .frame(width: 24, height: 24)
                                    
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(FitCompColors.buttonTextOnPrimary)
                                }
                                .padding(8)
                            }
                            Spacer()
                        }
                    }
                }
                .aspectRatio(1, contentMode: .fit)
                
                // Name label (only for selected or first item)
                if isSelected && name != "Custom" {
                    Text(name.uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                        .tracking(2)
                        .padding(.top, 8)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
