//
//  GroupDetailsChallengeTimerBadge.swift
//  FitComp
//

import SwiftUI

// MARK: - Challenge Timer Badge

struct ChallengeTimerBadge: View {
    let startDate: Date
    let endDate: Date
    @State private var timeRemaining: TimeInterval = 0
    @State private var timer: Timer?
    
    private var hasStarted: Bool {
        Date() >= startDate
    }
    
    private var hasEnded: Bool {
        Date() >= endDate
    }
    
    private var hours: Int {
        Int(timeRemaining) / 3600
    }
    
    private var minutes: Int {
        (Int(timeRemaining) % 3600) / 60
    }
    
    private var seconds: Int {
        Int(timeRemaining) % 60
    }
    
    var body: some View {
        if !hasEnded {
            HStack(spacing: 6) {
                Image(systemName: "timer")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(FitCompColors.primary)
                
                Text(hasStarted ? "ENDS IN" : "STARTS IN")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .tracking(0.5)
                
                Text(String(format: "%02d:%02d:%02d", hours, minutes, seconds))
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.4))
            .background(.ultraThinMaterial)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .onAppear {
                updateTimeRemaining()
                timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                    updateTimeRemaining()
                }
                if let timer = timer {
                    RunLoop.main.add(timer, forMode: .common)
                }
            }
            .onDisappear {
                timer?.invalidate()
                timer = nil
            }
        }
    }
    
    private func updateTimeRemaining() {
        let now = Date()
        let targetDate = hasStarted ? endDate : startDate
        if targetDate > now {
            timeRemaining = targetDate.timeIntervalSince(now)
        } else {
            timeRemaining = 0
        }
    }
}
