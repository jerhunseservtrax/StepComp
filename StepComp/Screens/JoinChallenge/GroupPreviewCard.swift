//
//  GroupPreviewCard.swift
//  FitComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import SwiftUI
import Combine

struct GroupPreviewCard: View {
    let challenge: Challenge
    let onJoin: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(challenge.name)
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text(challenge.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
            }
            
            Divider()
            
            HStack(spacing: 24) {
                Label("\(challenge.targetSteps.formatted())", systemImage: "target")
                Label("\(challenge.participantIds.count)", systemImage: "person.2")
                Label("\(challenge.daysRemaining)", systemImage: "calendar")
                Spacer()
            }
            .font(.caption)
            .foregroundColor(.secondary)
            
            Button(action: onJoin) {
                Text("Join Challenge")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .cardStyle()
    }
}

