import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/ai_repository.dart';
import '../../core/icons.dart';
import '../../core/theme.dart';
import '../../shared/widgets/common.dart';
import 'setting_row.dart';
import 'settings_provider.dart';

Future<void> showApiKeySheet(BuildContext context) {
  return showAppSheet<void>(
    context,
    title: 'API key Gemini',
    icon: AppIcons.key,
    builder: (ctx) => settingsAccent(ctx, const _ApiKeyForm()),
  );
}

class _ApiKeyForm extends StatefulWidget {
  const _ApiKeyForm();

  @override
  State<_ApiKeyForm> createState() => _ApiKeyFormState();
}

class _ApiKeyFormState extends State<_ApiKeyForm> {
  late final TextEditingController _key =
      TextEditingController(text: context.read<SettingsProvider>().apiKey);
  bool _obscure = true;
  bool _testing = false;
  bool? _valid;

  @override
  void dispose() {
    _key.dispose();
    super.dispose();
  }

  Future<void> _test() async {
    final ai = context.read<AiRepository>();
    setState(() {
      _testing = true;
      _valid = null;
    });
    final ok = await ai.testConnection(apiKey: _key.text.trim());
    if (!mounted) return;
    setState(() {
      _testing = false;
      _valid = ok;
    });
  }

  Future<void> _save() async {
    final navigator = Navigator.of(context);
    await context.read<SettingsProvider>().setApiKey(_key.text);
    if (!mounted) return;
    showSnack(context, 'API key disimpan');
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Buat API key gratis di Google AI Studio (aistudio.google.com), lalu tempel di sini. '
          'Key hanya disimpan di perangkat ini.',
          style: TextStyle(fontSize: 12.5, height: 1.5, color: context.muted),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _key,
          obscureText: _obscure,
          autocorrect: false,
          enableSuggestions: false,
          onChanged: (_) => setState(() => _valid = null),
          decoration: InputDecoration(
            hintText: 'Tempel API key Gemini di sini',
            prefixIcon: const Icon(AppIcons.key, size: 19),
            suffixIcon: IconButton(
              icon: Icon(_obscure ? AppIcons.eye : AppIcons.eyeOff, size: 19),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
        ),
        if (_valid != null) ...[
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: StatusPill(
              label: _valid! ? 'API key valid' : 'API key tidak valid atau koneksi bermasalah',
              ok: _valid!,
            ),
          ),
        ],
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: TonalButton(
                icon: AppIcons.wifi,
                label: _testing ? 'Menguji…' : 'Uji koneksi',
                onTap: _testing ? null : _test,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TonalButton(
                filled: true,
                icon: AppIcons.check,
                label: 'Simpan',
                onTap: _save,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
