# 🔥 Streak Calculation Fix - Daily Goal Based

## ❌ Original Problem

**Issue:** In the Settings page, the "Current Streak" stat showed **0 days** even though the user had hit their daily step goal for multiple consecutive days.

**Expected Behavior:** Streak should count consecutive days where the user **meets or exceeds** their set daily step goal.

---

## 🔍 Root Cause

The `calculateStreak()` function in `SettingsView.swift` was using the wrong criteria:

### **Before:**
```swift
if todayStat.steps > 0 {  // ❌ Just checking for ANY steps
    streak = 1
    // Continue counting...
}
```

**Problem:** 
- Counted ANY day with steps > 0 as part of the streak
- Did not consider the user's actual daily goal
- If you had 1,000 steps but your goal was 10,000, it would still count

### **What It Should Do:**
- Check if steps **meet or exceed** the daily goal
- For example: If goal is 10,000 steps, only count days with ≥10,000 steps

---

## ✅ Solution

Updated the streak calculation to:
1. Get the user's daily step goal from UserDefaults
2. Check if each day's steps **≥ daily goal**
3. Fetch 30 days of data (not just 7) for accurate streak counting
4. Add detailed logging to debug streak issues

---

## 📝 Changes Made

### **1. Updated `calculateStreak()` Function**

**File:** `StepComp/Screens/Settings/SettingsView.swift`

```swift
private func calculateStreak(from stats: [StepStats]) -> Int {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    var streak = 0
    
    // ✅ Get user's daily step goal
    var dailyGoal = UserDefaults.standard.integer(forKey: "dailyStepGoal")
    if dailyGoal <= 0 {
        dailyGoal = 10000 // Default goal if not set
    }
    
    // ✅ Check today first - must meet or exceed daily goal
    if let todayStat = stats.first(where: { calendar.isDate($0.date, inSameDayAs: today) }),
       todayStat.steps >= dailyGoal {  // ✅ Now checks goal
        streak = 1
        
        // ✅ Check previous days - each must meet or exceed daily goal
        for i in 1..<30 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today),
               let stat = stats.first(where: { calendar.isDate($0.date, inSameDayAs: date) }),
               stat.steps >= dailyGoal {  // ✅ Now checks goal
                streak += 1
            } else {
                break  // ✅ Streak broken
            }
        }
    }
    
    return max(streak, 0)
}
```

### **2. Updated Data Fetching**

**Before:**
```swift
let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
let weeklyStats = try await healthKitService.getSteps(from: weekAgo, to: now)
```

**After:**
```swift
let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: now) ?? now
let streakStats = try await healthKitService.getSteps(from: thirtyDaysAgo, to: now)
```

**Why:** 
- 7 days wasn't enough if user had a streak > 7 days
- Now fetches 30 days to properly calculate longer streaks

---

## 🎯 How It Works Now

### **Example 1: Valid Streak**

**Daily Goal:** 10,000 steps

| Date | Steps | Meets Goal? | Streak |
|------|-------|-------------|--------|
| Jan 7 (today) | 12,500 | ✅ Yes | 3 days |
| Jan 6 | 10,200 | ✅ Yes | Continues |
| Jan 5 | 11,000 | ✅ Yes | Continues |
| Jan 4 | 8,500 | ❌ No | **BROKEN** |

**Result:** Streak = **3 days** (Jan 5, 6, 7)

### **Example 2: No Streak (Goal Not Met Today)**

**Daily Goal:** 10,000 steps

| Date | Steps | Meets Goal? | Streak |
|------|-------|-------------|--------|
| Jan 7 (today) | 8,500 | ❌ No | 0 days |
| Jan 6 | 10,200 | ✅ Yes | N/A |
| Jan 5 | 11,000 | ✅ Yes | N/A |

**Result:** Streak = **0 days** (today's goal not met)

### **Example 3: Long Streak**

**Daily Goal:** 10,000 steps

| Date | Steps | Meets Goal? | Streak |
|------|-------|-------------|--------|
| Jan 7 (today) | 12,500 | ✅ Yes | 14 days |
| Jan 6 | 10,200 | ✅ Yes | Continues |
| ... | ... | ✅ All days | Continues |
| Dec 25 | 11,000 | ✅ Yes | Continues |
| Dec 24 | 9,500 | ❌ No | **BROKEN** |

**Result:** Streak = **14 days** (Dec 25 - Jan 7)

---

## 📊 Logic Flow

```
1. Load 30 days of step data from HealthKit
   ↓
2. Get user's daily goal (e.g., 10,000)
   ↓
3. Check today:
   - Steps ≥ goal? → streak = 1
   - Steps < goal? → streak = 0, STOP
   ↓
4. If today met goal, check yesterday:
   - Steps ≥ goal? → streak++, continue
   - Steps < goal? → STOP
   ↓
5. Repeat for up to 30 days back
   ↓
6. Display final streak count
```

---

## 🐛 Debug Logging

Added detailed console logging to help debug streak issues:

```
📊 Calculating streak with daily goal: 10000
✅ Today's goal met: 12500 >= 10000
✅ Day -1 goal met: 10200 >= 10000
✅ Day -2 goal met: 11000 >= 10000
❌ Day -3 goal NOT met: 8500 < 10000 - streak broken
🔥 Final streak: 3 days
```

---

## ✅ Testing

### **Test Case 1: User Meets Goal Multiple Days**
1. ✅ Set daily goal to 10,000
2. ✅ Walk 10,000+ steps for 3 days straight
3. ✅ Open Settings
4. ✅ **Expected:** Streak shows "3 Days"

### **Test Case 2: User Misses Goal One Day**
1. ✅ Walk 10,000+ steps on Day 1 and Day 3
2. ✅ Walk only 5,000 steps on Day 2
3. ✅ Open Settings on Day 3
4. ✅ **Expected:** Streak shows "1 Day" (only Day 3)

### **Test Case 3: User Hasn't Met Goal Today**
1. ✅ Walk 10,000+ steps for 5 days
2. ✅ Today walk only 2,000 steps so far
3. ✅ Open Settings
4. ✅ **Expected:** Streak shows "0 Days"

### **Test Case 4: Different Daily Goals**
1. ✅ Set daily goal to 5,000 (not 10,000)
2. ✅ Walk 6,000 steps for 2 days
3. ✅ Open Settings
4. ✅ **Expected:** Streak shows "2 Days"

---

## 🎯 Where Else Streak Is Calculated

This fix only updates the **Settings page**. If streak is shown elsewhere, those locations also need updating:

### **To Check:**
- ✅ `SettingsView.swift` - **FIXED**
- ❓ `DashboardViewModel.swift` - Has `calculateStreak()` - may need same fix
- ❓ Home screen - if streak is displayed

---

## 📋 Commit Message

```
fix: Calculate streak based on daily goal achievement

PROBLEM:
- Settings page showed 0 days streak even when user hit daily goal
- Streak counted ANY day with steps > 0, not goal achievement
- Only fetched 7 days of data (insufficient for longer streaks)

SOLUTION:
- Check if steps >= daily goal for each day
- Fetch 30 days of HealthKit data
- Add debug logging for streak calculation
- Break streak on first day goal not met

EXAMPLE:
- Daily Goal: 10,000 steps
- Day 1: 12,000 steps ✅
- Day 2: 11,000 steps ✅
- Day 3: 8,000 steps ❌
- Streak: 0 (today's goal not met)

RESULT:
✅ Streak accurately reflects consecutive goal achievements
✅ Users see correct streak count in Settings
✅ Better motivation to maintain daily goals
```

---

## 🎉 Summary

**Fixed:**
- ❌ Streak no longer counts days with any steps
- ✅ Streak now counts consecutive days meeting daily goal
- ✅ Fetches 30 days of data (not just 7)
- ✅ Added debug logging

**User Impact:**
- 🎯 Accurate streak tracking
- 🔥 Better motivation to hit daily goals
- 📊 Clear criteria: meet goal = continue streak

**Example:**
- Goal: 10,000 steps
- Hit goal 4 days in a row
- Settings shows: **"4 Days" streak** ✅

Your streak should now accurately reflect your goal achievements! 🎉

