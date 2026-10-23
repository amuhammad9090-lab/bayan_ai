import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/icons.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../shared/widgets/common.dart';
import '../auth/auth_provider.dart';
import '../auth/user_avatar.dart';
import '../history/history_provider.dart';
import '../history/history_sheet.dart';
import '../settings/settings_provider.dart';
import '../shell/nav_provider.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final nav = context.read<NavProvider>();
    final hasKey = context.select<SettingsProvider, bool>((s) => s.hasApiKey);
    final history = context.watch<HistoryProvider>();

    final items = <Widget>[
        const _Greeting(),
        const SizedBox(height: 14),
        _Hero(onStart: () => nav.go(NavProvider.ocr)),
        const SizedBox(height: 16),

        if (!hasKey) ...[
          AppCard(
            color: context.surface2,
            shadow: false,
            onTap: () => nav.go(NavProvider.settings),
            child: Row(
              children: [
                const IconChip(icon: AppIcons.key, size: 40),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('API key belum diatur',
                          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                      SizedBox(height: 2),
                      Text('Ketuk untuk mengisi di Setelan.', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                Icon(AppIcons.chevronRight, size: 18, color: context.muted),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        const SectionHeader(title: 'Fitur utama', subtitle: 'Pilih alat yang lu butuhin'),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.08,
          children: [
            _FeatureTile(
              icon: AppIcons.ocr,
              title: 'Pindai Mushaf',
              desc: 'Ubah foto jadi teks Arab berharakat',
              onTap: () => nav.go(NavProvider.ocr),
            ),
            _FeatureTile(
              icon: AppIcons.quran,
              title: 'Ayat & Tafsir',
              desc: 'Cari ayat berdasarkan topik',
              onTap: () => nav.go(NavProvider.quran),
            ),
            _FeatureTile(
              icon: AppIcons.nahwu,
              title: 'Analisis Nahwu',
              desc: "I'rab kata per kata",
              onTap: () => nav.go(NavProvider.nahwu),
            ),
            _FeatureTile(
              icon: AppIcons.history,
              title: 'Riwayat',
              desc: '${history.items.length} hasil tersimpan',
              onTap: () => showHistorySheet(context),
            ),
          ],
        ),
        const SizedBox(height: 22),

        Row(
          children: [
            Expanded(
              child: _Stat(
                label: 'OCR',
                value: history.count(HistoryType.ocr),
                icon: AppIcons.ocr,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Stat(
                label: "Qur'an",
                value: history.count(HistoryType.quran),
                icon: AppIcons.quran,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Stat(
                label: 'Nahwu',
                value: history.count(HistoryType.nahwu),
                icon: AppIcons.nahwu,
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),

        SectionHeader(
          title: 'Terakhir digunakan',
          trailing: history.items.isEmpty
              ? null
              : TextButton(
                  onPressed: () => showHistorySheet(context),
                  child: const Text('Lihat semua'),
                ),
        ),
        if (history.items.isEmpty)
          const AppCard(
            shadow: false,
            child: EmptyState(
              icon: AppIcons.sparkles,
              title: 'Mulai dari pindai atau cari',
              subtitle: 'Aktivitas lu bakal muncul di sini.',
            ),
          )
        else
          for (final h in history.recent)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: HistoryTile(item: h, onTap: () => reuseHistory(context, h)),
            ),
    ];

    // Tiap blok masuk bergantian (fade + naik), jadi beranda terasa "hidup".
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: items
          .animate(interval: 60.ms)
          .fadeIn(duration: 420.ms)
          .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting();

  static String _salam() {
    final h = DateTime.now().hour;
    if (h < 11) return 'Selamat pagi';
    if (h < 15) return 'Selamat siang';
    if (h < 18) return 'Selamat sore';
    return 'Selamat malam';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final guest = auth.status == AuthStatus.guest;
    final name = guest ? 'Tamu' : (auth.user?.shownName ?? '');

    return Row(
      children: [
        UserAvatar(user: guest ? null : auth.user, size: 44),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Assalamu'alaikum, ${_salam().toLowerCase()}",
                style: TextStyle(fontSize: 12, color: context.muted),
              ),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  final VoidCallback onStart;
  const _Hero({required this.onStart});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: Container(
        decoration: const BoxDecoration(gradient: AppColors.heroGradient),
        padding: const EdgeInsets.all(22),
        child: Stack(
          children: [
            Positioned(
              right: -40,
              top: -50,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .moveY(begin: -8, end: 8, duration: 3.seconds, curve: Curves.easeInOut),
            ),
            Positioned(
              right: 30,
              bottom: -60,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .moveX(begin: -10, end: 10, duration: 3.6.seconds, curve: Curves.easeInOut),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Directionality(
                  textDirection: TextDirection.rtl,
                  child: SizedBox(
                    width: double.infinity,
                    child: Text(
                      'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'ScheherazadeNew',
                        fontSize: 26,
                        color: Colors.white,
                        height: 1.8,
                      ),
                    ),
                  ),
                )
                    .animate(onPlay: (c) => c.repeat())
                    .shimmer(delay: 1400.ms, duration: 2200.ms, color: AppColors.blue200),
                const SizedBox(height: 8),
                const Text(
                  'Belajar Al-Qur\'an & Nahwu\nlebih cerdas dengan AI',
                  style: TextStyle(
                    fontSize: 19,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Pindai mushaf, cari ayat dan tafsir, lalu bedah i\'rab-nya.',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.5,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: onStart,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.blue800,
                    minimumSize: const Size(0, 44),
                  ),
                  icon: const Icon(AppIcons.ocr, size: 18),
                  label: const Text('Mulai pindai'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  final VoidCallback onTap;
  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.desc,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconChip(icon: icon, size: 46),
          const Spacer(),
          Text(title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(
            desc,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11.5, height: 1.4, color: context.muted),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  const _Stat({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      shadow: false,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      child: Column(
        children: [
          Icon(icon, size: 18, color: context.cs.primary),
          const SizedBox(height: 8),
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: value),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => Text(
              '$v',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ),
          Text(label, style: TextStyle(fontSize: 11.5, color: context.muted)),
        ],
      ),
    );
  }
}
