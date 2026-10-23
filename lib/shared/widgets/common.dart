import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/icons.dart';
import '../../core/theme.dart';

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

class AppCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(20);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: (shadow && !context.isDark)
            ? [
                BoxShadow(
                  color: AppColors.blue700.withValues(alpha: 0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Material(
        color: gradient == null ? (color ?? context.cs.surface) : Colors.transparent,
        borderRadius: radius,
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: radius,
            border: gradient == null ? Border.all(color: context.border) : null,
          ),
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: Padding(padding: padding, child: child),
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
        color: background ?? (context.isDark ? AppColors.darkSurface2 : AppColors.blue100),
        borderRadius: BorderRadius.circular(size * 0.34),
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
    final radius = BorderRadius.circular(16);
    return Opacity(
      opacity: onPressed == null && !loading ? 0.5 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: AppColors.blue600.withValues(alpha: 0.28),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: radius,
          child: Ink(
            decoration: BoxDecoration(gradient: AppColors.buttonGradient, borderRadius: radius),
            child: InkWell(
              borderRadius: radius,
              onTap: enabled ? onPressed : null,
              child: SizedBox(
                height: 52,
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
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
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
    final c = danger ? AppColors.danger : context.cs.primary;
    return Opacity(
      opacity: onTap == null ? 0.45 : 1,
      child: Material(
        color: c.withValues(alpha: context.isDark ? 0.16 : 0.09),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
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
  const SkeletonList({super.key, this.count = 3, this.height = 96});

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
    final a = context.isDark ? AppColors.darkSurface : AppColors.blue50;
    final b = context.isDark ? AppColors.darkSurface2 : AppColors.blue100;
    return AnimatedBuilder(
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
          fontFamily: 'Poppins',
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
