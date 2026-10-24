import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/art.dart';
import '../../core/icons.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../shared/widgets/animations.dart';
import '../../shared/widgets/common.dart';
import '../auth/auth_provider.dart';
import '../auth/user_avatar.dart';
import '../history/history_provider.dart';
import '../history/history_sheet.dart';
import '../nahwu/nahwu_provider.dart';
import '../profile/profile_page.dart';
import '../quran/quran_provider.dart';
import '../settings/settings_provider.dart';
import '../shell/nav_provider.dart';

part 'home_header.dart';
part 'home_widgets.dart';

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
            color: AppColors.featQuran,
            title: 'Ayat & Tafsir',
            subtitle: "Cari ayat berdasarkan topik atau nama surah",
            selected: _scope == _SearchScope.quran,
            onTap: () => Navigator.pop(ctx, _SearchScope.quran),
          ),
          const SizedBox(height: 10),
          _ScopeTile(
            icon: AppIcons.nahwu,
            color: AppColors.featNahwu,
            title: 'Analisis Nahwu',
            subtitle: 'Tulis kalimat Arab, langsung dianalisis',
            selected: _scope == _SearchScope.nahwu,
            onTap: () => Navigator.pop(ctx, _SearchScope.nahwu),
          ),
          const SizedBox(height: 10),
          _ScopeTile(
            icon: AppIcons.history,
            color: AppColors.history,
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
    final wide = context.isWide;

    Widget pad(Widget w) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: w,
        );

    // Pil fitur & kartu fitur: di layar lebar sebaris, di HP 2x2 / carousel.
    final pills = <Widget>[
      _TopicPill(
        icon: AppIcons.quran,
        label: "Qur'an",
        color: AppColors.featQuran,
        filled: true,
        onTap: () => nav.go(NavProvider.quran),
      ),
      _TopicPill(
        icon: AppIcons.nahwu,
        label: 'Nahwu',
        color: AppColors.featNahwu,
        onTap: () => nav.go(NavProvider.nahwu),
      ),
      _TopicPill(
        icon: AppIcons.ocr,
        label: 'Pindai',
        color: AppColors.featOcr,
        onTap: () => nav.go(NavProvider.ocr),
      ),
      _TopicPill(
        icon: AppIcons.history,
        label: 'Riwayat',
        color: AppColors.history,
        onTap: () => showHistorySheet(context),
      ),
    ];
    final cards = <Widget>[
      _FeatureCard(
        gradient: AppColors.gradQuran,
        shadow: AppColors.featQuran,
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
      _FeatureCard(
        gradient: AppColors.gradNahwu,
        shadow: AppColors.featNahwu,
        asset: Art.homeNahwu,
        fallback: AppIcons.nahwu,
        title: 'Analisis Nahwu',
        subtitle: 'Nahwu kata per kata dengan 7 bab',
        chips: [
          (AppIcons.nahwu, '${history.count(HistoryType.nahwu)} hasil'),
          (AppIcons.lightbulb, '7 bab'),
        ],
        onTap: () => nav.go(NavProvider.nahwu),
      ),
      _FeatureCard(
        gradient: AppColors.gradOcr,
        shadow: AppColors.featOcr,
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
    ];

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
      pad(wide
          ? Row(
              children: [
                for (var k = 0; k < pills.length; k++) ...[
                  if (k > 0) const SizedBox(width: 10),
                  Expanded(child: pills[k]),
                ],
              ],
            )
          : Column(
              children: [
                Row(
                  children: [
                    Expanded(child: pills[0]),
                    const SizedBox(width: 10),
                    Expanded(child: pills[1]),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: pills[2]),
                    const SizedBox(width: 10),
                    Expanded(child: pills[3]),
                  ],
                ),
              ],
            )),
      const SizedBox(height: 18),
      SizedBox(
        height: 262,
        child: wide
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var k = 0; k < cards.length; k++) ...[
                      if (k > 0) const SizedBox(width: 14),
                      Expanded(child: cards[k]),
                    ],
                  ],
                ),
              )
            : ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                clipBehavior: Clip.none,
                itemCount: cards.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, k) => SizedBox(width: 216, child: cards[k]),
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
            art: Art.stateEmpty,
            title: 'Mulai dari pindai atau cari',
            subtitle: 'Aktivitas kamu akan tampil di sini.',
          ),
        ))
      else
        for (final h in history.recent)
          pad(Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _RecentCard(item: h, onTap: () => reuseHistory(context, h)),
          )),
    ];

    final scroll = CustomScrollView(
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
      );

    if (!dark) {
      return DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE3F1FD), AppColors.lightBg],
          ),
        ),
        child: scroll,
      );
    }
    // Gelap: cahaya lembut warna-warna fitur di latar supaya nggak flat.
    return Stack(
      fit: StackFit.expand,
      children: [
        const Positioned.fill(
          child: AmbientGlow(
            spots: [
              (Alignment(-1.1, -0.35), Color(0xFF3A8EE6), 0.16, 0.9),
              (Alignment(1.2, 0.15), AppColors.featNahwu, 0.09, 0.8),
              (Alignment(-1.0, 1.0), AppColors.featOcr, 0.11, 0.9),
            ],
          ),
        ),
        scroll,
      ],
    );
  }
}

// ───────────────────────── Header ─────────────────────────
