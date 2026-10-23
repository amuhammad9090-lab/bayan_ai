import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/ai_repository.dart';
import '../../core/history_recorder.dart';
import '../../models/models.dart';

class OcrProvider extends ChangeNotifier {
  OcrProvider(this._ai, this._history);

  final AiRepository _ai;
  final HistoryRecorder _history;

  XFile? _image;
  Uint8List? _bytes;
  String _text = '';
  int _textVersion = 0;
  bool _loading = false;
  String? _error;

  /// Naik tiap clear/setImage/run: hasil request lama dibuang kalau sudah basi.
  int _gen = 0;
  bool _disposed = false;

  XFile? get image => _image;
  Uint8List? get bytes => _bytes;
  String get text => _text;
  int get textVersion => _textVersion;
  bool get loading => _loading;
  String? get error => _error;
  bool get hasText => _text.trim().isNotEmpty;

  void setImage(XFile f, Uint8List bytes) {
    _gen++;
    _loading = false;
    _image = f;
    _bytes = bytes;
    _setText('');
    _error = null;
    notifyListeners();
  }

  void clear() {
    _gen++;
    _image = null;
    _bytes = null;
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
    final data = _bytes;
    if (img == null || data == null || _loading) return;
    final gen = ++_gen;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _ai.ocr(data, img.mimeType ?? _mimeOf(img.name));
      if (gen != _gen) return;
      _setText(result);
      await _history.record(HistoryType.ocr, '', result);
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
    super.dispose();
  }

  String _mimeOf(String path) {
    final p = path.toLowerCase();
    if (p.endsWith('.png')) return 'image/png';
    if (p.endsWith('.webp')) return 'image/webp';
    if (p.endsWith('.heic')) return 'image/heic';
    return 'image/jpeg';
  }
}
