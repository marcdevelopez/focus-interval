import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/pomodoro_machine.dart';
import 'schema_version.dart';

class PomodoroSession {
  final String taskId;
  final String? groupId;
  final String? currentTaskId;
  final int? currentTaskIndex;
  final int? totalTasks;
  final int dataVersion;
  final String ownerDeviceId;
  final PomodoroStatus status;
  final PomodoroPhase? phase;
  final int currentPomodoro;
  final int totalPomodoros;
  final int phaseDurationSeconds;
  final int remainingSeconds;
  final DateTime? phaseStartedAt;
  final DateTime? currentTaskStartedAt;
  final DateTime? pausedAt;
  final DateTime? lastUpdatedAt;
  final DateTime? finishedAt;
  final String? pauseReason;
  final OwnershipRequest? ownershipRequest;

  PomodoroSession({
    required this.taskId,
    this.groupId,
    this.currentTaskId,
    this.currentTaskIndex,
    this.totalTasks,
    required this.dataVersion,
    required this.ownerDeviceId,
    required this.status,
    required this.phase,
    required this.currentPomodoro,
    required this.totalPomodoros,
    required this.phaseDurationSeconds,
    required this.remainingSeconds,
    required this.phaseStartedAt,
    required this.currentTaskStartedAt,
    required this.pausedAt,
    required this.lastUpdatedAt,
    required this.finishedAt,
    required this.pauseReason,
    this.ownershipRequest,
  });

  Map<String, dynamic> toMap() => {
    'taskId': taskId,
    'groupId': groupId,
    'currentTaskId': currentTaskId,
    'currentTaskIndex': currentTaskIndex,
    'totalTasks': totalTasks,
    'dataVersion': dataVersion,
    'ownerDeviceId': ownerDeviceId,
    'status': status.name,
    'phase': phase?.name,
    'currentPomodoro': currentPomodoro,
    'totalPomodoros': totalPomodoros,
    'phaseDurationSeconds': phaseDurationSeconds,
    'remainingSeconds': remainingSeconds,
    'phaseStartedAt': phaseStartedAt,
    'currentTaskStartedAt': currentTaskStartedAt,
    'pausedAt': pausedAt,
    'lastUpdatedAt': lastUpdatedAt,
    'finishedAt': finishedAt,
    'pauseReason': pauseReason,
    if (ownershipRequest != null) 'ownershipRequest': ownershipRequest!.toMap(),
  };

  factory PomodoroSession.fromMap(Map<String, dynamic> map) {
    final statusRaw = map['status'] as String?;
    final phaseRaw = map['phase'] as String?;
    final dataVersion = readDataVersion(map);
    return PomodoroSession(
      taskId: map['taskId'] as String? ?? '',
      groupId: map['groupId'] as String?,
      currentTaskId: map['currentTaskId'] as String?,
      currentTaskIndex: _readInt(map, 'currentTaskIndex'),
      totalTasks: _readInt(map, 'totalTasks'),
      dataVersion: dataVersion,
      ownerDeviceId: map['ownerDeviceId'] as String? ?? '',
      status: PomodoroStatus.values.firstWhere(
        (e) => e.name == statusRaw,
        orElse: () => PomodoroStatus.idle,
      ),
      phase: phaseRaw == null
          ? null
          : PomodoroPhase.values.firstWhere(
              (e) => e.name == phaseRaw,
              orElse: () => PomodoroPhase.pomodoro,
            ),
      currentPomodoro: _readInt(map, 'currentPomodoro') ?? 0,
      totalPomodoros: _readInt(map, 'totalPomodoros') ?? 0,
      phaseDurationSeconds: _readInt(map, 'phaseDurationSeconds') ?? 0,
      remainingSeconds: _readInt(map, 'remainingSeconds') ?? 0,
      phaseStartedAt: _readDateTime(map['phaseStartedAt']),
      currentTaskStartedAt: _readDateTime(map['currentTaskStartedAt']),
      pausedAt: _readDateTime(map['pausedAt']),
      lastUpdatedAt: _readDateTime(map['lastUpdatedAt']),
      finishedAt: _readDateTime(map['finishedAt']),
      pauseReason: map['pauseReason'] as String?,
      ownershipRequest: OwnershipRequest.fromMap(
        map['ownershipRequest'] as Map<String, dynamic>?,
      ),
    );
  }

  static DateTime? _readDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  static int? _readInt(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}

enum OwnershipRequestStatus { pending, rejected }

class OwnershipRequest {
  final String? requestId;
  final String requesterDeviceId;
  final OwnershipRequestStatus status;
  final DateTime? requestedAt;
  final DateTime? respondedAt;
  final String? respondedByDeviceId;

  const OwnershipRequest({
    required this.requestId,
    required this.requesterDeviceId,
    required this.status,
    required this.requestedAt,
    required this.respondedAt,
    required this.respondedByDeviceId,
  });

  Map<String, dynamic> toMap() => {
    if (requestId != null) 'requestId': requestId,
    'requesterDeviceId': requesterDeviceId,
    'status': status.name,
    'requestedAt': requestedAt,
    'respondedAt': respondedAt,
    'respondedByDeviceId': respondedByDeviceId,
  };

  static OwnershipRequest? fromMap(Map<String, dynamic>? map) {
    if (map == null) return null;
    final statusRaw = map['status'] as String?;
    final status = OwnershipRequestStatus.values.firstWhere(
      (e) => e.name == statusRaw,
      orElse: () => OwnershipRequestStatus.pending,
    );
    return OwnershipRequest(
      requestId: map['requestId'] as String?,
      requesterDeviceId: map['requesterDeviceId'] as String? ?? '',
      status: status,
      requestedAt: _readDateTime(map['requestedAt']),
      respondedAt: _readDateTime(map['respondedAt']),
      respondedByDeviceId: map['respondedByDeviceId'] as String?,
    );
  }

  static DateTime? _readDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
