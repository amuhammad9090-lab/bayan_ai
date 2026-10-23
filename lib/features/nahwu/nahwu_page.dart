import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/art.dart';
import '../../core/icons.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../shared/widgets/bound_text.dart';
import '../../shared/widgets/common.dart';
import '../shell/header_actions.dart';
import '../settings/settings_provider.dart';
import 'nahwu_provider.dart';

class NahwuPage extends StatelessWidget {
  const NahwuPage({super.key});

  void _analyze(BuildContext context) {
    final nahwu = context.read<NahwuProvider>();
    FocusScope.of(context).unfocus();
    if (nahwu.input.trim().isEmpty) {
      showSnack(context, 'Teks Arab tidak boleh kosong', error: true);
      return;
    }
    nahwu.analyze();
  }

  Future<void> _paste(BuildContext context) async {
    final nahwu = context.read<NahwuProvider>();
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final t = data?.text?.trim() ?? '';
    if (t.isEmpty) {
      if (context.mounted) showSnack(context, 'Papan klip kosong', error: true);
      return;
    }
    nahwu.setInput(t);
  }

  @override
  Widget build(BuildContext context) {
    final nahwu = context.watch<NahwuProvider>();
    final arabicSize = context.select<SettingsProvider, double>((s) => s.arabicSize);
    final analysis = nahwu.analysis;

    return FeatureScroll(
          actions: const HeaderActions(),
          gradient: AppColors.cardPurple,
          shadow: AppColors.purple,
          asset: Art.homeNahwu,
          fallback: AppIcons.nahwu,
          title: 'Bedah Nahwu',
          subtitle: 'Analisis nahwu kata per kata: jenis kata, kedudukan, dan tandanya.',
          onRefresh: () async {
            if (nahwu.input.trim().isNotEmpty) {
              await nahwu.analyze();
            } else {
              await Future<void>.delayed(const Duration(milliseconds: 700));
            }
          },
      children: [

        // ── Kartu kerja: input + alat bantu + aksi utama ──
        SectionLabel(
          'Kalimat Arab',
          hint: 'Ketik, tempel, atau kirim dari OCR',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MiniIconButton(
                tooltip: 'Tempel',
                icon: AppIcons.paste,
                onTap: () => _paste(context),
              ),
              const SizedBox(width: 6),
              _MiniIconButton(
                tooltip: 'Contoh acak',
                icon: AppIcons.shuffle,
                onTap: nahwu.randomExample,
              ),
            ],
          ),
        ),
        AppCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BoundText(
                source: nahwu,
                read: () => nahwu.input,
                version: () => nahwu.inputVersion,
                onChanged: nahwu.onUserEdit,
                builder: (context, controller) => ArabicField(
                  controller: controller,
                  hint: 'اكتب أو الصق الجملة العربية هنا…',
                  size: arabicSize,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GradientButton(
                      label: nahwu.loading ? 'Menganalisis…' : 'Proses Nahwu',
                      icon: AppIcons.sparkles,
                      loading: nahwu.loading,
                      onPressed: () => _analyze(context),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 54,
                    width: 54,
                    child: OutlinedButton(
                      onPressed: nahwu.clear,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(54, 54),
                      ),
                      child: const Icon(AppIcons.trash, size: 19),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        PageGap.section,

        SectionLabel(
          'Hasil analisis',
          hint: analysis != null && analysis.isStructured ? '${analysis.words.length} kata' : null,
          trailing: (analysis != null && analysis.isStructured)
              ? ActionChipButton(
                  icon: AppIcons.copy,
                  label: 'Salin semua',
                  onTap: () => copyText(context, analysis.toPlainText(), label: 'Hasil nahwu'),
                )
              : null,
        ),
        if (nahwu.loading)
          const SkeletonList(
            count: 4,
            height: 92,
            thinking: ['Memecah kalimat…', 'Menentukan jenis kata…', 'Menyusun analisis…'],
          )
        else if (nahwu.error != null)
          ErrorCard(message: nahwu.error!)
        else if (analysis == null)
          const AppCard(
            shadow: false,
            child: EmptyState(
              icon: AppIcons.nahwu,
              title: 'Bedah nahwu kata per kata',
              subtitle: 'Masukkan kalimat Arab (lebih baik berharakat) lalu tekan Proses Nahwu.',
            ),
          )
        else if (!analysis.isStructured)
          AppCard(child: RichResult(text: analysis.raw, arabicSize: arabicSize))
        else ...[
          if (analysis.jenisKalimat.isNotEmpty) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Pill(
                label: analysis.jenisKalimat,
                color: context.cs.primary,
                icon: AppIcons.sparkles,
              ),
            ),
            const SizedBox(height: 12),
          ],
          for (var i = 0; i < analysis.words.length; i++)
            _WordCard(
              key: ValueKey('${nahwu.runId}-$i'),
              index: i,
              word: analysis.words[i],
              arabicSize: arabicSize,
            ),
          if (analysis.ringkasan.isNotEmpty) ...[
            const SizedBox(height: 4),
            AppCard(
              color: AppColors.purple.withValues(alpha: context.isDark ? 0.2 : 0.12),
              shadow: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(AppIcons.lightbulb, size: 16, color: context.tone(AppColors.purple)),
                      const SizedBox(width: 8),
                      const Text(
                        'Ringkasan struktur',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    analysis.ringkasan,
                    style: const TextStyle(fontSize: 13, height: 1.6),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          const Footnote(
            "Analisis dibuat oleh AI mengikuti kerangka 7 bab (Al-Kalam, Al-I'rab, Al-Af'al, Isim Marfu', "
            "Isim Manshub, Isim Makhfudh, At-Tawabi'). Untuk pengajaran, tetap periksa kembali dengan kitab rujukan.",
          ),
        ],
      ],
    );
  }
}

Color _jenisColor(String jenis) {
  final j = jenis.toLowerCase();
  if (j.contains('fi')) return AppColors.cyan;
  if (j.contains('huruf')) return AppColors.indigo;
  return AppColors.purple; // isim & lainnya
}

Color _babColor(String bab) {
  final b = bab.toLowerCase();
  if (b.contains('marfu')) return AppColors.purple;
  if (b.contains('manshub')) return AppColors.cyan;
  if (b.contains('makhfudh')) return AppColors.indigo;
  if (b.contains('tawabi')) return const Color(0xFF0D9488);
  if (b.contains('af')) return const Color(0xFF7C3AED);
  return AppColors.purple; // Al-Kalam, Al-I'rab
}

class _WordCard extends StatelessWidget {
  final int index;
  final NahwuWord word;
  final double arabicSize;
  const _WordCard({
    super.key,
    required this.index,
    required this.word,
    required this.arabicSize,
  });

  @override
  Widget build(BuildContext context) {
    final base = _jenisColor(word.jenis);
    final color = context.tone(base);
    final delay = (index * 70).clamp(0, 700);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, 16 * (1 - t)), child: child),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: AppCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: context.muted,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (word.jenis.isNotEmpty) Pill(label: word.jenis, color: base),
                        if (word.bab.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Flexible(
                            child: Pill(label: word.bab, color: _babColor(word.bab)),
                          ),
                        ],
                      ],
                    ),
                    if (word.irab.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        word.irab,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    if (word.tanda.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Tanda: ${word.tanda}',
                        style: TextStyle(fontSize: 12, height: 1.5, color: context.tone(base)),
                      ),
                    ],
                    if (word.makna.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        word.makna,
                        style: TextStyle(fontSize: 12.5, height: 1.5, color: context.muted),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 130),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    word.kata,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'ScheherazadeNew',
                      fontSize: arabicSize + 2,
                      height: 1.6,
                      fontWeight: FontWeight.w600,
                      color: color,
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

class _MiniIconButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;
  const _MiniIconButton({required this.tooltip, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.cs.primary;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: c.withValues(alpha: context.isDark ? 0.16 : 0.09),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 17, color: c),
          ),
        ),
      ),
    );
  }
}
