import 'package:flutter/material.dart';

/// Lokasi gambar ilustrasi. Taruh file-nya manual di assets/images/.
/// Kalau file belum ada, [ArtImage] menampilkan ikon pengganti (nggak crash).
class Art {
  Art._();

  static const onboarding1 = 'assets/images/onboarding_1.png';
  static const onboarding2 = 'assets/images/onboarding_2.png';
  static const onboarding3 = 'assets/images/onboarding_3.png';

  static const homeOcr = 'assets/images/home_ocr.png';
  static const homeQuran = 'assets/images/home_quran.png';
  static const homeNahwu = 'assets/images/home_nahwu.png';
  static const homeBanner = 'assets/images/home_banner.png';
}

class ArtImage extends StatelessWidget {
  final String asset;
  final IconData fallbackIcon;
  final Color fallbackColor;
  final double fallbackSize;
  final BoxFit fit;

  const ArtImage({
    super.key,
    required this.asset,
    required this.fallbackIcon,
    this.fallbackColor = Colors.white,
    this.fallbackSize = 64,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      fit: fit,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, __, ___) => Center(
        child: Icon(
          fallbackIcon,
          size: fallbackSize,
          color: fallbackColor.withValues(alpha: 0.9),
        ),
      ),
    );
  }
}
