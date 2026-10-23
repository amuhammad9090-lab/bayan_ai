import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// Logo app. Memakai aset ikon asli (sama dengan ikon launcher).
/// Ganti [kLogoAsset] kalau mau pakai gambar lain.
const kLogoAsset = 'assets/icons/icon.png';

class LogoMark extends StatelessWidget {
  final double size;
  const LogoMark({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size * 0.26);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: AppColors.blue600.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Image.asset(
          kLogoAsset,
          width: size,
          height: size,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
          // Ukuran decode kecil biar hemat memori (aslinya 1024px).
          cacheWidth: (size * 3).round(),
        ),
      ),
    );
  }
}
