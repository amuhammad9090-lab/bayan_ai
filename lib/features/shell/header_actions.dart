import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/icons.dart';
import '../../core/theme.dart';
import '../history/history_sheet.dart';
import '../settings/settings_provider.dart';

/// Dua tombol bulat kecil di pojok banner: Riwayat & Ganti tema.
/// Menggantikan app bar di tab selain Beranda.
class HeaderActions extends StatelessWidget {
  const HeaderActions({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = context.isDark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Round(
          tooltip: 'Riwayat',
          icon: AppIcons.history,
          onTap: () => showHistorySheet(context),
        ),
        const SizedBox(width: 8),
        _Round(
          tooltip: 'Ganti tema',
          icon: dark ? AppIcons.sun : AppIcons.moon,
          onTap: () => context.read<SettingsProvider>().setThemeMode(
                dark ? ThemeMode.light : ThemeMode.dark,
              ),
        ),
      ],
    );
  }
}

class _Round extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;
  const _Round({required this.tooltip, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.28),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(9),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Icon(icon, key: ValueKey(icon), size: 18, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
