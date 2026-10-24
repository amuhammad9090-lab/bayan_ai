import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'bootstrap.dart';
import 'core/ai_repository.dart';
import 'core/app_info.dart';
import 'core/handoff.dart';
import 'core/storage.dart';
import 'core/theme.dart';
import 'features/auth/auth_provider.dart';
import 'features/backup/backup_provider.dart';
import 'features/gate/app_gate.dart';
import 'features/history/history_provider.dart';
import 'features/nahwu/nahwu_provider.dart';
import 'features/ocr/ocr_provider.dart';
import 'features/quran/quran_provider.dart';
import 'features/settings/settings_provider.dart';
import 'features/shell/nav_provider.dart';

class BayanAiApp extends StatelessWidget {
  const BayanAiApp({super.key, required this.deps});

  final AppDeps deps;

  @override
  Widget build(BuildContext context) {
    final ai = deps.ai;
    return MultiProvider(
      providers: [
        Provider<KeyValueStore>.value(value: deps.store),
        Provider<HandoffService>.value(value: deps.handoff),
        Provider<AiRepository>.value(value: ai),
        Provider<AiCache>.value(value: deps.cached),
        ChangeNotifierProvider<SettingsProvider>.value(value: deps.settings),
        ChangeNotifierProvider<HistoryProvider>.value(value: deps.history),
        ChangeNotifierProvider<AuthProvider>.value(value: deps.auth),
      ],
      child: _UserScoped(deps: deps),
    );
  }
}

/// Provider fitur (OCR/Quran/Nahwu/Nav) dibuat ulang tiap ganti akun, jadi
/// hasil & input user sebelumnya nggak kebawa, dan request yang masih
/// jalan ikut dibatalkan (provider lama di-dispose).
class _UserScoped extends StatelessWidget {
  const _UserScoped({required this.deps});

  final AppDeps deps;

  @override
  Widget build(BuildContext context) {
    final uid = context.select<AuthProvider, String?>((a) => a.user?.uid);
    final ai = deps.ai;
    return MultiProvider(
      key: ValueKey(uid ?? 'guest'),
      providers: [
        ChangeNotifierProvider(create: (_) => NavProvider(deps.handoff)),
        ChangeNotifierProvider(
          lazy: false,
          create: (_) => BackupProvider(uid: uid, store: deps.store, history: deps.history),
        ),
        ChangeNotifierProvider(create: (_) => OcrProvider(ai, deps.history, deps.handoff)),
        ChangeNotifierProvider(
          create: (_) => QuranProvider(ai, deps.quranText, deps.history, deps.handoff),
        ),
        ChangeNotifierProvider(
          create: (_) => NahwuProvider(ai, deps.history, deps.handoff),
        ),
      ],
      child: const _AppView(),
    );
  }
}

class _AppView extends StatelessWidget {
  const _AppView();

  @override
  Widget build(BuildContext context) {
    final mode = context.select<SettingsProvider, ThemeMode>(
      (s) => s.themeMode,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: kAppName,
      themeMode: mode,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      builder: (context, child) {
        final dark = Theme.of(context).brightness == Brightness.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
            systemNavigationBarColor: dark
                ? AppColors.darkSurface
                : AppColors.lightSurface,
            systemNavigationBarIconBrightness: dark
                ? Brightness.light
                : Brightness.dark,
          ),
          // Tata letak lebar (web/desktop) diatur per halaman: sidebar di
          // ShellPage, bingkai di AppGate, batas lebar di Profil.
          child: child!,
        );
      },
      home: const AppGate(),
    );
  }
}
