import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/pomodoro_machine.dart';

class PomodoroSession {
  final String taskId;
  final String? groupId;
  final String? currentTaskId;
  final int? currentTaskIndex;
  final int? totalTasks;
  final String ownerDeviceId;
  final PomodoroStatus status;
  final PomodoroPhase? phase;
  final int currentPomodoro;
  final int totalPomodoros;
  final int phaseDurationSeconds;
  final int remainingSeconds;
  final DateTime? phaseStartedAt;
  final DateTime? lastUpdatedAt;
  final DateTime? finishedAt;
  final String? pauseReason;

  PomodoroSession({
    required this.taskId,
    this.groupId,
    this.currentTaskId,
    this.currentTaskIndex,
    this.totalTasks,
    required this.ownerDeviceId,
    required this.status,
    required this.phase,
    required this.currentPomodoro,
    required this.totalPomodoros,
    required this.phaseDurationSeconds,
    required this.remainingSeconds,
    required this.phaseStartedAt,
    required this.lastUpdatedAt,
    required this.finishedAt,
    required this.pauseReason,
  });

  Map<String, dynamic> toMap() => {
    'taskId': taskId,
    'groupId': groupId,
    'currentTaskId': currentTaskId,
    'currentTaskIndex': currentTaskIndex,
    'totalTasks': totalTasks,
    'ownerDeviceId': ownerDeviceId,
    'status': status.name,
    'phase': phase?.name,
    'currentPomodoro': currentPomodoro,
    'totalPomodoros': totalPomodoros,
    'phaseDurationSeconds': phaseDurationSeconds,
    'remainingSeconds': remainingSeconds,
    'phaseStartedAt': phaseStartedAt,
    'lastUpdatedAt': lastUpdatedAt,
    'finishedAt': finishedAt,
    'pauseReason': pauseReason,
  };

  factory PomodoroSession.fromMap(Map<String, dynamic> map) => PomodoroSession(
    taskId: map['taskId'] as String,
    groupId: map['groupId'] as String?,
    currentTaskId: map['currentTaskId'] as String?,
    currentTaskIndex: (map['currentTaskIndex'] as num?)?.toInt(),
    totalTasks: (map['totalTasks'] as num?)?.toInt(),
    ownerDeviceId: map['ownerDeviceId'] as String,
    status: PomodoroStatus.values.firstWhere(
      (e) => e.name == map['status'] as String,
    ),
    phase: (map['phase'] as String?) == null
        ? null
        : PomodoroPhase.values.firstWhere(
            (e) => e.name == map['phase'] as String,
          ),
    currentPomodoro: (map['currentPomodoro'] as num).toInt(),
    totalPomodoros: (map['totalPomodoros'] as num).toInt(),
    phaseDurationSeconds: (map['phaseDurationSeconds'] as num).toInt(),
    remainingSeconds: (map['remainingSeconds'] as num).toInt(),
    phaseStartedAt: (map['phaseStartedAt'] as Timestamp?)?.toDate(),
    lastUpdatedAt: (map['lastUpdatedAt'] as Timestamp?)?.toDate(),
    finishedAt: (map['finishedAt'] as Timestamp?)?.toDate(),
    pauseReason: map['pauseReason'] as String?,
  );
}
