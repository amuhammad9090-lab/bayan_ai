import 'package:flutter/material.dart';

import '../../core/icons.dart';
import '../../core/theme.dart';
import '../../shared/widgets/animations.dart';
import '../../shared/widgets/common.dart';

/// Semua ilustrasi digambar di kanvas 280x254, lalu di-FittedBox oleh halaman.
const double kArtWidth = 280;
const double kArtHeight = 254;

TextStyle _arabic(double size, Color color) => TextStyle(
  fontFamily: 'ScheherazadeNew',
  fontSize: size,
  height: 1.7,
  color: color,
);

// ───────────────────────── 1. Pindai mushaf ─────────────────────────

class ScanArt extends StatelessWidget {
  const ScanArt({super.key});

  static const _lines = [
    'ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَـٰلَمِينَ',
    'ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
    'مَـٰلِكِ يَوْمِ ٱلدِّينِ',
  ];

  @override
  Widget build(BuildContext context) {
    final primary = context.cs.primary;
    final pageBg = context.isDark ? AppColors.darkBg : Colors.white;

    return SizedBox(
      width: kArtWidth,
      height: kArtHeight,
      child: LoopBuilder(
        duration: const Duration(milliseconds: 2800),
        reverse: true,
        builder: (context, t0) {
          final t = Curves.easeInOut.transform(t0);
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 200,
                height: 186,
                decoration: BoxDecoration(
                  color: pageBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: context.border),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.blue700.withValues(alpha: 0.12),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (final line in _lines)
                              Directionality(
                                textDirection: TextDirection.rtl,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    line,
                                    style: _arabic(20, context.textColor),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        top: t * 186 - 46,
                        height: 46,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                primary.withValues(alpha: 0),
                                primary.withValues(alpha: 0.22),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        top: t * 183,
                        height: 3,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: primary,
                            boxShadow: [
                              BoxShadow(
                                color: primary.withValues(alpha: 0.7),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: 226,
                height: 212,
                child: ScanCorners(color: primary, margin: 0),
              ),
              Positioned(
                bottom: 2,
                child: AnimatedOpacity(
                  opacity: t0 > 0.8 ? 1 : 0,
                  duration: const Duration(milliseconds: 250),
                  child: const Pill(
                    label: 'Teks terdeteksi',
                    color: AppColors.success,
                    icon: AppIcons.check,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ───────────────────────── 2. Cari ayat & tafsir ─────────────────────────

class QuranArt extends StatelessWidget {
  const QuranArt({super.key});

  static const _query = 'ayat tentang sabar';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: kArtWidth,
      height: kArtHeight,
      child: LoopBuilder(
        duration: const Duration(milliseconds: 6200),
        builder: (context, t) {
          final typed = (segment(t, 0.04, 0.3) * _query.length).floor();
          final cursor = (t * 36).floor().isEven;
          final out = t > 0.9 ? 1 - (t - 0.9) / 0.1 : 1.0;

          return Opacity(
            opacity: out,
            child: Column(
              children: [
                Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: context.surface2,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: context.border),
                  ),
                  child: Row(
                    children: [
                      Icon(AppIcons.search, size: 18, color: context.muted),
                      const SizedBox(width: 10),
                      Text(
                        _query.substring(0, typed) + (cursor ? '|' : ' '),
                        style: const TextStyle(fontSize: 13.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                _reveal(
                  segment(t, 0.4, 0.14),
                  const _AyatMini(
                    label: 'QS. Al-Baqarah · 153',
                    arab: 'إِنَّ ٱللَّهَ مَعَ ٱلصَّـٰبِرِينَ',
                    arti: 'Sungguh, Allah bersama orang-orang yang sabar.',
                  ),
                ),
                const SizedBox(height: 8),
                _reveal(
                  segment(t, 0.54, 0.14),
                  const _AyatMini(
                    label: 'QS. Az-Zumar · 10',
                    arab: 'إِنَّمَا يُوَفَّى ٱلصَّـٰبِرُونَ أَجْرَهُم بِغَيْرِ حِسَابٍ',
                    arti: 'Hanya orang yang bersabar yang disempurnakan pahalanya.',
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _reveal(double p, Widget child) {
    final e = Curves.easeOutCubic.transform(p);
    return Opacity(
      opacity: e,
      child: Transform.translate(offset: Offset(0, 18 * (1 - e)), child: child),
    );
  }
}

class _AyatMini extends StatelessWidget {
  final String label;
  final String arab;
  final String arti;
  const _AyatMini({
    required this.label,
    required this.arab,
    required this.arti,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 86,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: context.cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.border),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: 240,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Pill(
                label: label,
                color: AppColors.blue600,
                icon: AppIcons.bookMarked,
              ),
              Directionality(
                textDirection: TextDirection.rtl,
                child: SizedBox(
                  width: 240,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(arab, style: _arabic(19, context.textColor)),
                  ),
                ),
              ),
              Text(
                arti,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10.5, color: context.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── 3. Bedah nahwu ─────────────────────────

class NahwuArt extends StatelessWidget {
  const NahwuArt({super.key});

  static const _words = [
    ('ٱلْحَمْدُ', "Mubtada'", AppColors.blue600),
    ('لِلَّهِ', 'Jar-Majrur', AppColors.cyan),
    ('رَبِّ', "Na'at", AppColors.indigo),
    ('ٱلْعَـٰلَمِينَ', 'Mudhaf ilaih', Color(0xFF0D9488)),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: kArtWidth,
      height: kArtHeight,
      child: LoopBuilder(
        duration: const Duration(milliseconds: 5600),
        builder: (context, t) {
          final out = t > 0.92 ? 1 - (t - 0.92) / 0.08 : 1.0;
          return Opacity(
            opacity: out,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      for (var i = 0; i < _words.length; i++)
                        _WordChip(
                          word: _words[i].$1,
                          label: _words[i].$2,
                          color: _words[i].$3,
                          p: Curves.easeOutCubic.transform(
                            segment(t, 0.08 + i * 0.17, 0.1),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Opacity(
                  opacity: segment(t, 0.76, 0.1),
                  child: const Pill(
                    label: 'Jumlah ismiyyah',
                    color: AppColors.blue600,
                    icon: AppIcons.sparkles,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _WordChip extends StatelessWidget {
  final String word;
  final String label;
  final Color color;
  final double p;
  const _WordChip({
    required this.word,
    required this.label,
    required this.color,
    required this.p,
  });

  @override
  Widget build(BuildContext context) {
    final tone = context.tone(color);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(word, style: _arabic(28, Color.lerp(context.textColor, tone, p)!)),
        const SizedBox(height: 2),
        Container(
          height: 3,
          width: 44 * p,
          decoration: BoxDecoration(
            color: tone,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(height: 8),
        Opacity(
          opacity: p,
          child: Transform.scale(
            scale: 0.8 + 0.2 * p,
            child: Pill(label: label, color: color),
          ),
        ),
      ],
    );
  }
}
