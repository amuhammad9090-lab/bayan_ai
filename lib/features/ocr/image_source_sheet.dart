import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/icons.dart';
import '../../core/theme.dart';
import '../../shared/widgets/common.dart';

Future<ImageSource?> showImageSourceSheet(BuildContext context) {
  return showAppSheet<ImageSource>(
    context,
    title: 'Pilih sumber gambar',
    icon: AppIcons.imagePlus,
    builder: (ctx) => Column(
      children: [
        _SourceTile(
          icon: AppIcons.camera,
          title: 'Kamera',
          subtitle: 'Potret halaman mushaf secara langsung',
          onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
        ),
        const SizedBox(height: 10),
        _SourceTile(
          icon: AppIcons.gallery,
          title: 'Galeri',
          subtitle: 'Pilih gambar yang sudah ada',
          onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
        ),
      ],
    ),
  );
}

class _SourceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _SourceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      shadow: false,
      onTap: onTap,
      child: Row(
        children: [
          IconChip(icon: icon),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),
                Text(subtitle, style: TextStyle(fontSize: 12, color: context.muted)),
              ],
            ),
          ),
          Icon(AppIcons.chevronRight, size: 18, color: context.muted),
        ],
      ),
    );
  }
}
