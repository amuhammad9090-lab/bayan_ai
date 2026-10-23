import 'package:flutter/material.dart';

import '../../core/icons.dart';
import '../../core/theme.dart';
import 'core_widgets.dart';
import 'state_widgets.dart';

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
