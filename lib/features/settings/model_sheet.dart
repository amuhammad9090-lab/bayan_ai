import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/icons.dart';
import '../../core/theme.dart';
import '../../shared/widgets/common.dart';
import 'settings_provider.dart';

Future<void> showModelSheet(BuildContext context) {
  return showAppSheet<void>(
    context,
    title: 'Pilih model AI',
    icon: AppIcons.cpu,
    builder: (ctx) => const _ModelSheetBody(),
  );
}

class _ModelSheetBody extends StatefulWidget {
  const _ModelSheetBody();

  @override
  State<_ModelSheetBody> createState() => _ModelSheetBodyState();
}

class _ModelSheetBodyState extends State<_ModelSheetBody> {
  final _custom = TextEditingController();

  @override
  void dispose() {
    _custom.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return Column(
      children: [
        for (final m in kModelOptions)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppCard(
              shadow: false,
              onTap: () {
                settings.setModel(m.id);
                Navigator.of(context).pop();
              },
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.label,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        Text(m.desc, style: TextStyle(fontSize: 12, color: context.muted)),
                      ],
                    ),
                  ),
                  if (settings.model == m.id)
                    Icon(AppIcons.success, size: 22, color: context.cs.primary),
                ],
              ),
            ),
          ),
        const SizedBox(height: 6),
        TextField(
          controller: _custom,
          decoration: InputDecoration(
            hintText: 'Atau ketik ID model sendiri…',
            suffixIcon: IconButton(
              icon: const Icon(AppIcons.check, size: 18),
              onPressed: () {
                if (_custom.text.trim().isEmpty) return;
                settings.setModel(_custom.text);
                Navigator.of(context).pop();
              },
            ),
          ),
        ),
      ],
    );
  }
}
