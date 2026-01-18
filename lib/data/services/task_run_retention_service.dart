import 'package:shared_preferences/shared_preferences.dart';

class TaskRunRetentionService {
  static const int defaultRetention = 7;
  static const int maxRetention = 30;
  static const int minRetention = 1;
  static const String _key = 'task_run_retention_v1';

  Future<int> getRetentionCount() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getInt(_key) ?? defaultRetention;
    return _clamp(raw);
  }

  Future<int> setRetentionCount(int value) async {
    final prefs = await SharedPreferences.getInstance();
    final clamped = _clamp(value);
    await prefs.setInt(_key, clamped);
    return clamped;
  }

  int _clamp(int value) {
    if (value < minRetention) return minRetention;
    if (value > maxRetention) return maxRetention;
    return value;
  }
}
