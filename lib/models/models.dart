import 'dart:convert';

/// Bersihin pembungkus ```json ... ``` kalau model ngeluarin code fence.
String stripFences(String raw) {
  var s = raw.trim();
  if (s.startsWith('```')) {
    s = s.replaceFirst(RegExp(r'^```[a-zA-Z]*\s*'), '');
    s = s.replaceFirst(RegExp(r'\s*```$'), '');
  }
  return s.trim();
}

String _s(dynamic v) => v?.toString().trim() ?? '';

// ───────────────────────── Nahwu ─────────────────────────

class NahwuWord {
  final String kata;
  final String jenis; // isim / fi'il / huruf
  final String irab;
  final String makna;

  const NahwuWord({
    required this.kata,
    required this.jenis,
    required this.irab,
    required this.makna,
  });

  factory NahwuWord.fromJson(Map<String, dynamic> j) => NahwuWord(
        kata: _s(j['kata']),
        jenis: _s(j['jenis']),
        irab: _s(j['irab']),
        makna: _s(j['makna']),
      );
}

class NahwuAnalysis {
  final List<NahwuWord> words;
  final String jenisKalimat;
  final String ringkasan;

  /// Kalau JSON gagal diparse, teks mentah dari model disimpan di sini.
  final String raw;

  const NahwuAnalysis({
    this.words = const [],
    this.jenisKalimat = '',
    this.ringkasan = '',
    this.raw = '',
  });

  bool get isStructured => words.isNotEmpty;

  factory NahwuAnalysis.parse(String text) {
    try {
      final data = jsonDecode(stripFences(text));
      if (data is Map<String, dynamic>) {
        final list = (data['kata'] as List? ?? [])
            .whereType<Map>()
            .map((e) => NahwuWord.fromJson(Map<String, dynamic>.from(e)))
            .where((w) => w.kata.isNotEmpty)
            .toList();
        if (list.isNotEmpty) {
          return NahwuAnalysis(
            words: list,
            jenisKalimat: _s(data['jenis_kalimat']),
            ringkasan: _s(data['ringkasan']),
            raw: text,
          );
        }
      }
    } catch (_) {}
    return NahwuAnalysis(raw: text);
  }

  String toPlainText() {
    if (!isStructured) return raw;
    final b = StringBuffer();
    if (jenisKalimat.isNotEmpty) b.writeln('Jenis kalimat: $jenisKalimat\n');
    for (var i = 0; i < words.length; i++) {
      final w = words[i];
      b.writeln('${i + 1}. ${w.kata} — ${w.jenis} — ${w.irab} — ${w.makna}');
    }
    if (ringkasan.isNotEmpty) b.writeln('\nRingkasan: $ringkasan');
    return b.toString().trim();
  }
}

// ───────────────────────── Quran ─────────────────────────

class AyatResult {
  final String surah;
  final String nomor; // contoh "2:255"
  final String arab;
  final String terjemah;
  final String tafsir;

  const AyatResult({
    required this.surah,
    required this.nomor,
    required this.arab,
    required this.terjemah,
    required this.tafsir,
  });

  factory AyatResult.fromJson(Map<String, dynamic> j) => AyatResult(
        surah: _s(j['surah']),
        nomor: _s(j['nomor']),
        arab: _s(j['arab']),
        terjemah: _s(j['terjemah']),
        tafsir: _s(j['tafsir']),
      );

  String toPlainText() {
    final b = StringBuffer();
    b.writeln('QS. $surah ($nomor)');
    if (arab.isNotEmpty) b.writeln(arab);
    if (terjemah.isNotEmpty) b.writeln('\nTerjemah: $terjemah');
    if (tafsir.isNotEmpty) b.writeln('\nTafsir: $tafsir');
    return b.toString().trim();
  }
}

class QuranSearchResult {
  final String ringkasan;
  final List<AyatResult> ayat;
  final String raw;

  const QuranSearchResult({
    this.ringkasan = '',
    this.ayat = const [],
    this.raw = '',
  });

  bool get isStructured => ayat.isNotEmpty;

  factory QuranSearchResult.parse(String text) {
    try {
      final data = jsonDecode(stripFences(text));
      if (data is Map<String, dynamic>) {
        final list = (data['hasil'] as List? ?? [])
            .whereType<Map>()
            .map((e) => AyatResult.fromJson(Map<String, dynamic>.from(e)))
            .where((a) => a.arab.isNotEmpty || a.terjemah.isNotEmpty)
            .toList();
        if (list.isNotEmpty) {
          return QuranSearchResult(
            ringkasan: _s(data['ringkasan']),
            ayat: list,
            raw: text,
          );
        }
      }
    } catch (_) {}
    return QuranSearchResult(raw: text);
  }

  String toPlainText() {
    if (!isStructured) return raw;
    final b = StringBuffer();
    if (ringkasan.isNotEmpty) b.writeln('$ringkasan\n');
    for (final a in ayat) {
      b.writeln(a.toPlainText());
      b.writeln();
    }
    return b.toString().trim();
  }
}

// ───────────────────────── Riwayat ─────────────────────────

enum HistoryType { ocr, quran, nahwu }

class HistoryItem {
  final String id;
  final HistoryType type;
  final String input;
  final String output;
  final DateTime createdAt;

  const HistoryItem({
    required this.id,
    required this.type,
    required this.input,
    required this.output,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'input': input,
        'output': output,
        'createdAt': createdAt.toIso8601String(),
      };

  factory HistoryItem.fromJson(Map<String, dynamic> j) => HistoryItem(
        id: _s(j['id']),
        type: HistoryType.values.firstWhere(
          (t) => t.name == j['type'],
          orElse: () => HistoryType.ocr,
        ),
        input: _s(j['input']),
        output: _s(j['output']),
        createdAt: DateTime.tryParse(_s(j['createdAt'])) ?? DateTime.now(),
      );
}
