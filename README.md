# Bayan AI

Gabungan **Quran AI** + **Nahwu AI** jadi satu app Flutter (tema biru, ikon Lucide, Gemini).

## Cara pakai
1. Salin `lib/`, `assets/`, `web/`, `pubspec.yaml`, `analysis_options.yaml` ke project Flutter lu
   (yang punya folder `android/`), atau jalanin `flutter create .` di folder ini.
2. `flutter pub get`
3. (opsional) `dart run flutter_launcher_icons`
4. `flutter run`, lalu isi API key Gemini di tab **Setelan**.

Android: pastikan `INTERNET` + izin kamera sudah ada di AndroidManifest (sama seperti app lama).

## Struktur
- `core/` tema, ikon, kontrak (AiRepository, KeyValueStore, HistoryRecorder, HandoffService)
- `models/` hasil Nahwu, ayat, riwayat
- `data/` implementasi Gemini (GeminiAiRepository)
- `features/` ocr, quran, nahwu, settings, history, home, shell (page + provider per fitur)
- `shared/widgets/` komponen UI bersama
