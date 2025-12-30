# StepComp

A modern iOS app for step tracking, challenges, and friendly competition built with SwiftUI and Supabase.

## Features

- 🏃 **Step Tracking**: Real-time step tracking via HealthKit integration
- 🏆 **Challenges**: Create and join step challenges with friends
- 📊 **Leaderboards**: Daily, weekly, and all-time leaderboards with real-time updates
- 👥 **Social**: Friend system and group challenges
- 🔐 **Authentication**: Email, Apple Sign In, and Google Sign In via Supabase
- 📱 **Modern UI**: Beautiful SwiftUI interface with dark mode support

## Tech Stack

- **Frontend**: SwiftUI (iOS)
- **Backend**: Supabase (PostgreSQL, Auth, Realtime)
- **Health Data**: HealthKit
- **Architecture**: MVVM with Combine

## Requirements

- iOS 15.0+
- Xcode 14.0+
- Swift 5.7+
- Supabase account

## Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/YOUR_USERNAME/StepComp.git
   cd StepComp
   ```

2. **Configure Supabase**
   - Create a Supabase project at https://supabase.com
   - Update `StepComp/Services/SupabaseClient.swift` with your project URL and API key
   - Run the database setup script: `SUPABASE_DATABASE_SETUP_UPDATED.sql`

3. **Configure Apple Sign In** (Optional)
   - Follow instructions in `APPLE_SIGN_IN_SUPABASE_SETUP.md`
   - Add your `.p8` key to the `p8/` folder

4. **Open in Xcode**
   ```bash
   open StepComp.xcodeproj
   ```

5. **Build and Run**
   - Select your target device
   - Press ⌘R to build and run

## Project Structure

```
StepComp/
├── App/              # App entry point and root views
├── Models/           # Data models
├── Services/         # Business logic (Auth, Challenges, HealthKit)
├── ViewModels/       # MVVM view models
├── Screens/          # SwiftUI views
├── Navigation/       # Navigation routing
└── Utilities/        # Helper functions and extensions
```

## Database Schema

- `profiles`: User profiles with height, weight, and preferences
- `challenges`: Challenge metadata
- `challenge_members`: User participation and step tracking
- `friends`: Friend relationships

See `SUPABASE_DATABASE_SETUP_UPDATED.sql` for full schema.

## Documentation

- `QUICK_SETUP_GUIDE.md`: Quick start guide
- `SUPABASE_SETUP.md`: Supabase configuration
- `CHALLENGE_SYSTEM_EXPLANATION.md`: How challenges work
- `SUPABASE_CHALLENGES_IMPLEMENTATION.md`: Challenge implementation details

## License

[Add your license here]

## Contributing

[Add contribution guidelines here]

