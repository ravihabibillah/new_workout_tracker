# Changelog

All notable changes to IronLog are documented in this file.

## [Unreleased]

### Added
- **Edge-to-edge display** for Android — app now draws behind status bar and navigation bar
- **Loading indicator** on login button during Google Sign-In
- **Logout functionality** via settings menu on home screen with confirmation dialog
- **Quick Workout mode** — start a workout without selecting a program, with option to save as new program
- **Manual rest timer** with vibration feedback, +/-15s adjustment buttons
- **Rest timer configuration** per program (enable/disable, custom duration)
- **Exercise progress screen** with interactive charts and date range filters
- **Personal records tracking** — max weight, volume, and reps per exercise
- **Local caching with Hive** for exercise library (7-day TTL) and user programs
- **Global exercise library** with 140+ pre-seeded exercises synced from Firestore
- **Shimmer loading effects** replacing plain circular progress indicators
- **Unit tests** — 237 tests covering entities, models, repositories, viewmodels, and Hive caches

### Changed
- Replaced Material Icons with Font Awesome icons across all screens
- Improved timer picker UI with labels below fields
- Separated "close workout" (back navigation) from "cancel workout" (delete session)
- Success snackbar now uses green background for better visibility

### Fixed
- Programs now auto-load on home screen without requiring pull-to-refresh
- Fixed TextEditingController disposed error in save-as-program dialog
- Fixed navigation after deleting program from detail screen
- Deferred program loading until user is authenticated
- Removed duplicated code in workout_session_entity causing compilation errors

## [1.0.0] - 2026-05-01

### Added
- Initial release of IronLog
- **Google Authentication** with Firebase Auth
- **Program Management** — create, edit, delete workout programs
- **Active Workout Tracking** — log sets, reps, and weight in real-time
- **Workout History** — view past completed workouts
- **Progress Charts** — visualize strength gains with fl_chart
- **Dark Mode UI** — minimalist sports-themed design
- **Cloud Sync** — all data synced to Firebase Firestore
- Clean Architecture with MVVM pattern
- Riverpod for state management
- GoRouter for navigation
