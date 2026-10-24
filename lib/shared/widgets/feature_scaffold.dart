import 'package:flutter/cupertino.dart' show CupertinoSliverRefreshControl, RefreshIndicatorMode;
import 'package:flutter/material.dart';

import '../../core/art.dart';
import '../../core/theme.dart';

/// Halaman tab dengan header yang ikut bereaksi saat di-scroll:
/// banner besar (judul, deskripsi, ilustrasi) mengecil jadi app bar ramping
/// yang tetap menempel di atas, dengan ilustrasi memudar + parallax.
class FeatureScroll extends StatelessWidget {
  final Gradient gradient;
  final Color shadow;
  final String asset;
  final IconData fallback;
  final String title;
  final String subtitle;
  final Widget? actions;
  final Future<void> Function()? onRefresh;
  final List<Widget> children;
  const FeatureScroll({
    super.key,
    required this.gradient,
    required this.shadow,
    required this.asset,
    required this.fallback,
    required this.title,
    required this.subtitle,
    required this.children,
    this.actions,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return TabAccent(
      color: shadow,
      child: Theme(
      data: Theme.of(context).withAccent(shadow),
      child: Stack(
      fit: StackFit.expand,
      children: [
      // Gelap: satu cahaya lembut warna tab (lebih tipis dari Beranda).
      if (context.isDark)
        Positioned.fill(
          child: AmbientGlow(
            spots: [
              (const Alignment(-1.1, -0.2), shadow, 0.10, 0.95),
              (const Alignment(1.1, 1.0), shadow, 0.06, 0.85),
            ],
          ),
        ),
      CustomScrollView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        if (onRefresh != null) AppRefreshControl(onRefresh: onRefresh!),
        SliverPersistentHeader(
          pinned: true,
          delegate: _FeatureHeaderDelegate(
            gradient: gradient.forMode(context.isDark),
            shadow: shadow,
            dark: context.isDark,
            asset: asset,
            fallback: fallback,
            title: title,
            subtitle: subtitle,
            actions: actions,
            top: top,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
          sliver: SliverList(delegate: SliverChildListDelegate(children)),
        ),
      ],
    ),
      ],
    ),
    ),
    );
  }
}

/// Cahaya lembut di latar (dark mode) supaya halaman nggak flat.
/// Tiap titik: (posisi, warna, kekuatan alpha, radius).
class AmbientGlow extends StatelessWidget {
  final List<(Alignment, Color, double, double)> spots;
  const AmbientGlow({super.key, required this.spots});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          for (final (at, c, a, r) in spots)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: at,
                    radius: r,
                    colors: [c.withValues(alpha: a), c.withValues(alpha: 0)],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FeatureHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Gradient gradient;
  final Color shadow;
  final bool dark;
  final String asset;
  final IconData fallback;
  final String title;
  final String subtitle;
  final Widget? actions;
  final double top;
  _FeatureHeaderDelegate({
    required this.gradient,
    required this.shadow,
    required this.dark,
    required this.asset,
    required this.fallback,
    required this.title,
    required this.subtitle,
    required this.actions,
    required this.top,
  });

  static const _expanded = 156.0;
  static const _collapsed = 58.0;

  @override
  double get maxExtent => top + _expanded;
  @override
  double get minExtent => top + _collapsed;

  @override
  bool shouldRebuild(covariant _FeatureHeaderDelegate old) =>
      old.gradient != gradient ||
      old.title != title ||
      old.subtitle != subtitle ||
      old.asset != asset ||
      old.dark != dark ||
      old.top != top;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final range = maxExtent - minExtent;
    final t = (shrinkOffset / range).clamp(0.0, 1.0);
    final width = MediaQuery.of(context).size.width;
    const artH = _expanded - 34.0;

    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30 - 8 * t)),
        boxShadow: dark
            ? null
            : [
                BoxShadow(
                  color: shadow.withValues(alpha: 0.18 + 0.12 * t),
                  blurRadius: 16 + 6 * t,
                  offset: const Offset(0, 7),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30 - 8 * t)),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // Ilustrasi: memudar, mengecil, dan sedikit naik (parallax).
            Positioned(
              right: 10 - 30 * t,
              top: top + 30 - 26 * t,
              width: width * 0.42,
              height: artH,
              child: Opacity(
                opacity: (1 - t * 1.6).clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: 1 - 0.35 * t,
                  alignment: Alignment.topRight,
                  child: ArtImage(asset: asset, fallbackIcon: fallback, fallbackSize: 52),
                ),
              ),
            ),
            // Judul: mengecil dan naik ke posisi app bar.
            Positioned(
              left: 20,
              right: 130,
              top: top + 42 - 24 * t,
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22 - 5 * t,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            // Deskripsi: hilang lebih dulu.
            Positioned(
              left: 20,
              right: width * 0.42 + 4,
              top: top + 72 - 12 * t,
              child: Opacity(
                opacity: (1 - t * 2.2).clamp(0.0, 1.0),
                child: Text(
                  subtitle,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ),
            ),
            if (actions != null)
              Positioned(
                right: 12,
                top: top + 14,
                child: actions!,
              ),
          ],
        ),
      ),
    );
  }
}


// ───────────────────────── Tarik untuk refresh ─────────────────────────

/// Sliver tarik-ke-bawah dengan indikator animasi: logo "ب" berputar
/// mengikuti tarikan, lalu berputar terus + cincin loading saat refresh.
class AppRefreshControl extends StatelessWidget {
  final Future<void> Function() onRefresh;
  const AppRefreshControl({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return CupertinoSliverRefreshControl(
      refreshTriggerPullDistance: 96,
      refreshIndicatorExtent: 70,
      onRefresh: onRefresh,
      builder: (context, mode, pulled, trigger, extent) =>
          _PullSpinner(mode: mode, pulled: pulled, trigger: trigger),
    );
  }
}

class _PullSpinner extends StatefulWidget {
  final RefreshIndicatorMode mode;
  final double pulled;
  final double trigger;
  const _PullSpinner({required this.mode, required this.pulled, required this.trigger});

  @override
  State<_PullSpinner> createState() => _PullSpinnerState();
}

class _PullSpinnerState extends State<_PullSpinner> with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void didUpdateWidget(covariant _PullSpinner old) {
    super.didUpdateWidget(old);
    if (widget.mode == RefreshIndicatorMode.refresh) {
      if (!_spin.isAnimating) _spin.repeat();
    } else if (_spin.isAnimating) {
      _spin.stop();
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = (widget.pulled / widget.trigger).clamp(0.0, 1.0);
    final refreshing = widget.mode == RefreshIndicatorMode.refresh;
    final armed = widget.mode == RefreshIndicatorMode.armed;
    final scale = 0.55 + 0.45 * Curves.easeOutBack.transform(p);

    return Align(
      alignment: const Alignment(0, 0.35),
      child: Opacity(
        opacity: p.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: armed || refreshing ? 1.0 : scale,
          child: SizedBox(
            width: 46,
            height: 46,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 46,
                  height: 46,
                  child: CircularProgressIndicator(
                    value: refreshing ? null : p * 0.92,
                    strokeWidth: 3,
                    strokeCap: StrokeCap.round,
                    color: context.accent,
                    backgroundColor: context.accent.withValues(alpha: 0.15),
                  ),
                ),
                AnimatedBuilder(
                  animation: _spin,
                  builder: (context, child) => Transform.rotate(
                    angle: refreshing ? _spin.value * 6.2832 : p * 6.2832,
                    child: child,
                  ),
                  child: Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: context.accentGradient,
                      boxShadow: [
                        BoxShadow(
                          color: context.accent.withValues(alpha: armed || refreshing ? 0.5 : 0.25),
                          blurRadius: armed || refreshing ? 14 : 8,
                        ),
                      ],
                    ),
                    child: const Text(
                      'ب',
                      style: TextStyle(
                        fontFamily: 'ScheherazadeNew',
                        fontSize: 20,
                        height: 1.5,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
