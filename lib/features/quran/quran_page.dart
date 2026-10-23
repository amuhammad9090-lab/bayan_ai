import 'package:flutter/material.dart';
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
                backgroundColor: context.surface2,
                side: BorderSide(color: context.border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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
          const SkeletonList(count: 3, height: 140)
        else if (quran.error != null)
          ErrorCard(message: quran.error!)
        else if (result == null)
          const AppCard(
            shadow: false,
            child: EmptyState(
              icon: AppIcons.bookMarked,
              title: 'Cari ayat & tafsir',
              subtitle: 'Tulis topik seperti "ayat tentang sabar", atau nama surah, '
                  'lalu AI akan menampilkan ayat, terjemah, dan tafsir ringkas.',
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
            ),
            const SizedBox(height: 14),
          ],
          if (result.isStructured)
            for (final a in result.ayat)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _AyatCard(ayat: a, arabicSize: arabicSize),
              )
          else
            AppCard(child: RichResult(text: result.raw, arabicSize: arabicSize)),
          const NoticeCard(
            icon: AppIcons.info,
            message: 'Hasil dibuat oleh AI. Selalu cocokkan teks ayat dengan mushaf '
                'dan tafsir dari kitab rujukan sebelum dipakai mengajar.',
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
  bool _showTafsir = false;

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
          if (a.tafsir.isNotEmpty) ...[
            const SizedBox(height: 8),
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => setState(() => _showTafsir = !_showTafsir),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Text(
                      'Tafsir ringkas',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: context.cs.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    AnimatedRotation(
                      turns: _showTafsir ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(AppIcons.chevronDown, size: 16, color: context.cs.primary),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 220),
              crossFadeState:
                  _showTafsir ? CrossFadeState.showFirst : CrossFadeState.showSecond,
              firstChild: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.surface2,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: SelectableText(
                  a.tafsir,
                  style: const TextStyle(fontSize: 13, height: 1.6),
                ),
              ),
              secondChild: const SizedBox(width: double.infinity),
            ),
          ],
        ],
      ),
    );
  }
}
