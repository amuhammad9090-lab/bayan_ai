import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/ai_repository.dart';
import '../../core/handoff.dart';
import '../../core/history_recorder.dart';
import '../../data/quran_text.dart';
import '../../models/models.dart';

class QuranProvider extends ChangeNotifier {
  QuranProvider(this._ai, this._text, this._history, HandoffService handoff) {
    _sub = handoff.stream.listen((m) {
      if (m.target == HandoffTarget.quran) setQuery(m.text);
    });
  }

  final AiRepository _ai;
  final QuranText _text;
  final HistoryRecorder _history;
  late final StreamSubscription<HandoffMessage> _sub;

  String _query = '';
  int _queryVersion = 0;
  bool _loading = false;
  String? _error;
  QuranSearchResult? _result;

  /// Naik tiap clear/search: hasil request lama dibuang kalau sudah basi.
  int _gen = 0;
  bool _disposed = false;

  String get query => _query;
  int get queryVersion => _queryVersion;
  bool get loading => _loading;
  String? get error => _error;
  QuranSearchResult? get result => _result;

  static const suggestions = <String>[
    'Ayat tentang sabar',
    'Ayat Kursi',
    'Tafsir QS. Al-Ikhlas',
    'Adab kepada orang tua',
    'Keutamaan menuntut ilmu',
  ];

  /// Set query dari luar (chip saran, handoff). Memperbarui field input.
  void setQuery(String q) {
    _query = q;
    _queryVersion++;
    notifyListeners();
  }

  /// Dipanggil saat pengguna mengetik.
  void onUserEdit(String q) {
    if (q == _query) return;
    _query = q;
    notifyListeners();
  }

  void clear() {
    _gen++;
    _loading = false;
    _query = '';
    _queryVersion++;
    _result = null;
    _error = null;
    notifyListeners();
  }

  Future<void> search() async {
    final q = _query.trim();
    if (q.isEmpty || _loading) return;
    final gen = ++_gen;
    _loading = true;
    _error = null;
    _result = null;
    notifyListeners();
    try {
      final r = await _ai.searchQuran(q);
      if (gen != _gen) return;
      if (r.isEmpty) {
        _error = 'Belum ada ayat yang cocok dengan "$q". '
            'Coba kata kunci lain, misalnya topik atau nama surah.';
      } else if (!r.isStructured) {
        // Jawaban bebas dari AI bisa berisi teks ayat karangan: jangan ditampilkan.
        _error = 'Jawaban AI terpotong atau tidak terbaca. Silakan coba lagi.';
      } else {
        // AI cuma memilih nomor ayat; teks & terjemah diambil dari data Kemenag.
        final v = await _text.verify(r);
        if (gen != _gen) return;
        if (v.ayat.isEmpty) {
          _error = 'Nomor ayat dari AI tidak valid. Silakan coba lagi '
              'atau sebutkan nama surahnya.';
        } else {
          _result = v;
          await _history.record(HistoryType.quran, q, v.toPlainText());
        }
      }
    } on AiException catch (e) {
      if (gen == _gen) _error = e.message;
    } catch (e) {
      if (gen == _gen) _error = 'Terjadi kesalahan: $e';
    } finally {
      if (gen == _gen) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _gen++;
    _sub.cancel();
    super.dispose();
  }
}
