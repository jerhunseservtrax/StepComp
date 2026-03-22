//
//  ActivityChartView.swift
//  FitComp
//
//  Weekly activity chart with smooth curve
//

import SwiftUI

enum ActivityPeriod: String, CaseIterable {
    case day = "Day"
    case week = "Week"
    case month = "Month"
}

struct ActivityChartView: View {
    let weeklyData: [Int] // 7 days of step data
    @State private var selectedPeriod: ActivityPeriod = .week
    @State private var chartData: [Int] = []
    @State private var chartLabels: [String] = []
    @State private var isLoading = false
    @State private var showingDateRangePicker = false
    @State private var customStartDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var customEndDate: Date = Date()
    @State private var isUsingCustomRange = false
    @Namespace private var animation
    
    @EnvironmentObject var healthKitService: HealthKitService
    
    private let accentAmber = Color(red: 0.961, green: 0.620, blue: 0.043)
    
    private let weekLabels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    private let dayLabels = ["12AM", "4AM", "8AM", "12PM", "4PM", "8PM"]
    
    // Get current day of week (0 = Sunday, 1 = Monday, etc.)
    private var currentDayIndex: Int {
        switch selectedPeriod {
        case .week:
            let weekday = Calendar.current.component(.weekday, from: Date())
            // Convert to 0-indexed Monday-start (Mon=0, Sun=6)
            return weekday == 1 ? 6 : weekday - 2
        case .day:
            let hour = Calendar.current.component(.hour, from: Date())
            // 0-5 for 6 time blocks (4-hour blocks)
            return min(hour / 4, 5)
        case .month:
            let day = Calendar.current.component(.day, from: Date())
            // 0-4 for 5 weeks
            return min((day - 1) / 7, 4)
        }
    }
    
    // Date range string
    private var dateRangeString: String {
        // Show custom range if user selected one
        if isUsingCustomRange {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return "\(formatter.string(from: customStartDate)) - \(formatter.string(from: customEndDate))"
        }
        
        let calendar = Calendar.current
        let today = Date()
        
        switch selectedPeriod {
        case .week:
            // Find Monday of this week
            var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
            components.weekday = 2 // Monday
            guard let monday = calendar.date(from: components) else { return "" }
            guard let sunday = calendar.date(byAdding: .day, value: 6, to: monday) else { return "" }
            
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            
            return "\(formatter.string(from: monday)) - \(formatter.string(from: sunday))"
        case .day:
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d, yyyy"
            return formatter.string(from: today)
        case .month:
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: today)
        }
    }
    
    private var periodTitle: String {
        switch selectedPeriod {
        case .week:
            return "This Week"
        case .day:
            return "Today"
        case .month:
            return "This Month"
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Activity")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text(periodTitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .id(periodTitle) // Add ID to trigger animation
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
                
                Spacer()
                
                // Date range picker button
                Button(action: {
                    showingDateRangePicker = true
                }) {
                    HStack(spacing: 4) {
                        Text(dateRangeString)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(.systemGray6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color(.systemGray5), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            
            // Period selector tabs
            HStack(spacing: 8) {
                ForEach(ActivityPeriod.allCases, id: \.self) { period in
                    PeriodTab(
                        title: period.rawValue,
                        isSelected: selectedPeriod == period && !isUsingCustomRange,
                        primaryColor: FitCompColors.primary
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedPeriod = period
                            isUsingCustomRange = false // Reset custom range when selecting preset
                            Task {
                                await loadDataForPeriod()
                            }
                        }
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            
            // Chart
            if isLoading {
                ProgressView()
                    .frame(height: 160)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .transition(.opacity)
            } else {
                ActivityGraph(
                    data: chartData,
                    currentDayIndex: currentDayIndex,
                    primaryColor: FitCompColors.primary,
                    accentAmber: accentAmber
                )
                .frame(height: 160)
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .id(selectedPeriod) // Add ID to trigger animation on period change
                .transition(
                    .asymmetric(
                        insertion: .scale(scale: 0.9).combined(with: .opacity),
                        removal: .scale(scale: 0.9).combined(with: .opacity)
                    )
                )
            }
            
            // Labels
            HStack {
                ForEach(0..<chartLabels.count, id: \.self) { index in
                    Text(chartLabels[index])
                        .font(.system(size: 10, weight: index == currentDayIndex ? .bold : .medium))
                        .foregroundColor(index == currentDayIndex ? .primary : .secondary)
                        .frame(maxWidth: .infinity)
                        .id("\(selectedPeriod.rawValue)-\(index)") // Add ID for smooth label transitions
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 20)
        }
        .background(
            RoundedRectangle(cornerRadius: 32)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.06), radius: 20, x: 0, y: 8)
        )
        .padding(.horizontal, 20)
        .onAppear {
            // Initialize with week data on first load
            if weeklyData.count == 7 {
                chartData = weeklyData
                chartLabels = weekLabels
            } else {
                // Default to empty or zeros if weeklyData is invalid
                chartData = Array(repeating: 0, count: 7)
                chartLabels = weekLabels
            }
            Task {
                await loadDataForPeriod()
            }
        }
        .sheet(isPresented: $showingDateRangePicker) {
            DateRangePickerSheet(
                startDate: $customStartDate,
                endDate: $customEndDate,
                onApply: {
                    isUsingCustomRange = true
                    Task {
                        await loadCustomRangeData()
                    }
                }
            )
        }
    }
    
    // Load data for the selected period
    private func loadDataForPeriod() async {
        await MainActor.run {
            isLoading = true
        }
        
        switch selectedPeriod {
        case .day:
            // Load hourly data for today (6 blocks of 4 hours)
            await loadHourlyData()
            await MainActor.run {
                chartLabels = dayLabels
            }
        case .week:
            // Load daily data for the week (7 days)
            await loadWeeklyData()
            await MainActor.run {
                chartLabels = weekLabels
            }
        case .month:
            // Load weekly data for the month (5 weeks)
            await loadMonthlyData()
            await MainActor.run {
                chartLabels = ["Wk 1", "Wk 2", "Wk 3", "Wk 4", "Wk 5"]
            }
        }
        
        await MainActor.run {
            isLoading = false
        }
    }
    
    // Load hourly data for today (6 time blocks of 4 hours each)
    private func loadHourlyData() async {
        let calendar = Calendar.current
        let today = Date()
        guard let startOfDay = calendar.startOfDay(for: today) as Date? else { return }
        
        var hourlySteps: [Int] = []
        
        // 6 blocks of 4 hours each
        for block in 0..<6 {
            let blockStart = calendar.date(byAdding: .hour, value: block * 4, to: startOfDay) ?? startOfDay
            let blockEnd = calendar.date(byAdding: .hour, value: (block + 1) * 4, to: startOfDay) ?? startOfDay
            
            do {
                let stats = try await healthKitService.getSteps(from: blockStart, to: blockEnd)
                let blockSteps = stats.reduce(0) { $0 + $1.steps }
                hourlySteps.append(blockSteps)
            } catch {
                hourlySteps.append(0)
            }
        }
        
        await MainActor.run {
            chartData = hourlySteps
        }
    }
    
    // Load daily data for the week
    private func loadWeeklyData() async {
        let calendar = Calendar.current
        let today = Date()
        
        // Find Monday of this week
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
        components.weekday = 2 // Monday
        guard let monday = calendar.date(from: components) else { return }
        
        var dailySteps: [Int] = []
        
        for dayOffset in 0..<7 {
            guard let dayStart = calendar.date(byAdding: .day, value: dayOffset, to: monday),
                  let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else {
                dailySteps.append(0)
                continue
            }
            
            // Only fetch data for days up to today
            if dayStart > today {
                dailySteps.append(0)
                continue
            }
            
            do {
                let stats = try await healthKitService.getSteps(from: dayStart, to: dayEnd)
                let daySteps = stats.reduce(0) { $0 + $1.steps }
                dailySteps.append(daySteps)
            } catch {
                dailySteps.append(0)
            }
        }
        
        await MainActor.run {
            chartData = dailySteps
        }
    }
    
    // Load weekly data for the month (5 weeks)
    private func loadMonthlyData() async {
        let calendar = Calendar.current
        let today = Date()
        
        // Find start of the month
        var components = calendar.dateComponents([.year, .month], from: today)
        components.day = 1
        guard let startOfMonth = calendar.date(from: components) else { return }
        
        var weeklySteps: [Int] = []
        
        for week in 0..<5 {
            let weekStart = calendar.date(byAdding: .day, value: week * 7, to: startOfMonth) ?? startOfMonth
            let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? startOfMonth
            
            // Only fetch data for weeks up to today
            if weekStart > today {
                weeklySteps.append(0)
                continue
            }
            
            do {
                let stats = try await healthKitService.getSteps(from: weekStart, to: weekEnd)
                let weekSteps = stats.reduce(0) { $0 + $1.steps }
                weeklySteps.append(weekSteps)
            } catch {
                weeklySteps.append(0)
            }
        }
        
        await MainActor.run {
            chartData = weeklySteps
        }
    }
    
    // Load data for custom date range
    private func loadCustomRangeData() async {
        await MainActor.run {
            isLoading = true
        }
        
        let calendar = Calendar.current
        let daysBetween = calendar.dateComponents([.day], from: customStartDate, to: customEndDate).day ?? 0
        let numberOfDays = max(daysBetween + 1, 1)
        
        var dailySteps: [Int] = []
        var labels: [String] = []
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        
        for dayOffset in 0..<numberOfDays {
            guard let dayStart = calendar.date(byAdding: .day, value: dayOffset, to: customStartDate),
                  let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else {
                dailySteps.append(0)
                labels.append("")
                continue
            }
            
            // Only fetch data for days up to today
            if dayStart > Date() {
                dailySteps.append(0)
                labels.append(formatter.string(from: dayStart))
                continue
            }
            
            do {
                let stats = try await healthKitService.getSteps(from: dayStart, to: dayEnd)
                let daySteps = stats.reduce(0) { $0 + $1.steps }
                dailySteps.append(daySteps)
                labels.append(formatter.string(from: dayStart))
            } catch {
                dailySteps.append(0)
                labels.append(formatter.string(from: dayStart))
            }
        }
        
        await MainActor.run {
            chartData = dailySteps
            chartLabels = labels
            isLoading = false
        }
        
        print("📊 Loaded custom range: \(numberOfDays) days from \(formatter.string(from: customStartDate)) to \(formatter.string(from: customEndDate))")
    }
}

struct PeriodTab: View {
    let title: String
    let isSelected: Bool
    let primaryColor: Color
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.system(size: 12, weight: isSelected ? .bold : .semibold))
                .foregroundColor(isSelected ? .black : .secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? primaryColor : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(isSelected ? Color.clear : Color(.systemGray4), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ActivityGraph: View {
    let data: [Int]
    let currentDayIndex: Int
    let primaryColor: Color
    let accentAmber: Color
    
    @State private var animationProgress: CGFloat = 0
    @State private var selectedIndex: Int?
    @State private var isDragging = false
    
    private var maxValue: Int {
        max(data.max() ?? 1, 1)
    }
    
    private var normalizedData: [CGFloat] {
        data.map { CGFloat($0) / CGFloat(maxValue) }
    }
    
    // Determine which index to show (selected or current)
    private var displayIndex: Int {
        selectedIndex ?? currentDayIndex
    }
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            // Calculate stepX based on actual data count, with safety check
            let stepX = data.count > 1 ? width / CGFloat(data.count - 1) : width
            
            ZStack {
                // Only render if we have data
                if !data.isEmpty {
                // Grid lines
                ForEach(0..<3, id: \.self) { index in
                    let y = height * CGFloat(index + 1) / 4
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: width, y: y))
                    }
                    .stroke(Color(.systemGray5), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                }
                
                // Gradient fill under curve
                if normalizedData.count > 0 {
                    Path { path in
                        let points = normalizedData.enumerated().map { index, value in
                            CGPoint(x: CGFloat(index) * stepX, y: height * (1 - value * 0.85 * animationProgress))
                        }
                        
                        guard !points.isEmpty else { return }
                        
                        path.move(to: CGPoint(x: 0, y: height))
                        path.addLine(to: points[0])
                        
                        for i in 1..<points.count {
                            let control1 = CGPoint(
                                x: points[i-1].x + stepX * 0.4,
                                y: points[i-1].y
                            )
                            let control2 = CGPoint(
                                x: points[i].x - stepX * 0.4,
                                y: points[i].y
                            )
                            path.addCurve(to: points[i], control1: control1, control2: control2)
                        }
                        
                        path.addLine(to: CGPoint(x: width, y: height))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [FitCompColors.primary.opacity(0.5 * animationProgress), FitCompColors.primary.opacity(0)]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                
                // Line curve
                if normalizedData.count > 0 {
                    Path { path in
                        let points = normalizedData.enumerated().map { index, value in
                            CGPoint(x: CGFloat(index) * stepX, y: height * (1 - value * 0.85 * animationProgress))
                        }
                        
                        guard !points.isEmpty else { return }
                        
                        path.move(to: points[0])
                        
                        for i in 1..<points.count {
                            let control1 = CGPoint(
                                x: points[i-1].x + stepX * 0.4,
                                y: points[i-1].y
                            )
                            let control2 = CGPoint(
                                x: points[i].x - stepX * 0.4,
                                y: points[i].y
                            )
                            path.addCurve(to: points[i], control1: control1, control2: control2)
                        }
                    }
                    .stroke(accentAmber, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                }
                
                // Interactive dot with tooltip (shows selected or current)
                if displayIndex < normalizedData.count && animationProgress > 0.5 {
                    let x = CGFloat(displayIndex) * stepX
                    let y = height * (1 - normalizedData[displayIndex] * 0.85 * animationProgress)
                    let stepValue = data.count > displayIndex ? data[displayIndex] : 0
                    
                    // Tooltip
                    VStack(spacing: 0) {
                        Text(formatSteps(stepValue))
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(isDragging ? accentAmber : Color(.darkGray))
                            )
                        
                        // Arrow
                        Triangle()
                            .fill(isDragging ? accentAmber : Color(.darkGray))
                            .frame(width: 10, height: 6)
                    }
                    .position(x: x, y: y - 25)
                    .transition(.scale.combined(with: .opacity))
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: displayIndex)
                    
                    // Dot
                    Circle()
                        .fill(Color.white)
                        .frame(width: isDragging ? 14 : 12, height: isDragging ? 14 : 12)
                        .overlay(
                            Circle()
                                .stroke(accentAmber, lineWidth: isDragging ? 4 : 3)
                        )
                        .shadow(color: accentAmber.opacity(isDragging ? 0.5 : 0.3), radius: isDragging ? 6 : 4, x: 0, y: 2)
                        .position(x: x, y: y)
                        .transition(.scale.combined(with: .opacity))
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: displayIndex)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDragging)
                }
                } // End if !data.isEmpty
                
                // Invisible overlay for gesture detection
                Color.clear
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let x = value.location.x
                                let index = findNearestIndex(for: x, width: width)
                                
                                if selectedIndex != index {
                                    selectedIndex = index
                                    HapticManager.shared.light()
                                }
                                isDragging = true
                            }
                            .onEnded { _ in
                                // Reset to current day after a delay
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                        selectedIndex = nil
                                        isDragging = false
                                    }
                                }
                            }
                    )
                    .simultaneousGesture(
                        TapGesture()
                            .onEnded { _ in
                                // Tap immediately resets to current
                                if selectedIndex != nil {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        selectedIndex = nil
                                        isDragging = false
                                    }
                                    HapticManager.shared.light()
                                }
                            }
                    )
            }
            .onAppear {
                // Reset and animate
                animationProgress = 0
                withAnimation(.easeInOut(duration: 0.8)) {
                    animationProgress = 1.0
                }
            }
            .onChange(of: data) { _, _ in
                // Re-animate when data changes
                animationProgress = 0
                selectedIndex = nil
                isDragging = false
                withAnimation(.easeInOut(duration: 0.8)) {
                    animationProgress = 1.0
                }
            }
        }
    }
    
    // Find the nearest data point index for a given x position
    private func findNearestIndex(for x: CGFloat, width: CGFloat) -> Int {
        guard data.count > 1 else { return 0 }
        
        let stepX = width / CGFloat(data.count - 1)
        let index = Int(round(x / stepX))
        return max(0, min(index, data.count - 1))
    }
    
    private func formatSteps(_ steps: Int) -> String {
        if steps >= 1000 {
            return String(format: "%.1fk", Double(steps) / 1000.0)
        }
        return "\(steps)"
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Date Range Picker Sheet

struct DateRangePickerSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var startDate: Date
    @Binding var endDate: Date
    let onApply: () -> Void
    
    @State private var tempStartDate: Date
    @State private var tempEndDate: Date
    
    
    init(startDate: Binding<Date>, endDate: Binding<Date>, onApply: @escaping () -> Void) {
        self._startDate = startDate
        self._endDate = endDate
        self.onApply = onApply
        self._tempStartDate = State(initialValue: startDate.wrappedValue)
        self._tempEndDate = State(initialValue: endDate.wrappedValue)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Start Date Picker
                VStack(alignment: .leading, spacing: 12) {
                    Text("Start Date")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    DatePicker("", selection: $tempStartDate, in: ...Date(), displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .tint(FitCompColors.primary)
                }
                
                // End Date Picker
                VStack(alignment: .leading, spacing: 12) {
                    Text("End Date")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    DatePicker("", selection: $tempEndDate, in: tempStartDate...Date(), displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .tint(FitCompColors.primary)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Select Date Range")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        startDate = tempStartDate
                        endDate = tempEndDate
                        dismiss()
                        onApply()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(FitCompColors.primary)
                }
            }
        }
        .presentationDetents([.large])
    }
}

#Preview {
    ActivityChartView(weeklyData: [3200, 4500, 2800, 5499, 4100, 3800, 2900])
        .background(Color(.systemGray6))
}

