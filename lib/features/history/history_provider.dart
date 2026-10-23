import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../core/history_recorder.dart';
import '../../core/storage.dart';
import '../../models/models.dart';

class HistoryProvider extends ChangeNotifier implements HistoryRecorder {
  /// [enabled] dicek tiap [record] (mis. dari pengaturan auto-save),
  /// jadi provider ini nggak perlu tau soal Settings.
  HistoryProvider(this._store, {bool Function()? enabled})
      : _enabled = enabled ?? (() => true) {
    _load();
  }

  static const _key = 'history_v1';
  static const _max = 60;

  final KeyValueStore _store;
  final bool Function() _enabled;
  List<HistoryItem> _items = [];

  List<HistoryItem> get items => List.unmodifiable(_items);
  List<HistoryItem> get recent => _items.take(4).toList();
  int count(HistoryType t) => _items.where((e) => e.type == t).length;

  void _load() {
    final raw = _store.getString(_key);
    if (raw == null) return;
    try {
      final list = jsonDecode(raw) as List;
      _items = list
          .whereType<Map>()
          .map((e) => HistoryItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      _items = [];
    }
  }

  Future<void> _persist() => _store.setString(
        _key,
        jsonEncode(_items.map((e) => e.toJson()).toList()),
      );

  @override
  Future<void> record(HistoryType type, String input, String output) async {
    if (!_enabled() || output.trim().isEmpty) return;
    _items.insert(
      0,
      HistoryItem(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        type: type,
        input: input.trim(),
        output: output.trim(),
        createdAt: DateTime.now(),
      ),
    );
    if (_items.length > _max) _items = _items.sublist(0, _max);
    notifyListeners();
    await _persist();
  }

  Future<void> remove(String id) async {
    _items.removeWhere((e) => e.id == id);
    notifyListeners();
    await _persist();
  }

  Future<void> clear() async {
    _items = [];
    notifyListeners();
    await _persist();
  }
}
