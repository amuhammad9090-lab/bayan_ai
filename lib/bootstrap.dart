import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/ai_repository.dart';
import 'core/handoff.dart';
import 'core/storage.dart';
import 'data/cached_ai_repository.dart';
import 'data/gemini_ai_repository.dart';
import 'features/auth/auth_provider.dart';
import 'features/history/history_provider.dart';
import 'features/settings/settings_provider.dart';
import 'firebase_options.dart';

/// Composition root: satu-satunya tempat implementasi konkret dirakit.
class AppDeps {
  AppDeps._({
    required this.store,
    required this.handoff,
    required this.settings,
    required this.history,
    required this.cached,
    required this.auth,
  });

  final KeyValueStore store;
  final HandoffService handoff;
  final SettingsProvider settings;
  final HistoryProvider history;
  final CachedAiRepository cached;
  final AuthProvider auth;

  AiRepository get ai => cached;

  static Future<AppDeps> init() async {
    final KeyValueStore store = PrefsStore(
      await SharedPreferences.getInstance(),
    );
    final firebaseReady = await _initFirebase();

    final settings = SettingsProvider(store);
    final history = HistoryProvider(store, enabled: () => settings.autoSave);
    // Gemini dibungkus cache lokal (hemat kuota API gratis).
    final cached = CachedAiRepository(
      GeminiAiRepository(settings),
      settings,
      store,
    );

    final auth = AuthProvider(firebaseReady: firebaseReady);
    // Riwayat & cache AI dipisah per akun: ikut berganti saat login/logout.
    void syncUser() {
      final uid = auth.user?.uid;
      history.switchUser(uid);
      cached.switchUser(uid);
    }

    auth.addListener(syncUser);
    syncUser();

    return AppDeps._(
      store: store,
      handoff: HandoffService(),
      settings: settings,
      history: history,
      cached: cached,
      auth: auth,
    );
  }

  /// false kalau project Firebase belum dikonfigurasi -> app tetap jalan.
  static Future<bool> _initFirebase() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      return true;
    } catch (e) {
      debugPrint('Firebase belum siap: $e');
      return false;
    }
  }
}
