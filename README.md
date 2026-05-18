# IronLog - Weightlifting Progress Tracker

A production-ready Flutter app for tracking weightlifting workouts, managing programs, and visualizing progress.

## Features

- 🔐 **Google Authentication** - Secure sign-in with Firebase Auth
- 📋 **Program Management** - Create, edit, and organize workout programs
- 🏋️ **Active Workout Tracking** - Log sets, reps, and weight in real-time
- ⏱️ **Rest Timer** - Built-in countdown timer with skip/extend options
- 📈 **Progress Charts** - Visualize strength gains with interactive charts
- 💪 **Personal Records** - Track max weight, volume, and reps per exercise
- 📱 **Dark Mode UI** - Minimalist sports-themed design
- ☁️ **Cloud Sync** - All data synced to Firebase Firestore

## Tech Stack

- **Flutter**: 3.27.1
- **Dart**: 3.6.0
- **State Management**: Riverpod 2.6.1
- **Navigation**: GoRouter 14.x
- **Backend**: Firebase (Auth + Firestore)
- **Charts**: fl_chart 0.69.x
- **Architecture**: MVVM with Clean Architecture

## Project Structure

```
lib/
├── core/               # Constants, theme, router, utils
├── data/               # Models, datasources, repository implementations
├── domain/             # Entities, repository interfaces, use cases
└── presentation/       # ViewModels, screens, widgets
```

## Prerequisites

- Flutter SDK 3.27.1 or higher
- Dart SDK 3.6.0 or higher
- Firebase project with Firestore and Authentication enabled
- Google Sign-In configured for your Firebase project

## Setup Instructions

### 1. Clone the Repository

```bash
git clone <repository-url>
cd workout_tracker
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Firebase Setup

#### Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or use existing one
3. Enable **Authentication** → Sign-in method → **Google**
4. Enable **Cloud Firestore** → Create database (start in test mode)

#### Configure Firebase for Flutter

Install FlutterFire CLI:

```bash
dart pub global activate flutterfire_cli
```

Configure Firebase for your app:

```bash
flutterfire configure
```

This will:
- Create `firebase_options.dart`
- Configure Android and iOS apps
- Link your Firebase project

### 4. Google Sign-In Setup

#### Android Setup

1. Get your SHA-1 certificate fingerprint:

```bash
# Debug certificate
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# Release certificate (for production)
keytool -list -v -keystore /path/to/your/keystore.jks -alias your-key-alias
```

2. Add SHA-1 to Firebase:
   - Go to Firebase Console → Project Settings
   - Under "Your apps" → Android app
   - Add SHA-1 certificate fingerprint
   - Download updated `google-services.json`
   - Place in `android/app/`

3. Update `android/app/build.gradle`:

```gradle
android {
    defaultConfig {
        minSdkVersion 21  // Ensure minimum SDK 21
    }
}
```

#### iOS Setup

1. Download `GoogleService-Info.plist` from Firebase Console
2. Add to `ios/Runner/` in Xcode
3. Update `ios/Runner/Info.plist`:

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

Replace `YOUR-CLIENT-ID` with the reversed client ID from `GoogleService-Info.plist`.

### 5. Generate Riverpod Code

The app uses Riverpod code generation. Run:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

This generates all `.g.dart` files for ViewModels.

### 6. Run the App

```bash
# Run on connected device/emulator
flutter run

# Run in release mode
flutter run --release
```

## Firestore Security Rules

Update your Firestore security rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
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

## Development

### Code Generation (Watch Mode)

For continuous code generation during development:

```bash
flutter pub run build_runner watch --delete-conflicting-outputs
```

### Clean Build

If you encounter issues:

```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run
```

## Architecture

### MVVM Pattern

- **Model**: Domain entities and data models
- **View**: Flutter widgets (screens)
- **ViewModel**: Riverpod providers managing state and business logic

### Clean Architecture Layers

1. **Presentation**: UI and ViewModels
2. **Domain**: Business logic, entities, use cases
3. **Data**: Data sources, models, repository implementations

### Key Design Decisions

- **Riverpod** for dependency injection and state management
- **GoRouter** for type-safe navigation
- **Firebase** for authentication and cloud storage
- **MVVM** for clear separation of concerns
- **Use Cases** for single-responsibility business logic

## Troubleshooting

### Build Runner Issues

```bash
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

### Firebase Connection Issues

- Verify `google-services.json` (Android) is in `android/app/`
- Verify `GoogleService-Info.plist` (iOS) is in `ios/Runner/`
- Check Firebase project configuration in console

### Google Sign-In Not Working

- Verify SHA-1 certificate is added to Firebase Console
- Ensure Google Sign-In is enabled in Firebase Authentication
- Check that `google-services.json` is up to date

## License

This project is open source and available under the MIT License.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
