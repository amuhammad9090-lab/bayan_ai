import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/icons.dart';
import '../../core/theme.dart';

/// Potongan 0..1 dari timeline [t]: mulai di [start], panjang [length].
double segment(double t, double start, double length) =>
    ((t - start) / length).clamp(0.0, 1.0).toDouble();

/// Ngulang animasi terus-menerus; builder dapat nilai t (0..1).
class LoopBuilder extends StatefulWidget {
  final Duration duration;
  final bool reverse;
  final Widget Function(BuildContext context, double t) builder;

  const LoopBuilder({
    super.key,
    required this.duration,
    required this.builder,
    this.reverse = false,
  });

  @override
  State<LoopBuilder> createState() => _LoopBuilderState();
}

class _LoopBuilderState extends State<LoopBuilder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..repeat(reverse: widget.reverse);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (context, _) => widget.builder(context, _c.value),
  );
}

/// Huruf-huruf Arab yang melayang pelan di latar (splash, login).
class FloatingLetters extends StatefulWidget {
  final Color color;
  final int count;
  const FloatingLetters({
    super.key,
    this.color = Colors.white,
    this.count = 16,
  });

  @override
  State<FloatingLetters> createState() => _FloatingLettersState();
}

class _Glyph {
  final String char;
  final double x, y, size, phase;
  const _Glyph(this.char, this.x, this.y, this.size, this.phase);
}

class _FloatingLettersState extends State<FloatingLetters>
    with SingleTickerProviderStateMixin {
  static const _chars = [
    'ب',
    'ي',
    'ا',
    'ن',
    'ق',
    'ر',
    'ع',
    'ل',
    'م',
    'ك',
    'ح',
    'د',
    'ف',
    'س',
    'ت',
    'و',
  ];

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  )..repeat();

  late final List<_Glyph> _items = () {
    final r = math.Random(11);
    return List.generate(
      widget.count,
      (i) => _Glyph(
        _chars[i % _chars.length],
        r.nextDouble(),
        r.nextDouble(),
        26 + r.nextDouble() * 42,
        r.nextDouble(),
      ),
    );
  }();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const twoPi = 2 * math.pi;
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, box) => AnimatedBuilder(
          animation: _c,
          builder: (context, _) => Stack(
            children: [
              for (final g in _items)
                Positioned(
                  left:
                      g.x * box.maxWidth +
                      math.cos((_c.value + g.phase) * twoPi) * 12,
                  top:
                      g.y * box.maxHeight +
                      math.sin((_c.value + g.phase) * twoPi) * 20,
                  child: Opacity(
                    opacity:
                        0.05 +
                        0.08 *
                            (0.5 +
                                0.5 *
                                    math.sin((_c.value * 2 + g.phase) * twoPi)),
                    child: Text(
                      g.char,
                      style: TextStyle(
                        fontFamily: 'ScheherazadeNew',
                        fontSize: g.size,
                        color: widget.color,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tiga titik yang loncat bergantian.
class BouncingDots extends StatelessWidget {
  final Color color;
  final double size;
  const BouncingDots({super.key, this.color = Colors.white, this.size = 7});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: size * 0.4),
            child:
                Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    )
                    .animate(
                      delay: (i * 160).ms,
                      onPlay: (c) => c.repeat(reverse: true),
                    )
                    .moveY(
                      begin: 0,
                      end: -size,
                      duration: 420.ms,
                      curve: Curves.easeInOut,
                    )
                    .fade(begin: 0.4, end: 1, duration: 420.ms),
          ),
      ],
    );
  }
}

/// Banner "AI lagi mikir" dengan pesan yang gonta-ganti.
class AiThinking extends StatefulWidget {
  final List<String> messages;
  const AiThinking({super.key, required this.messages});

  @override
  State<AiThinking> createState() => _AiThinkingState();
}

class _AiThinkingState extends State<AiThinking> {
  int _i = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 2400), (_) {
      if (mounted) setState(() => _i = (_i + 1) % widget.messages.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.surface2,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(AppIcons.sparkles, size: 18, color: context.cs.primary)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(
                begin: 0.8,
                end: 1.2,
                duration: 700.ms,
                curve: Curves.easeInOut,
              )
              .rotate(begin: -0.05, end: 0.05, duration: 700.ms),
          const SizedBox(width: 10),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.4),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              ),
              layoutBuilder: (current, previous) => Stack(
                alignment: Alignment.centerLeft,
                children: [...previous, if (current != null) current],
              ),
              child: Text(
                widget.messages[_i],
                key: ValueKey(_i),
                style: TextStyle(fontSize: 13, color: context.muted),
              ),
            ),
          ),
          BouncingDots(color: context.cs.primary, size: 5),
        ],
      ),
    );
  }
}

/// Empat sudut bingkai pemindai.
class ScanCorners extends StatelessWidget {
  final Color color;
  final double margin;
  const ScanCorners({super.key, this.color = Colors.white, this.margin = 14});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _CornerPainter(color, margin), size: Size.infinite);
}

class _CornerPainter extends CustomPainter {
  final Color color;
  final double margin;
  const _CornerPainter(this.color, this.margin);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    const l = 22.0;
    final r = Rect.fromLTWH(
      margin,
      margin,
      size.width - 2 * margin,
      size.height - 2 * margin,
    );
    final path = Path()
      ..moveTo(r.left, r.top + l)
      ..lineTo(r.left, r.top)
      ..lineTo(r.left + l, r.top)
      ..moveTo(r.right - l, r.top)
      ..lineTo(r.right, r.top)
      ..lineTo(r.right, r.top + l)
      ..moveTo(r.right, r.bottom - l)
      ..lineTo(r.right, r.bottom)
      ..lineTo(r.right - l, r.bottom)
      ..moveTo(r.left + l, r.bottom)
      ..lineTo(r.left, r.bottom)
      ..lineTo(r.left, r.bottom - l);
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant _CornerPainter old) =>
      old.color != color || old.margin != margin;
}

/// Efek pemindai (garis cahaya naik-turun) di atas gambar saat OCR jalan.
class ScanOverlay extends StatelessWidget {
  const ScanOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LoopBuilder(
        duration: const Duration(milliseconds: 1800),
        reverse: true,
        builder: (context, t0) {
          final t = Curves.easeInOut.transform(t0);
          return LayoutBuilder(
            builder: (context, box) {
              final y = t * (box.maxHeight - 3);
              return Stack(
                children: [
                  Positioned.fill(
                    child: ColoredBox(
                      color: Colors.black.withValues(alpha: 0.28),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: y - 64,
                    height: 64,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.blue400.withValues(alpha: 0),
                            AppColors.blue400.withValues(alpha: 0.4),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: y,
                    height: 3,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.blue300,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.blue400.withValues(alpha: 0.9),
                            blurRadius: 14,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Positioned.fill(child: ScanCorners()),
                  Positioned(
                    bottom: 14,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            BouncingDots(size: 5),
                            SizedBox(width: 8),
                            Text(
                              'Membaca tulisan Arab…',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

/// Isi tab "masuk" pelan (fade + naik) tiap kali tab-nya jadi aktif.
/// Dipakai di dalam IndexedStack supaya state tiap tab tetap awet.
class TabEntrance extends StatefulWidget {
  final bool active;
  final Widget child;
  const TabEntrance({super.key, required this.active, required this.child});

  @override
  State<TabEntrance> createState() => _TabEntranceState();
}

class _TabEntranceState extends State<TabEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
    value: 1,
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _c,
    curve: Curves.easeOutCubic,
  );

  @override
  void didUpdateWidget(covariant TabEntrance old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curve,
      child: AnimatedBuilder(
        animation: _curve,
        child: widget.child,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, 16 * (1 - _curve.value)),
          child: child,
        ),
      ),
    );
  }
}
