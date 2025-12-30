//
//  LeaderboardPreview.swift
//  StepComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import SwiftUI

struct LeaderboardPreview: View {
    let challenge: Challenge
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Preview")
                .font(.headline)
            
            Text(challenge.name)
                .font(.title3)
                .fontWeight(.semibold)
            
            Text(challenge.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                Label("\(challenge.targetSteps.formatted()) steps", systemImage: "target")
                Spacer()
                Label("\(challenge.daysRemaining) days", systemImage: "calendar")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
        .cardStyle()
    }
}

