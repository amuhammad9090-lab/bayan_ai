import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/ai_repository.dart';
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
  List<String>? _remote;
  bool _loadingRemote = false;
  String? _remoteError;

  Future<void> _loadRemote() async {
    final ai = context.read<AiRepository>();
    setState(() {
      _loadingRemote = true;
      _remoteError = null;
    });
    try {
      final ids = await ai.listModels();
      if (mounted) setState(() => _remote = ids);
    } on AiException catch (e) {
      if (mounted) setState(() => _remoteError = e.message);
    } finally {
      if (mounted) setState(() => _loadingRemote = false);
    }
  }

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
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _loadingRemote ? null : _loadRemote,
            icon: _loadingRemote
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(AppIcons.replace, size: 17),
            label: const Text('Muat daftar model dari API key'),
          ),
        ),
        if (_remoteError != null) ...[
          const SizedBox(height: 10),
          ErrorCard(message: _remoteError!),
        ],
        if (_remote != null) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final id in _remote!)
                ActionChip(
                  label: Text(id, style: const TextStyle(fontSize: 12)),
                  avatar: settings.model == id
                      ? Icon(AppIcons.check, size: 14, color: context.cs.primary)
                      : null,
                  onPressed: () {
                    settings.setModel(id);
                    Navigator.of(context).pop();
                  },
                ),
            ],
          ),
        ],
        const SizedBox(height: 12),
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
