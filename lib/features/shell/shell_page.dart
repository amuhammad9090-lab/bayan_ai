import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_info.dart';
import '../../core/icons.dart';
import '../../core/theme.dart';
import '../../shared/widgets/animations.dart';
import '../../shared/widgets/logo_mark.dart';
import '../history/history_sheet.dart';
import '../home/home_page.dart';
import '../nahwu/nahwu_page.dart';
import '../ocr/ocr_page.dart';
import '../quran/quran_page.dart';
import '../settings/settings_page.dart';
import '../settings/settings_provider.dart';
import 'nav_provider.dart';

/// Layer komposisi: satu-satunya tempat yang kenal semua fitur.
class ShellPage extends StatelessWidget {
  const ShellPage({super.key});

  static const _titles = [
    (kAppName, 'Asisten belajar Al-Qur\'an'),
    ('Pindai Mushaf', 'OCR teks Arab dari gambar'),
    ("Al-Qur'an AI", 'Cari ayat & tafsir ringkas'),
    ('Nahwu AI', "Analisis tarkib & i'rab"),
    ('Setelan', 'Akun, API, tampilan, dan data'),
  ];

  static const _pages = <Widget>[
    HomePage(),
    OcrPage(),
    QuranPage(),
    NahwuPage(),
    SettingsPage(),
  ];

  static const _navItems = <(IconData, String)>[
    (AppIcons.home, 'Beranda'),
    (AppIcons.ocr, 'OCR'),
    (AppIcons.quran, "Qur'an"),
    (AppIcons.nahwu, 'Nahwu'),
    (AppIcons.settings, 'Setelan'),
  ];

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavProvider>();
    final i = nav.index;
    final dark = context.isDark;

    // Back di tab selain Beranda -> balik ke Beranda dulu, baru keluar app.
    return PopScope(
      canPop: i == NavProvider.home,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) nav.go(NavProvider.home);
      },
      child: Scaffold(
        appBar: i == NavProvider.home
            ? null
            : AppBar(
                toolbarHeight: 70,
                titleSpacing: 20,
                title: Row(
                  children: [
                    const LogoMark(size: 40),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 260),
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.25),
                              end: Offset.zero,
                            ).animate(anim),
                            child: child,
                          ),
                        ),
                        layoutBuilder: (current, previous) => Stack(
                          alignment: Alignment.centerLeft,
                          children: [...previous, if (current != null) current],
                        ),
                        child: Column(
                          key: ValueKey(i),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _titles[i].$1,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              _titles[i].$2,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: context.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                actions: [
                  _RoundAction(
                    tooltip: 'Riwayat',
                    icon: AppIcons.history,
                    onTap: () => showHistorySheet(context),
                  ),
                  const SizedBox(width: 8),
                  _RoundAction(
                    tooltip: 'Ganti tema',
                    icon: dark ? AppIcons.sun : AppIcons.moon,
                    onTap: () => context.read<SettingsProvider>().setThemeMode(
                      dark ? ThemeMode.light : ThemeMode.dark,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
        body: IndexedStack(
          index: i,
          children: [
            for (var k = 0; k < _pages.length; k++)
              TabEntrance(active: i == k, child: _pages[k]),
          ],
        ),
        bottomNavigationBar: _FloatingNav(
          index: i,
          items: _navItems,
          onTap: nav.go,
        ),
      ),
    );
  }
}

/// Tombol bulat kecil di app bar (riwayat, tema).
class _RoundAction extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;
  const _RoundAction({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: context.surface2,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                icon,
                key: ValueKey(icon),
                size: 19,
                color: context.cs.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom nav melayang: pil putih membulat, tab aktif berupa pil biru
/// dengan ikon + label, tab lain cuma ikon.
class _FloatingNav extends StatelessWidget {
  final int index;
  final List<(IconData, String)> items;
  final ValueChanged<int> onTap;
  const _FloatingNav({
    required this.index,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dark = context.isDark;
    final idle = dark ? AppColors.darkMuted : AppColors.blue300;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: Container(
          height: 68,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: context.cs.surface,
            borderRadius: BorderRadius.circular(34),
            border: dark ? Border.all(color: context.border) : null,
            boxShadow: dark
                ? null
                : [
                    BoxShadow(
                      color: AppColors.blue600.withValues(alpha: 0.14),
                      blurRadius: 26,
                      offset: const Offset(0, 10),
                    ),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var k = 0; k < items.length; k++)
                _NavItem(
                  icon: items[k].$1,
                  label: items[k].$2,
                  selected: k == index,
                  idleColor: idle,
                  onTap: () => onTap(k),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final Color idleColor;
  final VoidCallback onTap;
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.idleColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: selected ? 16 : 11,
            vertical: 11,
          ),
          decoration: BoxDecoration(
            color: selected ? AppColors.blue500 : Colors.transparent,
            borderRadius: BorderRadius.circular(26),
          ),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 22, color: selected ? Colors.white : idleColor),
                if (selected) ...[
                  const SizedBox(width: 8),
                  Text(
                    label,
                    maxLines: 1,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
