//
//  GroupDetailsSettingsTabView.swift
//  FitComp
//

import SwiftUI

struct SettingsTabView: View {
    @ObservedObject var viewModel: GroupViewModel
    let challenge: Challenge?
    let onDismiss: () -> Void

    @State private var showingDeleteAlert = false
    @State private var showingLeaveAlert = false

    var body: some View {
        VStack(spacing: 12) {
            if viewModel.canDelete {
                Button(role: .destructive, action: {
                    showingDeleteAlert = true
                }) {
                    HStack {
                        Image(systemName: "trash.fill")
                        Text("Delete Challenge")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    .foregroundColor(.red)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                    )
                }
            } else {
                Button(role: .destructive, action: {
                    showingLeaveAlert = true
                }) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("Leave Challenge")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    .foregroundColor(.red)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                    )
                }
            }
        }
        .alert("Delete Challenge?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteChallenge()
                    await MainActor.run {
                        onDismiss()
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete this challenge? All data including leaderboard and chat history will be permanently deleted. This action cannot be undone.")
        }
        .alert("Leave Challenge?", isPresented: $showingLeaveAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Leave", role: .destructive) {
                Task {
                    await viewModel.leaveChallenge()
                    await MainActor.run {
                        onDismiss()
                    }
                }
            }
        } message: {
            Text("Are you sure you want to leave this challenge? You will lose your progress and ranking in this challenge.")
        }
    }
}
