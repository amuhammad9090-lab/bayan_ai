import 'package:flutter/material.dart';

import '../../core/art.dart';
import '../../core/icons.dart';
import '../../core/theme.dart';

class _Slide {
  final String title;
  final String desc;
  final String asset;
  final IconData fallback;
  final Color blob;
  const _Slide(this.title, this.desc, this.asset, this.fallback, this.blob);
}

/// 3 slide ala desain referensi: blob berwarna + ilustrasi, judul dengan garis
/// biru, deskripsi, indikator titik, dan tombol pil besar.
/// Ilustrasi: taruh file di assets/images/ (lihat lib/core/art.dart).
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
      'Pindai Mushaf Jadi Teks',
      'Foto halaman mushaf atau kitab, lalu AI mengenali tulisan Arab berharakat dalam hitungan detik.',
      Art.onboarding1,
      AppIcons.ocr,
      AppColors.peach,
    ),
    _Slide(
      'Cari Ayat & Tafsir',
      'Ketik topik seperti "sabar" atau nama surah, dan dapatkan ayat, terjemah, serta penjelasan ringkas.',
      Art.onboarding2,
      AppIcons.quran,
      Color(0xFFBFE3FB),
    ),
    _Slide(
      "Bedah Nahwu Kata per Kata",
      "Lihat jenis kata, i'rab, dan tanda i'rab-nya dengan warna yang mudah dibaca.",
      Art.onboarding3,
      AppIcons.nahwu,
      Color(0xFFD9DAF4),
    ),
  ];

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final last = _page == _slides.length - 1;

    return Scaffold(
      backgroundColor: context.cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
                child: AnimatedOpacity(
                  opacity: last ? 0 : 1,
                  duration: const Duration(milliseconds: 250),
                  child: IgnorePointer(
                    ignoring: last,
                    child: TextButton(
                      onPressed: widget.onDone,
                      style: TextButton.styleFrom(foregroundColor: context.muted),
                      child: const Text('Lewati'),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pc,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) => _SlideView(slide: _slides[i]),
              ),
            ),
            _Dots(count: _slides.length, index: _page),
            const SizedBox(height: 26),
            Padding(
              padding: const EdgeInsets.fromLTRB(36, 0, 36, 28),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: last
                      ? widget.onDone
                      : () => _pc.nextPage(
                            duration: const Duration(milliseconds: 420),
                            curve: Curves.easeOutCubic,
                          ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(62),
                    shadowColor: AppColors.blue500,
                    elevation: 8,
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      last ? 'Mulai Sekarang' : 'Lanjut',
                      key: ValueKey(last),
                      style: const TextStyle(fontSize: 17),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  final _Slide slide;
  const _SlideView({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(4),
                      child: ArtImage(
                        asset: slide.asset,
                        fallbackIcon: slide.fallback,
                        fallbackColor: AppColors.blue600,
                        fallbackSize: 96,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: 58,
            height: 3.5,
            decoration: BoxDecoration(
              color: AppColors.blue500,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            slide.desc,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, height: 1.7, color: context.muted),
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }
}

/// Titik kecil; yang aktif berupa cincin dengan titik di tengah.
class _Dots extends StatelessWidget {
  final int count;
  final int index;
  const _Dots({required this.count, required this.index});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 5),
            width: i == index ? 18 : 6,
            height: i == index ? 18 : 6,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i == index ? Colors.transparent : AppColors.blue300,
              border: i == index
                  ? Border.all(color: AppColors.blue500, width: 1.8)
                  : null,
            ),
            child: i == index
                ? Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.blue500,
                    ),
                  )
                : null,
          ),
      ],
    );
  }
}
