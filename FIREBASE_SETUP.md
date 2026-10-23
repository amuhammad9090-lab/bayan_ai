# Setup Firebase untuk Bayan AI

App sudah siap pakai Firebase. Selama belum dikonfigurasi, app tetap jalan:
halaman login menampilkan peringatan + tombol "Lanjut tanpa akun (mode dev)".

## 1. Buat project
1. https://console.firebase.google.com > Add project.
2. **Authentication > Sign-in method**: aktifkan **Email/Password** dan **Google**.
3. **Firestore Database > Create database** (mode production, pilih region terdekat).
4. Tab **Rules**: tempel isi `firestore.rules` di root project ini, lalu Publish.

## 2. Hubungkan ke app (di folder project)
```powershell
npm install -g firebase-tools
firebase login
dart pub global activate flutterfire_cli
flutterfire configure
```
Pilih project tadi + platform **android** (tambah ios kalau perlu). Perintah ini
**menimpa `lib/firebase_options.dart`** dan membuat `android/app/google-services.json`.

## 3. SHA-1 (wajib untuk login Google di Android)
```powershell
cd android
.\gradlew signingReport
```
Salin **SHA-1** dan **SHA-256** dari varian `debug` ke
Firebase Console > Project settings > Your apps > Android > Add fingerprint.
Lakukan lagi untuk keystore release nanti. Lalu jalankan ulang `flutterfire configure`.

## 4. Jalankan
```powershell
flutter pub get
flutter run
```

## Struktur data
Setiap login sukses menulis/memperbarui `users/{uid}`:

| field        | isi                              |
|--------------|----------------------------------|
| uid          | UID Firebase Auth                |
| displayName  | nama                             |
| email        | email                            |
| photoUrl     | foto (Google) atau kosong        |
| provider     | `password` atau `google`         |
| createdAt    | diisi sekali, saat pertama masuk |
| lastLoginAt  | diperbarui tiap login            |

Kalau tulis ke Firestore gagal (biasanya karena Rules), login tetap berhasil dan
di **Setelan > Akun** muncul label merah "Firestore gagal, cek Rules".

## Masalah umum
- `minSdkVersion` kurang: set `minSdk = 23` di `android/app/build.gradle(.kts)`.
- Bentrok versi paket: `flutter pub upgrade --major-versions`.
- Login Google langsung gagal/tertutup: SHA-1/SHA-256 belum didaftarkan (langkah 3).
- Mau ulang onboarding: hapus data app (Settings Android > Storage > Clear data).
