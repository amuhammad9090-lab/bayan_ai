import 'package:flutter/material.dart';

import '../../core/art.dart';
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
    final fg = context.chipFg(color);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: context.chipBg(color),
        borderRadius: BorderRadius.circular(20),
        border: context.isDark ? Border.all(color: context.chipBorder(color)) : null,
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

/// Ilustrasi karakter yang mengambang pelan (naik-turun + miring tipis),
/// dengan bayangan di bawahnya yang ikut membesar-mengecil.
class StateArt extends StatelessWidget {
  final String asset;
  final IconData fallback;
  final double size;
  const StateArt({
    super.key,
    required this.asset,
    this.fallback = AppIcons.sparkles,
    this.size = 140,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size + 8,
      child: LoopBuilder(
        duration: const Duration(milliseconds: 2600),
        reverse: true,
        builder: (context, t) {
          final e = Curves.easeInOut.transform(t);
          return Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Positioned(
                bottom: 0,
                child: Container(
                  width: size * (0.46 - 0.08 * e),
                  height: 7,
                  decoration: BoxDecoration(
                    color: context.accent.withValues(alpha: 0.16 - 0.06 * e),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                child: Transform.translate(
                  offset: Offset(0, 8 - 14 * e),
                  child: Transform.rotate(
                    angle: (e - 0.5) * 0.035,
                    child: SizedBox(
                      width: size,
                      height: size,
                      child: ArtImage(asset: asset, fallbackIcon: fallback, fallbackColor: context.accent, fallbackSize: 48),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  /// Kalau diisi, ilustrasi karakter dipakai menggantikan ikon bulat.
  final String? art;
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.art,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (art != null)
            StateArt(asset: art!, fallback: icon)
          else
            IconChip(icon: icon, size: 56),
          SizedBox(height: art != null ? 6 : 14),
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
    final base = danger ? AppColors.danger : context.cs.primary;
    final c = context.chipFg(base);
    return Opacity(
      opacity: onTap == null ? 0.45 : 1,
      child: Material(
        color: context.isDark ? context.chipBg(base) : base.withValues(alpha: 0.09),
        shape: StadiumBorder(side: BorderSide(color: context.chipBorder(base))),
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

/// Tampilan "AI sedang berpikir": ilustrasi + pesan bergantian tanpa kotak.
class ThinkingView extends StatelessWidget {
  final List<String> messages;
  const ThinkingView({super.key, required this.messages});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          const StateArt(asset: Art.stateThink, size: 180),
          const SizedBox(height: 12),
          AiThinking(messages: messages),
        ],
      ),
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
