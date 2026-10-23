import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/art.dart';
import '../../core/icons.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../shared/widgets/common.dart';
import '../auth/auth_provider.dart';
import '../auth/user_avatar.dart';
import '../history/history_provider.dart';
import '../history/history_sheet.dart';
import '../nahwu/nahwu_provider.dart';
import '../quran/quran_provider.dart';
import '../settings/settings_provider.dart';
import '../shell/nav_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

enum _SearchScope { quran, nahwu, history }

class _HomePageState extends State<HomePage> {
  final _search = TextEditingController();
  _SearchScope _scope = _SearchScope.quran;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// Cari dari beranda sesuai filter: ayat (tab Qur'an), analisis nahwu
  /// (tab Nahwu), atau saring riwayat.
  void _submit(String value) {
    final q = value.trim();
    if (q.isEmpty) return;
    final nav = context.read<NavProvider>();
    switch (_scope) {
      case _SearchScope.quran:
        final quran = context.read<QuranProvider>();
        quran.setQuery(q);
        quran.search();
        nav.go(NavProvider.quran);
        break;
      case _SearchScope.nahwu:
        final nahwu = context.read<NahwuProvider>();
        nahwu.setInput(q);
        nahwu.analyze();
        nav.go(NavProvider.nahwu);
        break;
      case _SearchScope.history:
        showHistorySheet(context, query: q);
        break;
    }
    _search.clear();
    FocusScope.of(context).unfocus();
  }

  Future<void> _openFilter() async {
    FocusScope.of(context).unfocus();
    final picked = await showAppSheet<_SearchScope>(
      context,
      title: 'Filter pencarian',
      icon: AppIcons.tune,
      builder: (ctx) => Column(
        children: [
          _ScopeTile(
            icon: AppIcons.quran,
            color: AppColors.quran,
            title: 'Ayat & Tafsir',
            subtitle: "Cari ayat berdasarkan topik atau nama surah",
            selected: _scope == _SearchScope.quran,
            onTap: () => Navigator.pop(ctx, _SearchScope.quran),
          ),
          const SizedBox(height: 10),
          _ScopeTile(
            icon: AppIcons.nahwu,
            color: AppColors.purple,
            title: 'Analisis Nahwu',
            subtitle: "Tulis kalimat Arab, langsung di-i'rab",
            selected: _scope == _SearchScope.nahwu,
            onTap: () => Navigator.pop(ctx, _SearchScope.nahwu),
          ),
          const SizedBox(height: 10),
          _ScopeTile(
            icon: AppIcons.history,
            color: AppColors.green,
            title: 'Riwayat',
            subtitle: 'Saring hasil OCR, ayat, dan nahwu yang tersimpan',
            selected: _scope == _SearchScope.history,
            onTap: () => Navigator.pop(ctx, _SearchScope.history),
          ),
        ],
      ),
    );
    if (picked != null && mounted) setState(() => _scope = picked);
  }

  String get _hint {
    switch (_scope) {
      case _SearchScope.quran:
        return 'Cari ayat atau topik…';
      case _SearchScope.nahwu:
        return 'Tulis kalimat Arab…';
      case _SearchScope.history:
        return 'Cari di riwayat…';
    }
  }

  @override
  Widget build(BuildContext context) {
    final nav = context.read<NavProvider>();
    final hasKey = context.select<SettingsProvider, bool>((s) => s.hasApiKey);
    final history = context.watch<HistoryProvider>();
    final dark = context.isDark;
    final top = MediaQuery.of(context).padding.top;

    Widget pad(Widget w) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: w,
        );

    final items = <Widget>[
      if (!hasKey) ...[
        pad(_KeyBanner(onTap: () => nav.go(NavProvider.settings))),
        const SizedBox(height: 16),
      ],
      pad(const Text(
        'Fitur',
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
      )),
      const SizedBox(height: 10),
      pad(Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _TopicPill(
                  icon: AppIcons.ocr,
                  label: 'Pindai',
                  color: AppColors.ocr,
                  filled: true,
                  onTap: () => nav.go(NavProvider.ocr),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TopicPill(
                  icon: AppIcons.quran,
                  label: "Qur'an",
                  color: AppColors.quran,
                  onTap: () => nav.go(NavProvider.quran),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _TopicPill(
                  icon: AppIcons.nahwu,
                  label: 'Nahwu',
                  color: AppColors.purple,
                  onTap: () => nav.go(NavProvider.nahwu),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TopicPill(
                  icon: AppIcons.history,
                  label: 'Riwayat',
                  color: AppColors.green,
                  onTap: () => showHistorySheet(context),
                ),
              ),
            ],
          ),
        ],
      )),
      const SizedBox(height: 18),
      SizedBox(
        height: 262,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          clipBehavior: Clip.none,
          children: [
            _FeatureCard(
              gradient: AppColors.cardOcr,
              shadow: AppColors.ocr,
              asset: Art.homeOcr,
              fallback: AppIcons.ocr,
              title: 'Pindai Mushaf',
              subtitle: 'Foto halaman jadi teks Arab berharakat',
              chips: [
                (AppIcons.ocr, '${history.count(HistoryType.ocr)} hasil'),
                (AppIcons.sparkles, 'Gemini'),
              ],
              onTap: () => nav.go(NavProvider.ocr),
            ),
            const SizedBox(width: 12),
            _FeatureCard(
              gradient: AppColors.cardQuran,
              shadow: AppColors.quran,
              asset: Art.homeQuran,
              fallback: AppIcons.quran,
              title: 'Ayat & Tafsir',
              subtitle: 'Cari ayat berdasarkan topik atau nama surah',
              chips: [
                (AppIcons.quran, '${history.count(HistoryType.quran)} hasil'),
                (AppIcons.bookMarked, '2 tafsir'),
              ],
              onTap: () => nav.go(NavProvider.quran),
            ),
            const SizedBox(width: 12),
            _FeatureCard(
              gradient: AppColors.cardPurple,
              shadow: AppColors.purple,
              asset: Art.homeNahwu,
              fallback: AppIcons.nahwu,
              title: 'Analisis Nahwu',
              subtitle: "I'rab kata per kata dengan 7 bab",
              chips: [
                (AppIcons.nahwu, '${history.count(HistoryType.nahwu)} hasil'),
                (AppIcons.lightbulb, '7 bab'),
              ],
              onTap: () => nav.go(NavProvider.nahwu),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      pad(Row(
        children: [
          const Expanded(
            child: Text(
              'Terakhir digunakan',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
          if (history.items.isNotEmpty)
            TextButton(
              onPressed: () => showHistorySheet(context),
              child: const Text('Lihat semua'),
            ),
        ],
      )),
      const SizedBox(height: 10),
      if (history.items.isEmpty)
        pad(const AppCard(
          shadow: false,
          child: EmptyState(
            icon: AppIcons.sparkles,
            title: 'Mulai dari pindai atau cari',
            subtitle: 'Aktivitas lu bakal muncul di sini.',
          ),
        ))
      else
        for (final h in history.recent)
          pad(Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _RecentCard(item: h, onTap: () => reuseHistory(context, h)),
          )),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: dark
            ? null
            : const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFE3F1FD), AppColors.lightBg],
              ),
      ),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          AppRefreshControl(
            onRefresh: () async {
              context.read<HistoryProvider>().reload();
              await Future<void>.delayed(const Duration(milliseconds: 800));
            },
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _HomeHeaderDelegate(
              top: top,
              dark: dark,
              controller: _search,
              hint: _hint,
              filtered: _scope != _SearchScope.quran,
              onSubmit: _submit,
              onFilter: _openFilter,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(0, 18, 0, 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                items
                    .animate(interval: 50.ms)
                    .fadeIn(duration: 380.ms)
                    .slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Header ─────────────────────────

class _HomeHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double top;
  final bool dark;
  final TextEditingController controller;
  final String hint;
  final bool filtered;
  final ValueChanged<String> onSubmit;
  final VoidCallback onFilter;
  _HomeHeaderDelegate({
    required this.top,
    required this.dark,
    required this.controller,
    required this.hint,
    required this.filtered,
    required this.onSubmit,
    required this.onFilter,
  });

  static const _expanded = 150.0;
  static const _collapsed = 74.0;

  @override
  double get maxExtent => top + _expanded;
  @override
  double get minExtent => top + _collapsed;

  @override
  bool shouldRebuild(covariant _HomeHeaderDelegate old) =>
      old.hint != hint ||
      old.filtered != filtered ||
      old.dark != dark ||
      old.top != top;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final t = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final radius = BorderRadius.vertical(bottom: Radius.circular(30 - 8 * t));
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.cardBlue.forMode(dark),
        borderRadius: radius,
        boxShadow: dark
            ? null
            : [
                BoxShadow(
                  color: AppColors.blue500.withValues(alpha: 0.2 + 0.1 * t),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Stack(
        children: [
          // Sapaan + avatar: naik dan memudar saat di-scroll.
          Positioned(
            left: 16,
            right: 16,
            top: top + 14 - 18 * t,
            child: Opacity(
              opacity: (1 - t * 1.8).clamp(0.0, 1.0),
              child: const _Greeting(),
            ),
          ),
          // Pencarian + filter: selalu menempel di bawah header.
          Positioned(
            left: 16,
            right: 16,
            bottom: 14,
            height: 46,
            child: _SearchRow(
              controller: controller,
              hint: hint,
              filtered: filtered,
              onSubmit: onSubmit,
              onFilter: onFilter,
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Header ─────────────────────────

class _Greeting extends StatelessWidget {
  const _Greeting();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final guest = auth.status == AuthStatus.guest;
    final name = guest ? 'Tamu' : (auth.user?.shownName ?? '');

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Halo,',
                style: TextStyle(
                  fontSize: 13.5,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('👋', style: TextStyle(fontSize: 21)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.all(2.5),
          decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
          child: UserAvatar(user: guest ? null : auth.user, size: 40),
        ),
      ],
    );
  }
}

class _SearchRow extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool filtered;
  final ValueChanged<String> onSubmit;
  final VoidCallback onFilter;
  const _SearchRow({
    required this.controller,
    required this.hint,
    required this.filtered,
    required this.onSubmit,
    required this.onFilter,
  });

  @override
  Widget build(BuildContext context) {
    final dark = context.isDark;
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              // Terang: kolom putih. Gelap: kaca transparan, bukan blok gelap
              // di atas gradien.
              color: dark ? Colors.white.withValues(alpha: 0.18) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: dark
                  ? Border.all(color: Colors.white.withValues(alpha: 0.28))
                  : null,
            ),
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.search,
              onSubmitted: onSubmit,
              cursorColor: dark ? Colors.white : null,
              style: TextStyle(
                fontSize: 14,
                color: dark ? Colors.white : AppColors.lightText,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: dark
                      ? Colors.white.withValues(alpha: 0.7)
                      : AppColors.lightMuted,
                ),
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
                suffixIcon: IconButton(
                  onPressed: () => onSubmit(controller.text),
                  icon: Icon(
                    AppIcons.search,
                    size: 18,
                    color: dark ? Colors.white : AppColors.lightText,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Stack(
          clipBehavior: Clip.none,
          children: [
            Material(
              color: Colors.white.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: onFilter,
                child: const SizedBox(
                  width: 46,
                  height: 46,
                  child: Icon(AppIcons.tune, size: 19, color: Colors.white),
                ),
              ),
            ),
            if (filtered)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.orange,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _ScopeTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  const _ScopeTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.tone(color);
    return Material(
      color: selected ? c.withValues(alpha: context.isDark ? 0.2 : 0.12) : context.surface2,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                child: Icon(icon, size: 20, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: context.muted)),
                  ],
                ),
              ),
              Icon(
                selected ? AppIcons.success : AppIcons.chevronRight,
                size: selected ? 22 : 18,
                color: selected ? c : context.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Banner API key ─────────────────────────

class _KeyBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _KeyBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        gradient: AppColors.cardBlue.forMode(context.isDark),
        borderRadius: BorderRadius.circular(22),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 6, 14),
      child: Row(
        children: [
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Atur API key Gemini dulu biar bisa mulai !',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: onTap,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      child: Text(
                        'Atur Sekarang',
                        style: TextStyle(
                          color: Color(0xFF13203A),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Expanded(
            flex: 4,
            child: ArtImage(
              asset: Art.homeBanner,
              fallbackIcon: AppIcons.key,
              fallbackSize: 56,
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Pill kategori ─────────────────────────

class _TopicPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool filled;
  final VoidCallback onTap;
  const _TopicPill({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final dark = context.isDark;
    final bg = filled ? color : context.cs.surface;
    final fg = filled ? Colors.white : context.textColor;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(26),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            border: (!filled && dark) ? Border.all(color: context.border) : null,
            boxShadow: (!filled && !dark)
                ? [
                    BoxShadow(
                      color: AppColors.blue600.withValues(alpha: 0.07),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: filled ? Colors.white.withValues(alpha: 0.28) : color,
                ),
                child: Icon(icon, size: 18, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Kartu fitur (carousel) ─────────────────────────

class _FeatureCard extends StatelessWidget {
  final Gradient gradient;
  final Color shadow;
  final String asset;
  final IconData fallback;
  final String title;
  final String subtitle;
  final List<(IconData, String)> chips;
  final VoidCallback onTap;
  const _FeatureCard({
    required this.gradient,
    required this.shadow,
    required this.asset,
    required this.fallback,
    required this.title,
    required this.subtitle,
    required this.chips,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(26));
    return Container(
      width: 216,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: context.isDark
            ? null
            : [
                BoxShadow(
                  color: shadow.withValues(alpha: 0.28),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient.forMode(context.isDark),
            borderRadius: radius,
          ),
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 118,
                          height: 118,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        Positioned.fill(
                          child: ArtImage(asset: asset, fallbackIcon: fallback),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.82),
                      fontSize: 11.5,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      for (var k = 0; k < chips.length; k++) ...[
                        if (k > 0) const SizedBox(width: 12),
                        _MiniStat(icon: chips[k].$1, text: chips[k].$2),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MiniStat({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 13, color: Colors.white),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Kartu riwayat berwarna ─────────────────────────

class _RecentCard extends StatelessWidget {
  final HistoryItem item;
  final VoidCallback onTap;
  const _RecentCard({required this.item, required this.onTap});

  Gradient get _gradient {
    switch (item.type) {
      case HistoryType.ocr:
        return AppColors.cardOcr;
      case HistoryType.quran:
        return AppColors.cardQuran;
      case HistoryType.nahwu:
        return AppColors.cardPurple;
    }
  }

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(22));
    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: Ink(
        decoration: BoxDecoration(
          gradient: _gradient.forMode(context.isDark),
          borderRadius: radius,
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.28),
                  ),
                  child: Icon(historyIcon(item.type), size: 20, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        historyTitle(item),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${historyLabel(item.type)} · ${timeAgo(item.createdAt)}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(AppIcons.chevronRight, size: 18, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
