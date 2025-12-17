import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/pomodoro_machine.dart';

class PomodoroSession {
  final String taskId;
  final String ownerDeviceId;
  final PomodoroStatus status;
  final PomodoroPhase? phase;
  final int currentPomodoro;
  final int totalPomodoros;
  final int phaseDurationSeconds;
  final int remainingSeconds;
  final DateTime? phaseStartedAt;
  final DateTime? lastUpdatedAt;

  PomodoroSession({
    required this.taskId,
    required this.ownerDeviceId,
    required this.status,
    required this.phase,
    required this.currentPomodoro,
    required this.totalPomodoros,
    required this.phaseDurationSeconds,
    required this.remainingSeconds,
    required this.phaseStartedAt,
    required this.lastUpdatedAt,
  });

  Map<String, dynamic> toMap() => {
        'taskId': taskId,
        'ownerDeviceId': ownerDeviceId,
        'status': status.name,
        'phase': phase?.name,
        'currentPomodoro': currentPomodoro,
        'totalPomodoros': totalPomodoros,
        'phaseDurationSeconds': phaseDurationSeconds,
        'remainingSeconds': remainingSeconds,
        'phaseStartedAt': phaseStartedAt,
        'lastUpdatedAt': lastUpdatedAt,
      };

  factory PomodoroSession.fromMap(Map<String, dynamic> map) => PomodoroSession(
        taskId: map['taskId'] as String,
        ownerDeviceId: map['ownerDeviceId'] as String,
        status: PomodoroStatus.values
            .firstWhere((e) => e.name == map['status'] as String),
        phase: (map['phase'] as String?) == null
            ? null
            : PomodoroPhase.values
                .firstWhere((e) => e.name == map['phase'] as String),
        currentPomodoro: (map['currentPomodoro'] as num).toInt(),
        totalPomodoros: (map['totalPomodoros'] as num).toInt(),
        phaseDurationSeconds: (map['phaseDurationSeconds'] as num).toInt(),
        remainingSeconds: (map['remainingSeconds'] as num).toInt(),
        phaseStartedAt: (map['phaseStartedAt'] as Timestamp?)?.toDate(),
        lastUpdatedAt: (map['lastUpdatedAt'] as Timestamp?)?.toDate(),
      );
}
