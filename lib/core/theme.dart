import 'package:flutter/material.dart';

/// Palet biru terpadu untuk Quran & Nahwu AI.
class AppColors {
  AppColors._();

  // Ramp biru langit (gaya desain baru: terang, lembut, bulat).
  static const blue50 = Color(0xFFEEF7FE);
  static const blue100 = Color(0xFFDCEEFD);
  static const blue200 = Color(0xFFBCE0FB);
  static const blue300 = Color(0xFF8FCBF8);
  static const blue400 = Color(0xFF66BAF7);
  static const blue500 = Color(0xFF4FB6F9);
  static const blue600 = Color(0xFF38A4F0);
  static const blue700 = Color(0xFF2490DC);
  static const blue800 = Color(0xFF1B6FB0);
  static const blue900 = Color(0xFF154F80);
  static const navy = Color(0xFF0E2340);

  static const cyan = Color(0xFF0891B2);
  static const indigo = Color(0xFF4F46E5);

  // Aksen kartu & ikon (oranye, ungu, tosca, peach).
  static const orange = Color(0xFFF5A623);
  // Aksen fitur Qur'an: tosca-aqua (agak ke cyan, beda tipis dari tosca Setelan).
  static const quran = Color(0xFF2FBFCF);
  // Aksen fitur OCR (Pindai): biru royal lembut, serumpun dengan tema biru muda.
  static const ocr = Color(0xFF5E82E8);
  static const purple = Color(0xFF7B7FC6);
  static const teal = Color(0xFF4FD3CC);
  static const peach = Color(0xFFFFCBBD);

  // Light
  static const lightBg = Color(0xFFEDF4FB);
  static const lightSurface = Colors.white;
  static const lightBorder = Color(0xFFE2EBF5);
  static const lightText = Color(0xFF13203A);
  static const lightMuted = Color(0xFF77859B);

  // Dark
  // Dark mode "kalem": biru-abu lembut, bukan navy pekat.
  static const darkBg = Color(0xFF0F1729);
  static const darkSurface = Color(0xFF18223A);
  static const darkSurface2 = Color(0xFF212D4A);
  static const darkBorder = Color(0xFF2B3957);
  static const darkText = Color(0xFFE8EEFB);
  static const darkMuted = Color(0xFF9DAECD);

  static const danger = Color(0xFFE5484D);
  static const success = Color(0xFF16A34A);

  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [navy, blue800, blue600],
  );

  static const buttonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5CBBFA), Color(0xFF45AEF6)],
  );

  // Gradien kartu berwarna (beranda & daftar).
  static const cardBlue = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6CC2FA), Color(0xFF3FA9F2)],
  );
  // Header Beranda versi gelap: biru langit → royal → indigo, melebur ke
  // latar navy alih-alih biru terang yang "nyetrum".
  static const homeDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3C9AE6), Color(0xFF2C6CCB), Color(0xFF283F8E)],
  );
  static Gradient homeHeader(bool dark) => dark ? homeDark : cardBlue;
  // Warna Riwayat = warna Beranda (biru langit).
  static const history = blue500;
  static const cardOcr = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8FB0FA), Color(0xFF5E82E8)],
  );
  static const cardQuran = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF74DDE8), Color(0xFF2FBFCF)],
  );
  static const cardPurple = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF9EA1DE), Color(0xFF7B7FC6)],
  );
  // Warna per fitur, mengikuti urutan tab: Qur'an, Nahwu, OCR.
  static const featQuran = ocr; // biru royal
  static const featNahwu = quran; // tosca
  static const featOcr = purple; // ungu
  static const gradQuran = cardOcr;
  static const gradNahwu = cardQuran;
  static const gradOcr = cardPurple;

  // Setelan: abu-biru (slate), netral dan beda dari keempat tab lain.
  static const settings = Color(0xFF6B7BA0);
  static const cardSettings = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF9DABC9), Color(0xFF6B7BA0)],
  );
}

class AppTheme {
  AppTheme._();

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness b) {
    final dark = b == Brightness.dark;
    final bg = dark ? AppColors.darkBg : AppColors.lightBg;
    final surface = dark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = dark ? AppColors.darkBorder : AppColors.lightBorder;
    final text = dark ? AppColors.darkText : AppColors.lightText;
    final muted = dark ? AppColors.darkMuted : AppColors.lightMuted;
    final primary = dark ? AppColors.blue300 : AppColors.blue700;

    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.blue600,
      brightness: b,
    ).copyWith(
      primary: primary,
      onPrimary: dark ? AppColors.navy : Colors.white,
      secondary: AppColors.cyan,
      surface: surface,
      onSurface: text,
      onSurfaceVariant: muted,
      outline: border,
      outlineVariant: border,
      error: AppColors.danger,
      // Semua tone surface di-set eksplisit supaya widget M3 (chip, dialog,
      // segmented button, dll) nggak ngambil warna default yang beda antar tema.
      surfaceContainerLowest: bg,
      surfaceContainerLow: surface,
      surfaceContainer: surface,
      surfaceContainerHigh: dark ? AppColors.darkSurface2 : AppColors.blue50,
      surfaceContainerHighest: dark ? AppColors.darkSurface2 : AppColors.blue100,
      surfaceTint: Colors.transparent,
      primaryContainer: dark ? AppColors.darkSurface2 : AppColors.blue100,
      onPrimaryContainer: dark ? AppColors.blue200 : AppColors.blue900,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: b,
      colorScheme: scheme,
      fontFamily: 'PlusJakartaSans',
      scaffoldBackgroundColor: bg,
      splashFactory: InkRipple.splashFactory,
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(bodyColor: text, displayColor: text),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: text,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: text,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 68,
        indicatorColor: dark ? AppColors.darkSurface2 : AppColors.blue100,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final sel = states.contains(WidgetState.selected);
          return TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 11,
            fontWeight: sel ? FontWeight.w600 : FontWeight.w500,
            color: sel ? primary : muted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final sel = states.contains(WidgetState.selected);
          return IconThemeData(size: 22, color: sel ? primary : muted);
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? AppColors.darkSurface2 : AppColors.blue50,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: TextStyle(color: muted, fontSize: 14),
        labelStyle: TextStyle(color: muted, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primary, width: 1.6),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.blue500,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 54),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          textStyle: const TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size(0, 48),
          side: BorderSide(color: border),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
          textStyle: const TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: dark ? AppColors.darkSurface2 : AppColors.navy,
        contentTextStyle: const TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: 13,
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: dark ? AppColors.darkSurface2 : AppColors.blue50,
        side: BorderSide(color: border),
        labelStyle: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 12, color: text),
        shape: const StadiumBorder(),
        surfaceTintColor: Colors.transparent,
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        inactiveTrackColor: border,
        thumbColor: primary,
        overlayColor: primary.withValues(alpha: 0.12),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.white : muted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.blue500 : border,
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: primary),
    );
  }
}

extension GradientDim on Gradient {
  /// Di dark mode gradien kartu diredupkan sedikit (lebih gelap, sedikit
  /// kurang jenuh) supaya nggak menyilaukan dan teks putih tetap terbaca.
  Gradient forMode(bool dark) {
    final g = this;
    if (!dark || g is! LinearGradient) return this;
    Color dim(Color c) {
      final h = HSLColor.fromColor(c);
      return h
          .withLightness((h.lightness * 0.78).clamp(0.0, 1.0))
          .withSaturation((h.saturation * 0.92).clamp(0.0, 1.0))
          .toColor();
    }

    return LinearGradient(
      begin: g.begin,
      end: g.end,
      colors: g.colors.map(dim).toList(),
      stops: g.stops,
    );
  }
}

extension ThemeX on BuildContext {
  ColorScheme get cs => Theme.of(this).colorScheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get muted => isDark ? AppColors.darkMuted : AppColors.lightMuted;
  Color get border => isDark ? AppColors.darkBorder : AppColors.lightBorder;
  Color get surface2 {
    final a = TabAccent.maybeOf(this);
    if (a == null) return isDark ? AppColors.darkSurface2 : AppColors.blue50;
    return isDark
        ? Color.lerp(AppColors.darkSurface2, a, 0.10)!
        : Color.lerp(Colors.white, a, 0.07)!;
  }

  /// Warna aksen tab yang sedang aktif (default: biru beranda).
  Color get accent => TabAccent.maybeOf(this) ?? AppColors.blue500;

  /// Latar lembut berwarna aksen (pengganti blue100).
  Color get accentSoft {
    final a = TabAccent.maybeOf(this);
    if (a == null) return isDark ? AppColors.darkSurface2 : AppColors.blue100;
    return isDark
        ? Color.lerp(AppColors.darkSurface2, a, 0.22)!
        : Color.lerp(Colors.white, a, 0.18)!;
  }

  /// Gradien tombol dengan warna aksen tab.
  Gradient get accentGradient {
    final a = TabAccent.maybeOf(this);
    if (a == null) return AppColors.buttonGradient;
    final h = HSLColor.fromColor(a);
    final light = h.withLightness((h.lightness + 0.07).clamp(0.0, 1.0)).toColor();
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [light, a],
    );
  }
  /// Di dark mode, warna aksen dicerahin dikit biar kebaca di background kalem.
  Color tone(Color c) => isDark ? Color.lerp(c, Colors.white, 0.4)! : c;

  /// Versi warna yang tetap "berwarna" di dark mode (nggak pudar jadi abu).
  static Color _mid(Color c) {
    final h = HSLColor.fromColor(c);
    return h
        .withLightness(0.58)
        .withSaturation(h.saturation < 0.55 ? 0.55 : h.saturation)
        .toColor();
  }

  /// Latar pill/chip: rona warna yang jelas beda dari kartu & latar.
  Color chipBg(Color c) =>
      isDark ? _mid(c).withValues(alpha: 0.20) : c.withValues(alpha: 0.12);

  /// Garis tepi pill/chip (dark saja; terang tanpa garis).
  Color chipBorder(Color c) =>
      isDark ? _mid(c).withValues(alpha: 0.45) : Colors.transparent;

  /// Teks/ikon pill: di gelap dicerahkan tapi warnanya tetap kelihatan.
  Color chipFg(Color c) => isDark ? accentInk(c, true) : c;
  Gradient dim(Gradient g) => g.forMode(isDark);
  Color get textColor => isDark ? AppColors.darkText : AppColors.lightText;
}


/// Membawa warna aksen sebuah tab ke semua widget di dalamnya.
class TabAccent extends InheritedWidget {
  final Color color;
  const TabAccent({super.key, required this.color, required super.child});

  static Color? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TabAccent>()?.color;

  @override
  bool updateShouldNotify(TabAccent old) => old.color != color;
}

/// Warna aksen untuk teks/ikon: digelapkan di mode terang, dicerahkan di gelap.
Color accentInk(Color a, bool dark) {
  final h = HSLColor.fromColor(a);
  final l = dark ? (h.lightness < 0.72 ? 0.72 : h.lightness) : (h.lightness > 0.40 ? 0.40 : h.lightness);
  return h.withLightness(l).toColor();
}

extension AccentTheme on ThemeData {
  /// Salinan tema dengan warna utama diganti aksen tab.
  ThemeData withAccent(Color accent) {
    final dark = brightness == Brightness.dark;
    final ink = accentInk(accent, dark);
    final soft = dark
        ? Color.lerp(AppColors.darkSurface2, accent, 0.22)!
        : Color.lerp(Colors.white, accent, 0.18)!;
    final field = dark
        ? Color.lerp(AppColors.darkSurface2, accent, 0.10)!
        : Color.lerp(Colors.white, accent, 0.07)!;
    final cs = colorScheme.copyWith(
      primary: ink,
      onPrimary: dark ? AppColors.navy : Colors.white,
      primaryContainer: soft,
      secondaryContainer: soft,
      onSecondaryContainer: ink,
      surfaceContainerHigh: field,
      surfaceContainerHighest: soft,
    );
    return copyWith(
      colorScheme: cs,
      inputDecorationTheme: inputDecorationTheme.copyWith(
        fillColor: field,
        focusedBorder: (inputDecorationTheme.focusedBorder as OutlineInputBorder)
            .copyWith(borderSide: BorderSide(color: ink, width: 1.6)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: (filledButtonTheme.style ?? const ButtonStyle())
            .copyWith(backgroundColor: WidgetStatePropertyAll(accent)),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: (outlinedButtonTheme.style ?? const ButtonStyle())
            .copyWith(
              foregroundColor: WidgetStatePropertyAll(ink),
              side: dark
                  ? WidgetStatePropertyAll(
                      BorderSide(color: ink.withValues(alpha: 0.4)),
                    )
                  : null,
            ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: (textButtonTheme.style ?? const ButtonStyle())
            .copyWith(foregroundColor: WidgetStatePropertyAll(ink)),
      ),
    );
  }
}
