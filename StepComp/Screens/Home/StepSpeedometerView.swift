//
//  StepSpeedometerView.swift
//  StepComp
//
//  Speedometer-style step progress indicator
//

import SwiftUI

struct StepSpeedometerView: View {
    let currentSteps: Int
    let dailyGoal: Int
    let percentageChange: Double
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
    // Calculate progress
    private var progress: Double {
        guard dailyGoal > 0 else { return 0 }
        return min(Double(currentSteps) / Double(dailyGoal), 1.0)
    }
    
    private var remaining: Int {
        max(0, dailyGoal - currentSteps)
    }
    
    // Needle rotation angle (from -135° to +135°, total 270° sweep)
    private var needleAngle: Double {
        let startAngle = -135.0
        let endAngle = 135.0
        let totalSweep = endAngle - startAngle
        return startAngle + (progress * totalSweep)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                // Background Card
                RoundedRectangle(cornerRadius: 32)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.05), radius: 20, x: 0, y: 4)
                
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(primaryYellow)
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Image(systemName: "figure.walk")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.black)
                                )
                            
                            Text("CURRENT STEPS")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.secondary)
                                .tracking(1)
                        }
                        
                        Spacer()
                        
                        // Percentage Change Badge
                        if percentageChange != 0 {
                            HStack(spacing: 4) {
                                Image(systemName: percentageChange > 0 ? "arrow.up" : "arrow.down")
                                    .font(.system(size: 10, weight: .bold))
                                Text(String(format: "%+.0f%% vs yst", percentageChange))
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundColor(percentageChange > 0 ? .green : .red)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                (percentageChange > 0 ? Color.green : Color.red)
                                    .opacity(0.15)
                            )
                            .cornerRadius(16)
                        }
                    }
                    
                    // Speedometer
                    ZStack {
                        // Speedometer Arc Background
                        SpeedometerArc()
                            .stroke(Color(.systemGray5), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                            .frame(width: 220, height: 220)
                        
                        // Speedometer Arc Progress
                        SpeedometerArc()
                            .trim(from: 0, to: progress)
                            .stroke(
                                LinearGradient(
                                    colors: [primaryYellow, primaryYellow.opacity(0.6)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                style: StrokeStyle(lineWidth: 12, lineCap: .round)
                            )
                            .frame(width: 220, height: 220)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
                        
                        // Tick Marks
                        ForEach(0..<11, id: \.self) { index in
                            TickMark(index: index, totalTicks: 11, goal: dailyGoal)
                        }
                        
                        // Center Steps Display
                        VStack(spacing: 4) {
                            Text(formatNumber(currentSteps))
                                .font(.system(size: 48, weight: .black))
                                .foregroundColor(.primary)
                            
                            Text("steps today")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .offset(y: 20)
                        
                        // Needle (Red Gauge Hand)
                        Needle(angle: needleAngle)
                            .animation(.spring(response: 0.6, dampingFraction: 0.7), value: needleAngle)
                    }
                    .frame(height: 180)
                    
                    // Bottom Stats
                    HStack(spacing: 0) {
                        // Daily Goal
                        VStack(alignment: .leading, spacing: 4) {
                            Text("DAILY GOAL")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.secondary)
                                .tracking(1)
                            
                            Text(formatNumber(dailyGoal))
                                .font(.system(size: 22, weight: .black))
                                .foregroundColor(.primary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Vertical Divider
                        Rectangle()
                            .fill(Color(.systemGray5))
                            .frame(width: 1, height: 40)
                        
                        // Remaining
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("REMAINING")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.secondary)
                                .tracking(1)
                            
                            Text(formatNumber(remaining))
                                .font(.system(size: 22, weight: .black))
                                .foregroundColor(remaining == 0 ? .green : Color(red: 1.0, green: 0.23, blue: 0.19))
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .padding(.horizontal, 8)
                }
                .padding(24)
            }
            
            // Motivational Message
            if progress >= 1.0 {
                HStack(spacing: 8) {
                    Image(systemName: "bolt.fill")
                        .foregroundColor(primaryYellow)
                    Text("Goal reached! Keep going!")
                        .font(.system(size: 14, weight: .semibold))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                .padding(.top, 12)
            } else if progress >= 0.75 {
                HStack(spacing: 8) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text("You're on fire! Keep going.")
                        .font(.system(size: 14, weight: .semibold))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                .padding(.top, 12)
            }
        }
        .padding(.horizontal)
    }
    
    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}

// MARK: - Speedometer Arc Shape

struct SpeedometerArc: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY + 20)
        let radius = min(rect.width, rect.height) / 2
        
        // Arc from -135° to +135° (270° total sweep)
        path.addArc(
            center: center,
            radius: radius,
            startAngle: .degrees(-135),
            endAngle: .degrees(135),
            clockwise: false
        )
        
        return path
    }
}

// MARK: - Tick Mark

struct TickMark: View {
    let index: Int
    let totalTicks: Int
    let goal: Int
    
    private var angle: Double {
        let startAngle = -135.0
        let endAngle = 135.0
        let totalSweep = endAngle - startAngle
        let angleStep = totalSweep / Double(totalTicks - 1)
        return startAngle + (Double(index) * angleStep)
    }
    
    private var stepValue: Int {
        let increment = goal / (totalTicks - 1)
        return increment * index
    }
    
    private var showLabel: Bool {
        // Show labels every other tick (0, 2, 4, 6, 8, 10)
        return index % 2 == 0
    }
    
    var body: some View {
        ZStack {
            // Tick mark line
            Rectangle()
                .fill(Color(.systemGray4))
                .frame(width: 2, height: showLabel ? 12 : 8)
                .offset(y: -110)
                .rotationEffect(.degrees(angle))
            
            // Label
            if showLabel {
                Text(formatShortNumber(stepValue))
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)
                    .offset(y: -130)
                    .rotationEffect(.degrees(angle))
                    .rotationEffect(.degrees(-angle)) // Counter-rotate text to keep it upright
            }
        }
    }
    
    private func formatShortNumber(_ number: Int) -> String {
        if number >= 1000 {
            let thousands = Double(number) / 1000.0
            return String(format: "%.0fk", thousands)
        }
        return "\(number)"
    }
}

// MARK: - Needle (Red Gauge Hand)

struct Needle: View {
    let angle: Double
    
    var body: some View {
        ZStack {
            // Needle shadow
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.black.opacity(0.2))
                .frame(width: 4, height: 90)
                .offset(y: -45)
                .blur(radius: 2)
                .rotationEffect(.degrees(angle))
            
            // Needle
            RoundedRectangle(cornerRadius: 2)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 1.0, green: 0.23, blue: 0.19), Color(red: 1.0, green: 0.23, blue: 0.19).opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 3, height: 85)
                .offset(y: -42.5)
                .rotationEffect(.degrees(angle))
            
            // Center pin
            Circle()
                .fill(Color(red: 1.0, green: 0.23, blue: 0.19))
                .frame(width: 14, height: 14)
                .overlay(
                    Circle()
                        .fill(Color.white)
                        .frame(width: 6, height: 6)
                )
                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
        }
    }
}

// MARK: - Preview

struct StepSpeedometerView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            StepSpeedometerView(
                currentSteps: 6432,
                dailyGoal: 10000,
                percentageChange: 12
            )
            
            StepSpeedometerView(
                currentSteps: 10500,
                dailyGoal: 10000,
                percentageChange: -5
            )
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}

