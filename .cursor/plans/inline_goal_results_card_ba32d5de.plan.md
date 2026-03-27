---
name: Inline Goal Results Card
overview: Move the weight-goal picker and calorie results into the dark calculator card, replacing the separate bottom pickers with an inline results breakdown showing maintain/mild/moderate/extreme tiers.
todos:
  - id: move-pickers-into-card
    content: Remove external pickers, add WeightGoal segmented control and results breakdown rows inside the dark calculator card in CalorieCalculatorSheet.
    status: completed
  - id: build-verify
    content: Lint-check and build to confirm no regressions.
    status: completed
isProject: false
---

# Inline Goal Results in Calorie Calculator Card

## Goal

Move the lose/maintain/gain picker and aggressiveness controls **inside** the dark calculator card, and replace the current two-line summary with a full results breakdown (maintain, mild loss, moderate loss, extreme loss / mild gain, moderate gain, extreme gain) so the user sees all options at a glance -- similar to the reference screenshot.

## File

- [CalorieCalculatorView.swift](StepComp/Screens/Workouts/CalorieCalculatorView.swift) -- only this file changes.

## Current Layout (lines 202-284)

```
Dark card {
  header, inputs, workout days, summary (2 rows), "Calculate" button
}
// outside card:
Picker("Weight Goal") -- segmented (Lose / Maintain / Gain)
Picker("Aggressiveness") -- segmented (Mild / Moderate / Aggressive)
```

## New Layout

```
Dark card {
  header, inputs, workout days

  -- NEW: Goal selector (Lose / Maintain / Gain) as a segmented control
  --      styled with dark-card colors, inside the card

  -- NEW: Results breakdown section
  --      For "Maintain": single row showing TDEE at 100%
  --      For "Lose Weight": 3 rows
  --        Mild loss   (0.5 lb/week)  = TDEE - 250   ~90%
  --        Weight loss (1 lb/week)    = TDEE - 500   ~80%
  --        Extreme     (2 lb/week)    = TDEE - 750   ~61%
  --      For "Gain Weight": mirror with + deltas
  --      Each row: label, subtitle, calories/day, percentage of TDEE
  --      The row matching current selection gets a highlight/border

  -- NEW: Tappable rows -- tapping a row selects that aggressiveness
  --      and highlights it (yellow left accent or background tint)

  "Calculate New Plan" button (saves the selected tier's calories)
}
// Nothing below the card (pickers removed from outside)
```

## Detailed Changes

**1. Remove the external pickers** (lines 268-284 in current file)

- Delete the `VStack(spacing: 12)` containing the two `Picker`s that sit outside the dark card.

**2. Add goal selector inside the dark card** (after `workoutDaysField`, before the results)

- A `Picker` with `.segmented` style for `WeightGoal`, but styled to blend with the dark card (use `.colorMultiply` or wrap in a dark-themed container).

**3. Add a `resultsSection` computed property**

- Computes all tiers from `calculatedTDEE`:
  - Maintain: `calculatedTDEE`, percentage = 100
  - Mild loss: `CalorieCalculator.dailyTarget(tdee:, goal: .lose, aggressiveness: .mild)`, percentage = round(result/tdee * 100)
  - Moderate loss: same with `.moderate`
  - Extreme loss: same with `.aggressive`
  - (mirror for `.gain`)
- Each tier rendered as a row:
  - Left: title + subtitle (e.g. "Mild weight loss", "0.5 lb/week")
  - Right: calories/day + percentage badge
  - Selected tier gets a yellow left border or tinted background
- Tapping a row sets `goal` and `aggressiveness` accordingly.

**4. Update the `save()` function**

- Already saves `goal` and `aggressiveness` -- no change needed.
- `calculatedTarget` already derives from `goal + aggressiveness` -- no change needed.

**5. Update "Calculate New Plan" button**

- Currently works correctly; just ensure it remains at the bottom of the dark card after the new results section.

## Visual Spec for Each Result Row

```
HStack {
  VStack(leading) {
    "Mild weight loss"    -- .system(size: 14, weight: .bold), white
    "0.5 lb/week"         -- .system(size: 11, weight: .medium), white.opacity(0.5)
  }
  Spacer()
  VStack(trailing) {
    "2,299"               -- .system(size: 18, weight: .black), white
    "90% Calories/day"    -- .system(size: 10, weight: .bold), white.opacity(0.5)
  }
}
.padding(12)
.background(isSelected ? FitCompColors.primary.opacity(0.15) : Color.white.opacity(0.06))
.overlay(left yellow accent if selected)
.clipShape(RoundedRectangle(cornerRadius: 10))
```

## No Model Changes

- `WeightGoal`, `GoalAggressiveness`, `CalorieCalculator.dailyTarget(...)` already support all the math needed.
- No new files or model changes required.

