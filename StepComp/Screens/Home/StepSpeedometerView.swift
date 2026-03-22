//
//  StepSpeedometerView.swift
//  FitComp
//
//  Horizontal line step progress indicator
//

import SwiftUI

struct StepSpeedometerView: View {
    let currentSteps: Int
    let dailyGoal: Int
    
    
    // Calculate progress
    private var progress: Double {
        guard dailyGoal > 0 else { return 0 }
        return min(Double(currentSteps) / Double(dailyGoal), 1.0)
    }
    
    private var remaining: Int {
        max(0, dailyGoal - currentSteps)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                // Background Card
                RoundedRectangle(cornerRadius: 32)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.05), radius: 20, x: 0, y: 4)
                
                VStack(spacing: 16) {
                    // Header
                    HStack {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(FitCompColors.primary)
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
                    }
                    
                    // Large Step Count
                    Text(formatNumber(currentSteps))
                        .font(.system(size: 68, weight: .black))
                        .foregroundColor(.primary)
                    
                    // Progress Bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background track
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemGray5))
                                .frame(height: 16)
                            
                            // Yellow progress
                            RoundedRectangle(cornerRadius: 8)
                                .fill(FitCompColors.primary)
                                .frame(width: geometry.size.width * progress, height: 16)
                                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
                            
                            // Red position indicator
                            Circle()
                                .fill(Color(red: 1.0, green: 0.23, blue: 0.19))
                                .frame(width: 20, height: 20)
                                .offset(x: (geometry.size.width * progress) - 10)
                                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
                        }
                    }
                    .frame(height: 20)
                    
                    // Bottom Stats
                    HStack(spacing: 0) {
                        // Daily Goal
                        VStack(alignment: .leading, spacing: 4) {
                            Text("DAILY GOAL")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.secondary)
                                .tracking(1)
                            
                            Text(formatNumber(dailyGoal))
                                .font(.system(size: 20, weight: .black))
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
                                .font(.system(size: 20, weight: .black))
                                .foregroundColor(remaining == 0 ? Color(red: 0.4, green: 0.84, blue: 0.65) : Color(red: 1.0, green: 0.23, blue: 0.19))
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .padding(.horizontal, 8)
                }
                .padding(24)
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
