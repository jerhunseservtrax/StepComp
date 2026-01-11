# 📊 Daily Goal Card - Toggle View Feature

## 🎯 Goal

Add a toggle button to the Daily Goal Card that lets users switch between:
1. **Circular Progress View** (current default)
2. **Bar Chart View** (weekly step history)

---

## 📋 Implementation Status

### ✅ Completed:
1. Added `weeklyStepData: [Int]` parameter to `DailyGoalCard`
2. Added `ViewMode` enum with `.circular` and `.barChart` cases
3. Added `@State private var viewMode: ViewMode = .circular`
4. Added `@State private var barAnimationProgress: Double = 0`
5. Added toggle button in header with icon that changes based on view mode
6. Added `@EnvironmentObject var healthKitService: HealthKitService`

### ⚠️ In Progress:
- File structure is partially updated but needs completion
- The circular view code is currently mixed with the main body
- Need to extract circular view to `circularProgressView` computed property
- Need to complete `barChartView` computed property

---

## 🔧 What Needs To Be Done

### 1. Update HomeDashboardView.swift

**Location**: `StepComp/Screens/Home/HomeDashboardView.swift` (line 63)

**Current Code:**
```swift
DailyGoalCard(
    currentSteps: selectedDateSteps,
    dailyGoal: dailyGoal,
    calories: selectedDateCalories,
    distanceKm: selectedDateDistance,
    activeHours: Double(selectedDateSteps) / 6500.0,
    onRefresh: {
        await loadStepsForSelectedDate()
        await loadWeeklyData()
        viewModel.refresh()
    },
    celebrationManager: celebrationManager
)
```

**Change To:**
```swift
DailyGoalCard(
    currentSteps: selectedDateSteps,
    dailyGoal: dailyGoal,
    calories: selectedDateCalories,
    distanceKm: selectedDateDistance,
    activeHours: Double(selectedDateSteps) / 6500.0,
    weeklyStepData: weeklyStepData,  // ← ADD THIS LINE
    onRefresh: {
        await loadStepsForSelectedDate()
        await loadWeeklyData()
        viewModel.refresh()
    },
    celebrationManager: celebrationManager)
.environmentObject(healthKitService)  // ← ADD THIS LINE
```

---

### 2. Complete DailyGoalCard.swift Structure

The file needs to be restructured with three main view components:

#### **Structure Needed:**
```
var body: some View {
    ZStack(alignment: .topTrailing) {
        VStack(spacing: 0) {
            // Header with toggle button
            // Conditional view
            if viewMode == .circular {
                circularProgressView
            } else {
                barChartView
            }
            // Stats row
        }
        // Fireworks overlay
    }
}

private var circularProgressView: some View {
    // All the circular progress ring code (already exists)
}

private var barChartView: some View {
    // Weekly bar chart view (needs to be implemented)
}
```

---

## 📊 Bar Chart View Design (Based on Screenshot)

### **Components:**

#### 1. **Today's Stats Header**
```
7,715
3.6mi  ↗️ 2
```
- Large step count
- Distance + streak indicator

#### 2. **Week Label**
```
3 days
```

#### 3. **Bar Chart** (7 bars)
- Each bar shows:
  - Steps count on bar
  - Day label (Thu, Fri, Sat, etc.)
  - Distance label (2.2mi format)
- Bar colors:
  - **Green**: Goal met (≥ daily goal)
  - **Blue**: 50-99% of goal
  - **Orange/Red**: < 50% of goal
- Animated height based on bar animation progress

#### 4. **Weekly Summary Footer**
```
47,467 · 19.8 mi · 135% of Goal
```

---

## 🎨 Bar Chart Implementation Details

### **Bar Height Calculation:**
```swift
private func barHeight(for steps: Int, maxSteps: Int) -> CGFloat {
    let ratio = CGFloat(steps) / CGFloat(maxSteps)
    return 140 * max(ratio, 0.05) // Min 5% for visibility
}
```

### **Bar Color Logic:**
```swift
private func barColor(for steps: Int, goal: Int) -> LinearGradient {
    if steps >= goal {
        // Green gradient
    } else if steps >= goal / 2 {
        // Blue gradient
    } else {
        // Orange/Red gradient
    }
}
```

### **Animation:**
```swift
.onAppear {
    if viewMode == .barChart {
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
            barAnimationProgress = 1.0
        }
    }
}
```

---

## 🎯 User Experience Flow

1. **User opens home screen** → Sees circular view (default)
2. **Taps toggle button** → 
   - Icon changes from chart.bar.fill to circle.circle.fill
   - View smoothly transitions to bar chart
   - Bars animate upward from 0 to full height
   - Haptic feedback
3. **Taps toggle again** → Returns to circular view
4. **Taps card** → Refreshes data, updates both views

---

## 📱 Toggle Button Design

**Icon:**
- Circular view showing → Show `chart.bar.fill` icon
- Bar chart showing → Show `circle.circle.fill` icon

**Appearance:**
- 18pt font, semibold
- Primary color (yellow/coral)
- 32x32pt frame
- Circular background with 15% opacity
- Positioned next to percentage badge

**Interaction:**
- Spring animation (0.4s response, 0.7 damping)
- Light haptic feedback
- Smooth view transition

---

## 🔢 Data Source

**Weekly Step Data:**
- Array of 7 integers representing daily steps
- Ordered: [Mon, Tue, Wed, Thu, Fri, Sat, Sun]
- Already being loaded in `HomeDashboardView.loadWeeklyData()`
- Stored in `@State private var weeklyStepData: [Int] = []`

**Current Day Index:**
- Use `Calendar.current.component(.weekday, from: Date())` to highlight today

---

## ✅ Acceptance Criteria

- [ ] Toggle button appears in Daily Goal Card header
- [ ] Default view is circular progress (current behavior)
- [ ] Tapping toggle switches to bar chart view
- [ ] Bar chart shows 7 days of data with correct labels
- [ ] Bar heights animate smoothly on view appear
- [ ] Bar colors match goal progress (green/blue/orange)
- [ ] Week summary shows total steps, distance, and % of goal
- [ ] Tapping toggle again returns to circular view
- [ ] All animations are smooth with proper spring physics
- [ ] Haptic feedback on toggle tap

---

## 🐛 Known Issues To Fix

1. **File Structure**: The `DailyGoalCard.swift` file has mixed code that needs to be properly separated into computed properties
2. **Day Labels**: Need to calculate correct day names based on current date
3. **Today Highlight**: Need to determine which bar represents today
4. **Distance Units**: Need to respect user's unit preference (mi/km)

---

## 📚 References

- **Screenshot**: User provided screenshot showing desired bar chart layout
- **Weekly Data Loading**: `HomeDashboardView.swift` line 235-272
- **Activity Chart**: Similar bar chart in `ActivityChartView.swift` for reference

---

## 🚀 Next Steps

1. Complete the file restructuring in `DailyGoalCard.swift`
2. Implement the full `barChartView` computed property
3. Update `HomeDashboardView` to pass `weeklyStepData`
4. Test the toggle functionality
5. Refine animations and transitions
6. Test with real data from HealthKit

---

This feature will give users a powerful way to visualize their step progress over the week while maintaining the familiar circular view as the default! 📊✨

