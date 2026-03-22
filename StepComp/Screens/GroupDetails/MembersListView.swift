//
//  MembersListView.swift
//  FitComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import SwiftUI
import Combine

struct MembersListView: View {
    let members: [User]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Members")
                .font(.title3)
                .fontWeight(.semibold)
            
            if members.isEmpty {
                Text("No members yet")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(members) { member in
                        HStack(spacing: 12) {
                            AvatarView(
                                displayName: member.displayName,
                                avatarURL: member.avatarURL,
                                size: 40
                            )
                            
                            Text(member.displayName)
                                .font(.body)
                            
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
        }
        .padding()
        .cardStyle()
    }
}

