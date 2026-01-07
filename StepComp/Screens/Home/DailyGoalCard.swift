//
//  DailyGoalCard.swift
//  StepComp
//
//  Main daily goal card with circular progress ring
//

import SwiftUI

struct DailyGoalCard: View {
    let currentSteps: Int
    let dailyGoal: Int
    let calories: Int
    let distanceKm: Double
    let activeHours: Double
    var onRefresh: (() async -> Void)? = nil
    var celebrationManager: GoalCelebrationManager? = nil
    
    @ObservedObject private var unitPreference = UnitPreferenceManager.shared
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var animatedProgress: Double = 0
    @State private var rotation3D: Double = 0
    @State private var scale: CGFloat = 1.0
    @State private var rainbowPhase: Double = 0
    @State private var showFireworks = false
    @State private var fireworksTimer: Timer?
    @State private var isRefreshing = false
    
    private var progress: Double {
        guard dailyGoal > 0 else { return 0 }
        return min(Double(currentSteps) / Double(dailyGoal), 1.0)
    }
    
    private var isGoalExceeded: Bool {
        currentSteps >= dailyGoal
    }
    
    private var percentage: Int {
        Int(progress * 100)
    }
    
    // Rainbow gradient colors
    private var rainbowGradient: LinearGradient {
        let hue1 = (rainbowPhase).truncatingRemainder(dividingBy: 1.0)
        let hue2 = (rainbowPhase + 0.3).truncatingRemainder(dividingBy: 1.0)
        let hue3 = (rainbowPhase + 0.6).truncatingRemainder(dividingBy: 1.0)
        
        return LinearGradient(
            colors: [
                Color(hue: hue1, saturation: 0.8, brightness: 0.9),
                Color(hue: hue2, saturation: 0.8, brightness: 0.9),
                Color(hue: hue3, saturation: 0.8, brightness: 0.9)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
            // Header
            HStack {
                Text("Daily Goal")
                    .font(.stepTitleMedium())
                    .foregroundColor(StepCompColors.textPrimary)
                
                Spacer()
                
                // Percentage badge
                Text("\(percentage)%")
                    .font(.stepCaptionBold())
                    .foregroundColor(StepCompColors.accent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(StepCompColors.accent.opacity(0.2))
                    )
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            
            // Circular Progress Ring
            ZStack {
                // Glow effect - rainbow when goal exceeded
                if isGoalExceeded {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(hue: rainbowPhase, saturation: 0.8, brightness: 0.9).opacity(0.3),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 80,
                                endRadius: 140
                            )
                        )
                        .frame(width: 260, height: 260)
                        .blur(radius: 40)
                } else {
                    Circle()
                        .fill(StepCompColors.primary.opacity(0.15))
                        .frame(width: 260, height: 260)
                        .blur(radius: 40)
                }
                
                // Progress ring background (gray track)
                Circle()
                    .stroke(StepCompColors.textTertiary.opacity(0.2), lineWidth: 16)
                    .frame(width: 200, height: 200)
                
                // Progress ring (adaptive gradient - yellow in light, coral in dark, rainbow when goal exceeded)
                Circle()
                    .trim(from: 0, to: animatedProgress)
                    .stroke(
                        isGoalExceeded ? rainbowGradient : StepCompColors.progressGradient(for: colorScheme),
                        style: StrokeStyle(lineWidth: 16, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .shadow(
                        color: isGoalExceeded ? Color.white.opacity(0.5) : StepCompColors.primary.opacity(0.4),
                        radius: isGoalExceeded ? 12 : 8,
                        x: 0,
                        y: 4
                    )
                
                // Center content
                VStack(spacing: 4) {
                    Image(systemName: "figure.run")
                        .font(.system(size: 28))
                        .foregroundColor(StepCompColors.primary)
                    
                    Text(formatNumber(currentSteps))
                        .font(.stepNumber())
                        .foregroundColor(StepCompColors.textPrimary)
                    
                    Text("/ \(formatNumber(dailyGoal)) steps")
                        .font(.stepCaption())
                        .foregroundColor(StepCompColors.textSecondary)
                }
            }
            .frame(height: 240)
            .padding(.vertical, 8)
            .scaleEffect(scale)
            .rotation3DEffect(
                .degrees(rotation3D),
                axis: (x: 0, y: 1, z: 0),
                anchor: .center,
                perspective: 0.5
            )
            .onTapGesture {
                triggerRefillAnimation()
            }
            .onAppear {
                // Initial fill animation
                withAnimation(.easeInOut(duration: 1.2)) {
                    animatedProgress = progress
                }
                
                // Start rainbow animation if goal exceeded
                if isGoalExceeded {
                    startRainbowAnimation()
                }
            }
            .onChange(of: progress) { _, newValue in
                // Update when progress changes
                withAnimation(.easeInOut(duration: 0.8)) {
                    animatedProgress = newValue
                }
            }
            .onChange(of: isGoalExceeded) { _, exceeded in
                // Start/stop rainbow animation based on goal status
                if exceeded {
                    startRainbowAnimation()
                }
            }
            
            // Stats row
            HStack(spacing: 12) {
                StatBox(label: "Cal", value: "\(calories)")
                StatBox(
                    label: unitPreference.distanceUnit,
                    value: unitPreference.formatDistance(distanceKm)
                )
                StatBox(label: "Hrs", value: String(format: "%.1f", activeHours))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(
            RoundedRectangle(cornerRadius: 32)
                .fill(StepCompColors.surface)
                .shadow(color: StepCompColors.shadowSecondary, radius: 20, x: 0, y: 8)
        )
        .scaleEffect(isRefreshing ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isRefreshing)
        .padding(.horizontal, 20)
        .onTapGesture {
            // Trigger manual refresh when card is tapped
            guard let onRefresh = onRefresh else { return }
            Task {
                isRefreshing = true
                HapticManager.shared.medium()
                
                // Always trigger spin animation
                triggerRefillAnimation()
                
                // Refresh steps
                await onRefresh()
                
                // If goal is met, trigger celebration
                if isGoalExceeded, let celebrationManager = celebrationManager {
                    // Small delay to ensure steps are updated
                    try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s
                    await MainActor.run {
                        celebrationManager.forceTriggerCelebration(
                            steps: currentSteps,
                            goal: dailyGoal
                        )
                    }
                }
                
                isRefreshing = false
            }
        }
            
            // Fireworks overlay in top-right corner when goal is met
            if showFireworks && isGoalExceeded {
                FireworksView()
                    .frame(width: 80, height: 80)
                    .offset(x: -10, y: 10)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .onAppear {
            if isGoalExceeded {
                startFireworksTimer()
            }
        }
        .onChange(of: isGoalExceeded) { _, exceeded in
            if exceeded {
                startFireworksTimer()
                // Trigger immediate fireworks
                triggerFireworks()
            } else {
                stopFireworksTimer()
            }
        }
        .onDisappear {
            stopFireworksTimer()
        }
    }
    
    private func startFireworksTimer() {
        // Clear any existing timer
        fireworksTimer?.invalidate()
        
        // Create a timer that fires every 30 seconds
        fireworksTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            triggerFireworks()
        }
    }
    
    private func stopFireworksTimer() {
        fireworksTimer?.invalidate()
        fireworksTimer = nil
        showFireworks = false
    }
    
    private func triggerFireworks() {
        guard isGoalExceeded else { return }
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            showFireworks = true
        }
        
        // Hide fireworks after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeOut(duration: 0.3)) {
                showFireworks = false
            }
        }
    }
    
    private func startRainbowAnimation() {
        withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
            rainbowPhase = 1.0
        }
    }
    
    private func triggerRefillAnimation() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // 3D flip animation
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            rotation3D += 360
        }
        
        // Scale bounce
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            scale = 1.05
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                scale = 1.0
            }
        }
        
        // Reset and refill progress
        animatedProgress = 0
        
        // Delay for the flip, then refill
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut(duration: 1.2).delay(0.1)) {
                animatedProgress = progress
            }
        }
    }
    
    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}

// MARK: - Fireworks View

struct FireworksView: View {
    @State private var particles: [FireworkParticle] = []
    
    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .offset(x: particle.offsetX, y: particle.offsetY)
                    .opacity(particle.opacity)
            }
        }
        .onAppear {
            generateFireworks()
        }
    }
    
    private func generateFireworks() {
        let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]
        
        // Create 20 particles exploding outward
        for i in 0..<20 {
            let angle = Double(i) * (2 * .pi / 20) // Evenly distribute around circle
            let distance: CGFloat = CGFloat.random(in: 20...40)
            
            let particle = FireworkParticle(
                id: UUID(),
                color: colors.randomElement() ?? .yellow,
                size: CGFloat.random(in: 4...8),
                offsetX: 0,
                offsetY: 0,
                finalOffsetX: cos(angle) * distance,
                finalOffsetY: sin(angle) * distance,
                opacity: 1.0
            )
            
            particles.append(particle)
            
            // Animate particle
            withAnimation(.easeOut(duration: 0.8).delay(Double(i) * 0.02)) {
                if let index = particles.firstIndex(where: { $0.id == particle.id }) {
                    particles[index].offsetX = particle.finalOffsetX
                    particles[index].offsetY = particle.finalOffsetY
                }
            }
            
            // Fade out
            withAnimation(.easeOut(duration: 0.5).delay(0.5 + Double(i) * 0.02)) {
                if let index = particles.firstIndex(where: { $0.id == particle.id }) {
                    particles[index].opacity = 0
                }
            }
        }
    }
}

struct FireworkParticle: Identifiable {
    let id: UUID
    let color: Color
    let size: CGFloat
    var offsetX: CGFloat
    var offsetY: CGFloat
    let finalOffsetX: CGFloat
    let finalOffsetY: CGFloat
    var opacity: Double
}

struct StatBox: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.stepLabelSmall())
                .foregroundColor(StepCompColors.textSecondary)
            
            Text(value)
                .font(.stepBodySmall())
                .fontWeight(.bold)
                .foregroundColor(StepCompColors.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(StepCompColors.surfaceElevated)
        )
    }
}

#Preview {
    DailyGoalCard(
        currentSteps: 5499,
        dailyGoal: 6500,
        calories: 340,
        distanceKm: 4.2,
        activeHours: 1.5
    )
    .background(Color(.systemGray6))
}

