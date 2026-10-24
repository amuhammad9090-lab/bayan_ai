import 'package:shared_preferences/shared_preferences.dart';

/// Abstraksi penyimpanan key-value. Provider nggak tau SharedPreferences.
abstract class KeyValueStore {
  String? getString(String key);
  bool? getBool(String key);
  double? getDouble(String key);
  bool contains(String key);
  Future<void> setString(String key, String value);
  Future<void> setBool(String key, bool value);
  Future<void> setDouble(String key, double value);
  Future<void> remove(String key);
}

class PrefsStore implements KeyValueStore {
  PrefsStore(this._p);
  final SharedPreferences _p;

  @override
  String? getString(String key) => _p.getString(key);
  @override
  bool? getBool(String key) => _p.getBool(key);
  @override
  double? getDouble(String key) => _p.getDouble(key);
  @override
  bool contains(String key) => _p.containsKey(key);
  @override
  Future<void> setString(String key, String value) => _p.setString(key, value);
  @override
  Future<void> setBool(String key, bool value) => _p.setBool(key, value);
  @override
  Future<void> setDouble(String key, double value) => _p.setDouble(key, value);
  @override
  Future<void> remove(String key) => _p.remove(key);
}
