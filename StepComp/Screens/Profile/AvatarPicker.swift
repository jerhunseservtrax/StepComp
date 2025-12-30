//
//  AvatarPicker.swift
//  StepComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import SwiftUI

struct AvatarPicker: View {
    @Binding var selectedAvatarURL: String?
    let avatars: [String] = [] // TODO: Add avatar options
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(avatars, id: \.self) { avatarURL in
                    Button(action: {
                        selectedAvatarURL = avatarURL
                    }) {
                        AsyncImage(url: URL(string: avatarURL)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Color.gray.opacity(0.3)
                        }
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(selectedAvatarURL == avatarURL ? Color.blue : Color.clear, lineWidth: 3)
                        )
                    }
                }
            }
            .padding()
        }
    }
}

