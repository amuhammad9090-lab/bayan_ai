import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../core/storage.dart';
import '../history/history_provider.dart';
import 'backup_service.dart';

/// Cadangan cloud riwayat (Qur'an, Nahwu, OCR) per akun.
///
/// Hemat baca/tulis:
/// - Semua riwayat = 1 dokumen. Cadangkan = 1 tulis, pulihkan = 1 baca.
/// - Otomatis hanya kalau ada perubahan, ditunda [_debounce] supaya beberapa
///   pencarian beruntun cuma jadi 1 tulis; dikirim segera saat app ditutup.
/// - Pulihkan otomatis sekali saja per akun per perangkat (mis. install ulang).
/// - Sebelum tulis pertama di sesi ini, cadangan dicek sekali (1 baca) supaya
///   riwayat dari perangkat lain nggak ketimpa.
class BackupProvider extends ChangeNotifier {
  BackupProvider({
    required this.uid,
    required KeyValueStore store,
    required HistoryProvider history,
    BackupService? service,
  })  : _store = store,
        _history = history,
        _service = uid == null ? null : (service ?? BackupService()) {
    if (uid == null) return;
    _auto = _store.getBool(_k('auto')) ?? true;
    _lastAt = _readTime(_k('last'));
    _lastCount = int.tryParse(_store.getString(_k('count')) ?? '') ?? 0;
    _rev = int.tryParse(_store.getString(_k('rev')) ?? '') ?? 0;
    _syncedSig = _store.getString(_k('sig')) ?? '';
    _history.addListener(_onHistory);
    _life = AppLifecycleListener(onPause: _flush, onDetach: _flush);
    // Pertama kali akun ini dipakai di perangkat ini: tarik cadangan sekali.
    if (_store.getBool(_k('init')) != true) {
      scheduleMicrotask(() => restore(silent: true));
    }
  }

  static const _debounce = Duration(minutes: 2);

  /// null = tamu / Firebase belum siap: fitur nonaktif.
  final String? uid;
  final KeyValueStore _store;
  final HistoryProvider _history;
  final BackupService? _service;
  AppLifecycleListener? _life;
  Timer? _timer;
  bool _disposed = false;

  bool _auto = true;
  bool _busy = false;
  String? _error;
  DateTime? _lastAt;
  int _lastCount = 0;
  int _rev = 0;

  /// Tanda isi riwayat saat terakhir sinkron dengan cloud (disimpan, jadi
  /// tetap benar walau app ditutup sebelum sempat mencadangkan).
  String _syncedSig = '';
  bool _cloudChecked = false;

  bool get available => uid != null;
  bool get auto => _auto;
  bool get busy => _busy;
  String? get error => _error;
  DateTime? get lastBackupAt => _lastAt;
  int get lastCount => _lastCount;

  /// Ada perubahan riwayat yang belum dicadangkan.
  bool get dirty =>
      available && _history.ownerUid == uid && _history.items.isNotEmpty && _sig() != _syncedSig;

  /// Ringkas isi riwayat: berubah kalau ada entri ditambah/dihapus.
  String _sig() {
    var h = 0x811c9dc5;
    for (final e in _history.items) {
      for (final c in e.id.codeUnits) {
        h = ((h ^ c) * 0x01000193) & 0xFFFFFFFF;
      }
    }
    return '${_history.items.length}:$h';
  }

  String _k(String name) => 'backup_${name}_$uid';

  DateTime? _readTime(String key) {
    final ms = int.tryParse(_store.getString(key) ?? '');
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  void _onHistory() {
    if (_history.ownerUid != uid) return; // riwayat sedang ganti akun
    notifyListeners(); // status "ada perubahan" ikut terbarui
    if (!_auto || !dirty) return;
    _timer?.cancel();
    _timer = Timer(_debounce, () => backup(silent: true));
  }

  void _flush() {
    if (_auto && dirty && !_busy) {
      _timer?.cancel();
      backup(silent: true);
    }
  }

  Future<void> setAuto(bool v) async {
    if (!available) return;
    _auto = v;
    notifyListeners();
    await _store.setBool(_k('auto'), v);
    if (v && dirty) _onHistory();
  }

  /// Dipanggil sebelum keluar akun: kirim perubahan yang tertunda (maks. 6 detik).
  Future<void> flushBeforeSignOut() async {
    if (!_auto || !dirty) return;
    try {
      await backup(silent: true).timeout(const Duration(seconds: 6));
    } catch (_) {}
  }

  /// Cadangkan riwayat lokal. `true` kalau berhasil. [silent] = otomatis:
  /// nggak menulis apa pun kalau memang tidak ada perubahan.
  Future<bool> backup({bool silent = false}) async {
    final s = _service;
    final id = uid;
    if (s == null || id == null || _busy || _history.ownerUid != id) return false;
    _timer?.cancel();
    if (silent && !dirty) return true;
    if (_history.items.isEmpty) {
      // Jangan pernah menimpa cadangan dengan riwayat kosong.
      if (!silent) _setError('Riwayat masih kosong, belum ada yang dicadangkan.');
      return false;
    }
    _setBusy(true);
    try {
      // Sekali per sesi: kalau cadangan diubah perangkat lain, gabungkan dulu.
      if (!_cloudChecked) {
        final cloud = await s.load(id);
        _cloudChecked = true;
        if (cloud != null && cloud.rev != _rev) await _history.merge(cloud.items);
      }
      final items = _history.items;
      final rev = DateTime.now().millisecondsSinceEpoch;
      await s.save(id, items, rev);
      _rev = rev;
      _syncedSig = _sig();
      _lastAt = DateTime.now();
      _lastCount = items.length;
      await _persistMeta();
      _error = null;
      return true;
    } catch (e) {
      if (!silent) _setError(_describe(e));
      return false;
    } finally {
      _setBusy(false);
    }
  }

  /// Ambil cadangan dan gabungkan ke riwayat lokal (riwayat lokal tidak dihapus).
  /// Mengembalikan jumlah riwayat baru, atau null kalau gagal / belum ada cadangan.
  Future<int?> restore({bool silent = false}) async {
    final s = _service;
    final id = uid;
    if (s == null || id == null || _busy) return null;
    _setBusy(true);
    try {
      final cloud = await s.load(id);
      await _store.setBool(_k('init'), true);
      _cloudChecked = true;
      if (cloud == null) {
        if (!silent) _setError('Belum ada cadangan di cloud untuk akun ini.');
        return null;
      }
      final hadLocal = _history.items.length;
      final added = await _history.merge(cloud.items);
      _rev = cloud.rev;
      // Lokal kosong / sama persis dengan cloud -> nggak ada yang perlu dikirim balik.
      if (hadLocal == 0 || (added == 0 && _history.items.length == cloud.items.length)) {
        _syncedSig = _sig();
      }
      _lastAt ??= cloud.updatedAt;
      _lastCount = cloud.items.length;
      await _persistMeta();
      _error = null;
      return added;
    } catch (e) {
      if (!silent) _setError(_describe(e));
      return null;
    } finally {
      _setBusy(false);
    }
  }

  Future<void> _persistMeta() async {
    await _store.setString(_k('rev'), '$_rev');
    await _store.setString(_k('sig'), _syncedSig);
    await _store.setString(_k('count'), '$_lastCount');
    if (_lastAt != null) {
      await _store.setString(_k('last'), '${_lastAt!.millisecondsSinceEpoch}');
    }
  }

  String _describe(Object e) {
    final s = e.toString();
    if (s.contains('permission-denied')) {
      return 'Akses cadangan ditolak. Perbarui Firestore Rules (lihat firestore.rules).';
    }
    if (s.contains('unavailable') || s.contains('network')) {
      return 'Tidak ada koneksi internet. Coba lagi nanti.';
    }
    return 'Gagal memproses cadangan. Coba lagi nanti.';
  }

  void _setBusy(bool v) {
    _busy = v;
    notifyListeners();
  }

  void _setError(String m) {
    _error = m;
    notifyListeners();
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _life?.dispose();
    _history.removeListener(_onHistory);
    super.dispose();
  }
}
