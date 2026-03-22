//
//  ChallengeImageBackground.swift
//  FitComp
//
//  Created for challenge image display functionality
//

import SwiftUI

// MARK: - URL Validation Helper

/// Validates if a string is a valid image URL
/// - Parameter urlString: The URL string to validate
/// - Returns: true if the URL is valid, false otherwise
/// - Note: Logs warnings for invalid URLs to aid debugging
func isValidImageURL(_ urlString: String?) -> Bool {
    // Handle nil
    guard let urlString = urlString else {
        return false
    }
    
    // Trim whitespace and check if empty
    let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else {
        print("⚠️ [ChallengeImage] Invalid image URL: empty or whitespace-only string")
        return false
    }
    
    // Validate URL scheme (must be HTTP or HTTPS)
    guard trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") else {
        print("⚠️ [ChallengeImage] Invalid image URL scheme: '\(trimmed.prefix(20))...' (must start with http:// or https://)")
        return false
    }
    
    // Validate URL can be constructed
    guard URL(string: trimmed) != nil else {
        print("⚠️ [ChallengeImage] Invalid image URL format (cannot construct URL): '\(trimmed.prefix(50))...'")
        return false
    }
    
    return true
}

// MARK: - Challenge Image Background View

/// A reusable view component for displaying challenge images with proper error handling and fallback gradients
struct ChallengeImageBackground: View {
    let imageUrl: String?
    let gradientColors: [Color]
    let overlayOpacity: Double
    
    /// Initialize with image URL and gradient colors for fallback
    /// - Parameters:
    ///   - imageUrl: Optional image URL string
    ///   - gradientColors: Array of colors for gradient fallback (should have at least 2 colors)
    ///   - overlayOpacity: Opacity for the gradient overlay (default: 0.5)
    init(
        imageUrl: String?,
        gradientColors: [Color],
        overlayOpacity: Double = 0.5
    ) {
        self.imageUrl = imageUrl
        self.gradientColors = gradientColors
        self.overlayOpacity = overlayOpacity
    }
    
    var body: some View {
        Group {
            if isValidImageURL(imageUrl) {
                // User uploaded image with gradient overlay
                ZStack {
                    AsyncImage(url: URL(string: imageUrl!)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            // Fallback gradient on image load failure
                            LinearGradient(
                                colors: gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        case .empty:
                            // Loading state - show gradient
                            LinearGradient(
                                colors: gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        @unknown default:
                            LinearGradient(
                                colors: gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        }
                    }
                    
                    // Gradient overlay for better text readability
                    LinearGradient(
                        colors: [
                            gradientColors[0].opacity(overlayOpacity),
                            gradientColors[safe: 1]?.opacity(overlayOpacity) ?? gradientColors[0].opacity(overlayOpacity)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .blendMode(.multiply)
                }
            } else {
                // Default gradient background (no valid image URL)
                LinearGradient(
                    colors: gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }
}

// MARK: - Array Safe Access Extension

private extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
