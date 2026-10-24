import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/art.dart';
import '../../core/handoff.dart';
import '../../core/icons.dart';
import '../../core/theme.dart';
import '../../shared/widgets/animations.dart';
import '../../shared/widgets/bound_text.dart';
import '../../shared/widgets/common.dart';
import '../shell/header_actions.dart';
import '../settings/settings_provider.dart';
import 'image_source_sheet.dart';
import 'ocr_provider.dart';

class OcrPage extends StatefulWidget {
  const OcrPage({super.key});

  @override
  State<OcrPage> createState() => _OcrPageState();
}

class _OcrPageState extends State<OcrPage> {
  final _picker = ImagePicker();

  Future<void> _pick([ImageSource? preset]) async {
    // Di web tidak ada pilihan kamera/galeri: langsung buka pemilih file.
    final source = kIsWeb
        ? ImageSource.gallery
        : (preset ?? await showImageSourceSheet(context));
    if (source == null || !mounted) return;
    final ocr = context.read<OcrProvider>();
    try {
      final x = await _picker.pickImage(
        source: source,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );
      if (x != null) ocr.setImage(x, await x.readAsBytes());
    } catch (e) {
      if (mounted) showSnack(context, 'Gagal mengambil gambar: $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ocr = context.watch<OcrProvider>();
    final arabicSize = context.select<SettingsProvider, double>((s) => s.arabicSize);
    final handoff = context.read<HandoffService>();
    final has = ocr.hasText;

    return FeatureScroll(
          actions: const HeaderActions(),
          gradient: AppColors.gradOcr,
          shadow: AppColors.featOcr,
          asset: Art.homeOcr,
          fallback: AppIcons.ocr,
          title: 'Pindai Mushaf',
          subtitle: 'Foto halaman mushaf, AI membaca teks Arabnya lengkap dengan harakat.',
          onRefresh: () async {
            if (ocr.image != null) {
              await ocr.run();
            } else {
              await Future<void>.delayed(const Duration(milliseconds: 700));
            }
          },
      children: [

        // ── 1. Kartu kerja: gambar + sumber + aksi utama ──
        const SectionLabel('Gambar', hint: 'Satu halaman atau satu ayat'),
        AppCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: AspectRatio(
                  aspectRatio: 16 / 10,
                  child: ocr.image == null
                      ? Material(
                          color: context.surface2,
                          // Gelap: garis tipis warna tab biar area unggah nggak nyaru.
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                            side: context.isDark
                                ? BorderSide(
                                    color: context.chipBorder(context.accent).withValues(alpha: 0.35),
                                    width: 1.4,
                                  )
                                : BorderSide.none,
                          ),
                          child: InkWell(
                            onTap: () => _pick(),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const IconChip(icon: AppIcons.imagePlus, size: 52)
                                    .animate(onPlay: (c) => c.repeat(reverse: true))
                                    .moveY(begin: -4, end: 4, duration: 1400.ms, curve: Curves.easeInOut),
                                const SizedBox(height: 10),
                                const Text(
                                  'Belum ada gambar',
                                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  kIsWeb ? 'Klik untuk memilih file' : 'Ketuk untuk memilih',
                                  style: TextStyle(fontSize: 11.5, color: context.muted),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.memory(ocr.bytes!, fit: BoxFit.cover),
                            if (ocr.loading) const Positioned.fill(child: ScanOverlay()),
                            Positioned(
                              right: 8,
                              top: 8,
                              child: _OverlayButton(icon: AppIcons.close, onTap: ocr.clear),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (!kIsWeb) ...[
                    Expanded(
                      child: TonalButton(
                        icon: AppIcons.camera,
                        label: 'Kamera',
                        onTap: () => _pick(ImageSource.camera),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: TonalButton(
                      icon: AppIcons.gallery,
                      label: kIsWeb ? 'Pilih gambar' : 'Galeri',
                      onTap: () => _pick(ImageSource.gallery),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GradientButton(
                label: ocr.loading ? 'Memproses…' : 'Jalankan OCR',
                icon: AppIcons.sparkles,
                loading: ocr.loading,
                onPressed: ocr.image == null ? null : ocr.run,
              ),
            ],
          ),
        ),
        PageGap.section,

        // ── 2. Hasil + aksi lanjutan dalam satu kartu ──
        SectionLabel(
          'Hasil OCR',
          hint: 'Dapat diedit bila ada huruf yang keliru',
          trailing: has
              ? Pill(label: 'Dapat diedit', color: context.cs.primary, icon: AppIcons.type)
              : null,
        ),
        if (ocr.error != null) ...[
          ErrorCard(message: ocr.error!),
          PageGap.inner,
        ],
        AppCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (ocr.loading)
                const ThinkingView(messages: ['Membaca tulisan Arab…', 'Mengenali harakat…', 'Merapikan hasil…'])
              else
                BoundText(
                  source: ocr,
                  read: () => ocr.text,
                  version: () => ocr.textVersion,
                  onChanged: ocr.onUserEdit,
                  builder: (context, controller) => ArabicField(
                    controller: controller,
                    hint: 'Teks hasil OCR akan muncul di sini…',
                    size: arabicSize,
                    font: 'LPMQ',
                    minLines: 5,
                    maxLines: 12,
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TonalButton(
                      icon: AppIcons.copy,
                      label: 'Salin',
                      onTap: has ? () => copyText(context, ocr.text, label: 'Hasil OCR') : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TonalButton(
                      icon: AppIcons.nahwu,
                      label: 'Nahwu',
                      onTap: has ? () => handoff.send(HandoffTarget.nahwu, ocr.text.trim()) : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TonalButton(
                      icon: AppIcons.quran,
                      label: "Qur'an",
                      onTap: has ? () => handoff.send(HandoffTarget.quran, ocr.text.trim()) : null,
                    ),
                  ),
                ],
              ),
              if (has || ocr.image != null) ...[
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: ocr.clear,
                    icon: const Icon(AppIcons.trash, size: 15),
                    label: const Text('Bersihkan'),
                    style: TextButton.styleFrom(foregroundColor: context.tone(AppColors.danger)),
                  ),
                ),
              ],
            ],
          ),
        ),
        PageGap.section,
        const Footnote(
          'Tips: gunakan foto yang terang, lurus, dan tidak buram. '
          'Potong (crop) per halaman atau per ayat agar hasilnya lebih akurat.',
          icon: AppIcons.lightbulb,
        ),
      ],
    );
  }
}

class _OverlayButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _OverlayButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Icon(icon, size: 17, color: Colors.white),
        ),
      ),
    );
  }
}
