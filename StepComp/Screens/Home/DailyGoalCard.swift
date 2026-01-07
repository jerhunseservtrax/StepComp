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
    let weeklyStepData: [Int]  // NEW: Weekly step data for bar chart
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
    
    // NEW: Toggle view mode
    @State private var viewMode: ViewMode = .circular
    @State private var barAnimationProgress: Double = 0
    
    enum ViewMode {
        case circular
        case barChart
    }
    
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
                
                // NEW: View toggle button
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        viewMode = viewMode == .circular ? .barChart : .circular
                        if viewMode == .barChart {
                            // Trigger bar animation
                            barAnimationProgress = 0
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                                    barAnimationProgress = 1.0
                                }
                            }
                        }
                    }
                    HapticManager.shared.light()
                }) {
                    Image(systemName: viewMode == .circular ? "chart.bar.fill" : "circle.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(StepCompColors.primary)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(StepCompColors.primary.opacity(0.15))
                        )
                }
                .padding(.trailing, 4)
                
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
            
            // Conditional view based on toggle
            if viewMode == .circular {
                circularProgressView
            } else {
                barChartView
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
    
    
    // MARK: - Circular Progress View
    
    private var circularProgressView: some View {
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
    }
    
    // MARK: - Bar Chart View
    
    private var barChartView: some View {
        VStack(spacing: 12) {
            // Today's stats header
            VStack(spacing: 4) {
                Text(formatNumber(currentSteps))
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(StepCompColors.textPrimary)
                
                HStack(spacing: 4) {
                    Text(distanceText)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(StepCompColors.textSecondary)
                    
                    if currentStreak > 0 {
                        Image(systemName: "arrow.up.forward")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(colorScheme == .dark ? StepCompColors.green : Color.green.opacity(0.8))
                        
                        Text("\(currentStreak)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(colorScheme == .dark ? StepCompColors.green : Color.green.opacity(0.8))
                    }
                }
            }
            .padding(.top, 8)
            
            // Week label
            HStack {
                Text("Last 7 days")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(StepCompColors.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 20)
            
            // Bar chart
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(Array(weeklyStepData.enumerated()), id: \.offset) { index, steps in
                    VStack(spacing: 4) {
                        // Bar
                        ZStack(alignment: .bottom) {
                            // Background (goal line)
                            RoundedRectangle(cornerRadius: 8)
                                .fill(colorScheme == .dark 
                                    ? Color.white.opacity(0.05) 
                                    : Color.black.opacity(0.05))
                                .frame(height: 140)
                            
                            // Animated bar
                            RoundedRectangle(cornerRadius: 8)
                                .fill(barColor(for: steps, goal: dailyGoal))
                                .frame(height: barHeight(for: steps, maxSteps: weeklyStepData.max() ?? 1) * barAnimationProgress)
                            
                            // Value label
                            if steps > 0 {
                                Text(formatNumberShort(steps))
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(steps >= dailyGoal ? .white : StepCompColors.textSecondary)
                                    .padding(.bottom, 4)
                            }
                        }
                        
                        // Day label
                        Text(dayLabel(for: index))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(isToday(index) ? StepCompColors.textPrimary : StepCompColors.textSecondary)
                        
                        // Distance label
                        Text(distanceLabel(for: steps))
                            .font(.system(size: 10))
                            .foregroundColor(StepCompColors.textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 180)
            .padding(.horizontal, 16)
            
            // Weekly summary
            HStack {
                Spacer()
                Text("\(formatNumber(weeklyStepData.reduce(0, +))) · \(weeklyDistance) · \(goalPercentage)% of Goal")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(StepCompColors.textSecondary)
                Spacer()
            }
            .padding(.bottom, 8)
        }
        .frame(height: 280)
    }
    
    // MARK: - Bar Chart Helper Functions
    
    private var distanceText: String {
        let distance = unitPreference.formatDistance(distanceKm)
        return "\(distance) \(unitPreference.distanceUnit)"
    }
    
    private var currentStreak: Int {
        var streak = 0
        for steps in weeklyStepData.reversed() {
            if steps >= dailyGoal {
                streak += 1
            } else {
                break
            }
        }
        return streak
    }
    
    private var weeklyDistance: String {
        let totalKm = weeklyStepData.reduce(0) { $0 + (Double($1) * 0.0008) }
        return "\(unitPreference.formatDistance(totalKm)) \(unitPreference.distanceUnit)"
    }
    
    private var goalPercentage: Int {
        let totalSteps = weeklyStepData.reduce(0, +)
        let totalGoal = dailyGoal * weeklyStepData.count
        guard totalGoal > 0 else { return 0 }
        return Int((Double(totalSteps) / Double(totalGoal)) * 100)
    }
    
    private func barHeight(for steps: Int, maxSteps: Int) -> CGFloat {
        guard maxSteps > 0 else { return 0 }
        let ratio = CGFloat(steps) / CGFloat(max(maxSteps, dailyGoal))
        return 140 * max(ratio, 0.05) // Minimum 5% height for visibility
    }
    
    private func barColor(for steps: Int, goal: Int) -> LinearGradient {
        if steps >= goal {
            // Goal met - green gradient (adaptive)
            return LinearGradient(
                colors: colorScheme == .dark 
                    ? [Color.green.opacity(0.7), Color.green]
                    : [Color.green.opacity(0.6), Color.green.opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
        } else if steps >= Int(Double(goal) * 0.5) {
            // 50%+ - primary color gradient (adaptive yellow/coral)
            return LinearGradient(
                colors: [
                    StepCompColors.primary.opacity(0.6),
                    StepCompColors.primary
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        } else {
            // < 50% - orange/red gradient (adaptive)
            return LinearGradient(
                colors: colorScheme == .dark
                    ? [Color.orange.opacity(0.6), Color.red.opacity(0.6)]
                    : [Color.orange.opacity(0.7), Color.red.opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
    
    private func dayLabel(for index: Int) -> String {
        let calendar = Calendar.current
        let today = Date()
        
        // Calculate the date for this index (0 = 7 days ago, 6 = today)
        guard let date = calendar.date(byAdding: .day, value: index - 6, to: today) else {
            return ""
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
    
    private func isToday(_ index: Int) -> Bool {
        // Index 6 represents today in a 7-day array
        return index == 6
    }
    
    private func distanceLabel(for steps: Int) -> String {
        let km = Double(steps) * 0.0008
        let distance = unitPreference.formatDistance(km)
        return distance + unitPreference.distanceUnit.lowercased()
    }
    
    private func formatNumberShort(_ number: Int) -> String {
        if number >= 10000 {
            return String(format: "%.0fk", Double(number) / 1000)
        } else if number >= 1000 {
            return String(format: "%.1fk", Double(number) / 1000)
        }
        return "\(number)"
    }
    
    // MARK: - Animation Functions
    
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
        currentSteps: 7715,
        dailyGoal: 10000,
        calories: 340,
        distanceKm: 5.8,
        activeHours: 1.5,
        weeklyStepData: [3245, 8972, 12450, 7715, 9234, 10890, 11203]
    )
    .background(Color(.systemGray6))
}


