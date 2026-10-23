# Bayan AI

Gabungan **Quran AI** + **Nahwu AI** jadi satu app Flutter (tema biru, ikon Lucide, Gemini).

## Cara pakai
1. Salin `lib/`, `assets/`, `web/`, `pubspec.yaml`, `analysis_options.yaml` ke project Flutter lu
   (yang punya folder `android/`), atau jalanin `flutter create .` di folder ini.
2. `flutter pub get`
3. (opsional) `dart run flutter_launcher_icons`
4. `flutter run`, lalu isi API key Gemini di tab **Setelan**.

Android: pastikan `INTERNET` + izin kamera sudah ada di AndroidManifest (sama seperti app lama).

## Alur layar & animasi
Splash -> Onboarding (sekali saja) -> Login/Daftar -> Aplikasi (`features/gate/app_gate.dart`).
- `features/splash`: logo memantul, cincin berputar, huruf Arab melayang.
- `features/onboarding`: 3 slide dengan ilustrasi beranimasi (pindai, cari ayat, bedah nahwu) + parallax.
- `features/auth`: login/daftar email, Google, lupa password, simpan profil ke Firestore `users/{uid}`.
- `shared/widgets/animations.dart`: widget animasi bersama (efek pemindai OCR, banner "AI berpikir", transisi tab).
- `main.dart` sengaja pendek (init + runApp); perakitan dependency ada di `bootstrap.dart`, root widget di `app.dart`.

Setup Firebase: lihat **FIREBASE_SETUP.md**.

## Struktur
- `core/` tema, ikon, kontrak (AiRepository, KeyValueStore, HistoryRecorder, HandoffService)
- `models/` hasil Nahwu, ayat, riwayat
- `data/` implementasi Gemini (GeminiAiRepository)
- `features/` ocr, quran, nahwu, settings, history, home, shell (page + provider per fitur)
- `shared/widgets/` komponen UI bersama

## Android
Folder `android/` sudah termasuk: signing release (key.properties), manifest (INTERNET), icon adaptive.
1. Buat keystore: `cd android && bash create_keystore.sh` (Windows: `create_keystore.bat`)
2. `cp android/key.properties.example android/key.properties` lalu isi password
3. `flutter pub get && flutter build appbundle --release`

`android/local.properties` sengaja tidak disertakan; dibuat otomatis oleh Flutter (`flutter pub get`).
