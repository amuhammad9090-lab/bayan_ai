import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/handoff.dart';
import '../../core/icons.dart';
import '../../core/theme.dart';
import '../../shared/widgets/bound_text.dart';
import '../../shared/widgets/common.dart';
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
    final source = preset ?? await showImageSourceSheet(context);
    if (source == null || !mounted) return;
    final ocr = context.read<OcrProvider>();
    try {
      final x = await _picker.pickImage(source: source, imageQuality: 90);
      if (x != null) ocr.setImage(File(x.path));
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

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        AppCard(
          padding: EdgeInsets.zero,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: ocr.image == null
                  ? InkWell(
                      onTap: () => _pick(),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const IconChip(icon: AppIcons.imagePlus, size: 60),
                          const SizedBox(height: 14),
                          const Text(
                            'Pilih gambar mushaf',
                            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Ketuk untuk kamera atau galeri',
                            style: TextStyle(fontSize: 12, color: context.muted),
                          ),
                        ],
                      ),
                    )
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(ocr.image!, fit: BoxFit.cover),
                        Positioned(
                          right: 10,
                          top: 10,
                          child: Row(
                            children: [
                              _OverlayButton(icon: AppIcons.replace, onTap: () => _pick()),
                              const SizedBox(width: 8),
                              _OverlayButton(icon: AppIcons.close, onTap: ocr.clear),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
        const SizedBox(height: 14),

        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pick(ImageSource.camera),
                icon: const Icon(AppIcons.camera, size: 18),
                label: const Text('Kamera'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pick(ImageSource.gallery),
                icon: const Icon(AppIcons.gallery, size: 18),
                label: const Text('Galeri'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        GradientButton(
          label: ocr.loading ? 'Memproses…' : 'Jalankan OCR',
          icon: AppIcons.sparkles,
          loading: ocr.loading,
          onPressed: ocr.image == null ? null : ocr.run,
        ),
        const SizedBox(height: 22),

        SectionHeader(
          title: 'Hasil OCR',
          subtitle: 'Bisa diedit kalau ada huruf yang keliru',
          trailing: has
              ? const Pill(label: 'Bisa diedit', color: AppColors.blue600, icon: AppIcons.type)
              : null,
        ),

        if (ocr.error != null) ...[
          ErrorCard(message: ocr.error!),
          const SizedBox(height: 12),
        ],

        if (ocr.loading)
          const SkeletonList(count: 1, height: 150)
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

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ActionChipButton(
              icon: AppIcons.copy,
              label: 'Salin',
              onTap: has ? () => copyText(context, ocr.text, label: 'Hasil OCR') : null,
            ),
            ActionChipButton(
              icon: AppIcons.nahwu,
              label: 'Analisis Nahwu',
              onTap: has ? () => handoff.send(HandoffTarget.nahwu, ocr.text.trim()) : null,
            ),
            ActionChipButton(
              icon: AppIcons.quran,
              label: "Cari di Qur'an",
              onTap: has ? () => handoff.send(HandoffTarget.quran, ocr.text.trim()) : null,
            ),
            ActionChipButton(
              icon: AppIcons.trash,
              label: 'Bersihkan',
              danger: true,
              onTap: has || ocr.image != null ? ocr.clear : null,
            ),
          ],
        ),
        const SizedBox(height: 18),
        const NoticeCard(
          message: 'Tips: gunakan foto yang terang, lurus, dan tidak buram. '
              'Crop satu halaman atau satu ayat biar hasilnya lebih akurat.',
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
