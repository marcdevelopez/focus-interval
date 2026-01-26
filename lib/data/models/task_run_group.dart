import 'package:cloud_firestore/cloud_firestore.dart';

import 'selected_sound.dart';

enum TaskRunStatus { scheduled, running, completed, canceled }

int _readInt(Map<String, dynamic> map, String key, int fallback) {
  final value = map[key];
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

class TaskRunItem {
  final String sourceTaskId;
  final String name;
  final int pomodoroMinutes;
  final int shortBreakMinutes;
  final int longBreakMinutes;
  final int totalPomodoros;
  final int longBreakInterval;
  final SelectedSound startSound;
  final SelectedSound startBreakSound;
  final SelectedSound finishTaskSound;

  const TaskRunItem({
    required this.sourceTaskId,
    required this.name,
    required this.pomodoroMinutes,
    required this.shortBreakMinutes,
    required this.longBreakMinutes,
    required this.totalPomodoros,
    required this.longBreakInterval,
    required this.startSound,
    required this.startBreakSound,
    required this.finishTaskSound,
  });

  Map<String, dynamic> toMap() => {
    'sourceTaskId': sourceTaskId,
    'name': name,
    'pomodoroMinutes': pomodoroMinutes,
    'shortBreakMinutes': shortBreakMinutes,
    'longBreakMinutes': longBreakMinutes,
    'totalPomodoros': totalPomodoros,
    'longBreakInterval': longBreakInterval,
    'startSound': startSound.toMap(),
    'startBreakSound': startBreakSound.toMap(),
    'finishTaskSound': finishTaskSound.toMap(),
  };

  factory TaskRunItem.fromMap(Map<String, dynamic> map) => TaskRunItem(
    sourceTaskId: map['sourceTaskId'] as String? ?? '',
    name: map['name'] as String? ?? '',
    pomodoroMinutes: _readInt(map, 'pomodoroMinutes', 25),
    shortBreakMinutes: _readInt(map, 'shortBreakMinutes', 5),
    longBreakMinutes: _readInt(map, 'longBreakMinutes', 15),
    totalPomodoros: _readInt(map, 'totalPomodoros', 4),
    longBreakInterval: _readInt(map, 'longBreakInterval', 4),
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
  );

  int get totalDurationSeconds {
    final pomodoroSeconds = pomodoroMinutes * 60;
    final shortBreakSeconds = shortBreakMinutes * 60;
    final longBreakSeconds = longBreakMinutes * 60;
    var total = totalPomodoros * pomodoroSeconds;
    if (totalPomodoros <= 1) return total;

    for (var index = 1; index < totalPomodoros; index += 1) {
      final isLongBreak = index % longBreakInterval == 0;
      total += isLongBreak ? longBreakSeconds : shortBreakSeconds;
    }
    return total;
  }

  int get finalBreakSeconds {
    final isLongBreak = totalPomodoros % longBreakInterval == 0;
    final breakMinutes = isLongBreak ? longBreakMinutes : shortBreakMinutes;
    return breakMinutes * 60;
  }

  int durationSeconds({required bool includeFinalBreak}) {
    if (!includeFinalBreak) return totalDurationSeconds;
    return totalDurationSeconds + finalBreakSeconds;
  }
}

class TaskRunGroup {
  final String id;
  final String ownerUid;
  final List<TaskRunItem> tasks;
  final DateTime createdAt;
  final DateTime? scheduledStartTime;
  final String? scheduledByDeviceId;
  final DateTime? noticeSentAt;
  final String? noticeSentByDeviceId;
  final DateTime? actualStartTime;
  final DateTime theoreticalEndTime;
  final TaskRunStatus status;
  final int? noticeMinutes;
  final int? totalTasks;
  final int? totalPomodoros;
  final int? totalDurationSeconds;
  final DateTime updatedAt;

  const TaskRunGroup({
    required this.id,
    required this.ownerUid,
    required this.tasks,
    required this.createdAt,
    required this.scheduledStartTime,
    this.scheduledByDeviceId,
    this.noticeSentAt,
    this.noticeSentByDeviceId,
    required this.actualStartTime,
    required this.theoreticalEndTime,
    required this.status,
    required this.noticeMinutes,
    required this.totalTasks,
    required this.totalPomodoros,
    required this.totalDurationSeconds,
    required this.updatedAt,
  });

  TaskRunGroup copyWith({
    String? id,
    String? ownerUid,
    List<TaskRunItem>? tasks,
    DateTime? createdAt,
    DateTime? scheduledStartTime,
    String? scheduledByDeviceId,
    DateTime? noticeSentAt,
    String? noticeSentByDeviceId,
    DateTime? actualStartTime,
    DateTime? theoreticalEndTime,
    TaskRunStatus? status,
    int? noticeMinutes,
    int? totalTasks,
    int? totalPomodoros,
    int? totalDurationSeconds,
    DateTime? updatedAt,
  }) {
    return TaskRunGroup(
      id: id ?? this.id,
      ownerUid: ownerUid ?? this.ownerUid,
      tasks: tasks ?? this.tasks,
      createdAt: createdAt ?? this.createdAt,
      scheduledStartTime: scheduledStartTime ?? this.scheduledStartTime,
      scheduledByDeviceId: scheduledByDeviceId ?? this.scheduledByDeviceId,
      noticeSentAt: noticeSentAt ?? this.noticeSentAt,
      noticeSentByDeviceId: noticeSentByDeviceId ?? this.noticeSentByDeviceId,
      actualStartTime: actualStartTime ?? this.actualStartTime,
      theoreticalEndTime: theoreticalEndTime ?? this.theoreticalEndTime,
      status: status ?? this.status,
      noticeMinutes: noticeMinutes ?? this.noticeMinutes,
      totalTasks: totalTasks ?? this.totalTasks,
      totalPomodoros: totalPomodoros ?? this.totalPomodoros,
      totalDurationSeconds: totalDurationSeconds ?? this.totalDurationSeconds,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'ownerUid': ownerUid,
    'tasks': tasks.map((task) => task.toMap()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'scheduledStartTime': scheduledStartTime?.toIso8601String(),
    'scheduledByDeviceId': scheduledByDeviceId,
    'noticeSentAt': noticeSentAt?.toIso8601String(),
    'noticeSentByDeviceId': noticeSentByDeviceId,
    'actualStartTime': actualStartTime?.toIso8601String(),
    'theoreticalEndTime': theoreticalEndTime.toIso8601String(),
    'status': status.name,
    'noticeMinutes': noticeMinutes,
    'totalTasks': totalTasks,
    'totalPomodoros': totalPomodoros,
    'totalDurationSeconds': totalDurationSeconds,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory TaskRunGroup.fromMap(Map<String, dynamic> map) {
    final tasks = _decodeTasks(map['tasks']);
    final createdAt = _parseDateTime(map['createdAt']) ?? DateTime.now();
    final updatedAt = _parseDateTime(map['updatedAt']) ?? createdAt;
    final totalTasks = (map['totalTasks'] as num?)?.toInt() ?? tasks.length;
    final totalPomodoros =
        (map['totalPomodoros'] as num?)?.toInt() ??
        tasks.fold<int>(0, (total, item) => total + item.totalPomodoros);
    final computedTotalDurationSeconds = groupDurationSecondsWithFinalBreaks(
      tasks,
    );
    final storedTotalDurationSeconds = (map['totalDurationSeconds'] as num?)
        ?.toInt();
    final totalDurationSeconds = computedTotalDurationSeconds > 0
        ? computedTotalDurationSeconds
        : storedTotalDurationSeconds;

    return TaskRunGroup(
      id: map['id'] as String? ?? '',
      ownerUid: map['ownerUid'] as String? ?? '',
      tasks: tasks,
      createdAt: createdAt,
      scheduledStartTime: _parseDateTime(map['scheduledStartTime']),
      scheduledByDeviceId: map['scheduledByDeviceId'] as String?,
      noticeSentAt: _parseDateTime(map['noticeSentAt']),
      noticeSentByDeviceId: map['noticeSentByDeviceId'] as String?,
      actualStartTime: _parseDateTime(map['actualStartTime']),
      theoreticalEndTime:
          _parseDateTime(map['theoreticalEndTime']) ?? createdAt,
      status: TaskRunStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => TaskRunStatus.scheduled,
      ),
      noticeMinutes: (map['noticeMinutes'] as num?)?.toInt(),
      totalTasks: totalTasks,
      totalPomodoros: totalPomodoros,
      totalDurationSeconds: totalDurationSeconds,
      updatedAt: updatedAt.isBefore(createdAt) ? createdAt : updatedAt,
    );
  }

  static List<TaskRunItem> _decodeTasks(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((entry) => TaskRunItem.fromMap(Map<String, dynamic>.from(entry)))
        .toList();
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

int groupDurationSecondsWithFinalBreaks(List<TaskRunItem> tasks) {
  var total = 0;
  for (var index = 0; index < tasks.length; index += 1) {
    total += tasks[index].durationSeconds(
      includeFinalBreak: index < tasks.length - 1,
    );
  }
  return total;
}
