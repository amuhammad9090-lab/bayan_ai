/// Data user yang dipakai UI (UI nggak perlu kenal tipe Firebase).
class AppUser {
  final String uid;
  final String displayName;
  final String email;
  final String photoUrl;

  /// ID provider login, mis. `google.com` atau `password`.
  final List<String> providers;
  final DateTime? createdAt;
  final DateTime? lastSignInAt;
  const AppUser({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.photoUrl,
    this.providers = const [],
    this.createdAt,
    this.lastSignInAt,
  });

  bool get isGoogle => providers.contains('google.com');
  bool get hasPassword => providers.contains('password');

  String get providerLabel {
    if (isGoogle && hasPassword) return 'Google & email';
    if (isGoogle) return 'Google';
    if (hasPassword) return 'Email & kata sandi';
    return 'Akun terdaftar';
  }

  /// Nama yang enak ditampilkan (fallback ke bagian depan email).
  String get shownName {
    if (displayName.trim().isNotEmpty) return displayName.trim();
    if (email.contains('@')) return email.split('@').first;
    return 'Pengguna';
  }

  String get initial =>
      String.fromCharCode(shownName.runes.first).toUpperCase();
}
