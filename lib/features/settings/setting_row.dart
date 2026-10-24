import 'package:flutter/material.dart';

import '../../core/icons.dart';
import '../../core/theme.dart';

/// Satu pola baris untuk seluruh Setelan:
/// ikon bulat · judul (+ keterangan) · nilai/status · chevron atau kontrol.
class SettingRow extends StatelessWidget {
  final IconData? icon;

  /// Pengganti ikon (mis. logo kecil).
  final Widget? leading;
  final String title;
  final String? subtitle;

  /// Nilai teks di kanan (mis. "28", "12 tersimpan").
  final String? value;

  /// Pengganti [value] (mis. status pill, switch, segmented).
  final Widget? trailing;
  final bool danger;
  final VoidCallback? onTap;

  const SettingRow({
    super.key,
    this.icon,
    this.leading,
    required this.title,
    this.subtitle,
    this.value,
    this.trailing,
    this.danger = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final red = context.chipFg(AppColors.danger);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          children: [
            leading ??
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: danger ? context.chipBg(AppColors.danger) : context.accentSoft,
                  ),
                  child: Icon(icon, size: 18, color: danger ? red : context.cs.primary),
                ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: danger ? red : null,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11.5, height: 1.35, color: context.muted),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ] else if (value != null) ...[
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 130),
                child: Text(
                  value!,
                  maxLines: 1,
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.5, color: context.muted),
                ),
              ),
            ],
            if (onTap != null && (trailing == null || trailing is StatusPill)) ...[
              const SizedBox(width: 6),
              Icon(AppIcons.chevronRight, size: 17, color: context.muted),
            ],
          ],
        ),
      ),
    );
  }
}

/// Status kecil di kanan baris (mis. "Tersambung" hijau / "Belum diatur" merah).
class StatusPill extends StatelessWidget {
  final String label;
  final bool ok;
  const StatusPill({super.key, required this.label, required this.ok});

  @override
  Widget build(BuildContext context) {
    final c = ok ? AppColors.success : AppColors.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: context.chipBg(c),
        borderRadius: BorderRadius.circular(20),
        border: context.isDark ? Border.all(color: context.chipBorder(c)) : null,
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: context.chipFg(c)),
      ),
    );
  }
}

/// Bungkus isi sheet dengan warna aksen Setelan (sheet dibuka di atas tab,
/// jadi nggak otomatis ikut tema tab).
Widget settingsAccent(BuildContext context, Widget child) => TabAccent(
      color: AppColors.settings,
      child: Theme(data: Theme.of(context).withAccent(AppColors.settings), child: child),
    );
