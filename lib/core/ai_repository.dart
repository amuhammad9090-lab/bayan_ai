import 'dart:typed_data';

import '../models/models.dart';

/// Error yang aman ditampilkan langsung ke pengguna.
class AiException implements Exception {
  final String message;
  const AiException(this.message);

  @override
  String toString() => message;
}

class AiConfig {
  final String apiKey;
  final String model;
  const AiConfig({required this.apiKey, required this.model});

  bool get hasKey => apiKey.trim().isNotEmpty;
}

/// Sumber konfigurasi AI (diimplementasi oleh SettingsProvider).
/// Repository baca config lewat interface ini, jadi nggak tau soal Settings.
abstract class AiConfigSource {
  AiConfig get aiConfig;
}

/// Kontrak layer AI. Fitur (provider) cuma tau interface ini,
/// bukan Gemini. Ganti vendor / mock buat test = tinggal ganti implementasi.
abstract class AiRepository {
  Future<String> ocr(Uint8List imageBytes, String mimeType);
  Future<QuranSearchResult> searchQuran(String query);
  Future<NahwuAnalysis> analyzeNahwu(String sentence);

  /// Cek API key (bisa key yang lagi diketik, belum disimpan).
  Future<bool> testConnection({String? apiKey});

  /// ID model Gemini yang bisa dipakai API key ini (untuk generateContent).
  Future<List<String>> listModels();
}

/// Kontrol cache hasil AI (diimplementasi oleh CachedAiRepository).
abstract class AiCache {
  int get size;
  Future<void> clear();
}
