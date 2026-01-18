import 'package:cloud_firestore/cloud_firestore.dart';

import 'selected_sound.dart';

class PomodoroTask {
  final String id;
  final String name;

  final int pomodoroMinutes;
  final int shortBreakMinutes;
  final int longBreakMinutes;

  final int totalPomodoros;
  final int longBreakInterval;
  final int order;

  final SelectedSound startSound;
  final SelectedSound startBreakSound;
  final SelectedSound finishTaskSound;

  final DateTime createdAt;
  final DateTime updatedAt;

  PomodoroTask({
    required this.id,
    required this.name,
    required this.pomodoroMinutes,
    required this.shortBreakMinutes,
    required this.longBreakMinutes,
    required this.totalPomodoros,
    required this.longBreakInterval,
    required this.order,
    required this.startSound,
    required this.startBreakSound,
    required this.finishTaskSound,
    required this.createdAt,
    required this.updatedAt,
  });

  PomodoroTask copyWith({
    String? id,
    String? name,
    int? pomodoroMinutes,
    int? shortBreakMinutes,
    int? longBreakMinutes,
    int? totalPomodoros,
    int? longBreakInterval,
    int? order,
    SelectedSound? startSound,
    SelectedSound? startBreakSound,
    SelectedSound? finishTaskSound,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PomodoroTask(
      id: id ?? this.id,
      name: name ?? this.name,
      pomodoroMinutes: pomodoroMinutes ?? this.pomodoroMinutes,
      shortBreakMinutes: shortBreakMinutes ?? this.shortBreakMinutes,
      longBreakMinutes: longBreakMinutes ?? this.longBreakMinutes,
      totalPomodoros: totalPomodoros ?? this.totalPomodoros,
      longBreakInterval: longBreakInterval ?? this.longBreakInterval,
      order: order ?? this.order,
      startSound: startSound ?? this.startSound,
      startBreakSound: startBreakSound ?? this.startBreakSound,
      finishTaskSound: finishTaskSound ?? this.finishTaskSound,
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
    'totalPomodoros': totalPomodoros,
    'longBreakInterval': longBreakInterval,
    'order': order,
    'startSound': startSound.toMap(),
    'startBreakSound': startBreakSound.toMap(),
    'finishTaskSound': finishTaskSound.toMap(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory PomodoroTask.fromMap(Map<String, dynamic> map) {
    final now = DateTime.now();
    final createdAt = _parseDateTime(map['createdAt']) ?? now;
    final updatedAt = _parseDateTime(map['updatedAt']) ?? createdAt;
    final order =
        (map['order'] as num?)?.toInt() ?? createdAt.millisecondsSinceEpoch;

    return PomodoroTask(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      pomodoroMinutes: map['pomodoroMinutes'] as int,
      shortBreakMinutes: map['shortBreakMinutes'] as int,
      longBreakMinutes: map['longBreakMinutes'] as int,
      totalPomodoros: map['totalPomodoros'] as int,
      longBreakInterval: map['longBreakInterval'] as int,
      order: order,
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
}
