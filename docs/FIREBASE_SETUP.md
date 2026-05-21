# Firebase Setup untuk Heft

## 🔥 Cara Konfigurasi Firebase

Ada 2 cara untuk mengkonfigurasi Firebase:

### Cara 1: Otomatis dengan FlutterFire CLI (RECOMMENDED)

#### Langkah 1: Install FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
```

Tambahkan ke PATH jika belum:
```bash
export PATH="$PATH":"$HOME/.pub-cache/bin"
```

#### Langkah 2: Login ke Firebase

```bash
firebase login
```

#### Langkah 3: Konfigurasi Project

```bash
cd /Volumes/V-GEN/Projects/workout_tracker
flutterfire configure
```

Ikuti prompt:
1. Pilih Firebase project Anda (atau buat baru)
2. Pilih platform: Android, iOS
3. File `firebase_options.dart` akan otomatis di-generate

#### Langkah 4: Verifikasi

File `lib/firebase_options.dart` sekarang berisi konfigurasi yang benar!

---

### Cara 2: Manual Configuration

Jika Anda ingin konfigurasi manual, ikuti langkah berikut:

#### Untuk Android:

1. Buka [Firebase Console](https://console.firebase.google.com/)
2. Pilih project Anda
3. Klik ⚙️ (Settings) → Project settings
4. Scroll ke "Your apps" → Pilih Android app
5. Download `google-services.json`
6. Copy nilai-nilai berikut:

```json
{
  "project_info": {
    "project_id": "YOUR_PROJECT_ID",
    "storage_bucket": "YOUR_PROJECT_ID.appspot.com"
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "YOUR_ANDROID_APP_ID"
      },
      "api_key": [
        {
          "current_key": "YOUR_ANDROID_API_KEY"
        }
      ]
    }
  ]
}
```

7. Update `lib/firebase_options.dart`:

```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'YOUR_ANDROID_API_KEY',           // dari current_key
  appId: 'YOUR_ANDROID_APP_ID',             // dari mobilesdk_app_id
  messagingSenderId: 'YOUR_SENDER_ID',      // dari project_number
  projectId: 'YOUR_PROJECT_ID',             // dari project_id
  storageBucket: 'YOUR_PROJECT_ID.appspot.com',
);
```

#### Untuk iOS:

1. Di Firebase Console, pilih iOS app
2. Download `GoogleService-Info.plist`
3. Buka file tersebut dan copy nilai:

```xml
<key>API_KEY</key>
<string>YOUR_IOS_API_KEY</string>
<key>GOOGLE_APP_ID</key>
<string>YOUR_IOS_APP_ID</string>
<key>GCM_SENDER_ID</key>
<string>YOUR_SENDER_ID</string>
<key>PROJECT_ID</key>
<string>YOUR_PROJECT_ID</string>
<key>STORAGE_BUCKET</key>
<string>YOUR_PROJECT_ID.appspot.com</string>
<key>BUNDLE_ID</key>
<string>com.example.workoutTracker</string>
```

4. Update `lib/firebase_options.dart`:

```dart
static const FirebaseOptions ios = FirebaseOptions(
  apiKey: 'YOUR_IOS_API_KEY',
  appId: 'YOUR_IOS_APP_ID',
  messagingSenderId: 'YOUR_SENDER_ID',
  projectId: 'YOUR_PROJECT_ID',
  storageBucket: 'YOUR_PROJECT_ID.appspot.com',
  iosBundleId: 'com.example.workoutTracker',
);
```

---

## 📱 Setup Platform-Specific Files

### Android Setup

1. **Download google-services.json**
   - Firebase Console → Project Settings → Android app
   - Download `google-services.json`
   - Place di: `android/app/google-services.json`

2. **Verify build.gradle**
   
   File: `android/build.gradle`
   ```gradle
   dependencies {
       classpath 'com.google.gms:google-services:4.3.15'
   }
   ```

   File: `android/app/build.gradle`
   ```gradle
   apply plugin: 'com.google.gms.google-services'
   
   android {
       defaultConfig {
           minSdkVersion 21
       }
   }
   ```

### iOS Setup

1. **Download GoogleService-Info.plist**
   - Firebase Console → Project Settings → iOS app
   - Download `GoogleService-Info.plist`

2. **Add to Xcode**
   - Open `ios/Runner.xcworkspace` di Xcode
   - Drag `GoogleService-Info.plist` ke folder `Runner`
   - ✅ Check "Copy items if needed"

3. **Update Info.plist**
   
   File: `ios/Runner/Info.plist`
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
   
   Ganti `YOUR-CLIENT-ID` dengan reversed client ID dari `GoogleService-Info.plist`

---

## 🔐 Google Sign-In Setup

### 1. Enable Google Sign-In di Firebase

1. Firebase Console → Authentication
2. Sign-in method → Google
3. Enable → Save

### 2. Android - Add SHA-1 Certificate

**Get SHA-1 (Debug):**
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

**Get SHA-1 (Release):**
```bash
keytool -list -v -keystore /path/to/your/release.keystore -alias your-alias
```

**Add to Firebase:**
1. Firebase Console → Project Settings
2. Your apps → Android app
3. Add fingerprint → Paste SHA-1
4. Download updated `google-services.json`

### 3. iOS - Configure URL Scheme

Sudah dijelaskan di bagian iOS Setup di atas.

---

## ✅ Verification Checklist

Setelah setup, pastikan:

- [ ] `lib/firebase_options.dart` berisi konfigurasi yang benar (bukan placeholder)
- [ ] `android/app/google-services.json` ada dan valid
- [ ] `ios/Runner/GoogleService-Info.plist` ada dan valid (untuk iOS)
- [ ] SHA-1 certificate sudah ditambahkan ke Firebase Console
- [ ] Google Sign-In enabled di Firebase Authentication
- [ ] Firestore Database sudah dibuat

---

## 🧪 Test Configuration

Run app untuk test:

```bash
flutter run
```

Jika berhasil:
- ✅ App tidak crash saat startup
- ✅ Bisa klik "Sign in with Google"
- ✅ Google Sign-In dialog muncul
- ✅ Setelah login, masuk ke Home screen

---

## 🐛 Troubleshooting

### Error: "No Firebase App '[DEFAULT]' has been created"
**Solusi:** Pastikan `Firebase.initializeApp()` dipanggil di `main.dart`

### Error: "API key not valid"
**Solusi:** 
- Regenerate `firebase_options.dart` dengan `flutterfire configure`
- Atau periksa API key di Firebase Console

### Google Sign-In tidak bekerja
**Solusi:**
- Pastikan SHA-1 sudah ditambahkan ke Firebase Console
- Download ulang `google-services.json` setelah menambah SHA-1
- Pastikan Google Sign-In enabled di Firebase Authentication

### Error: "CONFIGURATION_NOT_FOUND"
**Solusi:**
- Pastikan `google-services.json` ada di `android/app/`
- Pastikan `GoogleService-Info.plist` ada di `ios/Runner/`

---

## 📞 Need Help?

Jika masih ada masalah:
1. Check Firebase Console logs
2. Run `flutter doctor -v`
3. Check `flutter run` output untuk error messages

**Firebase sudah siap! 🔥**
