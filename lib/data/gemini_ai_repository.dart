import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../core/ai_repository.dart';
import '../models/models.dart';
import 'references.dart';

/// Implementasi AiRepository pakai Google Gemini (REST).
class GeminiAiRepository implements AiRepository {
  GeminiAiRepository(this._config, {http.Client? client})
      : _client = client ?? http.Client();

  static const _base = 'https://generativelanguage.googleapis.com/v1beta/models';
  /// Batas per request dan batas total (semua percobaan + model cadangan).
  static const _timeout = Duration(seconds: 60);
  static const _totalBudget = Duration(seconds: 100);

  /// Cadangan otomatis saat model pilihan sibuk/kena batas (ringan & longgar di free tier).
  static const _fallbacks = <String>[
    'gemini-3.5-flash-lite',
    'gemini-3.1-flash-lite',
    'gemini-2.5-flash-lite',
    'gemini-2.5-flash',
  ];

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
      system: kQuranReference,
      parts: [
        {
          'text': '''
Permintaan pengguna: "$query"

Carikan maksimal 3 ayat Al-Qur'an yang paling relevan (atau ayat yang disebutkan langsung oleh pengguna).
Untuk satu surah pendek atau satu kesatuan makna, boleh berupa rentang ayat (maksimal 10 ayat).
PENTING: JANGAN menulis teks Arab ayat maupun terjemahnya. Aplikasi mengambil teks dan
terjemah resmi dari mushaf Kemenag berdasarkan nomor, jadi pastikan nomor surah dan ayat benar.

Tafsirkan SECARA MENDALAM, per bagian, mengikuti metode masing-masing kitab:
- Tafsir al-Munir: kosakata penting (3-6 kata, salin PERSIS dari ayat beserta harakatnya),
  balaghah/i'rab yang memengaruhi makna, sabab nuzul (hanya bila ada riwayat yang masyhur;
  jika tidak ada, tulis "Tidak ada sabab nuzul khusus yang masyhur."), penjelasan makna ayat
  (4-6 kalimat), lalu hukum dan pelajaran praktis (3-5 poin).
- Tafsir al-Mishbah: tema/tujuan surah, munasabah dengan ayat sebelum/sesudahnya, makna kosakata
  kunci, penjelasan yang mengalir (4-6 kalimat), lalu pesan dan relevansinya masa kini (3-5 poin).
- Ayat terkait: 1-3 nomor ayat lain yang temanya berkaitan erat (hanya yang kamu yakin benar).

Jawab HANYA dengan JSON valid, tanpa teks lain, dengan bentuk:
{
  "ringkasan": "2-3 kalimat bahasa Indonesia tentang topik ini",
  "hasil": [
    {
      "surah": "nama surah, mis. Al-Baqarah",
      "nomor": "nomor surah:ayat, mis. 2:255, atau rentang mis. 112:1-4",
      "tafsir_munir": {
        "mufradat": [{"kata": "kata Arab dari ayat", "arti": "makna dan nuansanya"}],
        "balaghah": "uslub/balaghah atau i'rab penting dan pengaruhnya pada makna",
        "asbabun_nuzul": "sabab nuzul, atau keterangan bahwa tidak ada yang masyhur",
        "penjelasan": "penjelasan makna ayat (at-tafsir wal-bayan)",
        "hukum": ["hukum/pelajaran praktis 1", "poin 2", "poin 3"]
      },
      "tafsir_mishbah": {
        "tema": "tema dan tujuan surah serta posisi ayat ini di dalamnya",
        "munasabah": "keterkaitan dengan ayat sebelum/sesudahnya",
        "kosakata": [{"kata": "kata Arab kunci", "arti": "makna menurut bahasa & konteks"}],
        "penjelasan": "penjelasan yang mengalir",
        "pesan": ["pesan & relevansi masa kini 1", "poin 2", "poin 3"]
      },
      "ayat_terkait": ["2:153", "3:200"]
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
      system: kNahwuReference,
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
      "bab": "salah satu: Al-Kalam | Al-I'rab | Al-Af'al | Isim Marfu' | Isim Manshub | Isim Makhfudh | At-Tawabi'",
      "irab": "kedudukan i'rab lengkap, mis. Mubtada' marfu'",
      "tanda": "tanda i'rab, mis. dhammah zhahirah",
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
      // Cek ke daftar model (bukan model terpilih): kalau ID model yang salah,
      // API key tetap dinilai valid.
      final res = await _client
          .get(Uri.parse('$_base?pageSize=1'), headers: {'x-goog-api-key': key})
          .timeout(const Duration(seconds: 15));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<String>> listModels() async {
    final cfg = _config.aiConfig;
    if (!cfg.hasKey) throw const AiException('API key belum diatur.');
    try {
      final res = await _client
          .get(Uri.parse('$_base?pageSize=100'), headers: {'x-goog-api-key': cfg.apiKey.trim()})
          .timeout(const Duration(seconds: 20));
      if (res.statusCode != 200) {
        throw AiException(_friendlyError(res.statusCode, _tryDecode(utf8.decode(res.bodyBytes))));
      }
      final list = (_tryDecode(utf8.decode(res.bodyBytes))?['models'] as List? ?? []);
      final ids = <String>[];
      for (final m in list.whereType<Map>()) {
        final name = m['name']?.toString() ?? '';
        final methods = (m['supportedGenerationMethods'] as List? ?? []).map((e) => '$e');
        if (!name.startsWith('models/gemini-') || !methods.contains('generateContent')) continue;
        final id = name.substring('models/'.length);
        if (RegExp(r'embedding|tts|image|live|audio|robotics|computer-use').hasMatch(id)) continue;
        ids.add(id);
      }
      ids.sort((a, b) => b.compareTo(a));
      return ids;
    } on TimeoutException {
      throw const AiException('Waktu koneksi habis. Silakan coba lagi.');
    } on http.ClientException {
      throw const AiException('Tidak ada koneksi internet.');
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
      throw const AiException('API key belum diatur. Buka tab Setelan terlebih dahulu.');
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

    // Model utama dulu; kalau server sibuk (5xx), kuota habis (429) atau model
    // tidak tersedia (404), coba ulang lalu pindah ke model cadangan.
    // Semua percobaan dibatasi total [_totalBudget] supaya loading nggak lama.
    final models = <String>[cfg.model, ..._fallbacks.where((m) => m != cfg.model)];
    final clock = Stopwatch()..start();
    http.Response? ok;
    // Error paling bermakna: yang pertama, kecuali 404 (model cadangan tak ada)
    // yang nggak boleh menutupi 429/5xx dari model utama.
    http.Response? firstErr;
    AiException? netErr;

    Duration remaining() => _totalBudget - clock.elapsed;

    outer:
    for (final model in models) {
      for (var attempt = 0; attempt < 2; attempt++) {
        if (attempt > 0) await Future<void>.delayed(const Duration(milliseconds: 1500));
        final left = remaining();
        if (left <= const Duration(seconds: 5)) break outer;
        try {
          final r = await _client
              .post(
                Uri.parse('$_base/$model:generateContent'),
                headers: {
                  'content-type': 'application/json',
                  'x-goog-api-key': cfg.apiKey.trim(),
                },
                body: jsonEncode(body),
              )
              .timeout(left < _timeout ? left : _timeout);
          final c = r.statusCode;
          if (c == 200) {
            ok = r;
            break outer;
          }
          if (firstErr == null || (firstErr.statusCode == 404 && c != 404)) firstErr = r;
          // Error yang nggak membaik dengan ganti model (400/401/403): berhenti.
          if (c < 500 && c != 429 && c != 404) break outer;
          // Kuota habis / model tak ada: langsung coba model berikutnya.
          if (c == 429 || c == 404) break;
          // 5xx (server sibuk): ulang sekali, lalu model berikutnya.
        } on TimeoutException {
          // Sinyal lemah / server lambat: ganti model nggak akan menolong.
          netErr = const AiException(
            'Waktu koneksi habis. Periksa koneksi internet lalu coba lagi.',
          );
          break outer;
        } on http.ClientException {
          netErr = const AiException('Gagal terhubung ke server Gemini. Periksa koneksi internet.');
          break outer;
        }
      }
    }

    if (ok == null) {
      final e = firstErr;
      if (e != null) {
        throw AiException(_friendlyError(e.statusCode, _tryDecode(utf8.decode(e.bodyBytes))));
      }
      throw netErr ??
          const AiException('Server Gemini belum merespons. Silakan coba lagi sebentar lagi.');
    }

    final decoded = _tryDecode(utf8.decode(ok.bodyBytes));

    final block = decoded?['promptFeedback']?['blockReason'];
    if (block != null) {
      throw AiException('Permintaan ditolak oleh filter model ($block).');
    }

    final candidates = decoded?['candidates'];
    if (candidates is! List || candidates.isEmpty) {
      throw const AiException('Model tidak memberikan jawaban. Silakan coba lagi.');
    }
    final first = candidates.first;
    final cand = (first is Map) ? first : const <String, dynamic>{};
    final finish = cand['finishReason']?.toString();
    final content = cand['content'];
    final partsOut = (content is Map) ? content['parts'] : null;
    final text = (partsOut is List)
        ? partsOut
            .whereType<Map>()
            .where((p) => p['thought'] != true)
            .map((p) => p['text']?.toString() ?? '')
            .join()
            .trim()
        : '';

    switch (finish) {
      case null:
      case 'STOP':
      case 'FINISH_REASON_UNSPECIFIED':
        break;
      case 'MAX_TOKENS':
        // Teks biasa (OCR) yang kepotong masih berguna; JSON yang kepotong rusak.
        if (json || text.isEmpty) {
          throw const AiException(
            'Jawaban AI terpotong karena terlalu panjang. Coba persingkat atau persempit permintaan.',
          );
        }
      case 'SAFETY':
        throw const AiException('Jawaban diblokir oleh filter keamanan model. Coba ubah kata-katanya.');
      case 'RECITATION':
        throw const AiException(
          'Model berhenti karena jawabannya terdeteksi mengutip teks panjang. Silakan coba lagi.',
        );
      default:
        if (text.isEmpty) {
          throw AiException('Model berhenti tanpa jawaban ($finish). Silakan coba lagi.');
        }
    }
    return text;
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
          return 'API key tidak valid. Periksa kembali di Setelan.';
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
        if (code >= 500) return 'Server Gemini sedang bermasalah ($code). Silakan coba lagi nanti.';
        return 'Gagal ($code). $apiMsg'.trim();
    }
  }
}
