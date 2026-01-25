import 'package:shared_preferences/shared_preferences.dart';

enum AppMode { local, account }

extension AppModeX on AppMode {
  String get label => switch (this) {
    AppMode.local => 'Local mode',
    AppMode.account => 'Account mode',
  };
}

class AppModeService {
  static const String _prefsKey = 'app_mode_v1';
  final SharedPreferences? _prefs;
  AppMode? _memoryMode;

  AppModeService(this._prefs);

  factory AppModeService.memory() => AppModeService(null);

  AppMode readMode() {
    if (_prefs == null) return _memoryMode ?? AppMode.local;
    final value = _prefs.getString(_prefsKey);
    return _parse(value) ?? AppMode.local;
  }

  Future<void> saveMode(AppMode mode) async {
    if (_prefs == null) {
      _memoryMode = mode;
      return;
    }
    await _prefs.setString(_prefsKey, mode.name);
  }

  AppMode? _parse(String? raw) {
    return switch (raw) {
      'local' => AppMode.local,
      'account' => AppMode.account,
      _ => null,
    };
  }
}
