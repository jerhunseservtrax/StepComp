# FitComp Feature Tracker

> Comprehensive catalog of all features in the FitComp fitness competition app (formerly StepComp).
> Last updated: 2026-04-13 (v5)

---

## Table of Contents

- [Navigation & Tabs](#navigation--tabs)
- [Home Dashboard](#home-dashboard)
- [Workouts System](#workouts-system)
- [Challenges](#challenges)
- [Social & Friends](#social--friends)
- [Metrics Dashboard](#metrics-dashboard)
- [Settings & Profile](#settings--profile)
- [Onboarding](#onboarding)
- [Widgets & Live Activities](#widgets--live-activities)
- [Backend Services](#backend-services)
- [Utilities & Infrastructure](#utilities--infrastructure)
- [App Rebranding](#app-rebranding)

---

## App Rebranding

| Feature | File(s) | Description |
|---------|---------|-------------|
| StepComp → FitComp | All files | Complete app rename across codebase, URL schemes, keychain keys |
| URL Scheme Update | `DeepLinkRouter.swift`, `Info.plist` | Changed from `stepcomp://` to `fitcomp://` |
| Color System Overhaul | `StepCompColors.swift` | Unified yellow primary (#FACC15/#EAB308) across light/dark modes |
| Tab Bar Accent | `MainTabView.swift` | Changed tab selection indicator from yellow to blue |
| Color System Rename | `StepCompColors.swift` → `FitCompColors` | Renamed color references across all views |

---

## Navigation & Tabs

| Feature | File(s) | Description |
|---------|---------|-------------|
| 5-Tab Navigation | `MainTabView.swift` | Home, Workouts, Challenges, Metrics, Settings |
| Deep Link Routing | `DeepLinkRouter.swift`, `AppRoute.swift` | Route handling for leaderboard, profile, create/join challenge, OAuth callbacks |
| Invite Token Validation | `DeepLinkRouter.swift` | Validates invite tokens (8-128 chars, alphanumeric) before processing |
| Haptic Tab Switching | `HapticManager.swift` | Tactile feedback on tab changes |

---

## Home Dashboard

| Feature | File(s) | Description |
|---------|---------|-------------|
| Daily Step Count | `HomeDashboardView.swift` | Real-time step count display with HealthKit |
| Step Speedometer | `StepSpeedometerView.swift` | Animated radial progress gauge |
| Daily Goal Card | `DailyGoalCard.swift` | Progress toward daily step goal with goal line, over-100% progress support |
| Goal Celebration | `GoalCelebrationView.swift` | Auto-triggered celebration when daily goal is reached |
| Activity Chart | `ActivityChartView.swift` | Step history visualization over 30 days |
| Date Selector | `DateSelectorView.swift` | View historical data by date |
| Date Selector Default Position | `DateSelectorView.swift`, `HomeDashboardView.swift` | Date strip now opens on current (rightmost) date and allows scrolling left for older dates |
| Daily Pulse Stats | `DailyPulseStatsView.swift` | Today's key fitness metrics at a glance |
| Dashboard Header | `DashboardHeader.swift` | Personalized greeting with user info |
| Active Challenge Card | `ActiveChallengeCard.swift` | Current challenge summary on home screen |
| Stacked Challenges | `StackedChallengesView.swift` | Compact multi-challenge overview |
| Personal Stats Card | `PersonalStatsCard.swift` | User stats snapshot |
| Upcoming Workout Card | `UpcomingWorkoutCard.swift` | Next scheduled workout preview |
| Create Challenge CTA | `CreateChallengeCTA.swift` | Prompt to create first challenge |
| Add Friends CTA | `AddFriendsCTA.swift` | Prompt to add friends |
| Pull-to-Refresh | `HomeDashboardView.swift` | Manual data refresh |
| Auto-Refresh | `DashboardViewModel.swift` | Periodic live updates |
| Steps/Workouts Toggle | `HomeDashboardView.swift` | Segmented picker to switch views |
| Simplified Dashboard Init | `DashboardViewModel.swift` | Lazy service injection; deferred data loading until userId available |
| Paged Dashboard Layout | `HomeDashboardView.swift` | TabView-based paged layout for home sections |
| Metric Pairs | `DashboardViewModel.swift` | Weekly and long-term scope metric pairs for dashboard stats |

---

## Workouts System

### Workout Management

| Feature | File(s) | Description |
|---------|---------|-------------|
| Create Workouts | `CreateWorkoutView.swift` | Custom workout builder with exercise selection |
| Edit Workouts | `EditWorkoutView.swift` | Modify existing workout templates |
| Delete Workouts | `WorkoutsView.swift` | Remove workouts with confirmation |
| Workout Templates | `WorkoutTemplates.swift` | Predefined splits (PPL, Upper/Lower, Full Body, etc.) |
| Suggested Workouts | `SuggestedWorkoutsView.swift` | Algorithm-powered recommendations by muscle group |
| Recurring Scheduling | `CreateWorkoutView.swift` | Schedule workouts for recurring days of the week |
| One-Time Scheduling | `CreateWorkoutView.swift` | Schedule a workout for a specific date (non-recurring) |

### Exercise Library

| Feature | File(s) | Description |
|---------|---------|-------------|
| Exercise Picker | `ExercisePickerView.swift` | Searchable exercise database (100+ exercises) |
| Exercise Demos | `ExerciseDemoView.swift` | Exercise demonstration/instructions |
| Muscle Group Targeting | `Exercise.swift` | 10+ muscle groups supported |
| ExerciseDB ID Mapping | `Exercise.swift` | Static lookup table mapping 100+ exercise names to ExerciseDB IDs for images/demos |
| ExerciseDB Integration | `ExerciseDBService.swift` | External exercise images and data |

### Active Workout Sessions

| Feature | File(s) | Description |
|---------|---------|-------------|
| Workout Timer | `ActiveWorkoutView.swift` | Real-time session duration tracking |
| Set/Rep Tracking | `ActiveWorkoutView.swift` | Log sets, reps, and weight per exercise |
| Custom Number Pad | `ActiveWorkoutView.swift` | Built-in number pad (replaces system keyboard) |
| Pause/Resume | `ActiveWorkoutView.swift` | Pause and continue workout |
| Rest Timer | `RestTimerOverlayView.swift`, `RestTimerManager.swift` | Configurable rest intervals (30s–5min) with presets |
| Rest Timer Alerts | `RestTimerManager.swift` | Visual, haptic, sound, and push notification alerts |
| Smart Rest Suggestions | `WorkoutAnalyticsEngine.swift` | Auto-suggest rest duration based on exercise intensity and set exertion |
| Progressive Overload | `WorkoutAnalyticsEngine.swift` | Trend detection (progressing/plateau/regressing), 1RM estimation, overload recommendations |
| Workout Persistence | `WorkoutViewModel.swift` | Save/restore active workout state across app lifecycle |
| Workout Summary | `WorkoutSummaryView.swift` | Post-workout stats (duration, exercises, sets, calories) |
| Session History | `CompletedSessionDetailView.swift` | View past workout details |
| Edit Sessions | `EditCompletedSessionView.swift` | Modify completed session data |
| Workout Progress | `WorkoutProgressView.swift` | Track progress over time |

### Weight Tracking

| Feature | File(s) | Description |
|---------|---------|-------------|
| Log Weight | `WeightEntryView.swift` | Daily weight entries |
| Weight Graph | `WeightTrackingCard.swift` | Weight history visualization |
| Weight Progress | `WeightViewModel.swift` | Trend tracking over time |

### Transformation Photos

| Feature | File(s) | Description |
|---------|---------|-------------|
| Add Photo Sets | `AddTransformationPhotoSetView.swift` | Before/after style photo capture |
| Photo Gallery | `TransformationPhotoGalleryView.swift` | Timeline view of all photos |
| Photo Cards | `TransformationPhotoCard.swift` | Photo preview cards in workouts view |
| Photo Management | `TransformationPhotoViewModel.swift` | Add, delete, organize photos by date |

### Food & Nutrition Logging

| Feature | File(s) | Description |
|---------|---------|-------------|
| Food Search | `AddMealView.swift`, `FoodSearchSection.swift`, `FoodSearchResultsSection.swift`, `USDAFoodService.swift` | USDA food database search |
| Meal Logging | `FoodLogViewModel.swift`, `AddMealView.swift`, `MealEntryRow.swift`, `FoodLogMealSectionView.swift` | Log meals with calories and macros |
| Daily Summary | `FoodLogView.swift`, `FoodLogSummaryCard.swift`, `FoodLogDailySummaryHeader.swift` | Calorie/macro progress rings |
| Calorie Calculator | `CalorieCalculatorView.swift`, `CalorieCalculator.swift` | BMR/TDEE estimation with activity level |
| Macro Targets | `FoodLogViewModel.swift` | Protein, carbs, fat goal tracking |
| CalorieNinjas API | `CalorieNinjasService.swift` | Alternative nutrient calculation |
| FatSecret API | `FatSecretFoodService.swift` | Alternative food database |

---

## Challenges

| Feature | File(s) | Description |
|---------|---------|-------------|
| Create Challenge | `CreateChallengeView.swift`, `CreateChallengeViewModel.swift` | Name, description, dates, step target, image, privacy |
| Privacy Settings | `PrivacyToggleView.swift` | Public/private challenge toggle |
| Friends-Only Mode | `FriendsOnlyToggleView.swift` | Restrict to friends |
| Category Selection | `CreateChallengeView.swift` | Short-Term, Friends, Corporate, Marathon, Fun |
| Challenge Images | `ChallengeImageBackground.swift` | Unsplash-powered background images |
| Invite Codes | `CreateChallengeViewModel.swift` | 8-char shareable codes for private challenges |
| Active Challenges Tab | `ActiveChallengesTab.swift` | Current challenges list with progress |
| Discover Tab | `DiscoverChallengesTab.swift` | Browse/search public challenges |
| Archived Tab | `ArchivedChallengesTab.swift` | Historical completed challenges |
| Join Challenge | `JoinChallengeView.swift`, `JoinChallengeViewModel.swift` | Join via code or discover |
| Group Preview | `GroupPreviewCard.swift` | Challenge preview before joining |
| Challenge Summary | `ChallengeSummaryView.swift` | Challenge details and stats |
| Challenge Celebration | `ChallengeCelebrationView.swift` | Completion celebration screen |
| Leaderboard Preview | `LeaderboardPreview.swift` | Preview ranking before joining |
| Invite Friends | `InviteFriendsToChallengeView.swift` | Invite friends to existing challenges |

### Group Details

| Feature | File(s) | Description |
|---------|---------|-------------|
| Group Info | `GroupDetailsView.swift` (coordinator), `GroupDetailsMemberContentView.swift`, `GroupDetailsChallengePreviewView.swift`, tab/header/countdown files in `Screens/GroupDetails/`, `GroupViewModel.swift` | Challenge details, stats, management; large SwiftUI surface split into focused subviews |
| Group Settings | `GroupSettingsView.swift` | Creator admin controls |
| Members List | `MembersListView.swift`, `MembersView.swift` | View/manage participants |
| Group Chat | `ChallengeChatView.swift` | In-challenge messaging |
| Leave Challenge | `GroupViewModel.swift` | Leave with proper DB cleanup |

---

## Social & Friends

| Feature | File(s) | Description |
|---------|---------|-------------|
| Friends List | `FriendsView.swift`, `FriendsViewModel.swift` | View current friends |
| Add Friends | `AddFriendsView.swift` | Search public profiles by username |
| Paginated Discovery | `FriendsViewModel.swift` | Infinite scroll for discovering new users with offset/limit pagination (30 per page) |
| Friend Requests | `PendingRequestRow.swift` | Send/accept/decline/cancel requests |
| Public Profile Toggle | `SettingsView.swift` | Control discoverability |
| Invite Accept | `InviteAcceptView.swift` | Accept friend/challenge invitations |

### Chat System

| Feature | File(s) | Description |
|---------|---------|-------------|
| Challenge Chat | `ChallengeChatView.swift`, `ChallengeChatViewModel.swift` | Real-time group messaging via Supabase postgresChange streams with polling fallback |
| Chat List | `ChatListView.swift`, `ChatListViewModel.swift` | Overview of all chat conversations |
| Message Actions | `ChallengeChatViewModel.swift` | Send, delete, auto-scroll |

### Leaderboard

| Feature | File(s) | Description |
|---------|---------|-------------|
| Daily Leaderboard | `LeaderboardView.swift`, `LeaderboardViewModel.swift` | Today's step rankings |
| All-Time Leaderboard | `LeaderboardView.swift` | Cumulative step rankings |
| Podium Display | `LeaderboardView.swift` | 1st/2nd/3rd place highlights |
| Leaderboard Row | `LeaderboardRow.swift` | Individual rank display |
| Scope Toggle | `LeaderboardScope.swift` | Daily vs. All-Time switch |

### Inbox

| Feature | File(s) | Description |
|---------|---------|-------------|
| Notifications | `InboxView.swift` | Challenge invites, friend requests |
| Accept/Decline | `InboxView.swift` | Action buttons on notifications |
| Unread Count | `InboxView.swift` | Badge for unread items |

---

## Metrics Dashboard

| Feature | File(s) | Description |
|---------|---------|-------------|
| Killer Scores | `Screens/Metrics/` | Multi-pillar analytics dashboard |
| Today Pillar | Metrics views | Steps, workout duration, calories |
| Performance Pillar | Metrics views | Estimated 1RM, PRs, volume, progression |
| Workout-Only Metrics View | `MetricsView.swift`, `InsightsPillarSection.swift` | Metrics page now focuses on workout-derived sections (Performance + workout-centric Insights) |
| Insights Weekly Workout Report | `InsightsPillarSection.swift`, `ComprehensiveMetricsStore.swift` | Weekly report surfaces strength change availability, compared lifts, and workouts completed |
| Time Period Selection | Metrics views | Today, Week, Month, All-time views |
| Workout Analytics | `WorkoutAnalyticsEngine.swift` | Advanced workout performance analysis |
| Profile Metrics | `ProfileMetricsBuilder.swift` | Metrics builder for profile display |
| Comprehensive Store | `ComprehensiveMetricsStore.swift` | Local metrics caching |
| Strength Trend Accuracy | `ComprehensiveMetricsStore.swift`, `MetricsViewModel.swift`, `PerformancePillarSection.swift`, `ComprehensiveMetrics.swift` | Strength trend compares equal recent/prior windows, supports insufficient-data fallback (N/A), and shows comparable lift count |
| Exercise History Section | `ExerciseHistorySection.swift`, `MetricsViewModel.swift`, `MetricsView.swift` | Collapsible metrics section showing top 5 exercises always visible with per-exercise volume trend sparklines and expandable full history list |
| App Store Privacy Hardening | `Info.plist`, `PrivacyInfo.xcprivacy` | Pre-submission hardening removes unsupported background audio mode and declares collected data types for App Review compliance |

---

## Settings & Profile

### Profile

| Feature | File(s) | Description |
|---------|---------|-------------|
| User Profile | `ProfileView.swift`, `ProfileViewModel.swift` | Stats, avatar, achievements |
| Profile Card | `UserProfileCard.swift` | User info summary card |
| Achievements Grid | `AchievementsGrid.swift` | Badge/achievement display |
| Friends Section | `FriendsSection.swift` | Friends list on profile |
| Profile Settings | `ProfileSettingsView.swift` | Edit username, display name, height, weight |
| Avatar Selection | `AvatarSelectionView.swift` | Choose profile avatar |

### Settings

| Feature | File(s) | Description |
|---------|---------|-------------|
| Settings screen (coordinator) | `SettingsView.swift`, `SettingsViewModifiers.swift` | Layout, HealthKit load/streak math, sign-out/delete flows, lifecycle & preference sync modifiers |
| Settings layout & profile header | `SettingsLayoutViews.swift` | Mobile header, iPad sidebar, profile section, mini stat cards |
| Settings grid content | `SettingsMainContent.swift` | Scroll/grid of cards, log out / delete account actions, footer |
| Connectivity | `SettingsConnectivityCard.swift` | HealthKit sync, Apple Watch row |
| Notifications card | `SettingsNotificationsCard.swift` | Permission UI and notification toggles |
| App preferences card | `SettingsPreferencesCard.swift` | Dark mode, units, rest timer alerts, daily step goal sheet entry |
| Support & legal | `SettingsSupportLegalCard.swift` | Feedback, FAQ, privacy, about sheets |
| Shared settings UI | `SettingsSharedComponents.swift` | `SettingsCard`, `SettingItemRow`, `FunFooter`, layout helper |
| Measurement / step goal sheets | `SettingsMeasurementSheets.swift`, `SettingsDailyStepGoalSheet.swift` | Height/weight editor (pickers), daily step goal editor |
| Dark Mode Toggle | `SettingsPreferencesCard.swift`, `ThemeManager.swift` | Light/dark theme switching |
| Unit Preference | `SettingsPreferencesCard.swift`, `UnitPreferenceManager.swift` | Metric/imperial system |
| HealthKit Toggle | `SettingsConnectivityCard.swift` | Enable/disable HealthKit integration |
| Notification Prefs | `SettingsNotificationsCard.swift` | Daily recap, leaderboard alerts, motivational nudges |
| Sign Out | `SettingsView.swift`, `SettingsMainContent.swift`, `SessionViewModel.swift` | Logout with proper cleanup |
| Delete Account | `DeleteAccountConfirmationView.swift`, `SettingsView.swift`, `SettingsViewModifiers.swift` | Account deletion with confirmation |
| Streak Display | `SettingsView.swift`, `SettingsLayoutViews.swift` | Current step streak (30-day lookback) |

### Feedback System

| Feature | File(s) | Description |
|---------|---------|-------------|
| Feedback Board | `FeedbackBoardView.swift`, `FeedbackBoardViewModel.swift` | Community feature requests & bug reports |
| Feedback Categories | `FeedbackModels.swift` | Bug, Feature, Suggestion types |
| Vote System | `FeedbackBoardViewModel.swift` | Upvote/downvote feedback items |
| Feedback CRUD | `FeedbackBoardViewModel.swift` | Create, edit, delete own posts |

### Legal & Support

| Feature | File(s) | Description |
|---------|---------|-------------|
| Terms of Service | `LegalAndSupportViews.swift` | In-app ToS display |
| Privacy Policy | `LegalAndSupportViews.swift` | In-app privacy policy |
| Support/Help | `SupportViews.swift` | Contact and help resources |
| Feedback Sheets | `FeedbackSheets.swift` | Quick feedback submission |

---

## Onboarding

| Feature | File(s) | Description |
|---------|---------|-------------|
| Welcome Screen | `WelcomeView.swift` | App introduction and value proposition |
| Health Permission | `HealthPermissionView.swift` | HealthKit authorization request |
| Goal Setting | `GoalSettingView.swift` | Daily step goal configuration |
| Avatar Selection | `AvatarSelectionView.swift` | Profile picture/avatar choice |
| First Win | `FirstWinView.swift` | First achievement celebration |
| Sign In | `SignInView.swift`, `SignInOnboardingLandingView.swift`, `SignInOnboardingView+Auth.swift`, `EmailAuthSheet.swift`, `OnboardingSignUpView.swift`, `EmailSignInFormView.swift`, `ForgotPasswordSheet.swift`, `PasswordResetView.swift`, `AppleSignInDelegate.swift` | Apple Sign In, email sign-up/sign-in, forgot/reset password (split into focused files; coordinator in `SignInView.swift`) |
| Onboarding Flow | `OnboardingFlowView.swift` | 6-step sequential flow |

---

## Widgets & Live Activities

| Feature | File(s) | Description |
|---------|---------|-------------|
| Workout Widget | `WorkoutWidget.swift` | Home screen widget (Small, Medium, Accessory) |
| Widget Provider | `WorkoutWidgetProvider.swift` | Timeline data for widgets |
| Widget View | `WorkoutWidgetView.swift` | Widget UI rendering |
| Widget Entry | `WorkoutWidgetEntry.swift` | Widget data model |
| Widget Store | `WorkoutWidgetStore.swift` | Shared data between app and widget |
| Live Activity | `WorkoutLiveActivity.swift` | Lock Screen / Dynamic Island workout tracking |
| Live Activity Manager | `WorkoutLiveActivityManager.swift` | Start/update/end Live Activities |
| Live Activity Recovery | `WorkoutLiveActivityManager.swift` | Adopt existing system activities after app relaunch; update-or-create on start to prevent duplicates |
| Workout Attributes | `WorkoutAttributes.swift` | Live Activity data schema |

---

## Backend Services

| Feature | File(s) | Description |
|---------|---------|-------------|
| Supabase Auth | `AuthService.swift` | Singleton auth with Keychain persistence, Apple Sign In, auth state listener |
| Auth State Listener | `AuthService.swift` | Real-time auth state monitoring via Supabase events with automatic session recovery |
| Auth Recovery | `RootView.swift` | Debounced periodic auth state recovery checks on foreground transitions |
| Automatic Metrics Sync | `RootView.swift` | One-shot metrics sync on foreground/auth changes with dedup flag |
| Singleton Services | `HealthKitService.swift`, `ChallengeService.swift` | Shared singleton instances to prevent state desync |
| Supabase Client | `SupabaseClient.swift` | Database client configuration |
| Step Sync | `StepSyncService.swift` | Sync steps to server with fraud detection, RPC fallback |
| Challenge Service | `ChallengeService.swift` | CRUD for challenges, invites, leaderboards |
| Friends Service | `FriendsService.swift` | Friendship management, profile search |
| Metrics Service | `MetricsService.swift` | Sync workouts, weight, nutrition to server |
| HealthKit Service | `HealthKitService.swift` | Steps, distance, calories, weight, and expanded health data |
| Resting Heart Rate | `HealthKitService.swift` | Recovery indicator from HealthKit |
| Heart Rate Variability | `HealthKitService.swift` | HRV (SDNN) analysis for recovery tracking |
| VO2 Max | `HealthKitService.swift` | Aerobic capacity measurement |
| Sleep Analysis | `HealthKitService.swift` | Sleep hours averaging and quality scoring |
| Cardio Workout Metrics | `HealthKitService.swift` | Enhanced cardio tracking with workout type detection |
| Notification Manager | `NotificationManager.swift` | Push notification auth, scheduling, APNs |
| Challenge Notifications | `ChallengeNotificationService.swift` | Challenge-specific alerts |
| Step Goal Notifications | `StepGoalNotificationService.swift` | Local milestone alerts at 50% and 100% of daily step goal |
| Edge Functions | `EdgeFunctionService.swift` | Secure backend operations via Supabase Edge Functions |
| Unsplash Service | `UnsplashService.swift` | Challenge background images |

---

## Utilities & Infrastructure

| Feature | File(s) | Description |
|---------|---------|-------------|
| Theme Manager | `ThemeManager.swift` | Dark/light mode management |
| Unit Preferences | `UnitPreferenceManager.swift` | Full metric/imperial system (kg/lbs, km/mi, cm/ft-in) with height/weight storage converters, distance formatting, and display name helpers |
| Haptic Manager | `HapticManager.swift` | Haptic feedback patterns |
| Keychain Store | `KeychainStore.swift` | Secure credential storage with kSecAttrService scoping and OSStatus error handling |
| Retry Utility | `RetryUtility.swift` | Exponential backoff retry logic |
| Offline Cache | `OfflineCacheService.swift` | Generic disk-backed Codable cache with fetch-with-fallback for offline resilience |
| Cached Async Image | `CachedAsyncImage.swift` | Image caching for remote images (used in ProfileView, etc.) |
| Reaction Effects | `ReactionEffectManager.swift` | Celebration/reaction animations |
| Avatar View | `AvatarView.swift` | Reusable avatar component |
| Card Styles | `CardStyle.swift`, `FitCompCardStyles.swift` | Consistent card UI components |
| Color System | `FitCompColors.swift`, `PlatformColors.swift` | Custom color palette |
| Font System | `FitCompFonts.swift` | Custom typography |
| Progress Styles | `FitCompProgressStyles.swift` | Progress indicator styles |
| Extensions | `Extensions.swift` | Swift utility extensions |
| Notification Names | `NotificationNames.swift` | Notification center constants |
| App Delegate | `AppDelegate.swift` | APNs registration, lifecycle hooks |
