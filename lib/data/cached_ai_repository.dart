import 'dart:convert';
import 'dart:typed_data';

import '../core/ai_repository.dart';
import '../core/storage.dart';
import '../models/models.dart';

/// Decorator: bungkus AiRepository mana pun dengan cache lokal supaya
/// permintaan yang sama (gambar/teks/model sama) tidak makan kuota API lagi.
class CachedAiRepository implements AiRepository, AiCache {
  CachedAiRepository(
    this._inner,
    this._config,
    this._store, {
    this.maxEntries = 40,
    this.ttl = const Duration(days: 7),
  }) {
    _load();
  }

  static const _baseKey = 'ai_cache_v1';
  String? _uid;

  String get _key => _uid == null ? _baseKey : '${_baseKey}_$_uid';

  /// Ganti pemilik cache (dipanggil saat login/logout). null = tamu.
  void switchUser(String? uid) {
    if (uid == _uid) return;
    _uid = uid;
    _entries = {};
    _load();
  }

  /// Hapus permanen cache AI milik [uid] di perangkat ini (saat akun dihapus).
  Future<void> purgeUser(String uid) async {
    await _store.remove('${_baseKey}_$uid');
    if (_uid == uid) _entries = {};
  }

  final AiRepository _inner;
  final AiConfigSource _config;
  final KeyValueStore _store;
  final int maxEntries;
  final Duration ttl;

  // key -> {'t': epochMillis, 'v': text}
  Map<String, Map<String, dynamic>> _entries = {};

  void _load() {
    _entries = {};
    final raw = _store.getString(_key);
    if (raw == null) return;
    try {
      final d = jsonDecode(raw) as Map<String, dynamic>;
      _entries = d.map((k, v) => MapEntry(k, Map<String, dynamic>.from(v as Map)));
    } catch (_) {
      _entries = {};
    }
  }

  Future<void> _persist() => _store.setString(_key, jsonEncode(_entries));

  String? _get(String key) {
    final e = _entries[key];
    if (e == null) return null;
    final t = DateTime.fromMillisecondsSinceEpoch(e['t'] as int);
    if (DateTime.now().difference(t) > ttl) {
      _entries.remove(key);
      return null;
    }
    return e['v'] as String?;
  }

  Future<void> _put(String key, String value) async {
    _entries[key] = {'t': DateTime.now().millisecondsSinceEpoch, 'v': value};
    if (_entries.length > maxEntries) {
      final sorted = _entries.entries.toList()
        ..sort((a, b) => (a.value['t'] as int).compareTo(b.value['t'] as int));
      for (final e in sorted.take(_entries.length - maxEntries)) {
        _entries.remove(e.key);
      }
    }
    await _persist();
  }

  /// FNV-1a 32-bit.
  int _fnv(Iterable<int> data) {
    var h = 0x811c9dc5;
    for (final b in data) {
      h ^= b;
      h = (h * 0x01000193) & 0xFFFFFFFF;
    }
    return h;
  }

  String _k(String type, Iterable<int> data, int length) =>
      '$type|${_config.aiConfig.model}|${_fnv(data)}|$length';

  // ───────────────────────── AiRepository ─────────────────────────

  @override
  Future<String> ocr(Uint8List imageBytes, String mimeType) async {
    final key = _k('ocr', imageBytes, imageBytes.length);
    final hit = _get(key);
    if (hit != null) return hit;
    final r = await _inner.ocr(imageBytes, mimeType);
    await _put(key, r);
    return r;
  }

  @override
  Future<QuranSearchResult> searchQuran(String query) async {
    final q = query.trim();
    final key = _k('quran', q.codeUnits, q.length);
    final hit = _get(key);
    if (hit != null) return QuranSearchResult.parse(hit);
    final r = await _inner.searchQuran(q);
    if (r.isStructured) await _put(key, r.raw);
    return r;
  }

  @override
  Future<NahwuAnalysis> analyzeNahwu(String sentence) async {
    final s = sentence.trim();
    final key = _k('nahwu', s.codeUnits, s.length);
    final hit = _get(key);
    if (hit != null) return NahwuAnalysis.parse(hit);
    final r = await _inner.analyzeNahwu(s);
    if (r.isStructured) await _put(key, r.raw);
    return r;
  }

  @override
  Future<bool> testConnection({String? apiKey}) => _inner.testConnection(apiKey: apiKey);

  @override
  Future<List<String>> listModels() => _inner.listModels();

  // ───────────────────────── AiCache ─────────────────────────

  @override
  int get size => _entries.length;

  @override
  Future<void> clear() async {
    _entries = {};
    await _persist();
  }
}
