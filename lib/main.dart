import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/ai_repository.dart';
import 'core/handoff.dart';
import 'core/storage.dart';
import 'data/gemini_ai_repository.dart';
import 'features/history/history_provider.dart';
import 'features/nahwu/nahwu_provider.dart';
import 'features/ocr/ocr_provider.dart';
import 'features/quran/quran_provider.dart';
import 'features/settings/settings_provider.dart';
import 'features/shell/nav_provider.dart';

/// Composition root: satu-satunya tempat implementasi konkret dirakit.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final KeyValueStore store = PrefsStore(await SharedPreferences.getInstance());
  final handoff = HandoffService();
  final settings = SettingsProvider(store);
  final history = HistoryProvider(store, enabled: () => settings.autoSave);
  final AiRepository ai = GeminiAiRepository(settings);

  runApp(
    MultiProvider(
      providers: [
        Provider<HandoffService>.value(value: handoff),
        Provider<AiRepository>.value(value: ai),
        ChangeNotifierProvider<SettingsProvider>.value(value: settings),
        ChangeNotifierProvider<HistoryProvider>.value(value: history),
        ChangeNotifierProvider(create: (_) => NavProvider(handoff)),
        ChangeNotifierProvider(create: (_) => OcrProvider(ai, history)),
        ChangeNotifierProvider(create: (_) => QuranProvider(ai, history, handoff)),
        ChangeNotifierProvider(create: (_) => NahwuProvider(ai, history, handoff)),
      ],
      child: const BayanAiApp(),
    ),
  );
}
