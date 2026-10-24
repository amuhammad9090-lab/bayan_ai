import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../core/ai_repository.dart';
import '../../core/handoff.dart';
import '../../core/history_recorder.dart';
import '../../models/models.dart';

class NahwuProvider extends ChangeNotifier {
  NahwuProvider(this._ai, this._history, HandoffService handoff) {
    _sub = handoff.stream.listen((m) {
      if (m.target == HandoffTarget.nahwu) setInput(m.text);
    });
  }

  final AiRepository _ai;
  final HistoryRecorder _history;
  final _rand = Random();
  late final StreamSubscription<HandoffMessage> _sub;

  String _input = '';
  int _inputVersion = 0;
  bool _loading = false;
  String? _error;
  NahwuAnalysis? _analysis;

  /// Naik tiap clear/analyze: hasil request lama dibuang kalau sudah basi.
  int _gen = 0;
  bool _disposed = false;

  /// Naik tiap hasil baru, dipakai buat me-restart animasi kartu.
  int _runId = 0;

  String get input => _input;
  int get inputVersion => _inputVersion;
  bool get loading => _loading;
  String? get error => _error;
  NahwuAnalysis? get analysis => _analysis;
  int get runId => _runId;

  static const examples = <String>[
    'مَنْ لَمْ يَشْكُرِ الْقَلِيلَ لَمْ يَشْكُرِ الْكَثِيرَ',
    'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ',
    'قُلْ هُوَ اللَّهُ أَحَدٌ',
    'رَبِّ اشْرَحْ لِي صَدْرِي',
    'إِنَّ اللَّهَ مَعَ الصَّابِرِينَ',
  ];

  /// Set input dari luar (paste, contoh, handoff). Memperbarui field input.
  void setInput(String t) {
    _input = t;
    _inputVersion++;
    notifyListeners();
  }

  /// Dipanggil saat pengguna mengetik.
  void onUserEdit(String t) {
    if (t == _input) return;
    _input = t;
    notifyListeners();
  }

  void randomExample() => setInput(examples[_rand.nextInt(examples.length)]);

  void clear() {
    _gen++;
    _loading = false;
    _input = '';
    _inputVersion++;
    _analysis = null;
    _error = null;
    notifyListeners();
  }

  Future<void> analyze() async {
    final t = _input.trim();
    if (t.isEmpty || _loading) return;
    final gen = ++_gen;
    _loading = true;
    _error = null;
    _analysis = null;
    notifyListeners();
    try {
      final a = await _ai.analyzeNahwu(t);
      if (gen != _gen) return;
      if (a.isEmpty) {
        _error = 'Kalimat belum bisa dianalisis. '
            'Pastikan teksnya berbahasa Arab (lebih baik berharakat), lalu coba lagi.';
      } else if (a.isBroken) {
        _error = 'Jawaban AI terpotong atau tidak terbaca. Silakan coba lagi.';
      } else {
        _analysis = a;
        _runId++;
        await _history.record(HistoryType.nahwu, t, a.toPlainText());
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
