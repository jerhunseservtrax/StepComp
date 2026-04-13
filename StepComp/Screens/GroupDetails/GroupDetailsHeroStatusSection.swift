//
//  GroupDetailsHeroStatusSection.swift
//  FitComp
//

import SwiftUI

struct HeroStatusSection: View {
    let challenge: Challenge

    var daysElapsed: Int {
        let calendar = Calendar.current
        let now = Date()
        guard now >= challenge.startDate else { return 0 }
        let components = calendar.dateComponents([.day], from: challenge.startDate, to: now)
        return (components.day ?? 0) + 1
    }

    var totalDays: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: challenge.startDate, to: challenge.endDate)
        return (components.day ?? 0) + 1
    }

    var challengeProgress: Double {
        guard totalDays > 0 else { return 0 }
        return min(Double(daysElapsed) / Double(totalDays), 1.0)
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Challenge Status")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(2)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(.systemGray6))
                .cornerRadius(999)

            Text("Day \(daysElapsed) of \(totalDays)")
                .font(.system(size: 32, weight: .bold))

            VStack(spacing: 8) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray5))
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [FitCompColors.primary, FitCompColors.primary.opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * challengeProgress, height: 8)
                            .shadow(color: FitCompColors.primary.opacity(0.5), radius: 4, x: 0, y: 0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.7), value: challengeProgress)
                    }
                }
                .frame(height: 8)

                Text("\(Int(challengeProgress * 100))% Complete")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)

            HStack(spacing: 4) {
                Image(systemName: "calendar")
                    .font(.system(size: 16))
                Text("\(challenge.daysRemaining) days left in challenge")
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(.secondary)
        }
    }
}
