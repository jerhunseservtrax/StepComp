//
//  PrivacyToggleView.swift
//  StepComp
//
//  Privacy toggle for challenge creation (Public vs Private)
//

import SwiftUI

struct PrivacyToggleView: View {
    @Binding var isPrivate: Bool
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Privacy")
                .font(.system(size: 16, weight: .bold))
            
            HStack(spacing: 12) {
                // Private Button
                Button(action: {
                    isPrivate = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: isPrivate ? "lock.fill" : "lock")
                            .font(.system(size: 14))
                        Text("Private")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(isPrivate ? StepCompColors.primary : Color(.systemGray6))
                    .foregroundColor(isPrivate ? .black : .secondary)
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
                
                // Public Button
                Button(action: {
                    isPrivate = false
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: isPrivate ? "globe" : "globe.americas.fill")
                            .font(.system(size: 14))
                        Text("Public")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(!isPrivate ? StepCompColors.primary : Color(.systemGray6))
                    .foregroundColor(!isPrivate ? .black : .secondary)
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
            }
            
            // Description text
            HStack(spacing: 6) {
                Image(systemName: "info.circle")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                
                Text(isPrivate ? 
                    "Only invited friends can see and join this challenge" : 
                    "Anyone can discover and join this challenge from the Discover tab")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 4)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    VStack(spacing: 32) {
        // Private selected
        PrivacyToggleView(isPrivate: .constant(true))
            .padding()
        
        Divider()
        
        // Public selected
        PrivacyToggleView(isPrivate: .constant(false))
            .padding()
    }
}

