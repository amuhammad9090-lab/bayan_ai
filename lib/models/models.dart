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

/// Teks mentah dianggap "kosong" kalau benar-benar kosong atau cuma kerangka
/// JSON valid tanpa isi (mis. {"hasil": []}).
bool _blankRaw(String raw) {
  final t = stripFences(raw);
  if (t.isEmpty) return true;
  if (!t.startsWith('{') && !t.startsWith('[')) return false;
  try {
    jsonDecode(t);
    return true;
  } catch (_) {
    return false; // JSON rusak/terpotong: bukan "kosong", lihat [_brokenRaw].
  }
}

/// JSON yang rusak atau terpotong (mis. jawaban model kepotong di tengah).
bool _brokenRaw(String raw) {
  final t = stripFences(raw);
  return (t.startsWith('{') || t.startsWith('[')) && !_blankRaw(t);
}

String _s(dynamic v) => v?.toString().trim() ?? '';

// ───────────────────────── Nahwu ─────────────────────────

class NahwuWord {
  final String kata;
  final String jenis; // isim / fi'il / huruf
  final String bab; // salah satu dari 7 bab (Al-Kalam, Al-I'rab, ...)
  final String irab;
  final String tanda; // alamat i'rab, mis. dhammah zhahirah
  final String makna;

  const NahwuWord({
    required this.kata,
    required this.jenis,
    this.bab = '',
    required this.irab,
    this.tanda = '',
    required this.makna,
  });

  factory NahwuWord.fromJson(Map<String, dynamic> j) => NahwuWord(
        kata: _s(j['kata']),
        jenis: _s(j['jenis']),
        bab: _s(j['bab']),
        irab: _s(j['irab']),
        tanda: _s(j['tanda']),
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
  bool get isEmpty => !isStructured && _blankRaw(raw);
  bool get isBroken => !isStructured && _brokenRaw(raw);

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
      final parts = [w.kata, w.jenis, if (w.bab.isNotEmpty) 'Bab ${w.bab}', w.irab,
        if (w.tanda.isNotEmpty) 'tanda: ${w.tanda}', w.makna];
      b.writeln('${i + 1}. ${parts.join(' — ')}');
    }
    if (ringkasan.isNotEmpty) b.writeln('\nRingkasan: $ringkasan');
    return b.toString().trim();
  }
}

// ───────────────────────── Quran ─────────────────────────

/// Satu bagian tafsir (mis. "Kosakata", "Penjelasan", "Pelajaran").
/// Isinya bisa paragraf ([text]), poin-poin ([points]), atau daftar kata ([words]).
class TafsirSection {
  final String title;
  final String text;
  final List<String> points;
  final List<(String kata, String arti)> words;

  const TafsirSection(
    this.title, {
    this.text = '',
    this.points = const [],
    this.words = const [],
  });

  bool get isEmpty => text.isEmpty && points.isEmpty && words.isEmpty;

  String toPlainText() {
    final b = StringBuffer('$title:');
    if (text.isNotEmpty) b.write(' $text');
    for (final p in points) {
      b.write('\n- $p');
    }
    for (final (k, a) in words) {
      b.write('\n- $k: $a');
    }
    return b.toString();
  }

  /// Urutan & judul bagian tiap pendekatan tafsir (kunci JSON -> judul).
  static const munirSchema = <(String, String)>[
    ('mufradat', 'Kosakata (mufradat)'),
    ('balaghah', 'Balaghah & i\'rab penting'),
    ('asbabun_nuzul', 'Sabab nuzul'),
    ('penjelasan', 'Tafsir & penjelasan'),
    ('hukum', 'Fiqh al-hayah: hukum & pelajaran'),
  ];
  static const mishbahSchema = <(String, String)>[
    ('tema', 'Tema & tujuan surah'),
    ('munasabah', 'Munasabah (keterkaitan ayat)'),
    ('kosakata', 'Makna kosakata'),
    ('penjelasan', 'Penjelasan'),
    ('pesan', 'Pesan & relevansi masa kini'),
  ];

  /// Format lama (satu paragraf) tetap didukung: jadi satu bagian "Ringkasan".
  static List<TafsirSection> parse(dynamic v, List<(String, String)> schema) {
    if (v is String) {
      final t = v.trim();
      return t.isEmpty ? const [] : [TafsirSection('Ringkasan', text: t)];
    }
    if (v is! Map) return const [];
    final out = <TafsirSection>[];
    for (final (key, title) in schema) {
      final x = v[key];
      if (x is String && x.trim().isNotEmpty) {
        out.add(TafsirSection(title, text: x.trim()));
      } else if (x is List) {
        final words = <(String, String)>[];
        final points = <String>[];
        for (final e in x) {
          if (e is Map) {
            final k = _s(e['kata']);
            final a = _s(e['arti']);
            if (k.isNotEmpty && a.isNotEmpty) words.add((k, a));
          } else {
            final p = _s(e);
            if (p.isNotEmpty) points.add(p);
          }
        }
        if (words.isNotEmpty || points.isNotEmpty) {
          out.add(TafsirSection(title, points: points, words: words));
        }
      }
    }
    return out;
  }
}

class AyatResult {
  final String surah;
  final String nomor; // contoh "2:255"
  final String arab;
  final String terjemah;
  final List<TafsirSection> munir; // pendekatan Tafsir al-Munir
  final List<TafsirSection> mishbah; // pendekatan Tafsir al-Mishbah
  final String tafsir; // fallback kalau model cuma ngasih satu tafsir

  /// Rujukan ayat lain yang berkaitan, mis. "Al-Baqarah 2:153" (sudah divalidasi).
  final List<String> terkait;

  const AyatResult({
    required this.surah,
    required this.nomor,
    required this.arab,
    required this.terjemah,
    this.munir = const [],
    this.mishbah = const [],
    this.tafsir = '',
    this.terkait = const [],
  });

  bool get hasTafsir => munir.isNotEmpty || mishbah.isNotEmpty || tafsir.isNotEmpty;

  AyatResult copyWith({
    String? surah,
    String? nomor,
    String? arab,
    String? terjemah,
    List<String>? terkait,
  }) =>
      AyatResult(
        surah: surah ?? this.surah,
        nomor: nomor ?? this.nomor,
        arab: arab ?? this.arab,
        terjemah: terjemah ?? this.terjemah,
        munir: munir,
        mishbah: mishbah,
        tafsir: tafsir,
        terkait: terkait ?? this.terkait,
      );

  factory AyatResult.fromJson(Map<String, dynamic> j) => AyatResult(
        surah: _s(j['surah']),
        nomor: _s(j['nomor']),
        arab: _s(j['arab']),
        terjemah: _s(j['terjemah']),
        munir: TafsirSection.parse(j['tafsir_munir'], TafsirSection.munirSchema),
        mishbah: TafsirSection.parse(j['tafsir_mishbah'], TafsirSection.mishbahSchema),
        tafsir: _s(j['tafsir']),
        terkait: (j['ayat_terkait'] as List? ?? []).map(_s).where((e) => e.isNotEmpty).toList(),
      );

  String toPlainText() {
    final b = StringBuffer();
    b.writeln('QS. $surah ($nomor)');
    if (arab.isNotEmpty) b.writeln(arab);
    if (terjemah.isNotEmpty) b.writeln('\nTerjemah: $terjemah');
    if (munir.isNotEmpty) {
      b.writeln('\nPendekatan Tafsir al-Munir');
      for (final x in munir) {
        b.writeln(x.toPlainText());
      }
    }
    if (mishbah.isNotEmpty) {
      b.writeln('\nPendekatan Tafsir al-Mishbah');
      for (final x in mishbah) {
        b.writeln(x.toPlainText());
      }
    }
    if (tafsir.isNotEmpty) b.writeln('\nTafsir: $tafsir');
    if (terkait.isNotEmpty) b.writeln('\nAyat terkait: ${terkait.join(', ')}');
    return b.toString().trim();
  }
}

class QuranSearchResult {
  final String ringkasan;
  final List<AyatResult> ayat;
  final String raw;

  /// true = teks Arab & terjemah sudah diganti data resmi Kemenag.
  final bool verified;

  const QuranSearchResult({
    this.ringkasan = '',
    this.ayat = const [],
    this.raw = '',
    this.verified = false,
  });

  bool get isStructured => ayat.isNotEmpty;
  bool get isEmpty => !isStructured && _blankRaw(raw);
  bool get isBroken => !isStructured && _brokenRaw(raw);

  factory QuranSearchResult.parse(String text) {
    try {
      final data = jsonDecode(stripFences(text));
      if (data is Map<String, dynamic>) {
        final list = (data['hasil'] as List? ?? [])
            .whereType<Map>()
            .map((e) => AyatResult.fromJson(Map<String, dynamic>.from(e)))
            // Yang penting nomor ayatnya; teks diambil dari data resmi.
            .where((a) => a.nomor.isNotEmpty)
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
