import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/icons.dart';
import '../../core/theme.dart';
import '../../shared/widgets/common.dart';
import '../settings/setting_row.dart';
import 'backup_provider.dart';

/// Ringkasan status untuk baris "Cadangan cloud" di Setelan.
String backupStatus(BackupProvider b) {
  if (b.busy) return 'Sedang sinkron…';
  final last = b.lastBackupAt;
  if (last == null) return 'Belum pernah dicadangkan';
  return 'Terakhir ${timeAgo(last)} · ${b.lastCount} riwayat'
      '${b.dirty ? ' · ada yang baru' : ''}';
}

Future<void> showBackupSheet(BuildContext context) {
  return showAppSheet<void>(
    context,
    title: 'Cadangan cloud',
    icon: AppIcons.cloud,
    builder: (ctx) => settingsAccent(ctx, const _BackupPanel()),
  );
}

class _BackupPanel extends StatelessWidget {
  const _BackupPanel();

  Future<void> _backup(BuildContext context) async {
    final b = context.read<BackupProvider>();
    final ok = await b.backup();
    if (!context.mounted) return;
    if (ok) {
      showSnack(context, '${b.lastCount} riwayat dicadangkan ke cloud');
    } else if (b.error != null) {
      showSnack(context, b.error!, error: true);
      b.clearError();
    }
  }

  Future<void> _restore(BuildContext context) async {
    final b = context.read<BackupProvider>();
    final added = await b.restore();
    if (!context.mounted) return;
    if (added == null) {
      if (b.error != null) {
        showSnack(context, b.error!, error: true);
        b.clearError();
      }
    } else {
      showSnack(
        context,
        added == 0 ? 'Riwayat di perangkat ini sudah lengkap' : '$added riwayat dipulihkan dari cloud',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = context.watch<BackupProvider>();
    final synced = b.lastBackupAt != null && !b.dirty && !b.busy;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Riwayat Qur\'an, Nahwu, dan OCR disimpan di akun kamu, '
          'jadi bisa dipulihkan saat ganti HP atau install ulang.',
          style: TextStyle(fontSize: 12.5, height: 1.5, color: context.muted),
        ),
        const SizedBox(height: 10),
        GroupCard(
          children: [
            SettingRow(
              icon: AppIcons.cloud,
              title: 'Status',
              subtitle: backupStatus(b),
              trailing: b.busy
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: context.cs.primary),
                    )
                  : synced
                      ? const StatusPill(label: 'Tersinkron', ok: true)
                      : null,
            ),
            SettingRow(
              icon: AppIcons.cloudUpload,
              title: 'Cadangkan sekarang',
              subtitle: 'Simpan semua riwayat ke akun kamu',
              onTap: b.busy ? null : () => _backup(context),
            ),
            SettingRow(
              icon: AppIcons.cloudDownload,
              title: 'Pulihkan dari cloud',
              subtitle: 'Digabung dengan riwayat di perangkat ini',
              onTap: b.busy ? null : () => _restore(context),
            ),
            SettingRow(
              icon: AppIcons.replace,
              title: 'Cadangkan otomatis',
              subtitle: 'Saat ada riwayat baru, ditunda sebentar agar hemat kuota',
              trailing: Switch(value: b.auto, onChanged: b.setAuto),
            ),
          ],
        ),
      ],
    );
  }
}
