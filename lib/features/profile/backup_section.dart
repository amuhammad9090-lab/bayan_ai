import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/icons.dart';
import '../../core/theme.dart';
import '../../shared/widgets/common.dart';
import '../backup/backup_provider.dart';
import 'profile_parts.dart';

/// Bagian "Cadangan cloud" di Profil: status, cadangkan, pulihkan, otomatis.
class BackupSection extends StatelessWidget {
  const BackupSection({super.key});

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
    if (!b.available) return const SizedBox.shrink();

    final last = b.lastBackupAt;
    final String status;
    if (b.busy) {
      status = 'Sedang sinkron…';
    } else if (last == null) {
      status = 'Belum pernah dicadangkan';
    } else {
      status = 'Terakhir ${timeAgo(last)} · ${b.lastCount} riwayat'
          '${b.dirty ? ' · ada yang baru' : ''}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel('Cadangan cloud', hint: 'Riwayat Qur\'an, Nahwu & OCR'),
        GroupCard(
          children: [
            _StatusRow(status: status, busy: b.busy, synced: last != null && !b.dirty),
            ActionRow(
              icon: AppIcons.cloudUpload,
              title: 'Cadangkan sekarang',
              subtitle: 'Simpan semua riwayat ke akun kamu',
              onTap: b.busy ? null : () => _backup(context),
            ),
            ActionRow(
              icon: AppIcons.cloudDownload,
              title: 'Pulihkan dari cloud',
              subtitle: 'Gabungkan cadangan ke riwayat di perangkat ini',
              onTap: b.busy ? null : () => _restore(context),
            ),
            _AutoRow(value: b.auto, onChanged: b.setAuto),
          ],
        ),
      ],
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String status;
  final bool busy;
  final bool synced;
  const _StatusRow({required this.status, required this.busy, required this.synced});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: context.accentSoft, shape: BoxShape.circle),
            child: busy
                ? Padding(
                    padding: const EdgeInsets.all(11),
                    child: CircularProgressIndicator(strokeWidth: 2, color: context.cs.primary),
                  )
                : Icon(AppIcons.cloud, size: 18, color: context.cs.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Status cadangan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(status, style: TextStyle(fontSize: 11.5, height: 1.35, color: context.muted)),
              ],
            ),
          ),
          if (synced && !busy)
            Icon(AppIcons.success, size: 18, color: context.chipFg(AppColors.success)),
        ],
      ),
    );
  }
}

class _AutoRow extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _AutoRow({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: context.accentSoft, shape: BoxShape.circle),
            child: Icon(AppIcons.replace, size: 18, color: context.cs.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Cadangkan otomatis', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  'Saat ada riwayat baru (ditunda sebentar agar hemat kuota)',
                  style: TextStyle(fontSize: 11.5, height: 1.35, color: context.muted),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
