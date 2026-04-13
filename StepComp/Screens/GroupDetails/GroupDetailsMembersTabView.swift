//
//  GroupDetailsMembersTabView.swift
//  FitComp
//

import Foundation
import SwiftUI

struct MembersTabView: View {
    let members: [User]
    let leaderboardEntries: [LeaderboardEntry]
    @State private var selectedUserId: String?

    private var membersWithSteps: [(user: User, steps: Int, rank: Int)] {
        let sortedEntries = leaderboardEntries.sorted { $0.rank < $1.rank }
        return members.compactMap { member in
            if let entry = sortedEntries.first(where: { $0.userId == member.id }) {
                return (user: member, steps: entry.steps, rank: entry.rank)
            }
            return (user: member, steps: 0, rank: members.count)
        }
        .sorted { $0.rank < $1.rank }
    }

    var body: some View {
        ZStack {
            VStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(members.count) Members")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)

                    Text("Total steps accumulated since challenge started")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 8)

                HStack(spacing: 12) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(FitCompColors.primary)

                    Text("Step counts update daily and represent the total steps accumulated in this challenge.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(FitCompColors.primary.opacity(0.1))
                )
                .padding(.bottom, 8)

                ForEach(membersWithSteps, id: \.user.id) { item in
                    HStack(spacing: 12) {
                        Text("\(item.rank)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(item.rank <= 3 ? FitCompColors.primary : Color(.systemGray))
                            .frame(width: 24, alignment: .center)

                        AvatarView(
                            displayName: item.user.displayName,
                            avatarURL: item.user.avatarURL,
                            size: 48
                        )
                        .overlay(
                            Circle()
                                .stroke(item.rank == 1 ? FitCompColors.primary : Color(.systemGray5), lineWidth: item.rank == 1 ? 2 : 1)
                        )

                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.user.displayName)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.primary)
                                .lineLimit(1)

                            if !item.user.username.isEmpty {
                                Text("@\(item.user.username)")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text(formatSteps(item.steps))
                                .font(.system(size: 18, weight: .bold, design: .monospaced))
                                .foregroundColor(item.rank == 1 ? FitCompColors.primary : .primary)

                            Text("TOTAL STEPS")
                                .font(.system(size: 9, weight: .bold))
                                .tracking(0.5)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(item.rank == 1 ? FitCompColors.primary.opacity(0.3) : Color(.systemGray6), lineWidth: 1)
                    )
                    .onTapGesture {
                        selectedUserId = item.user.id
                    }
                }
            }

            if selectedUserId != nil {
                UserProfileCard(
                    userId: selectedUserId ?? "",
                    currentUserId: members.first?.id ?? "",
                    isPresented: Binding(
                        get: { selectedUserId != nil },
                        set: { if !$0 { selectedUserId = nil } }
                    )
                )
                .transition(.opacity)
                .zIndex(1000)
            }
        }
    }

    private func formatSteps(_ steps: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: steps)) ?? "\(steps)"
    }
}
