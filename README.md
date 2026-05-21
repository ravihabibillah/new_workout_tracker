# Heft - Weightlifting Progress Tracker

A Flutter app for tracking weightlifting workouts, managing programs, and visualizing strength progress.

## Features

- **Google Authentication** — Secure sign-in with Firebase Auth
- **Program Management** — Create, edit, and organize workout programs
- **Quick Workout** — Start a workout without a program, save as program when done
- **Active Workout Tracking** — Log sets, reps, and weight in real-time
- **Rest Timer** — Per-program countdown timer with skip/extend/vibration options
- **Progress Charts** — Visualize strength gains with interactive charts
- **Personal Records** — Track max weight, volume, and reps per exercise
- **Workout History** — Browse all past completed sessions
- **Local Cache** — Exercise library and programs cached with Hive for offline access
- **Dark Mode UI** — Minimalist sports-themed design
- **Cloud Sync** — All data synced to Firebase Firestore
- **Edge-to-Edge** — Full-screen display on Android

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.27.1 / Dart 3.6.0 |
| State Management | Riverpod 2.6.1 (code generation) |
| Navigation | GoRouter 14.x |
| Backend | Firebase Auth + Cloud Firestore |
| Local Cache | Hive 2.x |
| Charts | fl_chart 0.69.x |
| Architecture | Clean Architecture + MVVM |

## Project Structure

```
lib/
├── core/               # Constants, theme, router, utils, errors
├── data/               # Models, datasources (Firebase + Hive), repository implementations
├── domain/             # Entities, repository interfaces, use cases
└── presentation/       # ViewModels (Riverpod), screens

test/
├── core/               # Validators, errors
├── data/               # Model, repository, and Hive cache tests
└── presentation/       # ViewModel tests with ProviderContainer
```

## Prerequisites

- Flutter SDK 3.27.1+
- Dart SDK 3.6.0+
- Firebase project with Firestore and Authentication enabled
- Google Sign-In configured for your Firebase project

## Setup

### 1. Clone and install dependencies

```bash
git clone <repository-url>
cd workout_tracker
flutter pub get
```

### 2. Firebase Setup

1. Go to [Firebase Console](https://console.firebase.google.com/) and create a project
2. Enable **Authentication** → Sign-in method → **Google**
3. Enable **Cloud Firestore** → Create database

Install FlutterFire CLI and configure:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

This generates `lib/firebase_options.dart` and links your Firebase project.

### 3. Google Sign-In — Android

Get your SHA-1 fingerprint and add it to Firebase Console → Project Settings → Your apps → Android:

```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

Download the updated `google-services.json` and place it in `android/app/`.

### 4. Google Sign-In — iOS

1. Download `GoogleService-Info.plist` from Firebase Console
2. Add to `ios/Runner/` in Xcode
3. Add the reversed client ID to `ios/Runner/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.googleusercontent.apps.YOUR-CLIENT-ID</string>
        </array>
    </dict>
</array>
```

### 5. Generate Riverpod code

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 6. Deploy Firestore rules and indexes

```bash
firebase deploy --only firestore:rules --project workout-tracker-ead9b
firebase deploy --only firestore:indexes --project workout-tracker-ead9b
```

### 7. Run the app

```bash
flutter run
```

## Development

### Code generation (watch mode)

```bash
dart run build_runner watch --delete-conflicting-outputs
```

### Run tests

```bash
flutter test
```

### Analyze

```bash
dart analyze lib/
```

### Clean build

```bash
flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

## Firestore Structure

```
exercises/{exerciseId}          ← global exercise library (shared, ~140 pre-seeded)
exercises_meta/seed             ← seed marker (written once globally)
users/{userId}/programs/        ← per-user workout programs
users/{userId}/sessions/        ← per-user workout sessions (active + completed)
users/{userId}                  ← user preferences (preferredUnit, defaultRestTime)
```

## Local Cache (Hive)

| Cache | Box | Scope | Strategy |
|-------|-----|-------|----------|
| Exercise library | `exercise_library` | Global | TTL 7 days, background sync |
| Programs | `programs` | Per user | Mutation-driven, clear on logout |

## Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /exercises/{exerciseId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
    match /exercises_meta/{doc} {
      allow read, write: if request.auth != null;
    }
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      match /programs/{programId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
      match /sessions/{sessionId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

## Troubleshooting

**Build runner issues**
```bash
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs
```

**Firebase connection issues**
- Verify `google-services.json` (Android) is in `android/app/`
- Verify `GoogleService-Info.plist` (iOS) is in `ios/Runner/`
- Check SHA-1 fingerprint is registered in Firebase Console

**Google Sign-In not working**
- Verify SHA-1 certificate is added to Firebase Console
- Ensure Google Sign-In is enabled in Firebase Authentication
- Re-download and replace `google-services.json` after adding SHA-1

## License

This project is open source and available under the MIT License.
