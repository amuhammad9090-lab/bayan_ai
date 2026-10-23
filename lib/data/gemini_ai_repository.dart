import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../core/ai_repository.dart';
import '../models/models.dart';

/// Implementasi AiRepository pakai Google Gemini (REST).
class GeminiAiRepository implements AiRepository {
  GeminiAiRepository(this._config, {http.Client? client})
      : _client = client ?? http.Client();

  static const _base = 'https://generativelanguage.googleapis.com/v1beta/models';
  static const _timeout = Duration(seconds: 90);

  final AiConfigSource _config;
  final http.Client _client;

  // ───────────────────────── AiRepository ─────────────────────────

  @override
  Future<String> ocr(Uint8List imageBytes, String mimeType) async {
    final text = await _generate(
      system: 'Kamu adalah mesin OCR khusus teks Arab, terutama mushaf Al-Qur\'an.',
      parts: [
        {
          'text': 'Baca teks Arab pada gambar ini dan tulis ulang apa adanya dengan harakat selengkap yang terbaca. '
              'Pertahankan urutan baris. Jangan menambahkan terjemahan, tafsir, transliterasi, atau komentar. '
              'Keluarkan hanya teks Arabnya.'
        },
        {
          'inline_data': {'mime_type': mimeType, 'data': base64Encode(imageBytes)}
        },
      ],
      temperature: 0.1,
    );
    if (text.isEmpty) throw const AiException('Tidak ada teks yang terdeteksi di gambar.');
    return text;
  }

  @override
  Future<QuranSearchResult> searchQuran(String query) async {
    final text = await _generate(
      system: 'Kamu adalah asisten ilmu Al-Qur\'an yang teliti. Jangan mengarang ayat. '
          'Jika tidak yakin dengan nomor surah/ayat atau teksnya, kosongkan field yang tidak pasti, jangan menebak.',
      parts: [
        {
          'text': '''
Permintaan pengguna: "$query"

Carikan maksimal 5 ayat Al-Qur'an yang paling relevan (atau ayat yang disebutkan langsung oleh pengguna).
Jawab HANYA dengan JSON valid, tanpa teks lain, dengan bentuk:
{
  "ringkasan": "1-2 kalimat bahasa Indonesia tentang topik ini",
  "hasil": [
    {
      "surah": "nama surah, mis. Al-Baqarah",
      "nomor": "nomor surah:ayat, mis. 2:255",
      "arab": "teks ayat Arab dengan harakat",
      "terjemah": "terjemah bahasa Indonesia",
      "tafsir": "tafsir ringkas 2-4 kalimat bahasa Indonesia"
    }
  ]
}
'''
        },
      ],
      json: true,
    );
    return QuranSearchResult.parse(text);
  }

  @override
  Future<NahwuAnalysis> analyzeNahwu(String sentence) async {
    final text = await _generate(
      system: 'Kamu adalah ustadz ahli nahwu dan sharaf yang menjelaskan i\'rab dengan runtut dan tepat.',
      parts: [
        {
          'text': '''
Analisis tarkib nahwu dan i'rab kalimat Arab berikut, kata per kata sesuai urutan:

$sentence

Jawab HANYA dengan JSON valid, tanpa teks lain, dengan bentuk:
{
  "jenis_kalimat": "mis. Jumlah Ismiyyah / Jumlah Fi'liyyah / Syibhul Jumlah",
  "kata": [
    {
      "kata": "kata Arab (dengan harakat bila ada)",
      "jenis": "Isim | Fi'il | Huruf",
      "irab": "kedudukan i'rab lengkap, mis. Mubtada' marfu' wa alamatu rafi'ihi dhammah zhahirah",
      "makna": "arti singkat bahasa Indonesia"
    }
  ],
  "ringkasan": "ringkasan struktur kalimat dalam 1-3 kalimat bahasa Indonesia"
}
'''
        },
      ],
      json: true,
    );
    if (text.isEmpty) throw const AiException('Tidak ada hasil analisis dari model.');
    return NahwuAnalysis.parse(text);
  }

  @override
  Future<bool> testConnection({String? apiKey}) async {
    final cfg = _config.aiConfig;
    final key = (apiKey ?? cfg.apiKey).trim();
    if (key.isEmpty) return false;
    try {
      final res = await _client
          .get(Uri.parse('$_base/${cfg.model}'), headers: {'x-goog-api-key': key})
          .timeout(const Duration(seconds: 15));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ───────────────────────── Internal ─────────────────────────

  Future<String> _generate({
    required List<Map<String, dynamic>> parts,
    String? system,
    bool json = false,
    double temperature = 0.2,
  }) async {
    final cfg = _config.aiConfig;
    if (!cfg.hasKey) {
      throw const AiException('API key belum diatur. Buka tab Setelan dulu.');
    }

    final body = <String, dynamic>{
      if (system != null)
        'systemInstruction': {
          'parts': [
            {'text': system}
          ]
        },
      'contents': [
        {'role': 'user', 'parts': parts}
      ],
      'generationConfig': {
        'temperature': temperature,
        if (json) 'responseMimeType': 'application/json',
      },
    };

    http.Response res;
    try {
      res = await _client
          .post(
            Uri.parse('$_base/${cfg.model}:generateContent'),
            headers: {
              HttpHeaders.contentTypeHeader: 'application/json',
              'x-goog-api-key': cfg.apiKey.trim(),
            },
            body: jsonEncode(body),
          )
          .timeout(_timeout);
    } on TimeoutException {
      throw const AiException('Koneksi timeout. Coba lagi sebentar.');
    } on SocketException {
      throw const AiException('Tidak ada koneksi internet.');
    } on http.ClientException {
      throw const AiException('Gagal terhubung ke server Gemini.');
    }

    final decoded = _tryDecode(utf8.decode(res.bodyBytes));

    if (res.statusCode != 200) {
      throw AiException(_friendlyError(res.statusCode, decoded));
    }

    final block = decoded?['promptFeedback']?['blockReason'];
    if (block != null) {
      throw AiException('Permintaan ditolak oleh filter model ($block).');
    }

    final partsOut = decoded?['candidates']?[0]?['content']?['parts'];
    if (partsOut is! List) return '';
    return partsOut
        .whereType<Map>()
        .where((p) => p['thought'] != true)
        .map((p) => p['text']?.toString() ?? '')
        .join()
        .trim();
  }

  Map<String, dynamic>? _tryDecode(String s) {
    try {
      final d = jsonDecode(s);
      return d is Map<String, dynamic> ? d : null;
    } catch (_) {
      return null;
    }
  }

  String _friendlyError(int code, Map<String, dynamic>? body) {
    final apiMsg = body?['error']?['message']?.toString() ?? '';
    switch (code) {
      case 400:
        if (apiMsg.toLowerCase().contains('api key')) {
          return 'API key tidak valid. Cek lagi di Setelan.';
        }
        return 'Permintaan tidak valid. $apiMsg'.trim();
      case 401:
      case 403:
        return 'API key ditolak / tidak punya akses ke model ini.';
      case 404:
        return 'Model tidak ditemukan. Ganti model di Setelan.';
      case 429:
        return 'Kuota atau batas permintaan habis. Tunggu sebentar lalu coba lagi.';
      default:
        if (code >= 500) return 'Server Gemini lagi bermasalah ($code). Coba lagi nanti.';
        return 'Gagal ($code). $apiMsg'.trim();
    }
  }
}
