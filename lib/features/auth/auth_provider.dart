import 'dart:async';

import 'package:flutter/foundation.dart';

import 'auth_models.dart';
import 'auth_service.dart';

export 'auth_models.dart';

enum AuthStatus {
  /// Menunggu Firebase menjawab sesi tersimpan.
  loading,

  /// Firebase belum dikonfigurasi (mode dev).
  unconfigured,
  signedOut,
  signedIn,

  /// Lanjut tanpa akun, hanya tersedia saat Firebase belum dikonfigurasi.
  guest,
}

class AuthProvider extends ChangeNotifier {
  AuthProvider({required bool firebaseReady})
    : _service = firebaseReady ? AuthService() : null {
    final s = _service;
    if (s == null) {
      _status = AuthStatus.unconfigured;
    } else {
      _sub = s.userChanges.listen(
        _onUser,
        onError: (Object _) => _onUser(null),
      );
    }
  }

  final AuthService? _service;
  StreamSubscription<AppUser?>? _sub;

  AuthStatus _status = AuthStatus.loading;
  AppUser? _user;
  bool _busy = false;
  String? _error;
  int _errorTick = 0;
  bool? _firestoreOk;

  AuthStatus get status => _status;
  AppUser? get user => _user;
  bool get busy => _busy;
  String? get error => _error;

  /// Naik tiap ada error baru (buat memicu animasi shake).
  int get errorTick => _errorTick;

  /// null = belum ada info, true = dokumen user tersimpan, false = gagal (cek Rules).
  bool? get firestoreOk => _firestoreOk;

  void _onUser(AppUser? u) {
    _user = u;
    _status = u == null ? AuthStatus.signedOut : AuthStatus.signedIn;
    notifyListeners();
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) => _guard((s) async {
    _firestoreOk = await s.signInWithEmail(email: email, password: password);
  });

  Future<bool> register(String name, String email, String password) =>
      _guard((s) async {
        _firestoreOk = await s.registerWithEmail(
          name: name,
          email: email,
          password: password,
        );
      });

  Future<bool> signInWithGoogle() => _guard((s) async {
    _firestoreOk = await s.signInWithGoogle();
  });

  /// Ubah nama tampilan. `true` kalau berhasil.
  Future<bool> updateName(String name) => _guard((s) async {
    await s.updateName(name);
    _user = s.current ?? _user;
  });

  /// Muat ulang profil (gagal diam-diam: nggak penting banget).
  Future<void> refreshProfile() async {
    final s = _service;
    if (s == null) return;
    try {
      await s.refreshUser();
      _user = s.current ?? _user;
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> resetPassword(String email) =>
      _guard((s) => s.sendPasswordReset(email));

  void continueAsGuest() {
    if (_status != AuthStatus.unconfigured) return;
    _status = AuthStatus.guest;
    notifyListeners();
  }

  Future<void> signOut() async {
    if (_status == AuthStatus.guest) {
      _status = AuthStatus.unconfigured;
      notifyListeners();
      return;
    }
    _firestoreOk = null;
    await _service?.signOut();
  }

  Future<bool> _guard(Future<void> Function(AuthService s) job) async {
    final s = _service;
    if (s == null) {
      _error = 'Firebase belum dikonfigurasi.';
      _errorTick++;
      notifyListeners();
      return false;
    }
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await job(s);
      return true;
    } catch (e) {
      _error = describeAuthError(e);
      if (_error != null) _errorTick++;
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
