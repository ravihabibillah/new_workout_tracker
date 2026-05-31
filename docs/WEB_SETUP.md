# Web Setup Guide

## ✅ Completed Web Compatibility Fixes

All code has been updated for web support:

1. **Hive initialization** - Conditional imports for web vs mobile
2. **Vibration** - Conditional imports (no-op on web)
3. **SystemChrome** - Wrapped in `!kIsWeb` check
4. **Responsive layout** - Side nav on desktop (≥600px), bottom nav on mobile
5. **Google Sign-In** - Web client ID support added
6. **Dependencies** - Removed unused `audioplayers` and `path_provider`
7. **Web metadata** - Updated `web/index.html` and `web/manifest.json`

## 🔧 Required Setup Steps

### 1. Generate Firebase Options for Web

Run this command to generate `lib/firebase_options.dart` with web support:

```bash
flutterfire configure --project=workout-tracker-ead9b
```

When prompted, select:
- ✅ Android
- ✅ iOS  
- ✅ Web (IMPORTANT: select this!)

This will:
- Generate `lib/firebase_options.dart` with web configuration
- Update `firebase.json` with web platform config
- Download `google-services.json` and `GoogleService-Info.plist`

### 2. Configure Google Sign-In for Web

#### A. Get Web Client ID from Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select project: **workout-tracker-ead9b**
3. Go to **Authentication** → **Sign-in method** → **Google**
4. Under **Web SDK configuration**, copy the **Web client ID**
   - Format: `XXXXXXXXX-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.apps.googleusercontent.com`

#### B. Update Web Client ID in Code

Replace `YOUR_WEB_CLIENT_ID.apps.googleusercontent.com` in these files:

**File 1:** `lib/presentation/viewmodels/auth_viewmodel.dart` (line 18)
```dart
const String _googleSignInWebClientId =
    'YOUR_ACTUAL_WEB_CLIENT_ID.apps.googleusercontent.com';
```

**File 2:** `web/index.html` (line 36)
```html
<meta name="google-signin-client_id" content="YOUR_ACTUAL_WEB_CLIENT_ID.apps.googleusercontent.com">
```

### 3. Build and Test Web

```bash
# Build for web
flutter build web --release

# Or run in debug mode
flutter run -d chrome
```

### 4. Deploy to Firebase Hosting (Optional)

```bash
# Initialize hosting (first time only)
firebase init hosting

# Deploy
firebase deploy --only hosting
```

## 📱 Responsive Layout Features

### Mobile (< 600px)
- Bottom navigation bar with glass effect
- Center FAB for "Start Workout"
- Full-width content

### Desktop (≥ 600px)
- Side navigation rail (220px width)
- App branding at top
- "Start Workout" button at bottom
- Content area with divider
- Hover effects on nav items

## 🧪 Testing Checklist

- [ ] Run `flutterfire configure` with web enabled
- [ ] Update web client ID in 2 files
- [ ] Test `flutter run -d chrome`
- [ ] Test Google Sign-In on web
- [ ] Test responsive layout (resize browser)
- [ ] Test Hive cache on web (IndexedDB)
- [ ] Test all screens on desktop layout
- [ ] Test navigation between screens
- [ ] Test workout session (rest timer without vibration)

## 🐛 Known Limitations on Web

1. **No vibration** - Rest timer completion won't vibrate (expected)
2. **No audio** - Removed `audioplayers` (was unused anyway)
3. **IndexedDB storage** - Hive uses browser IndexedDB instead of files
4. **Google Sign-In popup** - May be blocked by popup blockers

## 📝 Files Changed

### New Files Created
- `lib/core/utils/haptic_feedback.dart` (conditional export)
- `lib/core/utils/haptic_feedback_web.dart` (no-op)
- `lib/core/utils/haptic_feedback_mobile.dart` (vibration)
- `lib/core/utils/haptic_feedback_stub.dart` (stub)
- `lib/data/datasources/local/hive_init.dart` (conditional export)
- `lib/data/datasources/local/hive_init_web.dart` (web init)
- `lib/data/datasources/local/hive_init_mobile.dart` (mobile init)
- `lib/data/datasources/local/hive_init_stub.dart` (stub)
- `lib/presentation/widgets/responsive_layout.dart` (responsive helpers)
- `lib/core/utils/platform_utils.dart` (platform detection)

### Modified Files
- `lib/main.dart` - Wrapped SystemChrome in !kIsWeb
- `lib/presentation/viewmodels/auth_viewmodel.dart` - Web client ID support
- `lib/presentation/viewmodels/workout_viewmodel.dart` - Conditional haptic
- `lib/data/datasources/local/exercise_library_cache.dart` - Conditional Hive init
- `lib/data/datasources/local/program_cache.dart` - Conditional Hive init
- `lib/presentation/views/shell/main_shell.dart` - Responsive layout
- `web/index.html` - Updated metadata + Google Sign-In meta tag
- `web/manifest.json` - Updated app name and theme
- `pubspec.yaml` - Removed audioplayers, path_provider

## 🎯 Next Steps

1. Run `flutterfire configure --project=workout-tracker-ead9b` (select web!)
2. Get web client ID from Firebase Console
3. Replace `YOUR_WEB_CLIENT_ID` in 2 files
4. Run `flutter run -d chrome`
5. Test the app!
