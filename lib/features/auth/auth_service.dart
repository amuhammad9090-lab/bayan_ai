import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'auth_models.dart';

/// Pembungkus Firebase Auth + Firestore. Cuma file ini yang kenal Firebase.
///
/// Dokumen user disimpan di `users/{uid}` setiap kali login berhasil.
class AuthService {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  /// userChanges (bukan authStateChanges) supaya perubahan nama setelah daftar ikut ke-update.
  Stream<AppUser?> get userChanges => _auth.userChanges().map(_map);

  AppUser? _map(User? u) => u == null
      ? null
      : AppUser(
          uid: u.uid,
          displayName: u.displayName ?? '',
          email: u.email ?? '',
          photoUrl: u.photoURL ?? '',
        );

  /// Semua method login mengembalikan `true` kalau dokumen Firestore berhasil disinkron.
  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return _syncUser(cred.user, 'password');
  }

  Future<bool> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = cred.user;
    if (user != null) {
      await user.updateDisplayName(name.trim());
      await user.reload();
    }
    return _syncUser(_auth.currentUser, 'password');
  }

  /// Google lewat provider Firebase (tanpa paket google_sign_in).
  /// Web memakai popup; Android/iOS memakai signInWithProvider.
  Future<bool> signInWithGoogle() async {
    final provider = GoogleAuthProvider();
    final cred = kIsWeb
        ? await _auth.signInWithPopup(provider)
        : await _auth.signInWithProvider(provider);
    return _syncUser(cred.user, 'google');
  }

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  Future<void> signOut() => _auth.signOut();

  /// Upsert `users/{uid}`. Gagal (mis. Rules menolak) tidak membatalkan login.
  Future<bool> _syncUser(User? u, String provider) async {
    if (u == null) return false;
    try {
      final ref = _db.collection('users').doc(u.uid);
      final snap = await ref.get();
      final data = <String, dynamic>{
        'uid': u.uid,
        'displayName': u.displayName ?? '',
        'email': u.email ?? '',
        'photoUrl': u.photoURL ?? '',
        'provider': provider,
        'lastLoginAt': FieldValue.serverTimestamp(),
      };
      if (!snap.exists) data['createdAt'] = FieldValue.serverTimestamp();
      await ref.set(data, SetOptions(merge: true));
      return true;
    } catch (e) {
      debugPrint('Sinkron Firestore gagal (cek Firestore Rules): $e');
      return false;
    }
  }
}

/// Terjemahan error Firebase -> kalimat yang enak dibaca.
/// Mengembalikan null kalau pengguna cuma membatalkan (nggak perlu pesan error).
String? describeAuthError(Object e) {
  if (e is FirebaseAuthException) {
    switch (e.code) {
      case 'invalid-email':
        return 'Format email nggak valid.';
      case 'user-disabled':
        return 'Akun ini dinonaktifkan.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
      case 'invalid-login-credentials':
        return 'Email atau password salah.';
      case 'email-already-in-use':
        return 'Email ini sudah terdaftar. Coba masuk saja.';
      case 'weak-password':
        return 'Password terlalu lemah (minimal 6 karakter).';
      case 'network-request-failed':
        return 'Koneksi internet bermasalah.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba lagi sebentar.';
      case 'operation-not-allowed':
        return 'Metode login ini belum diaktifkan di Firebase Console '
            '(Authentication > Sign-in method).';
      case 'account-exists-with-different-credential':
        return 'Email ini sudah dipakai dengan metode login lain.';
      case 'web-context-canceled':
      case 'popup-closed-by-user':
      case 'cancelled-popup-request':
      case 'canceled':
        return null;
      default:
        return 'Gagal masuk (${e.code}).';
    }
  }
  return 'Terjadi kesalahan: $e';
}
