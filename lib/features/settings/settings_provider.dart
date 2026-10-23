import 'package:flutter/material.dart';

import '../../core/ai_repository.dart';
import '../../core/storage.dart';

class ModelOption {
  final String id;
  final String label;
  final String desc;
  const ModelOption(this.id, this.label, this.desc);
}

const kDefaultModel = 'gemini-3.8-flash';

/// Daftar saran (gratis, ada batas). ID dari sumber pihak ketiga; kalau ada yang
/// tidak ketemu, pakai "Muat daftar model" di sheet pilih model.
const kModelOptions = <ModelOption>[
  ModelOption('gemini-3.8-flash', 'Gemini 3.8 Flash', 'Terbaru, seimbang (disarankan)'),
  ModelOption('gemini-3.6-flash', 'Gemini 3.6 Flash', 'Generasi sebelumnya, stabil'),
  ModelOption('gemini-3.5-flash-lite', 'Gemini 3.5 Flash-Lite', 'Paling hemat kuota & ringan'),
  ModelOption('gemini-3.1-flash-lite', 'Gemini 3.1 Flash-Lite', 'Ringan & cepat'),
  ModelOption('gemini-2.5-flash', 'Gemini 2.5 Flash', 'Model lama, masih tersedia'),
];

/// Key penyimpanan sengaja disamakan dengan kedua app lama
/// (api_key, model_name) supaya pengaturan lama tetap kebaca.
class SettingsProvider extends ChangeNotifier implements AiConfigSource {
  SettingsProvider(this._store) {
    _apiKey = _store.getString('api_key') ?? '';
    final saved = _store.getString('model_name');
    // gemini-2.0-flash dari app lama sudah usang -> pindah ke default baru.
    _model = (saved == null || saved == 'gemini-2.0-flash') ? kDefaultModel : saved;
    _arabicSize = _store.getDouble('arabic_size') ?? 26;
    _autoSave = _store.getBool('auto_save') ?? true;

    final mode = _store.getString('theme_mode');
    if (mode != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (m) => m.name == mode,
        orElse: () => ThemeMode.system,
      );
    } else if (_store.contains('isDarkTheme') || _store.contains('dark_theme')) {
      final dark = _store.getBool('isDarkTheme') ?? _store.getBool('dark_theme') ?? false;
      _themeMode = dark ? ThemeMode.dark : ThemeMode.light;
    }
  }

  final KeyValueStore _store;

  String _apiKey = '';
  String _model = kDefaultModel;
  ThemeMode _themeMode = ThemeMode.system;
  double _arabicSize = 26;
  bool _autoSave = true;

  String get apiKey => _apiKey;
  String get model => _model;
  ThemeMode get themeMode => _themeMode;
  double get arabicSize => _arabicSize;
  bool get autoSave => _autoSave;
  bool get hasApiKey => _apiKey.trim().isNotEmpty;

  @override
  AiConfig get aiConfig => AiConfig(apiKey: _apiKey, model: _model);

  Future<void> setApiKey(String v) async {
    _apiKey = v.trim();
    notifyListeners();
    await _store.setString('api_key', _apiKey);
  }

  Future<void> setModel(String v) async {
    _model = v.trim().isEmpty ? kDefaultModel : v.trim();
    notifyListeners();
    await _store.setString('model_name', _model);
  }

  Future<void> setThemeMode(ThemeMode m) async {
    _themeMode = m;
    notifyListeners();
    await _store.setString('theme_mode', m.name);
  }

  Future<void> setArabicSize(double v) async {
    _arabicSize = v;
    notifyListeners();
    await _store.setDouble('arabic_size', v);
  }

  Future<void> setAutoSave(bool v) async {
    _autoSave = v;
    notifyListeners();
    await _store.setBool('auto_save', v);
  }
}
