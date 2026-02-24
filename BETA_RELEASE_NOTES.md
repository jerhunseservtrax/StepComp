# StepComp Beta Release Notes

## 🏋️ NEW: Complete Workout Tracking & Progressive Overload System

We're excited to introduce a comprehensive workout tracking feature that helps you build strength systematically and track your progress over time.

---

## 🎯 What's New

### Full Workout Management
- **Create Custom Workouts**: Build your own workout routines with exercises from our extensive exercise library (100+ exercises)
- **Weekly Scheduling**: Assign workouts to specific days of the week for structured programming
- **Flexible Exercise Selection**: Choose from compound lifts, isolation exercises, and accessory movements
- **Set Management**: Add, remove, and customize sets for each exercise

### Smart Progressive Overload
Our intelligent progressive overload system automatically suggests weight and rep increases based on your previous performance:
- ✅ **Completed 12+ reps?** → Suggests +5-10 lbs with slightly lower reps
- ✅ **Completed 8-11 reps?** → Suggests +1-2 reps at same weight
- ✅ **Completed <8 reps?** → Suggests +2-3 reps at same weight
- Tap the green target button to auto-apply suggestions
- Visual indicators show when you've met or exceeded targets

### Live Workout Sessions
- **Real-time Timer**: Track workout duration with pause/resume functionality
- **Set Completion Tracking**: Mark sets complete with satisfying haptic feedback
- **Previous Performance**: See your last workout's weights and reps for each set
- **Dynamic Unit Support**: Works with both imperial (lbs) and metric (kg) units
- **Visual Progress**: Completed sets are highlighted with color-coded backgrounds

### Advanced Progress Metrics

#### Estimated 1RM Calculator
- Automatic calculation of your estimated one-rep max for big three lifts (Squat, Bench, Deadlift)
- Uses the Epley formula for accuracy
- Updates in real-time as you complete workouts
- Displays in your preferred unit (lbs/kg)

#### Body Composition & Activity
- **Weight Tracking**: Syncs with HealthKit or manual entry
- **Daily Steps**: Real-time step count integration
- Side-by-side cards for quick glancing

#### Consistency Heatmap
- 90-day workout consistency visualization
- Color-coded calendar showing workout frequency
- Track current streak and total sessions
- Motivates adherence to your program

### Comprehensive Workout History

#### Date-Based Navigation
- Horizontal calendar for easy date selection
- Visual indicators show which days have scheduled workouts
- Quick navigation to any date

#### Completed Exercises (NEW)
- **Expandable Cards**: Tap to view full workout details
- **Session Metadata**: See completion time, duration, and exercise count
- **Detailed Breakdown**: Every set, weight, and rep recorded
- **Quick Edit**: Modify completed workouts if you need to correct data
- **Date-Specific**: Only shows workouts completed on the selected date

#### Recent Logs
- See your 3 most recent workouts at a glance
- Shows best set (highest estimated 1RM) from each session
- **NEW PR Badge**: Automatically detects when you hit a personal record
- Quick access to edit any historical workout

### Workout Widgets (iOS Home Screen)
- Live workout tracker widget shows current exercise and timer
- Quick glance at workout progress without opening the app
- Updates in real-time during active sessions

---

## 🔧 Technical Improvements

### Weight Unit Standardization (FIXED)
- **Issue**: Weights were displaying incorrectly (155 lbs showing as 342 lbs)
- **Fix**: All workout weights now stored in kilograms (base unit) and properly converted for display
- **Migration**: Automatic one-time migration converts all existing workout data
- **Result**: Weights now display accurately in both imperial and metric units

### Unit Preference System
- Seamless switching between metric (kg/cm) and imperial (lbs/ft) units
- All workout data automatically converts based on user preference
- Consistent unit display throughout the app
- Settings sync across all workout features

---

## 📱 User Interface Updates

### Reorganized Workout Screen
The workout page has been completely redesigned for better information hierarchy:

1. **Calendar First**: Horizontal date selector at the top for quick navigation
2. **Today's Workout**: Scheduled workouts for selected date prominently displayed
3. **Progress Metrics**: 1RM estimates, weight, and steps cards
4. **Consistency Tracker**: Visual heatmap of your workout adherence
5. **Completed Exercises**: Detailed breakdown of workouts done on selected date
6. **Recent Activity**: Historical logs at the bottom for broader context

### Visual Enhancements
- Color-coded set completion indicators
- Progressive overload targets highlighted in green
- PR badges for personal records
- Smooth expand/collapse animations
- Dark mode optimized throughout

---

## 🎮 How to Use

### Creating Your First Workout
1. Tap the workout tab (dumbbell icon)
2. Tap "+" to create a new workout
3. Name your workout (e.g., "Upper Body A")
4. Add exercises from the library
5. Set number of sets for each exercise
6. Assign to days of the week
7. Save and you're ready to go!

### Starting a Workout
1. Navigate to the workout tab
2. Find your scheduled workout for today
3. Tap "Start Workout"
4. Enter weight and reps for each set
5. Tap the blue checkmark to complete each set
6. See progressive overload suggestions automatically
7. Tap "Finish Workout" when done

### Tracking Progress
- **View 1RM**: Check the "Estimated 1RM" card on workout tab
- **Check Consistency**: See the heatmap showing your workout frequency
- **Review History**: Scroll to "Recent Logs" or select a date to see completed exercises
- **Edit Sessions**: Tap the gear icon on any workout to modify data

---

## 🧪 What to Test

### Critical Flows
- [ ] Create a workout with 3-5 exercises
- [ ] Complete a full workout session
- [ ] View progressive overload suggestions
- [ ] Check estimated 1RM calculations
- [ ] Switch between imperial and metric units
- [ ] Edit a completed workout
- [ ] Navigate through different dates on the calendar
- [ ] Expand/collapse completed exercise cards

### Edge Cases
- [ ] Start and pause a workout
- [ ] Add extra sets during a workout
- [ ] Delete sets from a workout
- [ ] Cancel a workout mid-session
- [ ] Very heavy weights (500+ lbs / 225+ kg)
- [ ] Very high rep counts (20+ reps)
- [ ] Completing same workout multiple times in one day

### Data Accuracy
- [ ] Weight conversions (155 lbs = 70 kg, verify both ways)
- [ ] 1RM calculations (e.g., 225 lbs × 5 reps should estimate ~254 lbs)
- [ ] Progressive overload suggestions make sense
- [ ] Workout history shows correct dates and times
- [ ] Consistency heatmap matches actual workout dates

---

## 🐛 Known Issues & Limitations

- Progressive overload suggestions are currently only weight/rep based (doesn't factor in fatigue or deloads)
- 1RM calculation only works for rep ranges 1-10 (accuracy decreases at higher reps)
- Widget updates may have slight delay during active workouts
- Cannot currently copy workouts or create templates

---

## 💬 Feedback Needed

Please report any issues you encounter, especially:
- Weight calculation errors
- UI glitches or performance issues
- Confusing workflows
- Missing features you'd find valuable
- Any crashes or data loss

We're particularly interested in:
- Is the progressive overload system helpful?
- Does the workout flow feel natural?
- Are the metrics (1RM, consistency) motivating?
- Is the calendar navigation intuitive?

---

## 🚀 Coming Soon

- Workout templates and programs
- Rest timer between sets
- Superset support
- Exercise video demonstrations
- Export workout data
- Detailed analytics and charts
- Social features (share PRs with friends)

---

Thank you for beta testing! Your feedback is crucial in making StepComp the best fitness companion app. 💪

**Report Issues**: Use the in-app feedback form (Settings > Support > Send Feedback)
