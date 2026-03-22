//
//  AvatarView.swift
//  FitComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import SwiftUI

struct AvatarView: View {
    let displayName: String
    let avatarURL: String?
    let size: CGFloat
    
    init(displayName: String, avatarURL: String? = nil, size: CGFloat = 50) {
        self.displayName = displayName
        self.avatarURL = avatarURL
        self.size = size
    }
    
    private var initials: String {
        let components = displayName.components(separatedBy: " ")
        if components.count >= 2 {
            return String(components[0].prefix(1)) + String(components[1].prefix(1))
        }
        return String(displayName.prefix(2)).uppercased()
    }
    
    /// Checks if the string is an emoji (single or multiple emoji characters)
    private var isEmoji: Bool {
        guard let avatarURL = avatarURL, !avatarURL.isEmpty else { return false }
        // If it's a URL (starts with http), it's not an emoji
        if avatarURL.hasPrefix("http") { return false }
        // Check if all characters are emoji
        return avatarURL.unicodeScalars.allSatisfy { scalar in
            scalar.properties.isEmoji && scalar.properties.isEmojiPresentation ||
            scalar.properties.isEmoji && scalar.value > 0x238C
        }
    }
    
    /// Checks if the string is a valid URL
    private var isValidURL: Bool {
        guard let avatarURL = avatarURL, !avatarURL.isEmpty else { return false }
        return avatarURL.hasPrefix("http://") || avatarURL.hasPrefix("https://")
    }
    
    var body: some View {
        Group {
            if let avatarURL = avatarURL, !avatarURL.isEmpty {
                if isValidURL {
                    // Display image from URL
                    CachedAsyncImage(url: URL(string: avatarURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        placeholderView
                    }
                } else if isEmoji {
                    // Display emoji avatar
                    emojiAvatarView(emoji: avatarURL)
                } else {
                    // Fallback to placeholder
                    placeholderView
                }
            } else {
                placeholderView
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
    
    private func emojiAvatarView(emoji: String) -> some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.yellow.opacity(0.3), Color.orange.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text(emoji)
                .font(.system(size: size * 0.5))
        }
    }
    
    private var placeholderView: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text(initials)
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundColor(.white)
        }
    }
}

