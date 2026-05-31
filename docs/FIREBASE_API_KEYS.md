# Cara Mendapatkan API Key dari Firebase Console

File `lib/firebase_options.dart` sudah dibuat dengan placeholder. Ikuti langkah berikut untuk mengisi API key yang sebenarnya:

## Langkah 1: Buka Firebase Console

1. Buka https://console.firebase.google.com/project/workout-tracker-ead9b/settings/general
2. Login dengan akun Google yang memiliki akses ke project ini

## Langkah 2: Dapatkan API Key untuk Setiap Platform

### Web API Key & App ID

1. Scroll ke bagian **"Your apps"**
2. Cari app dengan icon **</>** (Web app)
3. Jika belum ada, klik **"Add app"** → pilih **Web** → beri nama "Heft Web"
4. Setelah dibuat, klik app tersebut untuk melihat config
5. Copy nilai:
   - **API Key** → ganti `YOUR_WEB_API_KEY` di `firebase_options.dart`
   - **App ID** → ganti `YOUR_WEB_APP_ID` di `firebase_options.dart`

### Android API Key

1. Di bagian **"Your apps"**, cari app dengan icon Android
2. Klik app tersebut
3. Copy **API Key** → ganti `YOUR_ANDROID_API_KEY` di `firebase_options.dart`

### iOS API Key

1. Di bagian **"Your apps"**, cari app dengan icon Apple
2. Klik app tersebut
3. Copy **API Key** → ganti `YOUR_IOS_API_KEY` di `firebase_options.dart`

## Langkah 3: Dapatkan Web Client ID untuk Google Sign-In

1. Masih di Firebase Console, buka **Authentication** → **Sign-in method**
2. Klik **Google** (pastikan sudah enabled)
3. Di bagian **Web SDK configuration**, copy **Web client ID**
4. Ganti `YOUR_WEB_CLIENT_ID.apps.googleusercontent.com` di 2 file:
   - `lib/presentation/viewmodels/auth_viewmodel.dart` (baris 18)
   - `web/index.html` (baris 36)

## Langkah 4: Test

```bash
# Test di Chrome
flutter run -d chrome

# Atau build production
flutter build web --release
```

## Alternatif: Gunakan FlutterFire CLI (Otomatis)

Jika ingin otomatis, jalankan:

```bash
# Login Firebase (buka browser untuk auth)
firebase login

# Generate firebase_options.dart otomatis
flutterfire configure --project=workout-tracker-ead9b
```

Pilih platform: Android, iOS, **Web** (penting!)

CLI akan otomatis mengisi semua API key dan membuat web app jika belum ada.

## Catatan Keamanan

Firebase Web API Key **bukan rahasia** — mereka dirancang untuk digunakan di client-side code. Keamanan sebenarnya diatur oleh:
- Firestore Security Rules
- Firebase Authentication
- App Check (opsional)

Jadi aman untuk commit `firebase_options.dart` ke git (meskipun biasanya di-gitignore untuk menghindari konflik antar developer).
