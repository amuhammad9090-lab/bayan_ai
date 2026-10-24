import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import '../models/models.dart';

/// Teks Al-Qur'an (rasm Kemenag) + terjemah resmi Kemenag RI, dibundel offline
/// di assets/quran/quran_id.json. Teks ayat TIDAK pernah diambil dari AI:
/// AI cuma memilih nomor ayat, teksnya diambil dari sini.
class QuranText {
  QuranText({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  static const asset = 'assets/quran/quran_id.json';

  /// Batas ayat per hasil (rentang panjang dipotong).
  static const maxRange = 10;

  final AssetBundle _bundle;
  Future<List<_Surah>>? _data;

  Future<List<_Surah>> _load() => _data ??= _read();

  Future<List<_Surah>> _read() async {
    try {
      final s = await _bundle.loadString(asset);
      return await compute(_parse, s);
    } catch (_) {
      _data = null; // biar bisa dicoba lagi
      rethrow;
    }
  }

  /// Muat data lebih awal (opsional) supaya pencarian pertama nggak nunggu.
  void warmUp() => _load().ignore();

  /// Ganti teks Arab, terjemah, dan nama surah setiap hasil dengan data resmi.
  /// Hasil dengan nomor ayat yang tidak valid dibuang.
  Future<QuranSearchResult> verify(QuranSearchResult r) async {
    if (!r.isStructured) return r;
    final data = await _load();
    final out = <AyatResult>[];
    final seen = <String>{};
    for (final a in r.ayat) {
      final ref = AyatRef.tryParse(a.nomor);
      if (ref == null || ref.surah < 1 || ref.surah > data.length) continue;
      final s = data[ref.surah - 1];
      if (ref.from < 1 || ref.from > s.text.length) continue;
      final to = math.min(math.min(ref.to, s.text.length), ref.from + maxRange - 1);
      final key = '${ref.surah}:${ref.from}-$to';
      if (!seen.add(key)) continue;

      final single = to == ref.from;
      final arab = StringBuffer();
      final terjemah = StringBuffer();
      for (var i = ref.from; i <= to; i++) {
        if (!single) {
          arab.write('${s.text[i - 1]} ﴿${arabicDigits(i)}﴾ ');
          terjemah.write('($i) ${s.translation[i - 1]} ');
        } else {
          arab.write(s.text[i - 1]);
          terjemah.write(s.translation[i - 1]);
        }
      }
      out.add(a.copyWith(
        surah: s.latin,
        nomor: single ? '${ref.surah}:${ref.from}' : '${ref.surah}:${ref.from}-$to',
        arab: arab.toString().trim(),
        terjemah: terjemah.toString().trim(),
      ));
    }
    return QuranSearchResult(ringkasan: r.ringkasan, ayat: out, raw: r.raw, verified: true);
  }

  static List<_Surah> _parse(String s) => (jsonDecode(s) as List)
      .cast<Map<String, dynamic>>()
      .map((m) => _Surah(
            latin: m['n'] as String,
            text: (m['t'] as List).cast<String>(),
            translation: (m['i'] as List).cast<String>(),
          ))
      .toList(growable: false);
}

class _Surah {
  final String latin;
  final List<String> text;
  final List<String> translation;
  const _Surah({required this.latin, required this.text, required this.translation});
}

/// Rujukan ayat, mis. "2:255" atau "2:255-257".
class AyatRef {
  final int surah;
  final int from;
  final int to;
  const AyatRef(this.surah, this.from, this.to);

  static final _re = RegExp(r'(\d{1,3})\s*[:.]\s*(\d{1,3})(?:\s*[-–—]\s*(\d{1,3}))?');

  static AyatRef? tryParse(String s) {
    final m = _re.firstMatch(s);
    if (m == null) return null;
    final surah = int.parse(m.group(1)!);
    final from = int.parse(m.group(2)!);
    final to = m.group(3) == null ? from : int.parse(m.group(3)!);
    return AyatRef(surah, from, to < from ? from : to);
  }
}

String arabicDigits(int n) => n
    .toString()
    .split('')
    .map((d) => String.fromCharCode(0x0660 + int.parse(d)))
    .join();
