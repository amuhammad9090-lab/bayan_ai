import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/app_info.dart';
import '../../core/theme.dart';
import '../../shared/widgets/animations.dart';
import '../../shared/widgets/logo_mark.dart';

/// Splash: logo memantul masuk + cincin berputar + huruf Arab melayang.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: Container(
          width: double.infinity,
          decoration: const BoxDecoration(gradient: AppColors.heroGradient),
          child: Stack(
            children: [
              const Positioned.fill(child: FloatingLetters(count: 20)),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _AnimatedLogo(),
                    const SizedBox(height: 26),
                    const Directionality(
                          textDirection: TextDirection.rtl,
                          child: Text(
                            'بَيَان',
                            style: TextStyle(
                              fontFamily: 'ScheherazadeNew',
                              fontSize: 54,
                              height: 1.3,
                              color: Colors.white,
                            ),
                          ),
                        )
                        .animate(delay: 500.ms)
                        .fadeIn(duration: 700.ms)
                        .slideY(begin: 0.3, end: 0, curve: Curves.easeOutCubic)
                        .blurXY(begin: 8, end: 0),
                    const SizedBox(height: 2),
                    const Text(
                          kAppName,
                          style: TextStyle(
                            fontSize: 20,
                            letterSpacing: 4,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        )
                        .animate(delay: 800.ms)
                        .fadeIn(duration: 600.ms)
                        .slideY(begin: 0.4, end: 0, curve: Curves.easeOutCubic)
                        .then(delay: 300.ms)
                        .shimmer(duration: 1400.ms, color: AppColors.blue200),
                    const SizedBox(height: 10),
                    Text(
                      'Asisten belajar Al-Qur\'an & Nahwu',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ).animate(delay: 1100.ms).fadeIn(duration: 600.ms),
                  ],
                ),
              ),
              const Positioned(
                left: 0,
                right: 0,
                bottom: 56,
                child: Center(child: BouncingDots()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedLogo extends StatelessWidget {
  const _AnimatedLogo();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 132,
      height: 132,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Cahaya berdenyut di belakang logo.
          Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.28),
                      Colors.white.withValues(alpha: 0),
                    ],
                  ),
                ),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(
                begin: 0.85,
                end: 1.25,
                duration: 1400.ms,
                curve: Curves.easeInOut,
              ),
          // Cincin yang berputar.
          const SizedBox(
                width: 128,
                height: 128,
                child: CustomPaint(painter: _RingPainter()),
              )
              .animate(onPlay: (c) => c.repeat())
              .rotate(
                begin: 0,
                end: 1,
                duration: 1800.ms,
                curve: Curves.linear,
              ),
          // Logo muncul memantul.
          const LogoMark(size: 84)
              .animate()
              .fadeIn(duration: 350.ms)
              .scaleXY(
                begin: 0.3,
                end: 1,
                duration: 1100.ms,
                curve: Curves.elasticOut,
              ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: [
          Colors.white.withValues(alpha: 0),
          Colors.white.withValues(alpha: 0.95),
        ],
      ).createShader(rect);
    canvas.drawArc(rect.deflate(2), 0, 2 * math.pi * 0.75, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
