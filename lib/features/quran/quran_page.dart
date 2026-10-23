import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/handoff.dart';
import '../../core/icons.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../shared/widgets/bound_text.dart';
import '../../shared/widgets/common.dart';
import '../settings/settings_provider.dart';
import 'quran_provider.dart';

class QuranPage extends StatelessWidget {
  const QuranPage({super.key});

  void _search(BuildContext context) {
    final quran = context.read<QuranProvider>();
    FocusScope.of(context).unfocus();
    if (quran.query.trim().isEmpty) {
      showSnack(context, 'Tulis kata kunci atau topik dulu', error: true);
      return;
    }
    quran.search();
  }

  @override
  Widget build(BuildContext context) {
    final quran = context.watch<QuranProvider>();
    final arabicSize = context.select<SettingsProvider, double>((s) => s.arabicSize);
    final result = quran.result;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        BoundText(
          source: quran,
          read: () => quran.query,
          version: () => quran.queryVersion,
          onChanged: quran.onUserEdit,
          builder: (context, controller) => TextField(
            controller: controller,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _search(context),
            decoration: InputDecoration(
              hintText: 'Topik, kata kunci, atau nama surah…',
              prefixIcon: const Icon(AppIcons.search, size: 20),
              suffixIcon: quran.query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(AppIcons.close, size: 18),
                      onPressed: quran.clear,
                    ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: QuranProvider.suggestions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final s = QuranProvider.suggestions[i];
              return ActionChip(
                label: Text(s, style: const TextStyle(fontSize: 12)),
                onPressed: () {
                  quran.setQuery(s);
                  _search(context);
                },
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        GradientButton(
          label: quran.loading ? 'Mencari…' : 'Cari dengan AI',
          icon: AppIcons.sparkles,
          loading: quran.loading,
          onPressed: () => _search(context),
        ),
        const SizedBox(height: 22),

        if (quran.loading)
          const SkeletonList(
            count: 3,
            height: 140,
            thinking: ['Mencari ayat yang relevan…', 'Membuka rujukan tafsir…', 'Menyusun ringkasan…'],
          )
        else if (quran.error != null)
          ErrorCard(message: quran.error!)
        else if (result == null)
          const AppCard(
            shadow: false,
            child: EmptyState(
              icon: AppIcons.bookMarked,
              title: 'Cari ayat & tafsir',
              subtitle: 'Tulis topik seperti "ayat tentang sabar", atau nama surah, '
                  'lalu AI akan menampilkan ayat, terjemah, dan penjelasan dengan pendekatan Tafsir al-Munir dan al-Mishbah.',
            ),
          )
        else ...[
          if (result.ringkasan.isNotEmpty) ...[
            AppCard(
              gradient: AppColors.heroGradient,
              shadow: false,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(AppIcons.sparkles, size: 18, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      result.ringkasan,
                      style: const TextStyle(fontSize: 13, height: 1.55, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
            const SizedBox(height: 14),
          ],
          if (result.isStructured)
            for (var i = 0; i < result.ayat.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _AyatCard(ayat: result.ayat[i], arabicSize: arabicSize)
                    .animate(delay: (120 + i * 100).ms)
                    .fadeIn(duration: 420.ms)
                    .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
              )
          else
            AppCard(child: RichResult(text: result.raw, arabicSize: arabicSize)),
          const NoticeCard(
            icon: AppIcons.info,
            message: 'Hasil dibuat oleh AI dengan pendekatan Tafsir al-Munir dan al-Mishbah, bukan kutipan '
                'langsung dari kitabnya. Cocokkan teks ayat dengan mushaf dan rujuk kitabnya sebelum dipakai mengajar.',
          ),
        ],
      ],
    );
  }
}

class _AyatCard extends StatefulWidget {
  final AyatResult ayat;
  final double arabicSize;
  const _AyatCard({required this.ayat, required this.arabicSize});

  @override
  State<_AyatCard> createState() => _AyatCardState();
}

class _AyatCardState extends State<_AyatCard> {
  int? _open;

  @override
  Widget build(BuildContext context) {
    final a = widget.ayat;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Pill(
                label: a.nomor.isEmpty ? a.surah : 'QS. ${a.surah} · ${a.nomor}',
                color: AppColors.blue600,
                icon: AppIcons.bookMarked,
              ),
              const Spacer(),
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => copyText(context, a.toPlainText(), label: 'Ayat'),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(AppIcons.copy, size: 17, color: context.muted),
                ),
              ),
              if (a.arab.isNotEmpty)
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () =>
                      context.read<HandoffService>().send(HandoffTarget.nahwu, a.arab),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(AppIcons.nahwu, size: 17, color: context.cs.primary),
                  ),
                ),
            ],
          ),
          if (a.arab.isNotEmpty) ...[
            const SizedBox(height: 8),
            ArabicText(a.arab, size: widget.arabicSize),
          ],
          if (a.terjemah.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              a.terjemah,
              style: TextStyle(
                fontSize: 13,
                height: 1.6,
                fontStyle: FontStyle.italic,
                color: context.muted,
              ),
            ),
          ],
          if (a.hasTafsir) ...[
            const SizedBox(height: 12),
            Builder(builder: (context) {
              final sections = <(String, String)>[
                if (a.munir.isNotEmpty) ('Al-Munir', a.munir),
                if (a.mishbah.isNotEmpty) ('Al-Mishbah', a.mishbah),
                if (a.tafsir.isNotEmpty) ('Tafsir ringkas', a.tafsir),
              ];
              final open = (_open != null && _open! < sections.length) ? _open : null;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (var i = 0; i < sections.length; i++)
                        _TafsirChip(
                          label: sections[i].$1,
                          selected: open == i,
                          onTap: () => setState(() => _open = open == i ? null : i),
                        ),
                    ],
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    alignment: Alignment.topCenter,
                    child: open == null
                        ? const SizedBox(width: double.infinity)
                        : Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(top: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: context.surface2,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SelectableText(
                                  sections[open].$2,
                                  style: const TextStyle(fontSize: 13, height: 1.6),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Ringkasan AI dengan pendekatan tafsir ini, bukan kutipan kitab.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                    color: context.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ],
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _TafsirChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TafsirChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.cs.primary;
    return Material(
      color: selected ? c.withValues(alpha: context.isDark ? 0.28 : 0.14) : Colors.transparent,
      shape: StadiumBorder(side: BorderSide(color: selected ? c : context.border)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(AppIcons.bookMarked, size: 14, color: selected ? c : context.muted),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? c : context.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
