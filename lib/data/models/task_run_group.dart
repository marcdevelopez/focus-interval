import 'package:cloud_firestore/cloud_firestore.dart';

import 'selected_sound.dart';
import 'schema_version.dart';

enum TaskRunStatus { scheduled, running, completed, canceled }

enum TaskRunIntegrityMode { shared, individual }

class TaskRunCanceledReason {
  static const String user = 'user';
  static const String conflict = 'conflict';
  static const String interrupted = 'interrupted';
  static const String missedSchedule = 'missedSchedule';
}

int _readInt(Map<String, dynamic> map, String key, int fallback) {
  final value = map[key];
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

TaskRunIntegrityMode _readIntegrityMode(Map<String, dynamic> map) {
  final raw = map['integrityMode'];
  if (raw is String && raw.isNotEmpty) {
    return TaskRunIntegrityMode.values.firstWhere(
      (mode) => mode.name == raw,
      orElse: () => TaskRunIntegrityMode.individual,
    );
  }
  return TaskRunIntegrityMode.individual;
}

class TaskRunItem {
  final String sourceTaskId;
  final String name;
  final String? presetId;
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
    this.presetId,
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
    'presetId': presetId,
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
    presetId: map['presetId'] as String?,
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
  final int dataVersion;
  final TaskRunIntegrityMode integrityMode;
  final List<TaskRunItem> tasks;
  final DateTime createdAt;
  final DateTime? scheduledStartTime;
  final String? scheduledByDeviceId;
  final String? postponedAfterGroupId;
  final DateTime? noticeSentAt;
  final String? noticeSentByDeviceId;
  final DateTime? actualStartTime;
  final DateTime theoreticalEndTime;
  final TaskRunStatus status;
  final String? canceledReason;
  final int? noticeMinutes;
  final int? totalTasks;
  final int? totalPomodoros;
  final int? totalDurationSeconds;
  final DateTime updatedAt;

  const TaskRunGroup({
    required this.id,
    required this.ownerUid,
    required this.dataVersion,
    required this.integrityMode,
    required this.tasks,
    required this.createdAt,
    required this.scheduledStartTime,
    this.scheduledByDeviceId,
    this.postponedAfterGroupId,
    this.noticeSentAt,
    this.noticeSentByDeviceId,
    required this.actualStartTime,
    required this.theoreticalEndTime,
    required this.status,
    this.canceledReason,
    required this.noticeMinutes,
    required this.totalTasks,
    required this.totalPomodoros,
    required this.totalDurationSeconds,
    required this.updatedAt,
  });

  TaskRunGroup copyWith({
    String? id,
    String? ownerUid,
    int? dataVersion,
    List<TaskRunItem>? tasks,
    DateTime? createdAt,
    DateTime? scheduledStartTime,
    String? scheduledByDeviceId,
    String? postponedAfterGroupId,
    DateTime? noticeSentAt,
    String? noticeSentByDeviceId,
    DateTime? actualStartTime,
    DateTime? theoreticalEndTime,
    TaskRunStatus? status,
    String? canceledReason,
    TaskRunIntegrityMode? integrityMode,
    int? noticeMinutes,
    int? totalTasks,
    int? totalPomodoros,
    int? totalDurationSeconds,
    DateTime? updatedAt,
  }) {
    return TaskRunGroup(
      id: id ?? this.id,
      ownerUid: ownerUid ?? this.ownerUid,
      dataVersion: dataVersion ?? this.dataVersion,
      integrityMode: integrityMode ?? this.integrityMode,
      tasks: tasks ?? this.tasks,
      createdAt: createdAt ?? this.createdAt,
      scheduledStartTime: scheduledStartTime ?? this.scheduledStartTime,
      scheduledByDeviceId: scheduledByDeviceId ?? this.scheduledByDeviceId,
      postponedAfterGroupId:
          postponedAfterGroupId ?? this.postponedAfterGroupId,
      noticeSentAt: noticeSentAt ?? this.noticeSentAt,
      noticeSentByDeviceId: noticeSentByDeviceId ?? this.noticeSentByDeviceId,
      actualStartTime: actualStartTime ?? this.actualStartTime,
      theoreticalEndTime: theoreticalEndTime ?? this.theoreticalEndTime,
      status: status ?? this.status,
      canceledReason: canceledReason ?? this.canceledReason,
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
    'dataVersion': dataVersion,
    'integrityMode': integrityMode.name,
    'tasks': tasks.map((task) => task.toMap()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'scheduledStartTime': scheduledStartTime?.toIso8601String(),
    'scheduledByDeviceId': scheduledByDeviceId,
    'postponedAfterGroupId': postponedAfterGroupId,
    'noticeSentAt': noticeSentAt?.toIso8601String(),
    'noticeSentByDeviceId': noticeSentByDeviceId,
    'actualStartTime': actualStartTime?.toIso8601String(),
    'theoreticalEndTime': theoreticalEndTime.toIso8601String(),
    'status': status.name,
    'canceledReason': canceledReason,
    'noticeMinutes': noticeMinutes,
    'totalTasks': totalTasks,
    'totalPomodoros': totalPomodoros,
    'totalDurationSeconds': totalDurationSeconds,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory TaskRunGroup.fromMap(Map<String, dynamic> map) {
    final tasks = _decodeTasks(map['tasks']);
    final integrityMode = _readIntegrityMode(map);
    final createdAt = _parseDateTime(map['createdAt']) ?? DateTime.now();
    final updatedAt = _parseDateTime(map['updatedAt']) ?? createdAt;
    final dataVersion = readDataVersion(map);
    final totalTasks = (map['totalTasks'] as num?)?.toInt() ?? tasks.length;
    final totalPomodoros =
        (map['totalPomodoros'] as num?)?.toInt() ??
        tasks.fold<int>(0, (total, item) => total + item.totalPomodoros);
    final computedTotalDurationSeconds = groupDurationSecondsByMode(
      tasks,
      integrityMode,
    );
    final storedTotalDurationSeconds = (map['totalDurationSeconds'] as num?)
        ?.toInt();
    final totalDurationSeconds = computedTotalDurationSeconds > 0
        ? computedTotalDurationSeconds
        : storedTotalDurationSeconds;

    return TaskRunGroup(
      id: map['id'] as String? ?? '',
      ownerUid: map['ownerUid'] as String? ?? '',
      dataVersion: dataVersion,
      integrityMode: integrityMode,
      tasks: tasks,
      createdAt: createdAt,
      scheduledStartTime: _parseDateTime(map['scheduledStartTime']),
      scheduledByDeviceId: map['scheduledByDeviceId'] as String?,
      postponedAfterGroupId: map['postponedAfterGroupId'] as String?,
      noticeSentAt: _parseDateTime(map['noticeSentAt']),
      noticeSentByDeviceId: map['noticeSentByDeviceId'] as String?,
      actualStartTime: _parseDateTime(map['actualStartTime']),
      theoreticalEndTime:
          _parseDateTime(map['theoreticalEndTime']) ?? createdAt,
      status: TaskRunStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => TaskRunStatus.scheduled,
      ),
      canceledReason: map['canceledReason'] as String?,
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

int groupDurationSecondsByMode(
  List<TaskRunItem> tasks,
  TaskRunIntegrityMode integrityMode,
) {
  if (tasks.isEmpty) return 0;
  if (integrityMode == TaskRunIntegrityMode.individual) {
    return groupDurationSecondsWithFinalBreaks(tasks);
  }
  final master = tasks.first;
  final pomodoroSeconds = master.pomodoroMinutes * 60;
  final shortBreakSeconds = master.shortBreakMinutes * 60;
  final longBreakSeconds = master.longBreakMinutes * 60;
  final totalPomodoros = tasks.fold<int>(
    0,
    (total, item) => total + item.totalPomodoros,
  );
  if (totalPomodoros <= 0) return 0;
  var total = totalPomodoros * pomodoroSeconds;
  for (var index = 1; index < totalPomodoros; index += 1) {
    final isLongBreak = index % master.longBreakInterval == 0;
    total += isLongBreak ? longBreakSeconds : shortBreakSeconds;
  }
  return total;
}

List<int> taskDurationSecondsByMode(
  List<TaskRunItem> tasks,
  TaskRunIntegrityMode integrityMode,
) {
  if (tasks.isEmpty) return const [];
  if (integrityMode == TaskRunIntegrityMode.individual) {
    return [
      for (var index = 0; index < tasks.length; index += 1)
        tasks[index].durationSeconds(
          includeFinalBreak: index < tasks.length - 1,
        ),
    ];
  }

  final master = tasks.first;
  final pomodoroSeconds = master.pomodoroMinutes * 60;
  final shortBreakSeconds = master.shortBreakMinutes * 60;
  final longBreakSeconds = master.longBreakMinutes * 60;
  final totalPomodoros = tasks.fold<int>(
    0,
    (total, item) => total + item.totalPomodoros,
  );
  if (totalPomodoros <= 0) {
    return List<int>.filled(tasks.length, 0);
  }

  final durations = <int>[];
  var globalIndex = 0;
  for (final task in tasks) {
    var taskTotal = 0;
    for (var localIndex = 0; localIndex < task.totalPomodoros; localIndex += 1) {
      globalIndex += 1;
      taskTotal += pomodoroSeconds;
      if (globalIndex >= totalPomodoros) {
        continue;
      }
      final isLongBreak = globalIndex % master.longBreakInterval == 0;
      taskTotal += isLongBreak ? longBreakSeconds : shortBreakSeconds;
    }
    durations.add(taskTotal);
  }
  return durations;
}
