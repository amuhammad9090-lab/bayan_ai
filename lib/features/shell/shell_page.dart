import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/icons.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../shared/widgets/animations.dart';
import 'side_nav.dart';
import '../home/home_page.dart';
import '../nahwu/nahwu_page.dart';
import '../ocr/ocr_page.dart';
import '../quran/quran_page.dart';
import '../settings/settings_page.dart';
import 'nav_provider.dart';

/// Layer komposisi: satu-satunya tempat yang kenal semua fitur.
class ShellPage extends StatelessWidget {
  const ShellPage({super.key});

  static const _pages = <Widget>[
    HomePage(),
    QuranPage(),
    NahwuPage(),
    OcrPage(),
    SettingsPage(),
  ];

  static const _navColors = <Color>[
    AppColors.blue500,
    AppColors.featQuran,
    AppColors.featNahwu,
    AppColors.featOcr,
    AppColors.settings,
  ];

  static const _navItems = <(IconData, String)>[
    (AppIcons.home, 'Beranda'),
    (AppIcons.quran, "Qur'an"),
    (AppIcons.nahwu, 'Nahwu'),
    (AppIcons.ocr, 'OCR'),
    (AppIcons.settings, 'Setelan'),
  ];

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavProvider>();
    final i = nav.index;
    final wide = context.isWide;
    // Dark mode: pil Beranda ikut warna banner Beranda yang lebih dalam.
    final colors = context.isDark
        ? [AppColors.homeDarkAccent, ..._navColors.skip(1)]
        : _navColors;

    final content = IndexedStack(
      index: i,
      children: [
        for (var k = 0; k < _pages.length; k++)
          TabEntrance(
            active: i == k,
            child: _pages[k],
          ),
      ],
    );

    // Back di tab selain Beranda -> balik ke Beranda dulu, baru keluar app.
    return PopScope(
      canPop: i == NavProvider.home,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) nav.go(NavProvider.home);
      },
      child: Scaffold(
        // Layar lebar (web/laptop/tablet): sidebar kiri + konten di tengah.
        body: wide
            ? Row(
                children: [
                  SideNav(
                    index: i,
                    items: _navItems,
                    colors: colors,
                    onTap: nav.go,
                  ),
                  Expanded(child: MaxWidth(child: content)),
                ],
              )
            : content,
        bottomNavigationBar: wide
            ? null
            : _FloatingNav(
                index: i,
                items: _navItems,
                colors: colors,
                onTap: nav.go,
              ),
      ),
    );
  }
}

/// Tombol bulat kecil di app bar (riwayat, tema).
/// Bottom nav melayang: pil putih membulat, tab aktif berupa pil biru
/// dengan ikon + label, tab lain cuma ikon.
class _FloatingNav extends StatelessWidget {
  final int index;
  final List<(IconData, String)> items;
  final List<Color> colors;
  final ValueChanged<int> onTap;
  const _FloatingNav({
    required this.index,
    required this.items,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dark = context.isDark;
    // Ikon yang tidak aktif ikut warna tab yang sedang dibuka (transisi halus).
    final active = colors[index];
    final idle = dark ? Color.lerp(active, Colors.white, 0.35)! : active;

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
                      color: colors[index].withValues(alpha: 0.18),
                      blurRadius: 26,
                      offset: const Offset(0, 10),
                    ),
                  ],
          ),
          child: TweenAnimationBuilder<Color?>(
            tween: ColorTween(end: idle),
            duration: const Duration(milliseconds: 380),
            curve: Curves.easeOut,
            builder: (context, idleNow, _) => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var k = 0; k < items.length; k++)
                  _NavItem(
                    icon: items[k].$1,
                    label: items[k].$2,
                    selected: k == index,
                    color: colors[k],
                    idleColor: idleNow ?? idle,
                    onTap: () => onTap(k),
                  ),
              ],
            ),
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
  final Color color;
  final Color idleColor;
  final VoidCallback onTap;
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.color,
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
            color: selected ? color : Colors.transparent,
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
