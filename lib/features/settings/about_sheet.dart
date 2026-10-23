import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_info.dart';
import '../../core/icons.dart';
import '../../core/theme.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/logo_mark.dart';

Future<void> showAboutSheet(BuildContext context) {
  return showAppSheet<void>(
    context,
    title: 'Tentang aplikasi',
    icon: AppIcons.info,
    builder: (ctx) => Column(
      children: [
        const SizedBox(height: 8),
        const LogoMark(size: 72),
        const SizedBox(height: 16),
        const Text(kAppName, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('Versi $kAppVersion', style: TextStyle(fontSize: 12.5, color: ctx.muted)),
        const SizedBox(height: 16),
        Text(
          'OCR mushaf, pencarian ayat & tafsir, dan analisis nahwu dalam satu aplikasi.\n'
          'Dibuat dengan Flutter + Google Gemini oleh Arie Muhammad.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, height: 1.6, color: ctx.muted),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => launchUrl(
              Uri.parse('https://github.com/amuhammad9090-lab'),
              mode: LaunchMode.externalApplication,
            ),
            icon: const Icon(AppIcons.github, size: 18),
            label: const Text('GitHub'),
          ),
        ),
        const SizedBox(height: 14),
        Text('© 2025 Arie Muhammad', style: TextStyle(fontSize: 11.5, color: ctx.muted)),
      ],
    ),
  );
}
