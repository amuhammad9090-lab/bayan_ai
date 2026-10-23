import 'package:flutter/material.dart';

import '../../core/app_info.dart';
import '../../core/icons.dart';
import '../../core/theme.dart';
import '../../shared/widgets/logo_mark.dart';
import 'onboarding_art.dart';

class _Slide {
  final String title;
  final String desc;
  final Widget art;
  const _Slide(this.title, this.desc, this.art);
}

/// 3 slide: ilustrasi beranimasi + parallax saat digeser.
class OnboardingPage extends StatefulWidget {
  final VoidCallback onDone;
  const OnboardingPage({super.key, required this.onDone});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _pc = PageController();
  int _page = 0;

  static const _slides = [
    _Slide(
      'Pindai mushaf jadi teks',
      'Foto halaman mushaf atau kitab, lalu AI mengenali tulisan Arab berharakat dalam hitungan detik.',
      ScanArt(),
    ),
    _Slide(
      'Cari ayat & tafsir',
      'Ketik topik seperti "sabar" atau nama surah, dan dapatkan ayat, terjemah, serta penjelasan ringkas.',
      QuranArt(),
    ),
    _Slide(
      'Bedah nahwu kata per kata',
      "Lihat jenis kata, i'rab, dan tanda i'rab-nya dengan warna yang mudah dibaca.",
      NahwuArt(),
    ),
  ];

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  double get _pos => (_pc.hasClients && _pc.position.haveDimensions)
      ? (_pc.page ?? _page.toDouble())
      : _page.toDouble();

  @override
  Widget build(BuildContext context) {
    final last = _page == _slides.length - 1;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: _Backdrop(position: () => _pos, listenable: _pc),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 12, 0),
                  child: Row(
                    children: [
                      const LogoMark(size: 34),
                      const SizedBox(width: 10),
                      const Text(
                        kAppName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      AnimatedOpacity(
                        opacity: last ? 0 : 1,
                        duration: const Duration(milliseconds: 250),
                        child: IgnorePointer(
                          ignoring: last,
                          child: TextButton(
                            onPressed: widget.onDone,
                            child: const Text('Lewati'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pc,
                    itemCount: _slides.length,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemBuilder: (context, i) => AnimatedBuilder(
                      animation: _pc,
                      builder: (context, _) =>
                          _SlideView(slide: _slides[i], delta: i - _pos),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                  child: Row(
                    children: [
                      _Dots(count: _slides.length, index: _page),
                      const Spacer(),
                      FilledButton(
                        onPressed: last
                            ? widget.onDone
                            : () => _pc.nextPage(
                                duration: const Duration(milliseconds: 450),
                                curve: Curves.easeOutCubic,
                              ),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 22),
                        ),
                        child: AnimatedSize(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: Text(
                                  last ? 'Mulai sekarang' : 'Lanjut',
                                  key: ValueKey(last),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(AppIcons.arrowRight, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  final _Slide slide;
  final double delta;
  const _SlideView({required this.slide, required this.delta});

  @override
  Widget build(BuildContext context) {
    final a = (1 - delta.abs()).clamp(0.0, 1.0).toDouble();
    return Column(
      children: [
        Expanded(
          child: Opacity(
            opacity: a,
            child: Transform.translate(
              offset: Offset(delta * -60, 0),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 8,
                ),
                child: Center(
                  child: AspectRatio(
                    aspectRatio: kArtWidth / kArtHeight,
                    child: Container(
                      decoration: BoxDecoration(
                        color: context.isDark
                            ? AppColors.darkSurface
                            : AppColors.lightSurface,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: context.border),
                        boxShadow: context.isDark
                            ? null
                            : [
                                BoxShadow(
                                  color: AppColors.blue700.withValues(
                                    alpha: 0.08,
                                  ),
                                  blurRadius: 28,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                      ),
                      padding: const EdgeInsets.all(18),
                      child: FittedBox(child: slide.art),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Opacity(
          opacity: a,
          child: Transform.translate(
            offset: Offset(delta * 40, 0),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 14, 28, 12),
              child: Column(
                children: [
                  Text(
                    slide.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    slide.desc,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.6,
                      color: context.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Dots extends StatelessWidget {
  final int count;
  final int index;
  const _Dots({required this.count, required this.index});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.only(right: 6),
            width: i == index ? 26 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == index ? context.cs.primary : context.border,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
      ],
    );
  }
}

/// Dua lingkaran lembut yang ikut bergeser saat slide digeser.
class _Backdrop extends StatelessWidget {
  final double Function() position;
  final Listenable listenable;
  const _Backdrop({required this.position, required this.listenable});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: listenable,
      builder: (context, _) {
        final p = position();
        return Stack(
          children: [
            Positioned(
              left: -90 - p * 40,
              top: -70 + p * 24,
              child: _Blob(size: 280, color: context.cs.primary),
            ),
            Positioned(
              right: -100 + p * 50,
              bottom: 60 - p * 30,
              child: const _Blob(size: 320, color: AppColors.cyan),
            ),
          ],
        );
      },
    );
  }
}

class _Blob extends StatelessWidget {
  final double size;
  final Color color;
  const _Blob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withValues(alpha: 0.16), color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}
