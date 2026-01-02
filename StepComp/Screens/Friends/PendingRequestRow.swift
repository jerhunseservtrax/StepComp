//
//  PendingRequestRow.swift
//  StepComp
//
//  Row component for displaying pending friend requests
//

import SwiftUI

struct PendingRequestRow: View {
    let item: FriendListItem
    let onAccept: () -> Void
    let onDecline: () -> Void
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            AvatarView(
                displayName: item.profile.displayName,
                avatarURL: item.profile.avatarURL,
                size: 48
            )
            
            // Name and info
            VStack(alignment: .leading, spacing: 4) {
                Text(item.profile.displayName)
                    .font(.system(size: 16, weight: .semibold))
                
                if let username = item.profile.username {
                    Text("@\(username)")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 8) {
                // Decline button
                Button(action: onDecline) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.red)
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
                
                // Accept button
                Button(action: onAccept) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(width: 32, height: 32)
                        .background(primaryYellow)
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.vertical, 4)
    }
}

