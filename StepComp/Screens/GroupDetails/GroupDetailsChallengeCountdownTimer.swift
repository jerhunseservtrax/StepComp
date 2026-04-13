//
//  GroupDetailsChallengeCountdownTimer.swift
//  FitComp
//

import SwiftUI

struct ChallengeCountdownTimer: View {
    let endDate: Date
    @State private var timeRemaining: TimeInterval = 0
    @State private var timer: Timer?

    private var hasEnded: Bool {
        Date() >= endDate
    }

    var body: some View {
        if !hasEnded {
            VStack(spacing: 0) {
                VStack(spacing: 12) {
                    HStack(spacing: 6) {
                        Image(systemName: "timer")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(FitCompColors.primary)

                        Text("Challenge ends in")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                            .tracking(1.5)
                    }

                    HStack(spacing: 8) {
                        CountdownUnit(
                            value: days,
                            label: "Days"
                        )

                        Text(":")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(FitCompColors.primary)
                            .padding(.top, 8)

                        CountdownUnit(
                            value: hours,
                            label: "Hours"
                        )

                        Text(":")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(FitCompColors.primary)
                            .padding(.top, 8)

                        CountdownUnit(
                            value: minutes,
                            label: "Mins"
                        )

                        Text(":")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(FitCompColors.primary)
                            .padding(.top, 8)

                        CountdownUnit(
                            value: seconds,
                            label: "Secs"
                        )
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity)
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(FitCompColors.primary.opacity(0.2), lineWidth: 1)
                )
            }
            .onAppear {
                updateTimeRemaining()
                startTimer()
            }
            .onDisappear {
                stopTimer()
            }
        }
    }

    private var days: Int {
        Int(timeRemaining) / 86400
    }

    private var hours: Int {
        (Int(timeRemaining) % 86400) / 3600
    }

    private var minutes: Int {
        (Int(timeRemaining) % 3600) / 60
    }

    private var seconds: Int {
        Int(timeRemaining) % 60
    }

    private func updateTimeRemaining() {
        let now = Date()
        if endDate > now {
            timeRemaining = endDate.timeIntervalSince(now)
        } else {
            timeRemaining = 0
        }
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            DispatchQueue.main.async {
                updateTimeRemaining()
            }
        }
        if let timer = timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

struct CountdownUnit: View {
    let value: Int
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(String(format: "%02d", value))
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .frame(minWidth: 56)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    FitCompColors.primary.opacity(0.1)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(FitCompColors.primary.opacity(0.2), lineWidth: 1)
                        )
                )
                .cornerRadius(12)

            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
    }
}
