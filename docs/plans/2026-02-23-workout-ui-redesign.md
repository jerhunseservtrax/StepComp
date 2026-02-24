# Workout UI Redesign: Minimalist Gym-Optimized Interface

**Date:** 2026-02-23  
**Status:** Approved  
**Goal:** Transform workout tracking UI from information-dense to action-dense, optimized for gym use

## Problem Statement

The current workout UI suffers from several friction points during active workouts:

1. **Too many labels** - SET, PREV, TARGET, LBS, REPS force users to decode instead of act
2. **Excessive vertical space** - Large cards with green backgrounds limit visibility to 2-3 sets per screen
3. **Buried information** - Weight and reps inputs lost in visual clutter
4. **Redundant feedback** - "Target achieved 🎯" banner repeats information already shown via checkmark and green highlight
5. **Cognitive overhead** - Users must scan multiple columns and process multiple indicators

During a workout, users need: **Weight → Reps → Done**. Everything else should support this flow without adding friction.

## Design Philosophy

### Core Principles

1. **Action over information** - Minimize reading, maximize doing
2. **Progressive disclosure** - Show context when relevant, hide when not needed
3. **Muscle memory** - Fast path (tap to complete) stays consistent, power tools (long press) available but hidden
4. **Density without complexity** - Fit 4-5 sets on screen without hiding information behind interactions
5. **Visual hierarchy** - Size indicates importance: Exercise name > Inputs > Set number > Context

### Success Criteria

- Users can see 4-5 sets without scrolling (vs 2-3 currently)
- Primary action (complete set) requires 1 tap (no menu)
- Progressive overload suggestions visible without interaction
- Completed exercises auto-collapse to maximize screen space
- No cognitive load increase from removed labels

## Interaction Model

### Primary Gestures

**Tap row → Complete + Auto-advance**
- Marks current set complete
- Advances focus to next incomplete set
- Haptic feedback (heavy impact)
- No menu, no confirmation - immediate action

**Long press row → Action menu**
- Complete Set
- Edit Set (focuses input fields)
- Delete Set (destructive, system confirmation)

**Tap collapsed exercise → Expand**
- Reveals all sets with full data
- Smooth animation
- Maintains scroll position

### Auto-behaviors

**Auto-collapse completed exercises**
- Triggers when last set marked complete
- Shows: `✓ Exercise Name | 3 sets • 2,412 lb • +2.5 lb`
- Manual collapse available via long press exercise header (for exercises in progress)

**Auto-populate from previous**
- Set 1 pre-fills with suggested weight/reps from progressive overload calculation
- User can accept (tap next field) or modify (clear and enter)
- Sets 2-3 remain empty until Set 1 completed

**Auto-advance cursor**
- After entering weight → cursor jumps to reps
- After entering reps → cursor jumps to next set's weight
- After last set → keyboard dismisses, no advance

### Visual Feedback States

1. **Empty state** - White/dark background, subtle 1px gray border
2. **Focused state** - Primary color border (2px), slight scale animation
3. **Filled state** - Green tint border (0.5 opacity) when meets/exceeds target
4. **Completed state** - Light blue background (0.18 opacity), 50% overall opacity, checkmark replaces button
5. **Target met (pre-complete)** - Green background tint (0.08 opacity), green border

## Visual Layout

### Header (Compact)

```
Upper 1                    ⏱ 25:13  ⏸
Monday Routine • 7 Exercises
```

**Specifications:**
- Workout name: 24pt bold (down from 28pt)
- Timer: 12pt icon + 14pt monospace digits
- Pause button: 28px circle (down from 32px)
- Subtitle: 14pt medium
- Overall height: ~80px (down from ~100px)
- Background: Surface color with 0.9 opacity, 1px bottom divider

### Exercise Card - Expanded State

```
┌─────────────────────────────────────────────┐
│ [icon] Bent Over Row         ↑ Progressive  │
│        Back • Lats                           │
│        Last best: 135 x 8                    │
│        Suggested: 137.5 x 8                  │
├─────────────────────────────────────────────┤
│                                              │
│ 1  [137.5] x [8]  ✓                         │
│    Last: 135 x 8                             │
│                                              │
│ 2  [137.5] x [ ]                             │
│    +2.5 lb suggested                         │
│                                              │
│ 3  [ ] x [ ]                                 │
│                                              │
│ + ADD SET                                    │
└─────────────────────────────────────────────┘
```

**Exercise Header:**
- Icon: 56px square, rounded 16px, light gray background
- Exercise name: 16pt bold
- Target muscles: 12pt medium, secondary color
- Progressive badge: 10pt bold, primary color, pill background
- Last best / Suggested: 12pt medium, appears below name
- Padding: 12px (down from 16px)

**Set Row Structure:**
```
[Set #]  [Weight Input]  x  [Reps Input]  [✓ Button]
[Context line if relevant]
```

**Set Row Specifications:**
- Set number: 14pt bold, 30px width, left-aligned
- Weight input: 16pt bold, 100px width × 44px height, 12px corner radius
- "x" separator: 14pt medium, 8px horizontal spacing
- Reps input: 16pt bold, 100px width × 44px height, 12px corner radius
- Complete button: 40px circle, light blue checkmark
- Context text: 11pt medium, gray, 4px below main row, left-aligned with inputs
- Row height: ~52px (down from ~72px with banner)
- Spacing between rows: 8px

**Context Line Display Logic:**
- Set 1 (first incomplete): Always shows "Last: X x Y"
- Set 2 (after Set 1 complete): Shows "+X lb suggested" if progressive overload applies
- Set 3+: No context line (user understands pattern)

### Exercise Card - Collapsed State

**After completion (auto-collapse):**
```
✓ Bent Over Row | 3 sets • 2,412 lb • +2.5 lb
```

**During workout (manual collapse):**
```
Bent Over Row | 2/3 sets • 1,606 lb
```

**Specifications:**
- Height: 48px single line
- Font: 14pt medium
- Green checkmark (completed) or progress indicator (incomplete)
- Subtle background tint
- Tap anywhere to expand

### Removed Elements

**No longer present:**
- ❌ Column headers (SET, PREV, TARGET, LBS, REPS)
- ❌ Per-set green background cards
- ❌ "Target achieved 🎯" banner with emoji
- ❌ Arrow indicators in separate column
- ❌ Separate PREV and TARGET columns
- ❌ Quick action menu on single tap (moved to long press)

### Spacing Summary

- Header: 80px
- Exercise card padding: 12px
- Between sets: 8px
- Set row height: ~52px
- **Result: 4-5 sets visible** (vs 2-3 currently)

## Progressive Overload Display

### Exercise Header Context (Always Visible)

Shows aggregated guidance for entire exercise:

```
Bent Over Row    ↑ Progressive
Back • Lats
Last best: 135 x 8
Suggested: 137.5 x 8
```

**Display logic:**
- "Last best" = highest weight×reps from previous session
- "Suggested" = progressive overload calculation applied
- Only shows if previous data exists
- If no previous data: "First time - set your baseline"
- Progressive badge only appears when suggestions differ from previous

### Set-Level Context (Contextual)

**Set 1 (provides orientation):**
```
1  [137.5] x [ ]
   Last: 135 x 8
```
Always shows previous performance for immediate context

**Set 2 (shows progression):**
```
2  [137.5] x [ ]
   +2.5 lb suggested
```
Shows delta from previous if progressive overload applies

**Set 3+ (minimal):**
```
3  [ ] x [ ]
```
Clean - user already understands the pattern

### Progressive Overload Badge

**Shows when:**
- Exercise has previous session data
- Suggested weight/reps differ from previous
- Not all sets completed yet

**Hides when:**
- No previous data (first time)
- All sets completed
- Exercise manually collapsed

### Smart Pre-fill Behavior

- Set 1: Pre-fills with suggested values from progressive overload calculation
- Sets 2+: Empty until Set 1 completed, then suggest matching Set 1
- If user changes Set 1, Sets 2+ follow user's actual weight (not original suggestion)
- User can accept (leave pre-filled, tap next field) or modify (clear, enter new)

## Component Architecture

### ExerciseCard Component

**Props:**
- `workoutExercise: WorkoutExercise`
- `viewModel: WorkoutViewModel`
- `unitManager: UnitPreferenceManager`
- `focusedField: FocusState<UUID?>.Binding`
- `collapsedExerciseIds: Binding<Set<UUID>>`

**States:**
1. Expanded (default for incomplete)
2. Collapsed (auto on completion)
3. Collapsed (manual, incomplete)

**Responsibilities:**
- Render exercise header with context
- Render all sets
- Handle collapse/expand animation
- Calculate summary stats for collapsed view

### SetRow Component

**Props:**
- `set: WorkoutSet`
- `exerciseId: UUID`
- `viewModel: WorkoutViewModel`
- `unitManager: UnitPreferenceManager`
- `focusedField: FocusState<UUID?>.Binding`
- `showContext: Bool`
- `contextText: String?`

**Structure:**
```swift
HStack(spacing: 12) {
    Text("\(set.setNumber)")           // Set number
    TextField("", text: $weightText)   // Weight input
    Text("x")                          // Separator
    TextField("", text: $repsText)     // Reps input
    Button { handleTap() }             // Complete button
}
if showContext {
    Text(contextText)                  // Context line
}
```

**Gesture Handling:**
- Tap row background → Complete and advance
- Long press row → Action menu (Complete, Edit, Delete)
- Tap input → Focus and select all text
- Context menu → Delete option

**Input Field Specifications:**
- Corner radius: 12px
- Border: 2px when focused (primary), 1px otherwise (gray)
- Background: Surface color
- Keyboard: Number pad with decimal (weight), number pad (reps)
- Auto-select text on focus
- Smart advance: weight → reps → next set's weight

## Data Flow & State Management

### ViewModel Changes (Minimal)

**Existing methods preserved:**
- `completeSet(exerciseId:setId:)` - unchanged
- `updateSet(exerciseId:setId:weight:reps:)` - unchanged
- `calculateProgressiveOverload()` - unchanged

**New helper methods:**
```swift
func getNextIncompleteSet(after setId: UUID, in exerciseId: UUID) -> WorkoutSet?
func allSetsCompleted(in exerciseId: UUID) -> Bool
func getExerciseSummary(_ exerciseId: UUID) -> (sets: Int, volume: Int, progression: Int)
```

### View State (New)

```swift
@State private var collapsedExerciseIds: Set<UUID> = []
@FocusState private var focusedField: UUID?
```

### Clean Separation

**ViewModel handles:**
- Data updates (set completion, weight/reps changes)
- Persistence
- Progressive overload calculations
- Business logic

**View handles:**
- UI state (collapsed exercises, focused fields)
- Animations
- Gesture recognition
- Focus management

**Example interaction flow:**
```swift
func handleSetTap(set: WorkoutSet, exerciseId: UUID) {
    // 1. Update data
    viewModel.completeSet(exerciseId: exerciseId, setId: set.id)
    
    // 2. Update UI
    if let nextSet = viewModel.getNextIncompleteSet(after: set.id, in: exerciseId) {
        focusedField = nextSet.id
    }
    
    // 3. Check auto-collapse
    if viewModel.allSetsCompleted(in: exerciseId) {
        withAnimation(.spring(response: 0.3)) {
            collapsedExerciseIds.insert(exerciseId)
        }
    }
    
    // 4. Haptic
    HapticManager.shared.success()
}
```

## Edge Cases

### No Previous Data (First Time)
```
Bent Over Row
Back • Lats
First time - set your baseline

1  [ ] x [ ]
```
- No "Last" or "Suggested" text
- Clean slate for user
- After completion, becomes baseline for next session

### Partial Previous Session
- Use last completed set as reference
- If Set 1 completed but Set 2-3 weren't, use Set 1 data
- Progressive overload from best completed set

### User Modifies Suggested Weight
```
1  [140] x [8] ✓  (went heavier than 137.5 suggestion)

2  [140] x [ ]    (follows Set 1, not original)
   +5 lb from last week
```
- Subsequent sets follow actual Set 1 weight
- Summary shows actual progression

### Many Sets (6+)
- All visible in expanded state (scrollable)
- Context text only on Set 1 and Set 2
- Sets 3+ minimal
- Collapsed: `6 sets • 4,824 lb`

### Persistence Failure
- Changes cached locally immediately
- Auto-retry save on next interaction
- Warning banner only after 5+ minutes without save
- Never block user from continuing

## Accessibility

### VoiceOver
```swift
.accessibilityElement(children: .combine)
.accessibilityLabel("Set \(set.setNumber), Weight \(weight), Reps \(reps)")
.accessibilityHint("Tap to complete, long press for options")
.accessibilityAddTraits(set.isCompleted ? .isSelected : [])
```

### Dynamic Type
- All fonts use `.system(size:weight:)` with relative sizing
- Minimum 44pt tap target maintained at all sizes
- Test at "Extra Extra Large" setting

### Haptic Feedback
- Success haptic on completion (heavy impact)
- Light haptic on suggestion applied
- Warning haptic on delete
- Respects system settings

### Color Contrast
- All text meets WCAG AA (4.5:1)
- Completed state (50% opacity) maintains 3:1
- Primary color tested in light/dark modes
- Don't rely on color alone (icons + text)

## Migration Strategy

### Backward Compatibility

- No data model changes required
- `WorkoutSet` already has needed fields
- Progressive overload calculation unchanged
- Persistence layer unchanged

### Implementation Phases

**Phase 1: Core Layout**
- Remove column headers
- Redesign SetRow component
- Implement new spacing/sizing
- Basic tap to complete

**Phase 2: Smart Interactions**
- Auto-advance on completion
- Smart field focus
- Long press menu
- Haptic feedback

**Phase 3: Collapse/Expand**
- Auto-collapse logic
- Expand/collapse animations
- Summary calculations
- Manual collapse controls

**Phase 4: Polish**
- Accessibility audit
- Dynamic Type testing
- Haptic refinement
- Edge case handling

### Testing Checklist

- [ ] 4-5 sets visible on standard iPhone screen
- [ ] Tap row completes and advances focus
- [ ] Long press shows action menu
- [ ] Auto-collapse on last set completion
- [ ] Collapsed exercise expands on tap
- [ ] Smart field advance (weight → reps → next set)
- [ ] Progressive suggestions show correctly
- [ ] Previous data displays on Set 1
- [ ] VoiceOver announces all elements
- [ ] Dynamic Type scales correctly
- [ ] Haptics feel natural
- [ ] Dark mode looks good
- [ ] No persistence issues

## Success Metrics

### Quantitative
- Screen density: 4-5 sets visible (vs 2-3)
- Tap reduction: 1 tap to complete (vs 1 tap currently, but larger target)
- Context visibility: 100% (vs ~60% with scrolling)

### Qualitative
- "Feels fast" - minimal cognitive load
- "Feels pro" - clean, purpose-built
- "Encourages progression" - suggestions always visible
- "Gym-ready" - works with sweaty hands, between sets

## Future Enhancements (Out of Scope)

- Rest timer between sets
- Exercise video demos
- Form check notes
- Social sharing of workouts
- AI-powered progressive overload tuning

---

**Design Status:** Approved  
**Next Step:** Implementation plan
