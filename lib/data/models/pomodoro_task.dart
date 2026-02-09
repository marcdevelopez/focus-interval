import 'package:cloud_firestore/cloud_firestore.dart';

import 'selected_sound.dart';
import 'schema_migrations.dart';
import 'schema_version.dart';

class PomodoroTask {
  static const Object _unset = Object();
  final String id;
  final String name;
  final int dataVersion;

  final int pomodoroMinutes;
  final int shortBreakMinutes;
  final int longBreakMinutes;

  final int totalPomodoros;
  final int longBreakInterval;
  final int order;
  final String? presetId;

  final SelectedSound startSound;
  final SelectedSound startBreakSound;
  final SelectedSound finishTaskSound;

  final DateTime createdAt;
  final DateTime updatedAt;

  PomodoroTask({
    required this.id,
    required this.name,
    required this.dataVersion,
    required this.pomodoroMinutes,
    required this.shortBreakMinutes,
    required this.longBreakMinutes,
    required this.totalPomodoros,
    required this.longBreakInterval,
    required this.order,
    this.presetId,
    required this.startSound,
    required this.startBreakSound,
    required this.finishTaskSound,
    required this.createdAt,
    required this.updatedAt,
  });

  PomodoroTask copyWith({
    String? id,
    String? name,
    int? dataVersion,
    int? pomodoroMinutes,
    int? shortBreakMinutes,
    int? longBreakMinutes,
    int? totalPomodoros,
    int? longBreakInterval,
    int? order,
    Object? presetId = _unset,
    SelectedSound? startSound,
    SelectedSound? startBreakSound,
    SelectedSound? finishTaskSound,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PomodoroTask(
      id: id ?? this.id,
      name: name ?? this.name,
      dataVersion: dataVersion ?? this.dataVersion,
      pomodoroMinutes: pomodoroMinutes ?? this.pomodoroMinutes,
      shortBreakMinutes: shortBreakMinutes ?? this.shortBreakMinutes,
      longBreakMinutes: longBreakMinutes ?? this.longBreakMinutes,
      totalPomodoros: totalPomodoros ?? this.totalPomodoros,
      longBreakInterval: longBreakInterval ?? this.longBreakInterval,
      order: order ?? this.order,
      presetId: identical(presetId, _unset) ? this.presetId : presetId as String?,
      startSound: startSound ?? this.startSound,
      startBreakSound: startBreakSound ?? this.startBreakSound,
      finishTaskSound: finishTaskSound ?? this.finishTaskSound,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'id': id,
      'name': name,
      'dataVersion': dataVersion,
      'totalPomodoros': totalPomodoros,
      'longBreakInterval': longBreakInterval,
      'order': order,
      'presetId': presetId,
      'startSound': startSound.toMap(),
      'startBreakSound': startBreakSound.toMap(),
      'finishTaskSound': finishTaskSound.toMap(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
    writeIntWithLegacy(
      map,
      'pomodoroMinutes',
      pomodoroMinutes,
      legacyKeys: const ['pomodoroDuration'],
    );
    writeIntWithLegacy(
      map,
      'shortBreakMinutes',
      shortBreakMinutes,
      legacyKeys: const ['shortBreakDuration'],
    );
    writeIntWithLegacy(
      map,
      'longBreakMinutes',
      longBreakMinutes,
      legacyKeys: const ['longBreakDuration'],
    );
    return map;
  }

  factory PomodoroTask.fromMap(Map<String, dynamic> map) {
    final now = DateTime.now();
    final createdAt = _parseDateTime(map['createdAt']) ?? now;
    final updatedAt = _parseDateTime(map['updatedAt']) ?? createdAt;
    final order =
        (map['order'] as num?)?.toInt() ?? createdAt.millisecondsSinceEpoch;
    final dataVersion = readDataVersion(map);
    final pomodoroMinutes = readIntWithLegacy(
      map,
      'pomodoroMinutes',
      legacyKeys: const ['pomodoroDuration'],
      fallback: 25,
    );
    final shortBreakMinutes = readIntWithLegacy(
      map,
      'shortBreakMinutes',
      legacyKeys: const ['shortBreakDuration'],
      fallback: 5,
    );
    final longBreakMinutes = readIntWithLegacy(
      map,
      'longBreakMinutes',
      legacyKeys: const ['longBreakDuration'],
      fallback: 15,
    );
    final totalPomodoros = _readInt(map, 'totalPomodoros', 4);
    final longBreakInterval = _readInt(map, 'longBreakInterval', 4);
    final rawPresetId = map['presetId'];
    final presetId = rawPresetId is String ? rawPresetId : null;

    return PomodoroTask(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      dataVersion: dataVersion,
      pomodoroMinutes: pomodoroMinutes,
      shortBreakMinutes: shortBreakMinutes,
      longBreakMinutes: longBreakMinutes,
      totalPomodoros: totalPomodoros,
      longBreakInterval: longBreakInterval,
      order: order,
      presetId: presetId?.trim().isEmpty ?? true ? null : presetId,
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
