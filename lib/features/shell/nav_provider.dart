import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/handoff.dart';

/// Index tab: 0 Beranda, 1 Al-Qur'an, 2 Nahwu, 3 OCR, 4 Setelan.
/// Otomatis pindah tab kalau ada handoff ke fitur tertentu.
class NavProvider extends ChangeNotifier {
  NavProvider(HandoffService handoff) {
    _sub = handoff.stream.listen((m) {
      switch (m.target) {
        case HandoffTarget.nahwu:
          go(nahwu);
          break;
        case HandoffTarget.quran:
          go(quran);
          break;
        case HandoffTarget.ocr:
          go(ocr);
          break;
      }
    });
  }

  static const home = 0;
  static const quran = 1;
  static const nahwu = 2;
  static const ocr = 3;
  static const settings = 4;

  late final StreamSubscription<HandoffMessage> _sub;

  int _index = 0;
  int get index => _index;

  void go(int i) {
    if (i == _index) return;
    _index = i;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
