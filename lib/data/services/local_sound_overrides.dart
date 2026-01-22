import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/selected_sound.dart';

enum SoundSlot { pomodoroStart, breakStart }

extension SoundSlotX on SoundSlot {
  String get key => switch (this) {
    SoundSlot.pomodoroStart => 'pomodoroStart',
    SoundSlot.breakStart => 'breakStart',
  };
}

class LocalSoundOverride {
  final SelectedSound sound;
  final String fallbackBuiltInId;
  final String? displayName;

  const LocalSoundOverride({
    required this.sound,
    required this.fallbackBuiltInId,
    this.displayName,
  });

  Map<String, dynamic> toMap() => {
    'type': sound.type.name,
    'value': sound.value,
    'fallback': fallbackBuiltInId,
    if (displayName != null) 'displayName': displayName,
  };

  static LocalSoundOverride? fromMap(Map<String, dynamic> map) {
    final rawType = map['type'];
    final rawValue = map['value'];
    final rawFallback = map['fallback'];
    final rawDisplayName = map['displayName'];
    if (rawType is! String || rawValue is! String || rawFallback is! String) {
      return null;
    }
    final type = SoundType.values.firstWhere(
      (t) => t.name == rawType,
      orElse: () => SoundType.custom,
    );
    if (type != SoundType.custom) return null;
    if (rawValue.trim().isEmpty) return null;
    return LocalSoundOverride(
      sound: SelectedSound.custom(rawValue),
      fallbackBuiltInId: rawFallback,
      displayName:
          rawDisplayName is String && rawDisplayName.trim().isNotEmpty
              ? rawDisplayName
              : null,
    );
  }
}

class LocalSoundOverrides {
  static const String _prefix = 'local_sound_override_v1';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  String _key(String taskId, SoundSlot slot) => '$_prefix:$taskId:${slot.key}';

  Future<LocalSoundOverride?> getOverride(String taskId, SoundSlot slot) async {
    final prefs = await _prefs;
    final raw = prefs.getString(_key(taskId, slot));
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return null;
    return LocalSoundOverride.fromMap(Map<String, dynamic>.from(decoded));
  }

  Future<void> setOverride({
    required String taskId,
    required SoundSlot slot,
    required SelectedSound sound,
    required String fallbackBuiltInId,
    String? displayName,
  }) async {
    if (sound.type != SoundType.custom) {
      await clearOverride(taskId, slot);
      return;
    }
    final override = LocalSoundOverride(
      sound: sound,
      fallbackBuiltInId: fallbackBuiltInId,
      displayName: displayName,
    );
    final prefs = await _prefs;
    await prefs.setString(_key(taskId, slot), jsonEncode(override.toMap()));
  }

  Future<void> clearOverride(String taskId, SoundSlot slot) async {
    final prefs = await _prefs;
    await prefs.remove(_key(taskId, slot));
  }
}
