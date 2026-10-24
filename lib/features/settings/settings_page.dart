import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/ai_repository.dart';
import '../../core/app_info.dart';
import '../../core/art.dart';
import '../../core/icons.dart';
import '../../core/theme.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/logo_mark.dart';
import '../auth/account_card.dart';
import '../backup/backup_provider.dart';
import '../backup/backup_sheet.dart';
import '../history/history_provider.dart';
import '../shell/header_actions.dart';
import 'about_sheet.dart';
import 'api_key_sheet.dart';
import 'arabic_size_sheet.dart';
import 'model_sheet.dart';
import 'setting_row.dart';
import 'settings_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Future<void> _confirmClear() async {
    final history = context.read<HistoryProvider>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.cs.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Hapus semua riwayat?', style: TextStyle(fontSize: 17)),
        content: const Text('Semua hasil OCR, ayat, dan nahwu yang tersimpan akan dihapus.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await history.clear();
      if (mounted) showSnack(context, 'Riwayat dihapus');
    }
  }

  Future<void> _clearCache() async {
    final cache = context.read<AiCache>();
    await cache.clear();
    if (!mounted) return;
    setState(() {});
    showSnack(context, 'Cache AI dibersihkan');
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsProvider>();
    final backup = context.watch<BackupProvider>();
    final modelLabel = kModelOptions
        .where((m) => m.id == s.model)
        .map((m) => m.label)
        .followedBy([s.model])
        .first;

    return FeatureScroll(
      actions: const HeaderActions(),
      gradient: AppColors.cardSettings,
      shadow: AppColors.settings,
      asset: Art.homeBanner,
      fallback: AppIcons.settings,
      title: 'Setelan',
      subtitle: 'Akun, koneksi AI, tampilan, dan data aplikasi.',
      onRefresh: () async {
        await Future<void>.delayed(const Duration(milliseconds: 700));
        if (mounted) setState(() {});
      },
      // Satu pola baris untuk semua: ikon bulat · judul · nilai · chevron/kontrol.
      // Isian yang jarang diubah (API key, ukuran Arab, cadangan) dibuka di sheet.
      children: [
        const SectionLabel('Akun'),
        const AccountCard(),
        PageGap.section,

        const SectionLabel('Kecerdasan AI'),
        GroupCard(
          children: [
            SettingRow(
              icon: AppIcons.key,
              title: 'API key Gemini',
              trailing: StatusPill(
                label: s.hasApiKey ? 'Tersimpan' : 'Belum diatur',
                ok: s.hasApiKey,
              ),
              onTap: () => showApiKeySheet(context),
            ),
            SettingRow(
              icon: AppIcons.cpu,
              title: 'Model AI',
              value: modelLabel,
              onTap: () => showModelSheet(context),
            ),
          ],
        ),
        PageGap.section,

        const SectionLabel('Tampilan'),
        GroupCard(
          children: [
            SettingRow(
              icon: AppIcons.moon,
              title: 'Tema',
              trailing: _ThemeSwitch(value: s.themeMode, onChanged: s.setThemeMode),
            ),
            SettingRow(
              icon: AppIcons.type,
              title: 'Ukuran teks Arab',
              value: '${s.arabicSize.round()}',
              onTap: () => showArabicSizeSheet(context),
            ),
          ],
        ),
        PageGap.section,

        const SectionLabel('Data dan penyimpanan'),
        GroupCard(
          children: [
            SettingRow(
              icon: AppIcons.history,
              title: 'Simpan riwayat otomatis',
              subtitle: 'OCR, ayat, dan nahwu',
              trailing: Switch(value: s.autoSave, onChanged: s.setAutoSave),
            ),
            if (backup.available)
              SettingRow(
                icon: AppIcons.cloud,
                title: 'Cadangan cloud',
                subtitle: backupStatus(backup),
                onTap: () => showBackupSheet(context),
              ),
            SettingRow(
              icon: AppIcons.database,
              title: 'Bersihkan cache AI',
              value: '${context.read<AiCache>().size} tersimpan',
              onTap: _clearCache,
            ),
            SettingRow(
              icon: AppIcons.trash,
              title: 'Hapus semua riwayat',
              danger: true,
              onTap: _confirmClear,
            ),
          ],
        ),
        PageGap.section,

        const SectionLabel('Tentang'),
        GroupCard(
          children: [
            SettingRow(
              leading: const LogoMark(size: 38),
              title: kAppName,
              value: 'Versi $kAppVersion',
              onTap: () => showAboutSheet(context),
            ),
          ],
        ),
      ],
    );
  }
}

/// Pilihan tema ringkas (ikon saja) supaya muat di kanan baris.
class _ThemeSwitch extends StatelessWidget {
  final ThemeMode value;
  final ValueChanged<ThemeMode> onChanged;
  const _ThemeSwitch({required this.value, required this.onChanged});

  static const _modes = <(ThemeMode, IconData, String)>[
    (ThemeMode.system, AppIcons.monitor, 'Sistem'),
    (ThemeMode.light, AppIcons.sun, 'Terang'),
    (ThemeMode.dark, AppIcons.moon, 'Gelap'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: context.surface2,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (mode, icon, label) in _modes)
            Tooltip(
              message: label,
              child: GestureDetector(
                onTap: () => onChanged(mode),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: value == mode ? context.accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    size: 16,
                    color: value == mode ? Colors.white : context.muted,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
