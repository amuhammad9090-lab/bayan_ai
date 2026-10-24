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

  static const _baseKey = 'history_v1';
  static const _max = 60;

  final KeyValueStore _store;
  final bool Function() _enabled;
  List<HistoryItem> _items = [];
  String? _uid;

  String get _key => _uid == null ? _baseKey : '${_baseKey}_$_uid';

  /// Ganti pemilik riwayat (dipanggil saat login/logout). null = tamu.
  void switchUser(String? uid) {
    if (uid == _uid) return;
    _uid = uid;
    _items = [];
    _load();
    notifyListeners();
  }

  /// Hapus permanen riwayat milik [uid] di perangkat ini (saat akun dihapus).
  Future<void> purgeUser(String uid) async {
    await _store.remove('${_baseKey}_$uid');
    if (_uid == uid) {
      _items = [];
      notifyListeners();
    }
  }

  /// Pemilik riwayat yang sedang dimuat (null = tamu).
  String? get ownerUid => _uid;

  static String _dedupeKey(HistoryItem e) =>
      '${e.type.name}|${e.input.isNotEmpty ? e.input : e.output}';

  /// Gabungkan riwayat dari cadangan cloud (tidak menghapus yang lokal).
  /// Mengembalikan jumlah entri baru yang masuk.
  Future<int> merge(List<HistoryItem> incoming) async {
    final before = {for (final e in _items) e.id};
    final byId = {for (final e in _items) e.id: e};
    for (final e in incoming) {
      byId.putIfAbsent(e.id, () => e);
    }
    final all = byId.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final seen = <String>{};
    var merged = all.where((e) => seen.add(_dedupeKey(e))).toList();
    if (merged.length > _max) merged = merged.sublist(0, _max);
    final added = merged.where((e) => !before.contains(e.id)).length;
    if (added == 0) return 0;
    _items = merged;
    notifyListeners();
    await _persist();
    return added;
  }

  List<HistoryItem> get items => List.unmodifiable(_items);
  List<HistoryItem> get recent => _items.take(4).toList();
  int count(HistoryType t) => _items.where((e) => e.type == t).length;

  void _load() {
    _items = [];
    final raw = _store.getString(_key);
    if (raw == null) return;
    try {
      final list = jsonDecode(raw) as List;
      _items = list
          .whereType<Map>()
          .map((e) => HistoryItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      // Bersihin duplikat lama (entri terbaru dipertahankan).
      final seen = <String>{};
      _items = _items
          .where((e) => seen.add('${e.type.name}|${e.input.isNotEmpty ? e.input : e.output}'))
          .toList();
    } catch (_) {
      _items = [];
    }
  }

  /// Muat ulang dari penyimpanan (tarik-untuk-refresh).
  void reload() {
    _load();
    notifyListeners();
  }

  Future<void> _persist() => _store.setString(
        _key,
        jsonEncode(_items.map((e) => e.toJson()).toList()),
      );

  @override
  Future<void> record(HistoryType type, String input, String output) async {
    if (!_enabled() || output.trim().isEmpty) return;
    // Pencarian/analisis yang sama (termasuk hasil cache & tarik-untuk-refresh)
    // nggak dicatat dobel: entri lama dibuang, yang baru naik ke paling atas.
    final inp = input.trim();
    final out = output.trim();
    _items.removeWhere((e) =>
        e.type == type && (inp.isNotEmpty ? e.input == inp : e.output == out));
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
