import 'package:shared_preferences/shared_preferences.dart';

class TaskRunNoticeService {
  static const int defaultNoticeMinutes = 5;
  static const int minNoticeMinutes = 0;
  static const int maxNoticeMinutes = 120;
  static const String _key = 'task_run_notice_minutes_v1';

  Future<int> getNoticeMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getInt(_key) ?? defaultNoticeMinutes;
    return _clamp(raw);
  }

  Future<int> setNoticeMinutes(int value) async {
    final prefs = await SharedPreferences.getInstance();
    final clamped = _clamp(value);
    await prefs.setInt(_key, clamped);
    return clamped;
  }

  int _clamp(int value) {
    if (value < minNoticeMinutes) return minNoticeMinutes;
    if (value > maxNoticeMinutes) return maxNoticeMinutes;
    return value;
  }
}
