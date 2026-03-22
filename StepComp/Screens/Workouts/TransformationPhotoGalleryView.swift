//
//  TransformationPhotoGalleryView.swift
//  FitComp
//
//  Created by Jeffery Erhunse on 2/23/26.
//

import SwiftUI
import UIKit

struct TransformationPhotoGalleryView: View {
    @ObservedObject var viewModel: TransformationPhotoViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var photoToDelete: TransformationPhoto?
    @State private var showingDeleteConfirmation = false
    @State private var showingFullScreen: TransformationPhoto?
    @State private var showingAddPhotoSet = false
    
    private var cardBackground: Color {
        colorScheme == .dark ? Color(hex: "1a1a1a") : Color(hex: "f8f8f5")
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                FitCompColors.background.ignoresSafeArea()
                
                if viewModel.photos.isEmpty {
                    emptyState
                } else {
                    photoTimeline
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
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        print("📸 Add photo button tapped")
                        showingAddPhotoSet = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .bold))
                            Text("Add")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(FitCompColors.primary)
                    }
                }
            }
            .fullScreenCover(isPresented: $showingAddPhotoSet) {
                AddTransformationPhotoSetView(viewModel: viewModel)
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
                .foregroundColor(FitCompColors.textPrimary)
            
            Text("Document your fitness journey")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(FitCompColors.textSecondary)
            
            Button {
                showingAddPhotoSet = true
            } label: {
                HStack {
                    Image(systemName: "camera.badge.plus")
                    Text("Add First Photo Set")
                        .font(.system(size: 16, weight: .bold))
                }
                .frame(width: 220, height: 56)
                .background(FitCompColors.primary)
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
            // Three photos in a row with delete button overlay
            ZStack(alignment: .topTrailing) {
                HStack(spacing: 0) {
                    PhotoAngleView(
                        photo: photo,
                        angle: .front,
                        viewModel: viewModel,
                        onTap: onTap
                    )
                    
                    PhotoAngleView(
                        photo: photo,
                        angle: .side,
                        viewModel: viewModel,
                        onTap: onTap
                    )
                    
                    PhotoAngleView(
                        photo: photo,
                        angle: .back,
                        viewModel: viewModel,
                        onTap: onTap
                    )
                }
                .frame(height: 300)
                
                // Delete button overlay
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
            
            // Date and note
            VStack(alignment: .leading, spacing: 8) {
                Text(dateString)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(FitCompColors.textPrimary)
                
                if let note = photo.note, !note.isEmpty {
                    Text(note)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(FitCompColors.textSecondary)
                }
            }
            .padding(16)
        }
        .background(cardBackground)
        .cornerRadius(20)
        .shadow(color: FitCompColors.shadowSecondary, radius: 10, x: 0, y: 4)
    }
}

struct PhotoAngleView: View {
    let photo: TransformationPhoto
    let angle: PhotoAngle
    @ObservedObject var viewModel: TransformationPhotoViewModel
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                if let image = viewModel.loadImage(for: photo, angle: angle) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 270)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(maxWidth: .infinity)
                        .frame(height: 270)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 32))
                                .foregroundColor(.gray)
                        )
                }
                
                // Label
                Text(angle.rawValue)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(FitCompColors.textSecondary)
                    .frame(height: 30)
                    .frame(maxWidth: .infinity)
                    .background(FitCompColors.background)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Full Screen Photo View

struct FullScreenPhotoView: View {
    let photo: TransformationPhoto
    @ObservedObject var viewModel: TransformationPhotoViewModel
    let dismiss: () -> Void
    
    @State private var selectedAngle: PhotoAngle = .front
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: photo.date)
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Close button
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
                
                // Image
                if let image = viewModel.loadImage(for: photo, angle: selectedAngle) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .transition(.opacity)
                }
                
                Spacer()
                
                // Angle selector
                HStack(spacing: 20) {
                    ForEach(PhotoAngle.allCases, id: \.self) { angle in
                        Button {
                            withAnimation {
                                selectedAngle = angle
                            }
                        } label: {
                            VStack(spacing: 8) {
                                Text(angle.rawValue)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(selectedAngle == angle ? FitCompColors.primary : .white.opacity(0.6))
                                
                                Rectangle()
                                    .fill(selectedAngle == angle ? FitCompColors.primary : Color.clear)
                                    .frame(height: 3)
                                    .cornerRadius(1.5)
                            }
                            .frame(width: 80)
                        }
                    }
                }
                .padding(.vertical, 12)
                .background(Color.black.opacity(0.7))
                
                // Date and note
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
