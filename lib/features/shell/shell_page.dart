import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_info.dart';
import '../../core/icons.dart';
import '../../core/theme.dart';
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
    ('Setelan', 'API, tampilan, dan data'),
  ];

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavProvider>();
    final i = nav.index;
    final dark = context.isDark;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 66,
        titleSpacing: 16,
        title: Row(
          children: [
            const LogoMark(size: 38),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _titles[i].$1,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700),
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
            onPressed: () => context
                .read<SettingsProvider>()
                .setThemeMode(dark ? ThemeMode.light : ThemeMode.dark),
            icon: Icon(dark ? AppIcons.sun : AppIcons.moon, size: 21),
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
        children: const [
          HomePage(),
          OcrPage(),
          QuranPage(),
          NahwuPage(),
          SettingsPage(),
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
          destinations: const [
            NavigationDestination(icon: Icon(AppIcons.home), label: 'Beranda'),
            NavigationDestination(icon: Icon(AppIcons.ocr), label: 'OCR'),
            NavigationDestination(icon: Icon(AppIcons.quran), label: "Qur'an"),
            NavigationDestination(icon: Icon(AppIcons.nahwu), label: 'Nahwu'),
            NavigationDestination(icon: Icon(AppIcons.settings), label: 'Setelan'),
          ],
        ),
      ),
    );
  }
}
