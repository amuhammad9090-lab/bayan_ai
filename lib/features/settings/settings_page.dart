import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/ai_repository.dart';
import '../../core/app_info.dart';
import '../../core/icons.dart';
import '../../core/theme.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/logo_mark.dart';
import '../auth/account_card.dart';
import '../history/history_provider.dart';
import 'about_sheet.dart';
import 'model_sheet.dart';
import 'settings_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final TextEditingController _key;
  bool _obscure = true;
  bool _testing = false;
  bool? _valid;

  @override
  void initState() {
    super.initState();
    _key = TextEditingController(text: context.read<SettingsProvider>().apiKey);
  }

  @override
  void dispose() {
    _key.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await context.read<SettingsProvider>().setApiKey(_key.text);
    if (mounted) {
      FocusScope.of(context).unfocus();
      showSnack(context, 'API key disimpan');
    }
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

  Future<void> _confirmClear() async {
    final history = context.read<HistoryProvider>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.cs.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Hapus semua riwayat?', style: TextStyle(fontSize: 17)),
        content: const Text('Semua hasil OCR, ayat, dan nahwu yang tersimpan akan dihapus.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await history.clear();
      if (mounted) showSnack(context, 'Riwayat dihapus');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsProvider>();
    final modelLabel = kModelOptions
        .where((m) => m.id == s.model)
        .map((m) => m.label)
        .followedBy([s.model])
        .first;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        const SectionHeader(title: 'Akun', subtitle: 'Profil dan sesi login'),
        const AccountCard(),
        const SizedBox(height: 22),
        const SectionHeader(title: 'Koneksi AI', subtitle: 'Gemini API key & model'),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _key,
                obscureText: _obscure,
                autocorrect: false,
                enableSuggestions: false,
                onChanged: (_) => setState(() => _valid = null),
                decoration: InputDecoration(
                  labelText: 'API key Gemini',
                  prefixIcon: const Icon(AppIcons.key, size: 19),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? AppIcons.eye : AppIcons.eyeOff, size: 19),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              if (_valid != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      _valid! ? AppIcons.success : AppIcons.warning,
                      size: 16,
                      color: _valid! ? AppColors.success : AppColors.danger,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _valid! ? 'API key valid' : 'API key gagal / koneksi error',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: _valid! ? AppColors.success : AppColors.danger,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _testing ? null : _test,
                      icon: _testing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(AppIcons.wifi, size: 17),
                      label: const Text('Tes koneksi'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _save,
                      icon: const Icon(AppIcons.check, size: 17),
                      label: const Text('Simpan'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(),
              _Tile(
                icon: AppIcons.cpu,
                title: 'Model AI',
                value: modelLabel,
                onTap: () => showModelSheet(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        const SectionHeader(title: 'Tampilan', subtitle: 'Tema dan ukuran teks Arab'),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<ThemeMode>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.system,
                      icon: Icon(AppIcons.monitor, size: 16),
                      label: Text('Sistem'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      icon: Icon(AppIcons.sun, size: 16),
                      label: Text('Terang'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      icon: Icon(AppIcons.moon, size: 16),
                      label: Text('Gelap'),
                    ),
                  ],
                  selected: {s.themeMode},
                  onSelectionChanged: (v) => s.setThemeMode(v.first),
                  style: SegmentedButton.styleFrom(
                    textStyle: const TextStyle(fontSize: 12, fontFamily: 'PlusJakartaSans'),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Icon(AppIcons.type, size: 18),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('Ukuran teks Arab',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500)),
                  ),
                  Text('${s.arabicSize.round()}',
                      style: TextStyle(fontSize: 13, color: context.muted)),
                ],
              ),
              Slider(
                value: s.arabicSize,
                min: 20,
                max: 40,
                divisions: 20,
                onChanged: s.setArabicSize,
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.surface2,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ArabicText(
                  'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ',
                  size: s.arabicSize,
                  selectable: false,
                  align: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        const SectionHeader(title: 'Data'),
        AppCard(
          child: Column(
            children: [
              Row(
                children: [
                  const IconChip(icon: AppIcons.database, size: 38),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Simpan riwayat otomatis',
                            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500)),
                        Text('OCR, ayat, dan nahwu', style: TextStyle(fontSize: 11.5)),
                      ],
                    ),
                  ),
                  Switch(value: s.autoSave, onChanged: s.setAutoSave),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(),
              _Tile(
                icon: AppIcons.database,
                title: 'Bersihkan cache AI',
                value: '${context.read<AiCache>().size} tersimpan',
                onTap: () async {
                  final cache = context.read<AiCache>();
                  await cache.clear();
                  if (!context.mounted) return;
                  setState(() {});
                  showSnack(context, 'Cache AI dibersihkan');
                },
              ),
              const Divider(),
              _Tile(
                icon: AppIcons.trash,
                title: 'Hapus semua riwayat',
                danger: true,
                onTap: _confirmClear,
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        AppCard(
          onTap: () => showAboutSheet(context),
          child: Row(
            children: [
              const LogoMark(size: 44),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(kAppName,
                        style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),
                    Text('Versi $kAppVersion', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              Icon(AppIcons.chevronRight, size: 18, color: context.muted),
            ],
          ),
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? value;
  final bool danger;
  final VoidCallback onTap;
  const _Tile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.value,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = danger ? AppColors.danger : null;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 19, color: c ?? context.cs.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: c),
              ),
            ),
            if (value != null)
              Flexible(
                child: Text(
                  value!,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.5, color: context.muted),
                ),
              ),
            const SizedBox(width: 6),
            Icon(AppIcons.chevronRight, size: 17, color: context.muted),
          ],
        ),
      ),
    );
  }
}
