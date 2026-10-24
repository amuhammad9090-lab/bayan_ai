import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/models.dart';

/// Cadangan riwayat di Firestore, dibuat sehemat mungkin:
/// SELURUH riwayat disimpan di SATU dokumen `users/{uid}/backup/history`,
/// jadi mencadangkan = 1 tulis, memulihkan = 1 baca (berapa pun jumlah riwayatnya).
class BackupService {
  /// Batas panjang teks per entri, supaya dokumen tetap jauh di bawah 1 MB.
  static const maxInput = 1000;
  static const maxOutput = 4000;

  DocumentReference<Map<String, dynamic>> _doc(String uid) => FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('backup')
      .doc('history');

  /// Timpa cadangan dengan riwayat lokal. [rev] = penanda versi tulisan ini.
  Future<void> save(String uid, List<HistoryItem> items, int rev) {
    String cut(String s, int max) => s.length <= max ? s : s.substring(0, max);
    return _doc(uid).set({
      'v': 1,
      'rev': rev,
      'count': items.length,
      'updatedAt': FieldValue.serverTimestamp(),
      'items': [
        for (final e in items)
          {
            'id': e.id,
            'type': e.type.name,
            'input': cut(e.input, maxInput),
            'output': cut(e.output, maxOutput),
            'createdAt': e.createdAt.toIso8601String(),
          },
      ],
    });
  }

  /// null kalau belum pernah ada cadangan.
  Future<CloudBackup?> load(String uid) async {
    final snap = await _doc(uid).get(const GetOptions(source: Source.server));
    final d = snap.data();
    if (d == null) return null;
    final items = (d['items'] as List? ?? [])
        .whereType<Map>()
        .map((e) => HistoryItem.fromJson(Map<String, dynamic>.from(e)))
        .where((e) => e.id.isNotEmpty && e.output.isNotEmpty)
        .toList();
    final ts = d['updatedAt'];
    return CloudBackup(
      items: items,
      rev: (d['rev'] as num?)?.toInt() ?? 0,
      updatedAt: (ts is Timestamp) ? ts.toDate() : null,
    );
  }
}

class CloudBackup {
  final List<HistoryItem> items;
  final int rev;
  final DateTime? updatedAt;
  const CloudBackup({required this.items, required this.rev, this.updatedAt});
}
