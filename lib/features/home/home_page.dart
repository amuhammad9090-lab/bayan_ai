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
import '../quran/quran_provider.dart';
import '../settings/settings_provider.dart';
import '../shell/nav_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// Cari dari beranda: isi kolom di tab Qur'an, jalankan pencarian, pindah tab.
  void _submit(String value) {
    final q = value.trim();
    if (q.isEmpty) return;
    final quran = context.read<QuranProvider>();
    final nav = context.read<NavProvider>();
    quran.setQuery(q);
    quran.search();
    nav.go(NavProvider.quran);
    _search.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final nav = context.read<NavProvider>();
    final hasKey = context.select<SettingsProvider, bool>((s) => s.hasApiKey);
    final history = context.watch<HistoryProvider>();
    final dark = context.isDark;
    final top = MediaQuery.of(context).padding.top;

    Widget pad(Widget w) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: w,
        );

    final items = <Widget>[
      pad(_SearchRow(
        controller: _search,
        onSubmit: _submit,
        onFilter: () => nav.go(NavProvider.settings),
      )),
      const SizedBox(height: 22),
      if (!hasKey) ...[
        pad(_KeyBanner(onTap: () => nav.go(NavProvider.settings))),
        const SizedBox(height: 22),
      ],
      pad(const Text(
        'Fitur',
        style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
      )),
      const SizedBox(height: 14),
      pad(Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _TopicPill(
                  icon: AppIcons.ocr,
                  label: 'Pindai',
                  color: AppColors.blue500,
                  filled: true,
                  onTap: () => nav.go(NavProvider.ocr),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _TopicPill(
                  icon: AppIcons.quran,
                  label: "Qur'an",
                  color: AppColors.orange,
                  onTap: () => nav.go(NavProvider.quran),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
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
              const SizedBox(width: 14),
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
      const SizedBox(height: 24),
      SizedBox(
        height: 330,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          clipBehavior: Clip.none,
          children: [
            _FeatureCard(
              gradient: AppColors.cardBlue,
              shadow: AppColors.blue500,
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
            const SizedBox(width: 16),
            _FeatureCard(
              gradient: AppColors.cardOrange,
              shadow: AppColors.orange,
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
            const SizedBox(width: 16),
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
      const SizedBox(height: 26),
      pad(Row(
        children: [
          const Expanded(
            child: Text(
              'Terakhir digunakan',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
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
            padding: const EdgeInsets.only(bottom: 14),
            child: _RecentCard(item: h, onTap: () => reuseHistory(context, h)),
          )),
    ];

    return Column(
      children: [
        // Header putih (sapaan + avatar), seperti desain referensi.
        Container(
          width: double.infinity,
          color: context.cs.surface,
          padding: EdgeInsets.fromLTRB(20, top + 16, 20, 18),
          child: const _Greeting(),
        ),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: dark
                  ? null
                  : const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFE3F1FD), AppColors.lightBg],
                    ),
            ),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(0, 22, 0, 24),
              children: items
                  .animate(interval: 50.ms)
                  .fadeIn(duration: 380.ms)
                  .slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic),
            ),
          ),
        ),
      ],
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
                style: TextStyle(fontSize: 16, color: context.muted),
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
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('👋', style: TextStyle(fontSize: 26)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        UserAvatar(user: guest ? null : auth.user, size: 50),
      ],
    );
  }
}

class _SearchRow extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSubmit;
  final VoidCallback onFilter;
  const _SearchRow({
    required this.controller,
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
            height: 54,
            decoration: BoxDecoration(
              color: context.cs.surface,
              borderRadius: BorderRadius.circular(18),
              border: dark ? Border.all(color: context.border) : null,
              boxShadow: dark
                  ? null
                  : [
                      BoxShadow(
                        color: AppColors.blue600.withValues(alpha: 0.07),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
            ),
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.search,
              onSubmitted: onSubmit,
              decoration: InputDecoration(
                hintText: 'Cari ayat atau topik…',
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.fromLTRB(18, 16, 8, 16),
                suffixIcon: IconButton(
                  onPressed: () => onSubmit(controller.text),
                  icon: Icon(AppIcons.search, size: 20, color: context.textColor),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Material(
          color: AppColors.blue500,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onFilter,
            child: const SizedBox(
              width: 54,
              height: 54,
              child: Icon(AppIcons.tune, size: 22, color: Colors.white),
            ),
          ),
        ),
      ],
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
      height: 150,
      decoration: BoxDecoration(
        gradient: AppColors.cardBlue,
        borderRadius: BorderRadius.circular(26),
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 8, 18),
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
                    fontSize: 17,
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
                      padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      child: Text(
                        'Atur Sekarang',
                        style: TextStyle(
                          color: Color(0xFF13203A),
                          fontSize: 13,
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
      borderRadius: BorderRadius.circular(32),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(32),
        onTap: onTap,
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
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
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: filled ? Colors.white.withValues(alpha: 0.28) : color,
                ),
                child: Icon(icon, size: 21, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
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
    const radius = BorderRadius.all(Radius.circular(30));
    return Container(
      width: 252,
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
          decoration: BoxDecoration(gradient: gradient, borderRadius: radius),
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 150,
                          height: 150,
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
                      fontSize: 20,
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
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
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
                fontSize: 12.5,
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
        return AppColors.cardTeal;
      case HistoryType.quran:
        return AppColors.cardOrange;
      case HistoryType.nahwu:
        return AppColors.cardPurple;
    }
  }

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(26));
    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: Ink(
        decoration: BoxDecoration(gradient: _gradient, borderRadius: radius),
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.28),
                  ),
                  child: Icon(historyIcon(item.type), size: 24, color: Colors.white),
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
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${historyLabel(item.type)} · ${timeAgo(item.createdAt)}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(AppIcons.chevronRight, size: 20, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
