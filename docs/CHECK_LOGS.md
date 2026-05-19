# Cara Check Error Logs

Untuk mengetahui kenapa app stuck di loading, jalankan:

## Option 1: Run dengan verbose logging
```bash
flutter run -v
```

Lalu cari error messages di output, terutama yang berkaitan dengan:
- Firebase initialization
- Auth state
- Router redirect

## Option 2: Check Android Logcat
```bash
# Jika sudah running, buka terminal baru dan jalankan:
flutter logs
```

## Option 3: Add Debug Logging

Saya bisa menambahkan debug logging ke code untuk identify masalahnya.

---

## Kemungkinan Penyebab:

1. **Firebase Auth belum di-enable** di Firebase Console
2. **Google Sign-In belum dikonfigurasi** (SHA-1 belum ditambahkan)
3. **Network issue** - Firebase tidak bisa connect
4. **Auth state stream hanging** - Stream tidak emit value

## Quick Fix - Tambah Timeout

Saya bisa menambahkan timeout ke splash screen agar tidak stuck selamanya.
