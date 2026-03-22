//
//  PendingRequestRow.swift
//  FitComp
//
//  Row component for displaying pending friend requests
//

import SwiftUI

struct PendingRequestRow: View {
    let item: FriendListItem
    let onAccept: () -> Void
    let onDecline: () -> Void
    
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            AvatarView(
                displayName: item.profile.displayName ?? item.profile.username,
                avatarURL: item.profile.avatarUrl,
                size: 48
            )
            
            // Name and info
            VStack(alignment: .leading, spacing: 4) {
                Text(item.profile.displayName ?? item.profile.username)
                    .font(.system(size: 16, weight: .semibold))
                
                Text("@\(item.profile.username)")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
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
                        .background(FitCompColors.primary)
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.vertical, 4)
    }
}

