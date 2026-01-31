import 'package:cloud_firestore/cloud_firestore.dart';

import 'selected_sound.dart';

class PomodoroPreset {
  final String id;
  final String name;

  final int pomodoroMinutes;
  final int shortBreakMinutes;
  final int longBreakMinutes;
  final int longBreakInterval;

  final SelectedSound startSound;
  final SelectedSound startBreakSound;
  final SelectedSound finishTaskSound;

  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  PomodoroPreset({
    required this.id,
    required this.name,
    required this.pomodoroMinutes,
    required this.shortBreakMinutes,
    required this.longBreakMinutes,
    required this.longBreakInterval,
    required this.startSound,
    required this.startBreakSound,
    required this.finishTaskSound,
    required this.isDefault,
    required this.createdAt,
    required this.updatedAt,
  });

  PomodoroPreset copyWith({
    String? id,
    String? name,
    int? pomodoroMinutes,
    int? shortBreakMinutes,
    int? longBreakMinutes,
    int? longBreakInterval,
    SelectedSound? startSound,
    SelectedSound? startBreakSound,
    SelectedSound? finishTaskSound,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PomodoroPreset(
      id: id ?? this.id,
      name: name ?? this.name,
      pomodoroMinutes: pomodoroMinutes ?? this.pomodoroMinutes,
      shortBreakMinutes: shortBreakMinutes ?? this.shortBreakMinutes,
      longBreakMinutes: longBreakMinutes ?? this.longBreakMinutes,
      longBreakInterval: longBreakInterval ?? this.longBreakInterval,
      startSound: startSound ?? this.startSound,
      startBreakSound: startBreakSound ?? this.startBreakSound,
      finishTaskSound: finishTaskSound ?? this.finishTaskSound,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'pomodoroMinutes': pomodoroMinutes,
    'shortBreakMinutes': shortBreakMinutes,
    'longBreakMinutes': longBreakMinutes,
    'longBreakInterval': longBreakInterval,
    'startSound': startSound.toMap(),
    'startBreakSound': startBreakSound.toMap(),
    'finishTaskSound': finishTaskSound.toMap(),
    'isDefault': isDefault,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory PomodoroPreset.fromMap(Map<String, dynamic> map) {
    final now = DateTime.now();
    final createdAt = _parseDateTime(map['createdAt']) ?? now;
    final updatedAt = _parseDateTime(map['updatedAt']) ?? createdAt;
    final pomodoroMinutes = _readInt(map, 'pomodoroMinutes', 25);
    final shortBreakMinutes = _readInt(map, 'shortBreakMinutes', 5);
    final longBreakMinutes = _readInt(map, 'longBreakMinutes', 15);
    final longBreakInterval = _readInt(map, 'longBreakInterval', 4);
    final isDefault = map['isDefault'] == true;

    return PomodoroPreset(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      pomodoroMinutes: pomodoroMinutes,
      shortBreakMinutes: shortBreakMinutes,
      longBreakMinutes: longBreakMinutes,
      longBreakInterval: longBreakInterval,
      startSound: SelectedSound.fromDynamic(
        map['startSound'],
        fallbackId: 'default_chime',
      ),
      startBreakSound: SelectedSound.fromDynamic(
        map['startBreakSound'],
        fallbackId: 'default_chime_break',
      ),
      finishTaskSound: SelectedSound.fromDynamic(
        map['finishTaskSound'],
        fallbackId: 'default_chime_finish',
      ),
      isDefault: isDefault,
      createdAt: createdAt,
      updatedAt: updatedAt.isBefore(createdAt) ? createdAt : updatedAt,
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }
    return null;
  }

  static int _readInt(Map<String, dynamic> map, String key, int fallback) {
    final value = map[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }
}
