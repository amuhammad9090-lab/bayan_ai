import 'package:flutter/material.dart';

import '../../core/icons.dart';
import '../../core/theme.dart';
import 'animations.dart';
import 'core_widgets.dart';

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
