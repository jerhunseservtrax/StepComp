//
//  CreateChallengeCTA.swift
//  FitComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import SwiftUI

struct CreateChallengeCTA: View {
    let onCreateChallenge: () -> Void
    
    var body: some View {
        ZStack {
            // Dark background matching design
            Color(red: 0.17, green: 0.17, blue: 0.08)
                .opacity(0.95)
            
            // Background pattern overlay (simplified)
            LinearGradient(
                colors: [
                    Color.black.opacity(0.2),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Start a new battle?")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Invite friends and see who can walk the talk.")
                            .font(.system(size: 14))
                            .foregroundColor(Color.white.opacity(0.7))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    Spacer()
                    
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 48, height: 48)
                        
                        Image(systemName: "flame.fill")
                            .foregroundColor(FitCompColors.primary)
                            .font(.system(size: 20))
                    }
                }
                
                Button(action: onCreateChallenge) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Create Challenge")
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
            }
            .padding(24)
        }
        .cornerRadius(32)
    }
}

