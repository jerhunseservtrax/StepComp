//
//  PrivateChallengesTab.swift
//  StepComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import SwiftUI

struct PrivateChallengesTab: View {
    @ObservedObject var sessionViewModel: SessionViewModel
    @ObservedObject var viewModel: ChallengesViewModel
    @EnvironmentObject var challengeService: ChallengeService
    @State private var navigationPath = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack(spacing: 16) {
                    if viewModel.privateChallenges.isEmpty {
                        EmptyPrivateChallengesView()
                    } else {
                        ForEach(viewModel.privateChallenges) { challenge in
                            PrivateChallengeCard(
                                challenge: challenge,
                                onTap: {
                                    navigationPath.append(AppRoute.groupDetails(challengeId: challenge.id))
                                }
                            )
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .navigationBarHidden(true)
            .navigationDestination(for: AppRoute.self) { route in
                destinationView(for: route)
            }
            .refreshable {
                await viewModel.loadChallenges()
            }
        }
    }
    
    @ViewBuilder
    private func destinationView(for route: AppRoute) -> some View {
        switch route {
        case .groupDetails(let challengeId):
            if let challenge = viewModel.privateChallenges.first(where: { $0.id == challengeId }) {
                GroupDetailsView(
                    sessionViewModel: sessionViewModel,
                    challengeId: challengeId
                )
            } else {
                EmptyView()
            }
        default:
            EmptyView()
        }
    }
}

struct PrivateChallengeCard: View {
    let challenge: Challenge
    let onTap: () -> Void
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(challenge.name)
                            .font(.system(size: 18, weight: .bold))
                        
                        Text(challenge.description.isEmpty ? "Private Challenge" : challenge.description)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "lock.fill")
                        .foregroundColor(primaryYellow)
                        .font(.system(size: 20))
                }
                
                HStack(spacing: 8) {
                    Label("\(challenge.durationInDays) Days", systemImage: "calendar")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(challenge.participantIds.count) participants")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EmptyPrivateChallengesView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.rectangle.stack")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Private Challenges")
                .font(.system(size: 20, weight: .bold))
            
            Text("Join or create private challenges to see them here")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 60)
    }
}
