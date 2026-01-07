//
//  AddFriendsCTA.swift
//  StepComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import SwiftUI

struct AddFriendsCTA: View {
    let onAddFriends: () -> Void
    
    
    var body: some View {
        Button(action: onAddFriends) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(StepCompColors.primary.opacity(0.2))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 20))
                        .foregroundColor(StepCompColors.primary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Add Friends")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("Invite friends to compete")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal)
    }
}

