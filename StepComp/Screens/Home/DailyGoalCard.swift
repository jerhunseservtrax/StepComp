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
    
    @ObservedObject private var unitPreference = UnitPreferenceManager.shared
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var animatedProgress: Double = 0
    @State private var rotation3D: Double = 0
    @State private var scale: CGFloat = 1.0
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
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("This Week")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(FitCompColors.textPrimary)
                Spacer()
                Text("\(formatNumber(currentSteps)) steps")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(FitCompColors.textSecondary)
            }
            .padding(.horizontal, 20)

            ScrollViewReader { scrollProxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    let chartMaxSteps = max(displayedBars.map { $0.steps }.max() ?? 1, dailyGoal)
                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 22)
                            .fill(FitCompColors.surfaceElevated)

                        GeometryReader { geometry in
                            let goalY = goalLineOffsetY(maxSteps: chartMaxSteps)

                            Rectangle()
                                .fill(FitCompColors.primary.opacity(0.85))
                                .frame(height: 2)
                                .padding(.horizontal, 12)
                                .offset(y: goalY)
                                .shadow(color: FitCompColors.primary.opacity(0.35), radius: 4, x: 0, y: 0)

                            Text("Goal \(formatNumberShort(dailyGoal))")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(FitCompColors.buttonTextOnPrimary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(FitCompColors.primary)
                                )
                                .offset(
                                    x: max(16, min(geometry.size.width - 110, geometry.size.width * 0.60)),
                                    y: goalY - 12
                                )
                        }

                        HStack(alignment: .bottom, spacing: 9) {
                            ForEach(displayedBars, id: \.index) { entry in
                                BarView(
                                    steps: entry.steps,
                                    dailyGoal: dailyGoal,
                                    maxSteps: chartMaxSteps,
                                    animationProgress: barAnimationProgress,
                                    dayLabel: dayLabel(for: entry.index),
                                    isToday: isToday(entry.index),
                                    isSelected: isSelectedDate(entry.index),
                                    colorScheme: colorScheme,
                                    trackHeight: barTrackHeight,
                                    showValue: isToday(entry.index) || isSelectedDate(entry.index)
                                )
                                .frame(width: 40)
                                .id(entry.index)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.top, barGroupTopPadding)
                        .padding(.bottom, 10)
                    }
                    .frame(height: 228)
                    .frame(minWidth: CGFloat(displayedBars.count) * 49 + 30)
                }
                .onAppear {
                    if let latestIndex = displayedBars.last?.index {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.easeOut(duration: 0.3)) {
                                scrollProxy.scrollTo(latestIndex, anchor: .trailing)
                            }
                        }
                    }
                }
            }
        }
        .padding(.top, 12)
        .padding(.bottom, 18)
    }
    
    // MARK: - Bar Chart Helper Functions
    
    private let barTrackHeight: CGFloat = 140
    private let barGroupTopPadding: CGFloat = 14

    private var displayedBars: [(index: Int, steps: Int)] {
        guard !weeklyStepData.isEmpty else { return [] }
        let startIndex = max(0, weeklyStepData.count - 7)
        return Array(weeklyStepData.enumerated().dropFirst(startIndex)).map { (index: $0.offset, steps: $0.element) }
    }

    private func goalLineOffsetY(maxSteps: Int) -> CGFloat {
        guard maxSteps > 0 else { return barGroupTopPadding + barTrackHeight }
        let cappedGoal = min(max(dailyGoal, 0), maxSteps)
        let goalHeight = CGFloat(cappedGoal) / CGFloat(maxSteps) * barTrackHeight
        return barGroupTopPadding + (barTrackHeight - goalHeight)
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
    let isToday: Bool
    let isSelected: Bool  // NEW: Highlight if selected in calendar
    let colorScheme: ColorScheme
    let trackHeight: CGFloat
    let showValue: Bool
    
    @State private var barScale: CGFloat = 1.0
    @State private var barAnimationProgress: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .bottom) {
                Capsule()
                    .fill(colorScheme == .dark
                        ? Color.white.opacity(0.06)
                        : Color.black.opacity(0.05))
                    .frame(height: trackHeight)
                    .overlay(
                        Capsule()
                            .strokeBorder(
                                isSelected ? FitCompColors.primary.opacity(0.65) : Color.clear,
                                style: StrokeStyle(lineWidth: 1.5, dash: isSelected ? [4, 3] : [])
                            )
                    )
                
                if steps > 0 {
                    let barHeight = CGFloat(steps) / CGFloat(maxSteps) * trackHeight

                    Capsule()
                        .fill(barColor(for: steps))
                        .frame(height: max(8, barHeight * barAnimationProgress))
                        .shadow(
                            color: (isToday || isSelected) ? glowColor(for: steps) : .clear,
                            radius: (isToday || isSelected) ? 7 : 0,
                            x: 0,
                            y: 0
                        )
                }
            }
            .overlay(alignment: .top) {
                if showValue && steps > 0 {
                    Text(formatNumberShort(steps))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(FitCompColors.textPrimary)
                        .offset(y: -16)
                }
            }
            .scaleEffect(isSelected ? 1.03 : barScale)
            .onTapGesture {
                HapticManager.shared.light()

                withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                    barScale = 1.05
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                        barScale = 1.0
                    }
                }

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
            
            Text(dayLabel.uppercased())
                .font(.system(size: 12, weight: isSelected ? .bold : .semibold))
                .foregroundColor(isSelected ? FitCompColors.primary : (isToday ? FitCompColors.textPrimary : FitCompColors.textSecondary))
        }
    }
    
    private func barColor(for steps: Int) -> LinearGradient {
        let percentage = Double(steps) / Double(dailyGoal)
        
        if percentage >= 1.0 {
            return LinearGradient(
                colors: [
                    FitCompColors.green.opacity(0.95),
                    FitCompColors.green.opacity(0.80)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        } else if percentage >= 0.6 {
            return LinearGradient(
                colors: [
                    FitCompColors.primary.opacity(0.95),
                    FitCompColors.primary.opacity(0.78)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        } else {
            return LinearGradient(
                colors: [
                    FitCompColors.textSecondary.opacity(0.55),
                    FitCompColors.textSecondary.opacity(0.38)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
    
    private func glowColor(for steps: Int) -> Color {
        let percentage = Double(steps) / Double(dailyGoal)
        
        if percentage >= 1.0 {
            return FitCompColors.green.opacity(0.35)
        } else if percentage >= 0.6 {
            return FitCompColors.primary.opacity(0.30)
        } else {
            return FitCompColors.textSecondary.opacity(0.18)
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


