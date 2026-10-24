import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/icons.dart';
import '../../core/theme.dart';
import '../../shared/widgets/common.dart';
import 'setting_row.dart';
import 'settings_provider.dart';

Future<void> showArabicSizeSheet(BuildContext context) {
  return showAppSheet<void>(
    context,
    title: 'Ukuran teks Arab',
    icon: AppIcons.type,
    builder: (ctx) => settingsAccent(ctx, const _ArabicSizeForm()),
  );
}

class _ArabicSizeForm extends StatelessWidget {
  const _ArabicSizeForm();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 110),
          alignment: Alignment.center,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.surface2,
            borderRadius: BorderRadius.circular(18),
          ),
          child: ArabicText(
            'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ',
            size: s.arabicSize,
            selectable: false,
            align: TextAlign.center,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Text('A', style: TextStyle(fontSize: 13, color: context.muted)),
            Expanded(
              child: Slider(
                value: s.arabicSize,
                min: 20,
                max: 40,
                divisions: 20,
                label: '${s.arabicSize.round()}',
                onChanged: s.setArabicSize,
              ),
            ),
            Text('A', style: TextStyle(fontSize: 20, color: context.muted)),
          ],
        ),
        Center(
          child: Text(
            'Ukuran ${s.arabicSize.round()}',
            style: TextStyle(fontSize: 12.5, color: context.muted),
          ),
        ),
      ],
    );
  }
}
