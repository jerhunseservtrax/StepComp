//
//  AddMealPhotoSection.swift
//  FitComp
//

import SwiftUI
import PhotosUI
import UIKit

struct AddMealPhotoSection: View {
    @ObservedObject var viewModel: FoodLogViewModel
    @Binding var mealPhoto: UIImage?
    @Binding var showingCamera: Bool
    @Binding var showingBarcodeScanner: Bool
    @Binding var manualBarcode: String
    @Binding var foodQuery: String
    @Binding var photoPickerItem: PhotosPickerItem?
    @Binding var didAutoScan: Bool
    var onManualBarcodeLookup: () -> Void
    var onSearch: () -> Void
    var onClearPhotoAndScan: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("SNAP & SCAN")
                    .font(.system(size: 11, weight: .black))
                    .tracking(1)
                    .foregroundColor(FitCompColors.textSecondary)
                Spacer()
                if mealPhoto != nil {
                    Text("Photo attached")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(FitCompColors.green)
                }
            }

            if mealPhoto == nil {
                HStack(spacing: 12) {
                    Button(action: { showingCamera = true }) {
                        VStack(spacing: 8) {
                            Image(systemName: "camera.viewfinder")
                                .font(.system(size: 28, weight: .semibold))
                            Text("Take Photo")
                                .font(.system(size: 12, weight: .bold))
                            Text("of your meal")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(FitCompColors.textTertiary)
                        }
                        .foregroundColor(FitCompColors.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(FitCompColors.primary.opacity(0.08))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(FitCompColors.primary.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .sheet(isPresented: $showingCamera) {
                        CameraPickerView(image: $mealPhoto)
                    }

                    PhotosPicker(selection: $photoPickerItem, matching: .images) {
                        VStack(spacing: 8) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 28, weight: .semibold))
                            Text("From Gallery")
                                .font(.system(size: 12, weight: .bold))
                            Text("pick a photo")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(FitCompColors.textTertiary)
                        }
                        .foregroundColor(FitCompColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(FitCompColors.textSecondary.opacity(0.06))
                        .cornerRadius(16)
                    }
                    .onChange(of: photoPickerItem) { _, newItem in
                        Task {
                            if let newItem,
                               let data = try? await newItem.loadTransferable(type: Data.self),
                               let uiImage = UIImage(data: data) {
                                mealPhoto = uiImage
                            }
                        }
                    }
                }

                Button(action: { showingBarcodeScanner = true }) {
                    HStack(spacing: 10) {
                        Image(systemName: "barcode.viewfinder")
                            .font(.system(size: 18, weight: .bold))
                        Text("Scan Barcode")
                            .font(.system(size: 13, weight: .bold))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(FitCompColors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .padding(.horizontal, 14)
                    .background(FitCompColors.textSecondary.opacity(0.06))
                    .cornerRadius(12)
                }

                HStack(spacing: 8) {
                    HStack {
                        Image(systemName: "number")
                            .foregroundColor(FitCompColors.textSecondary)
                        TextField("Enter barcode manually", text: $manualBarcode)
                            .font(.system(size: 14, weight: .medium))
                            .keyboardType(.numberPad)
                            .submitLabel(.search)
                            .onSubmit { onManualBarcodeLookup() }
                    }
                    .padding(12)
                    .background(FitCompColors.textSecondary.opacity(0.08))
                    .cornerRadius(12)

                    Button(action: onManualBarcodeLookup) {
                        if viewModel.isSearching {
                            ProgressView()
                                .frame(width: 44, height: 44)
                        } else {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(FitCompColors.primary)
                        }
                    }
                    .disabled(viewModel.isSearching || manualBarcode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            } else {
                AddMealPhotoPreviewPanel(
                    mealPhoto: $mealPhoto,
                    foodQuery: $foodQuery,
                    viewModel: viewModel,
                    onClear: onClearPhotoAndScan,
                    onSearch: onSearch
                )
            }
        }
        .onChange(of: mealPhoto) { _, newPhoto in
            guard let newPhoto, !didAutoScan else { return }
            didAutoScan = true
            Task { await viewModel.scanImage(newPhoto) }
        }
    }
}

private struct AddMealPhotoPreviewPanel: View {
    @Binding var mealPhoto: UIImage?
    @Binding var foodQuery: String
    @ObservedObject var viewModel: FoodLogViewModel
    var onClear: () -> Void
    var onSearch: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                ZStack(alignment: .topTrailing) {
                    if let photo = mealPhoto {
                        Image(uiImage: photo)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    Button(action: onClear) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.5), radius: 2)
                    }
                    .offset(x: 6, y: -6)
                }

                VStack(alignment: .leading, spacing: 6) {
                    switch viewModel.scanStatus {
                    case .scanning:
                        HStack(spacing: 8) {
                            ProgressView()
                            Text("Scanning photo...")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(FitCompColors.textSecondary)
                        }
                    case .foundItems:
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(FitCompColors.green)
                            Text("Found \(viewModel.searchResults.count) item(s)")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(FitCompColors.green)
                        }
                        Text("Select items below to add them")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(FitCompColors.textSecondary)
                    case .noTextDetected:
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 4) {
                                Image(systemName: "eye.fill")
                                    .foregroundColor(FitCompColors.accent)
                                Text("Describe your meal")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(FitCompColors.textPrimary)
                            }
                            Text("Type what you see (e.g. \"grilled chicken with rice\") and we'll look up the nutrition.")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(FitCompColors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    case .idle:
                        Text("Photo attached")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(FitCompColors.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if viewModel.scanStatus == .noTextDetected {
                HStack(spacing: 8) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(FitCompColors.textSecondary)
                        TextField("Describe what you see...", text: $foodQuery)
                            .font(.system(size: 14, weight: .medium))
                            .submitLabel(.search)
                            .onSubmit { onSearch() }
                    }
                    .padding(12)
                    .background(FitCompColors.primary.opacity(0.06))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(FitCompColors.primary.opacity(0.2), lineWidth: 1)
                    )

                    Button(action: onSearch) {
                        if viewModel.isSearching {
                            ProgressView()
                                .frame(width: 44, height: 44)
                        } else {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(FitCompColors.primary)
                        }
                    }
                    .disabled(viewModel.isSearching || foodQuery.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
