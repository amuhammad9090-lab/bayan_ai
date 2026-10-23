import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../core/ai_repository.dart';
import '../../core/history_recorder.dart';
import '../../models/models.dart';

class OcrProvider extends ChangeNotifier {
  OcrProvider(this._ai, this._history);

  final AiRepository _ai;
  final HistoryRecorder _history;

  File? _image;
  String _text = '';
  int _textVersion = 0;
  bool _loading = false;
  String? _error;

  File? get image => _image;
  String get text => _text;
  int get textVersion => _textVersion;
  bool get loading => _loading;
  String? get error => _error;
  bool get hasText => _text.trim().isNotEmpty;

  void setImage(File f) {
    _image = f;
    _setText('');
    _error = null;
    notifyListeners();
  }

  void clear() {
    _image = null;
    _error = null;
    _loading = false;
    _setText('');
    notifyListeners();
  }

  /// Dipanggil saat pengguna mengetik/mengedit hasil OCR.
  void onUserEdit(String t) {
    if (t == _text) return;
    _text = t;
    notifyListeners();
  }

  void _setText(String t) {
    _text = t;
    _textVersion++;
  }

  Future<void> run() async {
    final img = _image;
    if (img == null || _loading) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final bytes = await img.readAsBytes();
      final result = await _ai.ocr(bytes, _mimeOf(img.path));
      _setText(result);
      await _history.record(HistoryType.ocr, '', result);
    } on AiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Terjadi kesalahan: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  String _mimeOf(String path) {
    final p = path.toLowerCase();
    if (p.endsWith('.png')) return 'image/png';
    if (p.endsWith('.webp')) return 'image/webp';
    if (p.endsWith('.heic')) return 'image/heic';
    return 'image/jpeg';
  }
}
