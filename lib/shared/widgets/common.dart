import 'package:flutter/cupertino.dart' show CupertinoSliverRefreshControl, RefreshIndicatorMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/art.dart';
import '../../core/icons.dart';
import '../../core/theme.dart';
import 'animations.dart';

// ───────────────────────── Helpers ─────────────────────────

void showSnack(BuildContext context, String msg, {bool error = false}) {
  final m = ScaffoldMessenger.of(context);
  m.hideCurrentSnackBar();
  m.showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(
            error ? AppIcons.warning : AppIcons.success,
            size: 18,
            color: error ? const Color(0xFFFF8A8E) : AppColors.blue300,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(msg)),
        ],
      ),
    ),
  );
}

Future<void> copyText(BuildContext context, String text, {String label = 'Teks'}) async {
  if (text.trim().isEmpty) {
    showSnack(context, 'Belum ada teks untuk disalin', error: true);
    return;
  }
  await Clipboard.setData(ClipboardData(text: text));
  if (context.mounted) showSnack(context, '$label disalin ke clipboard');
}

String timeAgo(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'baru saja';
  if (d.inMinutes < 60) return '${d.inMinutes} menit lalu';
  if (d.inHours < 24) return '${d.inHours} jam lalu';
  if (d.inDays < 7) return '${d.inDays} hari lalu';
  return '${t.day}/${t.month}/${t.year}';
}

bool isMostlyArabic(String s) {
  final letters = s.runes.where((r) => !(r == 32 || (r >= 48 && r <= 57))).toList();
  if (letters.isEmpty) return false;
  final arabic = letters.where((r) => r >= 0x0600 && r <= 0x06FF).length;
  return arabic / letters.length > 0.5;
}

/// Bottom sheet dengan handle, judul, dan konten scrollable.
Future<T?> showAppSheet<T>(
  BuildContext context, {
  required String title,
  IconData? icon,
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => SheetFrame(title: title, icon: icon, child: builder(ctx)),
  );
}

class SheetFrame extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Widget child;
  const SheetFrame({super.key, required this.title, this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: context.border,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
            child: Row(
              children: [
                if (icon != null) ...[
                  IconChip(icon: icon!, size: 38),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(AppIcons.close, size: 20),
                  color: context.muted,
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Building blocks ─────────────────────────

class AppCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Gradient? gradient;
  final Color? color;
  final VoidCallback? onTap;
  final bool shadow;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.gradient,
    this.color,
    this.onTap,
    this.shadow = true,
  });

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final radius = BorderRadius.circular(24);
    // Kartu yang bisa diketuk "menekan" sedikit saat disentuh.
    return AnimatedScale(
      scale: _pressed ? 0.975 : 1,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOut,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: (w.shadow && !context.isDark)
              ? [
                  BoxShadow(
                    color: context.accent.withValues(alpha: 0.10),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: w.gradient == null ? (w.color ?? context.cs.surface) : Colors.transparent,
          borderRadius: radius,
          child: Ink(
            decoration: BoxDecoration(
              gradient: w.gradient?.forMode(context.isDark),
              borderRadius: radius,
              border: (w.gradient == null && context.isDark) ? Border.all(color: context.border) : null,
            ),
            child: InkWell(
              borderRadius: radius,
              onTap: w.onTap,
              onHighlightChanged:
                  w.onTap == null ? null : (v) => setState(() => _pressed = v),
              child: Padding(padding: w.padding, child: w.child),
            ),
          ),
        ),
      ),
    );
  }
}

class IconChip extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color? color;
  final Color? background;
  const IconChip({
    super.key,
    required this.icon,
    this.size = 44,
    this.color,
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background ?? context.accentSoft,
        borderRadius: BorderRadius.circular(size * 0.5),
      ),
      child: Icon(icon, size: size * 0.5, color: color ?? context.cs.primary),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  const SectionHeader({super.key, required this.title, this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                if (subtitle != null)
                  Text(subtitle!, style: TextStyle(fontSize: 12, color: context.muted)),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class GradientButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool loading;
  const GradientButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final radius = BorderRadius.circular(28);
    return Opacity(
      opacity: onPressed == null && !loading ? 0.5 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: context.accent.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: radius,
          child: Ink(
            decoration: BoxDecoration(gradient: context.accentGradient, borderRadius: radius),
            child: InkWell(
              borderRadius: radius,
              onTap: enabled ? onPressed : null,
              child: SizedBox(
                height: 54,
                child: Center(
                  child: loading
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon, size: 19, color: Colors.white),
                            const SizedBox(width: 10),
                            Text(
                              label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class Pill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  const Pill({super.key, required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    final fg = context.tone(color);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: context.isDark ? 0.22 : 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconChip(icon: icon, size: 56),
          const SizedBox(height: 14),
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: context.muted, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class ErrorCard extends StatelessWidget {
  final String message;
  const ErrorCard({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: context.isDark ? 0.16 : 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(AppIcons.warning, size: 18, color: AppColors.danger),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: const TextStyle(fontSize: 13, height: 1.45)),
          ),
        ],
      ),
    );
  }
}

class NoticeCard extends StatelessWidget {
  final IconData icon;
  final String message;
  const NoticeCard({super.key, required this.message, this.icon = AppIcons.lightbulb});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.surface2,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: context.cs.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 12.5, height: 1.5, color: context.muted),
            ),
          ),
        ],
      ),
    );
  }
}

/// Aksi kecil berbentuk chip (ikon + label).
class ActionChipButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool danger;
  const ActionChipButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = danger ? context.tone(AppColors.danger) : context.cs.primary;
    return Opacity(
      opacity: onTap == null ? 0.45 : 1,
      child: Material(
        color: c.withValues(alpha: context.isDark ? 0.16 : 0.09),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 15, color: c),
                const SizedBox(width: 7),
                Text(
                  label,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Skeleton loading ─────────────────────────

class SkeletonList extends StatefulWidget {
  final int count;
  final double height;

  /// Pesan bergantian "AI lagi mikir" di atas skeleton (opsional).
  final List<String>? thinking;
  const SkeletonList({super.key, this.count = 3, this.height = 96, this.thinking});

  @override
  State<SkeletonList> createState() => _SkeletonListState();
}

class _SkeletonListState extends State<SkeletonList> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = context.isDark ? AppColors.darkSurface : context.surface2;
    final b = context.accentSoft;
    final thinking = widget.thinking;
    return Column(
      children: [
        if (thinking != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AiThinking(messages: thinking),
          ),
        AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final color = Color.lerp(a, b, _c.value)!;
            return Column(
              children: List.generate(
                widget.count,
                (i) => Container(
                  height: widget.height,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

// ───────────────────────── Arabic ─────────────────────────

class ArabicText extends StatelessWidget {
  final String text;
  final double size;
  final String font;
  final double height;
  final bool selectable;
  final TextAlign align;
  final FontWeight? weight;

  const ArabicText(
    this.text, {
    super.key,
    required this.size,
    this.font = 'LPMQ',
    this.height = 1.9,
    this.selectable = true,
    this.align = TextAlign.right,
    this.weight,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontFamily: font,
      fontSize: size,
      height: height,
      fontWeight: weight,
      color: context.textColor,
    );
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SizedBox(
        width: double.infinity,
        child: selectable
            ? SelectableText(text, textAlign: align, style: style)
            : Text(text, textAlign: align, style: style),
      ),
    );
  }
}

/// Kolom input teks Arab (RTL, bisa diedit).
class ArabicField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final double size;
  final String font;
  final int minLines;
  final int maxLines;
  const ArabicField({
    super.key,
    required this.controller,
    required this.hint,
    required this.size,
    this.font = 'ScheherazadeNew',
    this.minLines = 3,
    this.maxLines = 8,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.right,
      keyboardType: TextInputType.multiline,
      style: TextStyle(fontFamily: font, fontSize: size, height: 1.9),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: 13,
          color: context.muted,
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }
}

/// Render teks bebas (fallback kalau JSON gagal): baris Arab -> RTL, **bold** didukung.
class RichResult extends StatelessWidget {
  final String text;
  final double arabicSize;
  const RichResult({super.key, required this.text, required this.arabicSize});

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n');
    final children = <Widget>[];
    for (final raw in lines) {
      var line = raw.trim();
      if (line.isEmpty) {
        children.add(const SizedBox(height: 8));
        continue;
      }
      line = line.replaceFirst(RegExp(r'^#{1,6}\s*'), '');
      line = line.replaceFirst(RegExp(r'^[-*]\s+'), '• ');
      if (isMostlyArabic(line)) {
        children.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: ArabicText(line.replaceAll('**', ''), size: arabicSize),
        ));
      } else {
        children.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: SelectableText.rich(
            TextSpan(children: _boldSpans(line)),
            style: TextStyle(fontSize: 13.5, height: 1.6, color: context.textColor),
          ),
        ));
      }
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }

  List<InlineSpan> _boldSpans(String line) {
    final spans = <InlineSpan>[];
    var last = 0;
    for (final m in RegExp(r'\*\*(.+?)\*\*').allMatches(line)) {
      if (m.start > last) spans.add(TextSpan(text: line.substring(last, m.start)));
      spans.add(TextSpan(
        text: m.group(1),
        style: const TextStyle(fontWeight: FontWeight.w600),
      ));
      last = m.end;
    }
    if (last < line.length) spans.add(TextSpan(text: line.substring(last)));
    return spans;
  }
}


/// Header berwarna di atas halaman fitur (OCR/Qur'an/Nahwu), selaras dengan
/// kartu fitur di Beranda: gradien, sudut besar, ilustrasi di kanan.
class FeatureHeader extends StatelessWidget {
  final Gradient gradient;
  final Color shadow;
  final String asset;
  final IconData fallback;
  final String title;
  final String subtitle;
  final Widget? actions;
  const FeatureHeader({
    super.key,
    required this.gradient,
    required this.shadow,
    required this.asset,
    required this.fallback,
    required this.title,
    required this.subtitle,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(28));
    return Container(
      height: 146,
      decoration: BoxDecoration(
        gradient: gradient.forMode(context.isDark),
        borderRadius: radius,
        boxShadow: context.isDark
            ? null
            : [
                BoxShadow(
                  color: shadow.withValues(alpha: 0.26),
                  blurRadius: 20,
                  offset: const Offset(0, 9),
                ),
              ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 10, 14),
      child: Stack(
        children: [
          Row(
        children: [
          Expanded(
            flex: 5,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 4,
            child: Padding(
              padding: EdgeInsets.only(top: actions == null ? 0 : 26),
              child: ArtImage(asset: asset, fallbackIcon: fallback, fallbackSize: 52),
            ),
          ),
        ],
      ),
          if (actions != null)
            Positioned(top: -4, right: 0, child: actions!),
        ],
      ),
    );
  }
}

// ───────────────────────── Kerangka halaman tab ─────────────────────────
// Semua tab (OCR, Qur'an, Nahwu, Setelan) dibangun dari potongan yang sama:
// banner -> kartu kerja (input + aksi utama) -> hasil -> catatan kecil.

/// Padding & jarak standar halaman tab.
class PageGap {
  PageGap._();
  static const padding = EdgeInsets.fromLTRB(16, 14, 16, 28);
  static const section = SizedBox(height: 20);
  static const inner = SizedBox(height: 12);
}

/// Label kecil di atas satu kelompok (pengganti judul besar yang berserakan).
class SectionLabel extends StatelessWidget {
  final String text;
  final String? hint;
  final Widget? trailing;
  const SectionLabel(this.text, {super.key, this.hint, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                text: text,
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                children: [
                  if (hint != null)
                    TextSpan(
                      text: '  $hint',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: context.muted,
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Satu kartu berisi beberapa baris/bagian, dipisah garis tipis.
class GroupCard extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry padding;
  const GroupCard({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.symmetric(horizontal: 14),
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const Divider(height: 1),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

/// Catatan kaki yang tenang (pengganti kartu peringatan besar).
class Footnote extends StatelessWidget {
  final String text;
  final IconData icon;
  const Footnote(this.text, {super.key, this.icon = AppIcons.info});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 14, color: context.muted),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 11.5, height: 1.55, color: context.muted),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tombol sekunder rata lebar di dalam kartu kerja (Kamera / Galeri, dll).
class TonalButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  /// true = versi solid (aksi utama), ukuran & huruf tetap sama dengan versi tonal.
  final bool filled;
  const TonalButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = filled ? Colors.white : context.cs.primary;
    return Opacity(
      opacity: onTap == null ? 0.45 : 1,
      child: Material(
        color: filled
            ? context.accent
            : c.withValues(alpha: context.isDark ? 0.16 : 0.09),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: SizedBox(
            height: 44,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 17, color: c),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
      child: CustomScrollView(
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
    final artH = _expanded - 34.0;

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
