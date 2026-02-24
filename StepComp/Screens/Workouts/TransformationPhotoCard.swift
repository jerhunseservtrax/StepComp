//
//  TransformationPhotoCard.swift
//  StepComp
//
//  Created by Jeffery Erhunse on 2/23/26.
//

import SwiftUI

struct TransformationPhotoCard: View {
    @ObservedObject var viewModel: TransformationPhotoViewModel
    @Binding var showingPhotoGallery: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    private var cardBackground: Color {
        colorScheme == .dark ? Color(hex: "1e1e1e") : Color.black
    }
    
    private var textColor: Color {
        colorScheme == .dark ? StepCompColors.primary : .white
    }
    
    private var dateString: String? {
        guard let latest = viewModel.photos.first else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: latest.date)
    }
    
    var body: some View {
        Button(action: { showingPhotoGallery = true }) {
            VStack(alignment: .leading, spacing: 0) {
                // Icon or photo at top
                HStack {
                    if let latestImage = viewModel.latestPhoto {
                        Image(uiImage: latestImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.1))
                                .frame(width: 40, height: 40)
                            Image(systemName: "camera.fill")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(textColor)
                        }
                    }
                    Spacer()
                }
                .padding(.bottom, 8)
                
                Spacer()
                
                // Label and info at bottom
                VStack(alignment: .leading, spacing: 4) {
                    Text("PHOTOS")
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(textColor.opacity(0.4))
                        .tracking(0.5)
                    
                    if let date = dateString {
                        Text(date)
                            .font(.system(size: 16, weight: .black))
                            .italic()
                            .foregroundColor(textColor)
                        Text("\(viewModel.photos.count) photo\(viewModel.photos.count == 1 ? "" : "s")")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(textColor.opacity(0.6))
                    } else {
                        Text("Add Photos")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(textColor.opacity(0.5))
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(cardBackground)
            .cornerRadius(24)
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
