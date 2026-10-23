/// Data user yang dipakai UI (UI nggak perlu kenal tipe Firebase).
class AppUser {
  final String uid;
  final String displayName;
  final String email;
  final String photoUrl;
  const AppUser({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.photoUrl,
  });

  /// Nama yang enak ditampilkan (fallback ke bagian depan email).
  String get shownName {
    if (displayName.trim().isNotEmpty) return displayName.trim();
    if (email.contains('@')) return email.split('@').first;
    return 'Pengguna';
  }

  String get initial =>
      String.fromCharCode(shownName.runes.first).toUpperCase();
}
