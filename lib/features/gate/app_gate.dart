import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/storage.dart';
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

  late bool _onboarded;
  bool _splashDone = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _onboarded = context.read<KeyValueStore>().getBool(_onboardingKey) ?? false;
    _timer = Timer(_splashMin, () {
      if (mounted) setState(() => _splashDone = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
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
      child: page,
    );
  }
}
