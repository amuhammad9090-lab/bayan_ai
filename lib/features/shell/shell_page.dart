import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

  /// Ikon aktif "memantul" tiap kali tab dipilih.
  static Widget _selected(IconData icon) => Icon(icon)
      .animate()
      .scaleXY(begin: 0.6, end: 1, duration: 380.ms, curve: Curves.easeOutBack);

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
          toolbarHeight: 66,
          titleSpacing: 16,
          title: Row(
            children: [
              const LogoMark(size: 38),
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
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        _titles[i].$2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11.5, color: context.muted),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Riwayat',
              onPressed: () => showHistorySheet(context),
              icon: const Icon(AppIcons.history, size: 21),
            ),
            IconButton(
              tooltip: 'Ganti tema',
              onPressed: () => context.read<SettingsProvider>().setThemeMode(
                dark ? ThemeMode.light : ThemeMode.dark,
              ),
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                transitionBuilder: (child, anim) => RotationTransition(
                  turns: Tween<double>(begin: 0.75, end: 1).animate(anim),
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: Icon(
                  dark ? AppIcons.sun : AppIcons.moon,
                  key: ValueKey(dark),
                  size: 21,
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Divider(color: context.border, height: 1),
          ),
        ),
        body: IndexedStack(
          index: i,
          children: [
            for (var k = 0; k < _pages.length; k++)
              TabEntrance(
                active: i == k,
                // Beranda tanpa app bar: jaga konten tetap di bawah status bar.
                child: k == NavProvider.home
                    ? SafeArea(bottom: false, child: _pages[k])
                    : _pages[k],
              ),
          ],
        ),
        bottomNavigationBar: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: context.border)),
          ),
          child: NavigationBar(
            selectedIndex: i,
            onDestinationSelected: nav.go,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: [
              NavigationDestination(
                icon: const Icon(AppIcons.home),
                selectedIcon: _selected(AppIcons.home),
                label: 'Beranda',
              ),
              NavigationDestination(
                icon: const Icon(AppIcons.ocr),
                selectedIcon: _selected(AppIcons.ocr),
                label: 'OCR',
              ),
              NavigationDestination(
                icon: const Icon(AppIcons.quran),
                selectedIcon: _selected(AppIcons.quran),
                label: "Qur'an",
              ),
              NavigationDestination(
                icon: const Icon(AppIcons.nahwu),
                selectedIcon: _selected(AppIcons.nahwu),
                label: 'Nahwu',
              ),
              NavigationDestination(
                icon: const Icon(AppIcons.settings),
                selectedIcon: _selected(AppIcons.settings),
                label: 'Setelan',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
