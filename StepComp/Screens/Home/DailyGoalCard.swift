//
//  DailyGoalCard.swift
//  FitComp
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
    let weeklyStepData: [Int]  // Weekly step data for bar chart (last 7 days)
    var selectedDate: Date = Date()  // NEW: Date selected in calendar
    var onRefresh: (() async -> Void)? = nil
    var celebrationManager: GoalCelebrationManager? = nil
    
    @ObservedObject private var unitPreference = UnitPreferenceManager.shared
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var animatedProgress: Double = 0
    @State private var rotation3D: Double = 0
    @State private var scale: CGFloat = 1.0
    @State private var showFireworks = false
    @State private var fireworksTimer: Timer?
    @State private var isRefreshing = false
    
    // Toggle view mode
    @State private var viewMode: ViewMode = .circular
    @State private var barAnimationProgress: Double = 0
    
    enum ViewMode {
        case circular
        case barChart
    }
    
    private var rawProgress: Double {
        guard dailyGoal > 0 else { return 0 }
        return Double(currentSteps) / Double(dailyGoal)
    }
    
    private var isGoalExceeded: Bool {
        rawProgress >= 1.0
    }
    
    private var percentage: Int {
        Int(rawProgress * 100)
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
            // Header
            HStack {
                // Percentage badge - MOVED TO LEFT
                Text("\(percentage)%")
                    .font(.stepCaptionBold())
                    .foregroundColor(FitCompColors.accent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(FitCompColors.accent.opacity(0.2))
                    )
                
                Text("Daily Goal")
                    .font(.stepTitleMedium())
                    .foregroundColor(FitCompColors.textPrimary)
                    .padding(.leading, 8)
                
                Spacer()
                
                // Pill toggle - Ring/Chart selector
                HStack(spacing: 0) {
                    // Ring option
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            viewMode = .circular
                        }
                        HapticManager.shared.light()
                    }) {
                        Text("Ring")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(viewMode == .circular ? FitCompColors.buttonTextOnPrimary : FitCompColors.textSecondary)
                            .frame(width: 50, height: 28)
                            .background(
                                Capsule()
                                    .fill(viewMode == .circular ? FitCompColors.primary : Color.clear)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Chart option
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            viewMode = .barChart
                            // Trigger bar animation
                            barAnimationProgress = 0
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                                    barAnimationProgress = 1.0
                                }
                            }
                        }
                        HapticManager.shared.light()
                    }) {
                        Text("Chart")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(viewMode == .barChart ? FitCompColors.buttonTextOnPrimary : FitCompColors.textSecondary)
                            .frame(width: 50, height: 28)
                            .background(
                                Capsule()
                                    .fill(viewMode == .barChart ? FitCompColors.primary : Color.clear)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(2)
                .background(
                    Capsule()
                        .fill(FitCompColors.surfaceElevated)
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
            
            // Stats row - only show for circular view (bar chart has its own)
            if viewMode == .circular {
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
        }
        .background(
            RoundedRectangle(cornerRadius: 32)
                .fill(FitCompColors.surface)
                .shadow(color: FitCompColors.shadowSecondary, radius: 20, x: 0, y: 8)
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
                
                // Note: Goal celebration is now only triggered automatically when goal is first reached,
                // not on manual taps
                
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
    
    private let ringDiameter: CGFloat = 184
    private let ringLineWidth: CGFloat = 14
    private let glowDiameter: CGFloat = 236
    
    private var circularProgressView: some View {
        ZStack {
            // Glow effect - uses current revolution color
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            currentRevColor.primary.opacity(isGoalExceeded ? 0.35 : 0.15),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 68,
                        endRadius: 120
                    )
                )
                .frame(width: glowDiameter, height: glowDiameter)
                .blur(radius: 34)
            
            // Progress ring background (gray track)
            Circle()
                .stroke(FitCompColors.textTertiary.opacity(0.2), lineWidth: ringLineWidth)
                .frame(width: ringDiameter, height: ringDiameter)
            
            // Stacked revolution layers — each layer uses ContinuousRingArc
            // which reads the single animatedProgress and computes its own fill,
            // so the animation is fully continuous across revolution boundaries.
            revolutionLayer(rev: 0)
            revolutionLayer(rev: 1)
            revolutionLayer(rev: 2)
            revolutionLayer(rev: 3)
            revolutionLayer(rev: 4)
            
            // Center content
            VStack(spacing: 4) {
                Image(systemName: "figure.run")
                    .font(.system(size: 28))
                    .symbolRenderingMode(.monochrome)
                    .foregroundColor(FitCompColors.primary)
                
                Text(formatNumber(currentSteps))
                    .font(.stepNumber())
                    .foregroundColor(FitCompColors.textPrimary)
                
                Text("/ \(formatNumber(dailyGoal)) steps")
                    .font(.stepCaption())
                    .foregroundColor(FitCompColors.textSecondary)
            }
        }
        .frame(height: 220)
        .padding(.vertical, 4)
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
            withAnimation(.interpolatingSpring(stiffness: 120, damping: 18)) {
                animatedProgress = rawProgress
            }
        }
        .onChange(of: rawProgress) { _, newValue in
            withAnimation(.interpolatingSpring(stiffness: 130, damping: 20)) {
                animatedProgress = newValue
            }
        }
    }
    
    @ViewBuilder
    private func revolutionLayer(rev: Int) -> some View {
        ContinuousRingArc(totalProgress: animatedProgress, revolution: rev)
            .stroke(
                ringGradient(for: rev),
                style: StrokeStyle(lineWidth: ringLineWidth, lineCap: .round)
            )
            .frame(width: ringDiameter, height: ringDiameter)
            .shadow(
                color: rev > 0 ? Color.black.opacity(0.4) : colorSet(for: 0).primary.opacity(0.3),
                radius: rev > 0 ? 6 : 8,
                x: 0, y: rev > 0 ? 3 : 4
            )
            .shadow(
                color: rev > 0 ? colorSet(for: rev).primary.opacity(0.4) : Color.clear,
                radius: rev > 0 ? 10 : 0
            )
    }
    
    @ViewBuilder
    private var leadingCapView: some View {
        if animatedProgress > 0 {
            Circle()
                .fill(moveRingCapGradient)
                .frame(width: ringLineWidth + 2, height: ringLineWidth + 2)
                .position(ringEndPoint(in: CGSize(width: ringDiameter, height: ringDiameter)))
                .shadow(
                    color: currentRevColor.primary.opacity(isGoalExceeded ? 0.85 : 0.6),
                    radius: isGoalExceeded ? 12 : 8
                )
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(colorScheme == .dark ? 0.25 : 0.45), lineWidth: 1)
                )
        }
    }
    
    // MARK: - Bar Chart View
    
    private var barChartView: some View {
        VStack(spacing: 12) {
            // Today's stats header
            VStack(spacing: 4) {
                Text(formatNumber(currentSteps))
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(FitCompColors.textPrimary)
                
                HStack(spacing: 4) {
                    Text(distanceText)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(FitCompColors.textSecondary)
                    
                    if currentStreak > 0 {
                        Image(systemName: "arrow.up.forward")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(colorScheme == .dark ? FitCompColors.green : Color.green.opacity(0.8))
                        
                        Text("\(currentStreak)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(colorScheme == .dark ? FitCompColors.green : Color.green.opacity(0.8))
                    }
                }
            }
            .padding(.top, 8)
            
            // Week label
            HStack {
                Text("Last 7 days")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(FitCompColors.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 20)
            
            // Scrollable bar chart with goal line
            ScrollViewReader { scrollProxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    ZStack(alignment: .bottom) {
                        // Goal line indicator - solid blue line
                        GeometryReader { geometry in
                            let maxSteps = max(weeklyStepData.max() ?? 1, dailyGoal)
                            let goalHeight = CGFloat(dailyGoal) / CGFloat(maxSteps) * 140
                            
                            // Solid blue goal line
                            Rectangle()
                                .fill(Color.blue)
                                .frame(height: 2)
                                .position(x: geometry.size.width / 2, y: 140 - goalHeight + 90)
                        }
                        
                        // Bars
                        HStack(alignment: .bottom, spacing: 8) {
                            ForEach(Array(weeklyStepData.enumerated()), id: \.offset) { index, steps in
                                BarView(
                                    steps: steps,
                                    dailyGoal: dailyGoal,
                                    maxSteps: max(weeklyStepData.max() ?? 1, dailyGoal),
                                    animationProgress: barAnimationProgress,
                                    dayLabel: dayLabel(for: index),
                                    distanceLabel: distanceLabel(for: steps),
                                    isToday: isToday(index),
                                    isSelected: isSelectedDate(index),
                                    colorScheme: colorScheme
                                )
                                .frame(width: 44)
                                .id(index)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .frame(height: 230)
                    // Width based on number of bars: 44pt per bar + 8pt spacing + padding
                    .frame(minWidth: CGFloat(weeklyStepData.count) * 52 + 32)
                }
                .onAppear {
                    // Scroll to show the most recent data (rightmost) on appear
                    if !weeklyStepData.isEmpty {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.easeOut(duration: 0.3)) {
                                scrollProxy.scrollTo(weeklyStepData.count - 1, anchor: .trailing)
                            }
                        }
                    }
                }
            }
            
            // Stats row (Cal, Mi, Hrs) - moved inside bar chart view
            HStack(spacing: 12) {
                StatBox(label: "Cal", value: "\(calories)")
                StatBox(
                    label: unitPreference.distanceUnit,
                    value: unitPreference.formatDistance(distanceKm)
                )
                StatBox(label: "Hrs", value: String(format: "%.1f", activeHours))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
        }
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
            // Goal met - vibrant lime/green gradient
            return LinearGradient(
                colors: [
                    Color(red: 0.2, green: 1.0, blue: 0.4),  // Bright lime
                    Color(red: 0.0, green: 0.9, blue: 0.3)   // Vivid green
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        } else if steps >= Int(Double(goal) * 0.5) {
            // 50%+ - vibrant yellow/orange gradient
            return LinearGradient(
                colors: [
                    Color(red: 1.0, green: 0.85, blue: 0.0),  // Bright yellow
                    Color(red: 1.0, green: 0.6, blue: 0.0)    // Vibrant orange
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        } else {
            // < 50% - vibrant orange/red gradient
            return LinearGradient(
                colors: [
                    Color(red: 1.0, green: 0.5, blue: 0.0),   // Bright orange
                    Color(red: 1.0, green: 0.2, blue: 0.2)    // Vivid red
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
    
    private func dayLabel(for index: Int) -> String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let totalDays = weeklyStepData.count
        
        // Calculate the date for this index (last index = today)
        // index 0 = (totalDays - 1) days ago, last index = today
        guard let date = calendar.date(byAdding: .day, value: index - (totalDays - 1), to: today) else {
            return ""
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
    
    private func isToday(_ index: Int) -> Bool {
        // Last index represents today
        return index == weeklyStepData.count - 1
    }
    
    private func isSelectedDate(_ index: Int) -> Bool {
        // Check if this bar's date matches the selected date from the calendar
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let totalDays = weeklyStepData.count
        
        // Calculate date for this index (last index = today)
        guard let barDate = calendar.date(byAdding: .day, value: index - (totalDays - 1), to: today) else {
            return false
        }
        
        let normalizedSelectedDate = calendar.startOfDay(for: selectedDate)
        return calendar.isDate(barDate, inSameDayAs: normalizedSelectedDate)
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
                animatedProgress = rawProgress
            }
        }
    }
    
    // MARK: - Revolution Color Palette
    
    private struct RingColorSet {
        let primary: Color
        let highlight: Color
        let shadow: Color
    }
    
    private let ringColors: [RingColorSet] = [
        RingColorSet(
            primary: Color(red: 1.0, green: 0.16, blue: 0.52),
            highlight: Color(red: 1.0, green: 0.42, blue: 0.66),
            shadow: Color(red: 0.82, green: 0.02, blue: 0.34)
        ),
        RingColorSet(
            primary: Color(red: 0.20, green: 0.90, blue: 0.40),
            highlight: Color(red: 0.45, green: 1.0, blue: 0.55),
            shadow: Color(red: 0.05, green: 0.72, blue: 0.25)
        ),
        RingColorSet(
            primary: Color(red: 0.10, green: 0.78, blue: 1.0),
            highlight: Color(red: 0.40, green: 0.88, blue: 1.0),
            shadow: Color(red: 0.02, green: 0.55, blue: 0.82)
        ),
        RingColorSet(
            primary: Color(red: 1.0, green: 0.78, blue: 0.0),
            highlight: Color(red: 1.0, green: 0.88, blue: 0.35),
            shadow: Color(red: 0.85, green: 0.62, blue: 0.0)
        ),
        RingColorSet(
            primary: Color(red: 0.68, green: 0.32, blue: 1.0),
            highlight: Color(red: 0.80, green: 0.55, blue: 1.0),
            shadow: Color(red: 0.48, green: 0.15, blue: 0.82)
        ),
    ]
    
    private func colorSet(for rev: Int) -> RingColorSet {
        ringColors[rev % ringColors.count]
    }
    
    private var currentRevColor: RingColorSet {
        let topRev = max(0, Int(max(0, animatedProgress)))
        return colorSet(for: topRev)
    }
    
    private func ringGradient(for rev: Int) -> AngularGradient {
        let c = colorSet(for: rev)
        return AngularGradient(
            gradient: Gradient(stops: [
                .init(color: c.primary.opacity(0.98), location: 0.0),
                .init(color: c.highlight, location: 0.2),
                .init(color: c.primary, location: 0.45),
                .init(color: c.shadow, location: 0.78),
                .init(color: c.primary.opacity(0.98), location: 1.0)
            ]),
            center: .center
        )
    }
    
    private var moveRingCapGradient: LinearGradient {
        let c = currentRevColor
        return LinearGradient(
            colors: [c.highlight, c.primary, c.shadow],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var ringEndAngleDegrees: Double {
        let p = max(0, animatedProgress)
        guard p > 0 else { return -90 }
        let fractional = p.truncatingRemainder(dividingBy: 1.0)
        let frac = (p >= 1.0 && fractional < 0.0001) ? 1.0 : fractional
        return -90 + (frac * 360)
    }
    
    private func ringEndPoint(in size: CGSize) -> CGPoint {
        let angleInRadians = ringEndAngleDegrees * .pi / 180
        let radius = min(size.width, size.height) / 2
        return CGPoint(
            x: size.width / 2 + CGFloat(cos(angleInRadians)) * radius,
            y: size.height / 2 + CGFloat(sin(angleInRadians)) * radius
        )
    }
    
    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}

struct ContinuousRingArc: Shape {
    var totalProgress: Double
    let revolution: Int
    
    var animatableData: Double {
        get { totalProgress }
        set { totalProgress = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        let p = max(0, totalProgress)
        let revStart = Double(revolution)
        guard p > revStart else { return Path() }
        
        let revFill = min(p - revStart, 1.0)
        
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let start = Angle.degrees(-90)
        let end = Angle.degrees(-90 + (360 * revFill))
        
        path.addArc(center: center, radius: radius,
                     startAngle: start, endAngle: end, clockwise: false)
        return path
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
                .foregroundColor(FitCompColors.textSecondary)
            
            Text(value)
                .font(.stepBodySmall())
                .fontWeight(.bold)
                .foregroundColor(FitCompColors.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(FitCompColors.surfaceElevated)
        )
    }
}

// MARK: - Individual Bar View with Tap Animation

struct BarView: View {
    let steps: Int
    let dailyGoal: Int
    let maxSteps: Int
    let animationProgress: CGFloat
    let dayLabel: String
    let distanceLabel: String
    let isToday: Bool
    let isSelected: Bool  // NEW: Highlight if selected in calendar
    let colorScheme: ColorScheme
    
    @State private var barScale: CGFloat = 1.0
    @State private var barAnimationProgress: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 4) {
            // Bar
            ZStack(alignment: .bottom) {
                // Background track
                RoundedRectangle(cornerRadius: 8)
                    .fill(colorScheme == .dark 
                        ? Color.white.opacity(0.05) 
                        : Color.black.opacity(0.05))
                    .frame(height: 140)
                
                // Animated bar with color based on progress
                if steps > 0 {
                    let barHeight = CGFloat(steps) / CGFloat(maxSteps) * 140
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(barColor(for: steps))
                        .frame(height: barHeight * barAnimationProgress)
                        .shadow(
                            color: isToday ? glowColor(for: steps) : .clear,
                            radius: isToday ? 12 : 0,
                            x: 0,
                            y: 0
                        )
                        .overlay(
                            // Selected date highlight border
                            isSelected ? RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(FitCompColors.primary, lineWidth: 3)
                                .shadow(color: FitCompColors.primary.opacity(0.5), radius: 8, x: 0, y: 0)
                            : nil
                        )
                }
                
                // Value label
                if steps > 0 {
                    Text(formatNumberShort(steps))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(steps >= dailyGoal ? .white : FitCompColors.textSecondary)
                        .padding(.bottom, 4)
                }
            }
            .scaleEffect(isSelected ? 1.08 : barScale)  // Scale up if selected
            .onTapGesture {
                // Tap animation
                HapticManager.shared.light()
                
                // Scale bounce
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    barScale = 1.1
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        barScale = 1.0
                    }
                }
                
                // Refill animation
                barAnimationProgress = 0
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                        barAnimationProgress = 1.0
                    }
                }
            }
            .onAppear {
                barAnimationProgress = animationProgress
            }
            .onChange(of: animationProgress) { _, newValue in
                withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                    barAnimationProgress = newValue
                }
            }
            
            // Day label
            Text(dayLabel)
                .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                .foregroundColor(isSelected ? FitCompColors.primary : (isToday ? FitCompColors.textPrimary : FitCompColors.textSecondary))
            
            // Distance label
            Text(distanceLabel)
                .font(.system(size: 10))
                .foregroundColor(FitCompColors.textTertiary)
        }
    }
    
    private func barColor(for steps: Int) -> LinearGradient {
        let percentage = Double(steps) / Double(dailyGoal)
        
        if percentage >= 1.0 {
            // 100%+ - Vibrant lime/green (goal met/exceeded)
            return LinearGradient(
                colors: [
                    Color(red: 0.2, green: 1.0, blue: 0.4),  // Bright lime
                    Color(red: 0.0, green: 0.9, blue: 0.3)   // Vivid green
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        } else if percentage >= 0.75 {
            // 75-99% - Vibrant yellow-green - almost there!
            return LinearGradient(
                colors: [
                    Color(red: 0.7, green: 1.0, blue: 0.0),  // Lime yellow
                    Color(red: 0.4, green: 0.9, blue: 0.2)   // Yellow-green
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        } else if percentage >= 0.5 {
            // 50-74% - Vibrant yellow/orange - halfway there
            return LinearGradient(
                colors: [
                    Color(red: 1.0, green: 0.85, blue: 0.0),  // Bright yellow
                    Color(red: 1.0, green: 0.6, blue: 0.0)    // Vibrant orange
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        } else if percentage >= 0.25 {
            // 25-49% - Vibrant orange - need more steps
            return LinearGradient(
                colors: [
                    Color(red: 1.0, green: 0.5, blue: 0.0),   // Bright orange
                    Color(red: 1.0, green: 0.3, blue: 0.1)    // Orange-red
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        } else {
            // 0-24% - Vibrant red - just getting started
            return LinearGradient(
                colors: [
                    Color(red: 1.0, green: 0.3, blue: 0.2),   // Bright red-orange
                    Color(red: 1.0, green: 0.15, blue: 0.15)  // Vivid red
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
    
    private func glowColor(for steps: Int) -> Color {
        let percentage = Double(steps) / Double(dailyGoal)
        
        if percentage >= 1.0 {
            return Color(red: 0.0, green: 1.0, blue: 0.4).opacity(0.8)  // Bright lime glow
        } else if percentage >= 0.75 {
            return Color(red: 0.5, green: 1.0, blue: 0.2).opacity(0.7)  // Yellow-green glow
        } else if percentage >= 0.5 {
            return Color(red: 1.0, green: 0.7, blue: 0.0).opacity(0.7)  // Yellow glow
        } else if percentage >= 0.25 {
            return Color(red: 1.0, green: 0.4, blue: 0.0).opacity(0.6)  // Orange glow
        } else {
            return Color(red: 1.0, green: 0.2, blue: 0.2).opacity(0.5)  // Red glow
        }
    }
    
    private func formatNumberShort(_ number: Int) -> String {
        if number >= 10000 {
            return String(format: "%.0fk", Double(number) / 1000)
        } else if number >= 1000 {
            return String(format: "%.1fk", Double(number) / 1000)
        }
        return "\(number)"
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


