import '../models/models.dart';

/// Fitur cukup tau "catat hasil ini". Mau disimpan atau nggak
/// (auto-save on/off) urusan implementasinya.
abstract class HistoryRecorder {
  Future<void> record(HistoryType type, String input, String output);
}
