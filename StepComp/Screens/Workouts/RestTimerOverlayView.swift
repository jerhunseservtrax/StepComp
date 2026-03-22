//
//  RestTimerOverlayView.swift
//  FitComp
//
//  Bottom sheet overlay with circular countdown timer between sets
//

import SwiftUI

struct RestTimerOverlayView: View {
    @ObservedObject var timerManager: RestTimerManager
    @State private var dragOffset: CGFloat = 0
    
    private let dismissThreshold: CGFloat = 120
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    if timerManager.isRunning {
                        timerManager.dismissOverlay()
                    } else {
                        timerManager.dismissFinishedAlert()
                    }
                }
            
            sheetContent
                .offset(y: max(0, dragOffset))
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            dragOffset = value.translation.height
                        }
                        .onEnded { value in
                            if value.translation.height > dismissThreshold {
                                if timerManager.isRunning {
                                    timerManager.dismissOverlay()
                                } else {
                                    timerManager.dismissFinishedAlert()
                                }
                            }
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                dragOffset = 0
                            }
                        }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: timerManager.showOverlay)
    }
    
    private var sheetContent: some View {
        VStack(spacing: 0) {
            dragIndicator
            
            if timerManager.isFinished {
                finishedContent
            } else {
                timerContent
            }
        }
        .background(FitCompColors.surface)
        .cornerRadius(28, corners: [.topLeft, .topRight])
        .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: -5)
    }
    
    private var dragIndicator: some View {
        Capsule()
            .fill(FitCompColors.textSecondary.opacity(0.3))
            .frame(width: 36, height: 5)
            .padding(.top, 10)
            .padding(.bottom, 4)
    }
    
    // MARK: - Timer Running Content
    
    private var timerContent: some View {
        VStack(spacing: 24) {
            Text("REST TIMER")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(FitCompColors.textSecondary)
                .tracking(2)

            if let reasoning = timerManager.restReasoning {
                Text(reasoning)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(FitCompColors.primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(FitCompColors.primary.opacity(0.1))
                    .cornerRadius(12)
            }

            circularTimer
            
            presetButtons
            
            HStack(spacing: 16) {
                Button(action: {
                    timerManager.addTime(15)
                }) {
                    Label("+15s", systemImage: "plus")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(FitCompColors.textPrimary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(FitCompColors.textSecondary.opacity(0.12))
                        .cornerRadius(20)
                }
                
                Button(action: {
                    timerManager.skipTimer()
                }) {
                    Text("Skip")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(FitCompColors.buttonTextOnPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(FitCompColors.primary)
                        .cornerRadius(24)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 36)
        }
    }
    
    private var circularTimer: some View {
        ZStack {
            Circle()
                .stroke(FitCompColors.textSecondary.opacity(0.15), lineWidth: 10)
                .frame(width: 180, height: 180)
            
            Circle()
                .trim(from: 0, to: 1.0 - timerManager.progress)
                .stroke(
                    FitCompColors.primary,
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .frame(width: 180, height: 180)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.1), value: timerManager.progress)
            
            VStack(spacing: 4) {
                Text(timerManager.formattedTimeRemaining)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(FitCompColors.textPrimary)
                
                Text("remaining")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(FitCompColors.textSecondary)
            }
        }
        .padding(.vertical, 8)
    }
    
    private var presetButtons: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(RestTimerPreset.allCases) { preset in
                    let isActive = Int(timerManager.totalDuration) == preset.rawValue
                    
                    Button(action: {
                        HapticManager.shared.light()
                        timerManager.selectPreset(preset)
                    }) {
                        Text(preset.label)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(isActive ? FitCompColors.buttonTextOnPrimary : FitCompColors.textPrimary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(isActive ? FitCompColors.primary : FitCompColors.textSecondary.opacity(0.12))
                            .cornerRadius(16)
                    }
                }
            }
            .padding(.horizontal, 24)
        }
    }
    
    // MARK: - Finished Content
    
    private var finishedContent: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(FitCompColors.primary.opacity(0.15))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 56))
                    .foregroundColor(FitCompColors.primary)
            }
            .padding(.top, 16)
            
            VStack(spacing: 6) {
                Text("Time's Up!")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(FitCompColors.textPrimary)
                
                Text("Ready for your next set")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(FitCompColors.textSecondary)
            }
            
            Button(action: {
                HapticManager.shared.medium()
                timerManager.dismissFinishedAlert()
            }) {
                Text("Start Next Set")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(FitCompColors.buttonTextOnPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(FitCompColors.primary)
                    .cornerRadius(26)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 36)
        }
    }
}

// MARK: - Compact Rest Timer Bar

struct RestTimerCompactBar: View {
    @ObservedObject var timerManager: RestTimerManager
    
    var body: some View {
        Button(action: {
            HapticManager.shared.light()
            timerManager.showOverlay = true
        }) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .stroke(FitCompColors.textSecondary.opacity(0.2), lineWidth: 3)
                        .frame(width: 28, height: 28)
                    
                    Circle()
                        .trim(from: 0, to: 1.0 - timerManager.progress)
                        .stroke(FitCompColors.primary, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 28, height: 28)
                        .rotationEffect(.degrees(-90))
                }
                
                Text(timerManager.formattedTimeRemaining)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(FitCompColors.textPrimary)
                
                Text("Rest")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(FitCompColors.textSecondary)
                
                Spacer()
                
                Button(action: {
                    HapticManager.shared.light()
                    timerManager.skipTimer()
                }) {
                    Text("Skip")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(FitCompColors.primary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(FitCompColors.surface)
            .cornerRadius(16)
            .shadow(color: FitCompColors.shadowSecondary, radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
    }
}

