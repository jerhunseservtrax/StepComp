//
//  TransformationPhotoGalleryView.swift
//  StepComp
//
//  Created by Jeffery Erhunse on 2/23/26.
//

import SwiftUI
import PhotosUI

struct TransformationPhotoGalleryView: View {
    @ObservedObject var viewModel: TransformationPhotoViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var selectedItem: PhotosPickerItem?
    @State private var photoToDelete: TransformationPhoto?
    @State private var showingDeleteConfirmation = false
    @State private var showingFullScreen: TransformationPhoto?
    
    private var cardBackground: Color {
        colorScheme == .dark ? Color(hex: "1a1a1a") : Color(hex: "f8f8f5")
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                StepCompColors.background.ignoresSafeArea()
                
                if viewModel.photos.isEmpty {
                    emptyState
                } else {
                    photoTimeline
                }
            }
            .navigationTitle("Transformation Photos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(StepCompColors.primary)
                    }
                }
            }
            .onChange(of: selectedItem) { oldValue, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        viewModel.addPhoto(image: image)
                        HapticManager.shared.success()
                    }
                }
            }
            .confirmationDialog("Delete Photo", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    if let photo = photoToDelete {
                        viewModel.deletePhoto(id: photo.id)
                    }
                    photoToDelete = nil
                }
                Button("Cancel", role: .cancel) {
                    photoToDelete = nil
                }
            } message: {
                Text("Are you sure you want to delete this transformation photo? This cannot be undone.")
            }
            .fullScreenCover(item: $showingFullScreen) { photo in
                FullScreenPhotoView(photo: photo, viewModel: viewModel, dismiss: {
                    showingFullScreen = nil
                })
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera")
                .font(.system(size: 64))
                .foregroundColor(.gray.opacity(0.3))
            
            Text("No transformation photos yet")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(StepCompColors.textPrimary)
            
            Text("Document your fitness journey")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(StepCompColors.textSecondary)
            
            PhotosPicker(selection: $selectedItem, matching: .images) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add First Photo")
                        .font(.system(size: 16, weight: .bold))
                }
                .frame(width: 200, height: 56)
                .background(StepCompColors.primary)
                .foregroundColor(.black)
                .cornerRadius(28)
            }
            .padding(.top, 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var photoTimeline: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(viewModel.photos) { photo in
                    PhotoTimelineCard(
                        photo: photo,
                        viewModel: viewModel,
                        onDelete: {
                            photoToDelete = photo
                            showingDeleteConfirmation = true
                        },
                        onTap: {
                            showingFullScreen = photo
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
    }
}

struct PhotoTimelineCard: View {
    let photo: TransformationPhoto
    @ObservedObject var viewModel: TransformationPhotoViewModel
    let onDelete: () -> Void
    let onTap: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    private var cardBackground: Color {
        colorScheme == .dark ? Color(hex: "1a1a1a") : Color.white
    }
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: photo.date)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Photo
            Button(action: onTap) {
                ZStack(alignment: .topTrailing) {
                    if let image = viewModel.loadImage(for: photo) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 300)
                            .clipped()
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(maxWidth: .infinity)
                            .frame(height: 300)
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.system(size: 48))
                                    .foregroundColor(.gray)
                            )
                    }
                    
                    // Delete button
                    Button(action: onDelete) {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.red)
                            .clipShape(Circle())
                    }
                    .padding(12)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // Date and note
            VStack(alignment: .leading, spacing: 8) {
                Text(dateString)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(StepCompColors.textPrimary)
                
                if let note = photo.note, !note.isEmpty {
                    Text(note)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(StepCompColors.textSecondary)
                }
            }
            .padding(16)
        }
        .background(cardBackground)
        .cornerRadius(20)
        .shadow(color: StepCompColors.shadowSecondary, radius: 10, x: 0, y: 4)
    }
}

struct FullScreenPhotoView: View {
    let photo: TransformationPhoto
    @ObservedObject var viewModel: TransformationPhotoViewModel
    let dismiss: () -> Void
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: photo.date)
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if let image = viewModel.loadImage(for: photo) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            }
            
            VStack {
                HStack {
                    Button(action: dismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                            .shadow(radius: 4)
                    }
                    Spacer()
                }
                .padding()
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(dateString)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    
                    if let note = photo.note, !note.isEmpty {
                        Text(note)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.black.opacity(0.7))
            }
        }
    }
}
