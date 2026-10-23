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
              // Tanpa bayangan (mis. kartu di dalam sheet) -> pakai garis tipis, di mode terang juga.
              border: (w.gradient == null && (context.isDark || (!w.shadow && w.color == null)))
                  ? Border.all(color: context.border)
                  : null,
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
