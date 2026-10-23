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
    _input = '';
    _inputVersion++;
    _analysis = null;
    _error = null;
    notifyListeners();
  }

  Future<void> analyze() async {
    final t = _input.trim();
    if (t.isEmpty || _loading) return;
    _loading = true;
    _error = null;
    _analysis = null;
    notifyListeners();
    try {
      final a = await _ai.analyzeNahwu(t);
      _analysis = a;
      _runId++;
      await _history.record(HistoryType.nahwu, t, a.toPlainText());
    } on AiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Terjadi kesalahan: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
