import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/responsive.dart';
import '../../core/storage.dart';
import '../../core/theme.dart';
import '../auth/auth_provider.dart';
import '../auth/login_page.dart';
import '../onboarding/onboarding_page.dart';
import '../shell/shell_page.dart';
import '../splash/splash_page.dart';

/// Urutan layar: Splash -> Onboarding (sekali saja) -> Login -> Aplikasi.
class AppGate extends StatefulWidget {
  const AppGate({super.key});

  @override
  State<AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<AppGate> {
  static const _onboardingKey = 'onboarding_done';
  static const _splashMin = Duration(milliseconds: 2800);

  /// Disimpan di luar state: AppGate ikut dibuat ulang tiap ganti akun
  /// (login/logout/daftar), dan splash cukup tampil sekali per buka aplikasi.
  static bool _splashShown = false;

  late bool _onboarded;
  bool _splashDone = _splashShown;
  Timer? _timer;

  /// App kembali ke depan -> cek lagi apakah akun masih aktif
  /// (mis. dihapus/dinonaktifkan dari Firebase Console).
  late final AppLifecycleListener _life;

  @override
  void initState() {
    super.initState();
    _life = AppLifecycleListener(
      onResume: () => context.read<AuthProvider>().validateSession(sync: false),
    );
    _onboarded = context.read<KeyValueStore>().getBool(_onboardingKey) ?? false;
    if (!_splashDone) {
      _timer = Timer(_splashMin, () {
        _splashShown = true;
        if (mounted) setState(() => _splashDone = true);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _life.dispose();
    super.dispose();
  }

  void _finishOnboarding() {
    context.read<KeyValueStore>().setBool(_onboardingKey, true);
    setState(() => _onboarded = true);
  }

  @override
  Widget build(BuildContext context) {
    final status = context.select<AuthProvider, AuthStatus>((a) => a.status);

    final Widget page;
    if (!_splashDone || status == AuthStatus.loading) {
      page = const SplashPage(key: ValueKey('splash'));
    } else if (!_onboarded) {
      page = OnboardingPage(
        key: const ValueKey('onboarding'),
        onDone: _finishOnboarding,
      );
    } else if (status == AuthStatus.signedIn || status == AuthStatus.guest) {
      page = const ShellPage(key: ValueKey('shell'));
    } else {
      page = const LoginPage(key: ValueKey('login'));
    }

    // Layar lebar: onboarding & login tampil sebagai kartu di tengah,
    // splash & aplikasi tetap penuh.
    final framed = context.isWide &&
        page is! SplashPage &&
        page is! ShellPage;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.97, end: 1).animate(anim),
          child: child,
        ),
      ),
      child: framed ? _WideFrame(key: page.key, child: page) : page,
    );
  }
}

/// Bingkai kartu untuk halaman sempit (onboarding/login) di layar lebar.
class _WideFrame extends StatelessWidget {
  final Widget child;
  const _WideFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.heroGradient),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440, maxHeight: 880),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 40,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
