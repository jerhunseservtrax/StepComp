//
//  StepCompProgressStyles.swift
//  StepComp
//
//  Gradient progress indicators and charts
//

import SwiftUI

// MARK: - Circular Progress Ring (with gradient)

struct CircularProgressRing: View {
    let progress: Double // 0.0 to 1.0
    var lineWidth: CGFloat = 12
    var size: CGFloat = 120
    var gradient: LinearGradient = StepCompColors.coralGradient
    var showPercentage: Bool = true
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(
                    StepCompColors.surface,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
            
            // Progress ring (gradient)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    gradient,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
            
            // Percentage text
            if showPercentage {
                VStack(spacing: 4) {
                    Text("\(Int(progress * 100))")
                        .font(.stepNumber())
                        .stepTextPrimary()
                    
                    Text("%")
                        .font(.stepCaption())
                        .stepTextSecondary()
                }
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Linear Progress Bar (with gradient)

struct GradientProgressBar: View {
    let progress: Double // 0.0 to 1.0
    var height: CGFloat = 8
    var cornerRadius: CGFloat = 4
    var gradient: LinearGradient = StepCompColors.coralGradient
    var showGlow: Bool = true
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(StepCompColors.surface)
                    .frame(height: height)
                
                // Progress fill
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(gradient)
                    .frame(width: geometry.size.width * progress, height: height)
                    .shadow(
                        color: showGlow ? StepCompColors.primary.opacity(0.5) : .clear,
                        radius: 8,
                        y: 0
                    )
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
            }
        }
        .frame(height: height)
    }
}

// MARK: - Segmented Progress Bar (for multi-step flows)

struct SegmentedProgressBar: View {
    let currentStep: Int
    let totalSteps: Int
    var height: CGFloat = 6
    var spacing: CGFloat = 4
    var gradient: LinearGradient = StepCompColors.coralGradient
    
    var body: some View {
        HStack(spacing: spacing) {
            ForEach(0..<totalSteps, id: \.self) { index in
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(
                        index < currentStep
                            ? AnyShapeStyle(gradient)
                            : AnyShapeStyle(StepCompColors.surface)
                    )
                    .frame(height: height)
            }
        }
    }
}

// MARK: - Stat Card with Progress Ring

struct StatProgressCard: View {
    let title: String
    let value: String
    let subtitle: String
    let progress: Double
    var gradient: LinearGradient = StepCompColors.coralGradient
    var icon: String = "figure.walk"
    
    var body: some View {
        DarkCard {
            HStack(spacing: 20) {
                // Progress ring
                CircularProgressRing(
                    progress: progress,
                    lineWidth: 8,
                    size: 80,
                    gradient: gradient,
                    showPercentage: false
                )
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 28))
                        .foregroundStyle(gradient)
                )
                
                // Stats
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.stepCaption())
                        .stepTextSecondary()
                    
                    Text(value)
                        .font(.stepNumberMedium())
                        .stepTextPrimary()
                    
                    Text(subtitle)
                        .font(.stepLabel())
                        .stepTextTertiary()
                }
                
                Spacer()
            }
        }
    }
}

// MARK: - Mini Progress Indicator (for lists)

struct MiniProgressIndicator: View {
    let progress: Double
    var gradient: LinearGradient = StepCompColors.coralGradient
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(StepCompColors.surface)
                
                RoundedRectangle(cornerRadius: 2)
                    .fill(gradient)
                    .frame(width: geometry.size.width * progress)
            }
        }
        .frame(height: 4)
    }
}

// MARK: - Example Usage in Preview

#Preview("Progress Components") {
    ZStack {
        StepCompColors.background
            .ignoresSafeArea()
        
        ScrollView {
            VStack(spacing: 24) {
                // Circular progress
                CircularProgressRing(progress: 0.65)
                
                // Linear progress
                GradientProgressBar(progress: 0.75)
                    .padding(.horizontal)
                
                // Segmented progress
                SegmentedProgressBar(currentStep: 2, totalSteps: 4)
                    .padding(.horizontal)
                
                // Stat card with progress
                StatProgressCard(
                    title: "Daily Goal",
                    value: "7,243",
                    subtitle: "of 10,000 steps",
                    progress: 0.72
                )
                .padding(.horizontal)
            }
            .padding(.vertical, 40)
        }
    }
}

