# IronLog - Complete Setup Guide

This guide will walk you through setting up the IronLog app from scratch.

## Prerequisites Checklist

- [ ] Flutter SDK 3.27.1+ installed
- [ ] Dart SDK 3.6.0+ installed
- [ ] Android Studio / Xcode installed
- [ ] Firebase account created
- [ ] Git installed

## Step-by-Step Setup

### Step 1: Fix Flutter Permissions (if needed)

If you encounter permission errors:

```bash
sudo chown -R $(whoami) ~/.flutter
sudo chown -R $(whoami) /path/to/flutter/sdk
```

### Step 2: Install Dependencies

```bash
cd /Volumes/V-GEN/Projects/workout_tracker
flutter pub get
```

Expected output: "Got dependencies!"

### Step 3: Generate Riverpod Code

The app uses Riverpod code generation for ViewModels. Run:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

This will generate all `.g.dart` files for:
- `lib/presentation/viewmodels/auth_viewmodel.g.dart`
- `lib/presentation/viewmodels/program_viewmodel.g.dart`
- `lib/presentation/viewmodels/workout_viewmodel.g.dart`
- `lib/presentation/viewmodels/progress_viewmodel.g.dart`

Expected output: "Succeeded after X.Xs with Y outputs"

### Step 4: Firebase Project Setup

#### 4.1 Create Firebase Project

1. Go to https://console.firebase.google.com/
2. Click "Add project"
3. Enter project name: "IronLog" (or your choice)
4. Disable Google Analytics (optional)
5. Click "Create project"

#### 4.2 Enable Authentication

1. In Firebase Console, go to "Authentication"
2. Click "Get started"
3. Click "Sign-in method" tab
4. Enable "Google" provider
5. Enter support email
6. Click "Save"

#### 4.3 Enable Firestore

1. In Firebase Console, go to "Firestore Database"
2. Click "Create database"
3. Select "Start in test mode" (we'll add security rules later)
4. Choose a location (closest to your users)
5. Click "Enable"

#### 4.4 Add Security Rules

In Firestore, go to "Rules" tab and paste:

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

Click "Publish"

### Step 5: Configure Firebase for Flutter

#### 5.1 Install FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
```

Add to PATH if needed:
```bash
export PATH="$PATH":"$HOME/.pub-cache/bin"
```

#### 5.2 Configure Firebase

```bash
cd /Volumes/V-GEN/Projects/workout_tracker
flutterfire configure
```

Follow the prompts:
1. Select your Firebase project
2. Select platforms: Android, iOS
3. This will generate `lib/firebase_options.dart`

### Step 6: Android Setup

#### 6.1 Get SHA-1 Certificate

For debug builds:
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

Copy the SHA-1 fingerprint.

#### 6.2 Add SHA-1 to Firebase

1. Go to Firebase Console → Project Settings
2. Under "Your apps" → Android app
3. Click "Add fingerprint"
4. Paste SHA-1 certificate
5. Download updated `google-services.json`
6. Place in `android/app/google-services.json`

#### 6.3 Verify Android Configuration

Check `android/app/build.gradle`:
```gradle
android {
    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 34
    }
}
```

### Step 7: iOS Setup

#### 7.1 Download GoogleService-Info.plist

1. Go to Firebase Console → Project Settings
2. Under "Your apps" → iOS app
3. Download `GoogleService-Info.plist`

#### 7.2 Add to Xcode

1. Open `ios/Runner.xcworkspace` in Xcode
2. Drag `GoogleService-Info.plist` into `Runner` folder
3. Ensure "Copy items if needed" is checked
4. Click "Finish"

#### 7.3 Update Info.plist

Open `ios/Runner/Info.plist` and add:

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

Replace `YOUR-CLIENT-ID` with reversed client ID from `GoogleService-Info.plist`.

### Step 8: Test the Build

#### 8.1 Check for Errors

```bash
flutter analyze
```

Fix any errors reported.

#### 8.2 Run the App

```bash
# Connect Android device/emulator or iOS simulator
flutter devices

# Run the app
flutter run
```

### Step 9: Test Core Features

Once the app is running:

1. **Test Authentication**
   - Tap "Sign in with Google"
   - Select Google account
   - Verify successful login

2. **Test Program Creation**
   - Tap "New Program"
   - Enter program name: "Push Day"
   - Add exercises: Bench Press, Shoulder Press
   - Save program

3. **Test Workout Session**
   - Tap "Start Workout"
   - Select "Push Day"
   - Add sets with weight and reps
   - Complete sets
   - Test rest timer
   - Finish workout

4. **Test Progress**
   - Go to Progress tab
   - Select an exercise
   - View charts and personal records

## Troubleshooting

### Build Runner Issues

```bash
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

### Firebase Not Connecting

- Verify `google-services.json` is in `android/app/`
- Verify `GoogleService-Info.plist` is in `ios/Runner/`
- Run `flutterfire configure` again

### Google Sign-In Fails

- Verify SHA-1 is added to Firebase Console
- Verify Google Sign-In is enabled in Firebase Authentication
- Check `google-services.json` is up to date

### Compilation Errors

```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run
```

## Next Steps

After successful setup:

1. **Customize the app**
   - Update app name in `pubspec.yaml`
   - Change package name
   - Update app icons

2. **Deploy to Production**
   - Generate release keystore
   - Update Firestore security rules
   - Add SHA-1 for release certificate
   - Build release APK/IPA

3. **Add Features**
   - Exercise library
   - Workout templates
   - Social features
   - Export data

## Support

If you encounter issues:
1. Check the main README.md
2. Review Firebase Console logs
3. Check Flutter doctor: `flutter doctor -v`

## Success Checklist

- [ ] Dependencies installed (`flutter pub get`)
- [ ] Riverpod code generated (`.g.dart` files exist)
- [ ] Firebase configured (`firebase_options.dart` generated)
- [ ] Android SHA-1 added to Firebase
- [ ] iOS GoogleService-Info.plist added
- [ ] App builds without errors
- [ ] Google Sign-In works
- [ ] Can create programs
- [ ] Can log workouts
- [ ] Can view progress

Congratulations! Your IronLog app is ready! 🎉💪
