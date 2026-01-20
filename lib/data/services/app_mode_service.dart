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
  final SharedPreferences _prefs;

  AppModeService(this._prefs);

  AppMode readMode() {
    final value = _prefs.getString(_prefsKey);
    return _parse(value) ?? AppMode.local;
  }

  Future<void> saveMode(AppMode mode) async {
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
