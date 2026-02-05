import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/pomodoro_session.dart';
import '../../data/models/task_run_group.dart';
import '../../domain/pomodoro_machine.dart';
import '../providers.dart';

final scheduledGroupCoordinatorProvider =
    NotifierProvider<ScheduledGroupCoordinator, ScheduledGroupAction?>(
      ScheduledGroupCoordinator.new,
    );

class ScheduledGroupAction {
  final String groupId;
  final int token;

  const ScheduledGroupAction.openTimer({
    required this.groupId,
    required this.token,
  });
}

class ScheduledGroupCoordinator extends Notifier<ScheduledGroupAction?> {
  static const Duration _ownerGrace = Duration(seconds: 10);

  Timer? _scheduledTimer;
  Timer? _preAlertTimer;
  Timer? _runningExpiryTimer;
  bool _autoStartInFlight = false;
  bool _initialized = false;
  bool _disposed = false;
  final Map<String, DateTime> _scheduledNotices = {};
  List<TaskRunGroup> _lastGroups = const [];

  @override
  ScheduledGroupAction? build() {
    _init();
    return null;
  }

  void _init() {
    if (_initialized) return;
    _initialized = true;
    ref.onDispose(_dispose);
    ref.listen<AsyncValue<List<TaskRunGroup>>>(taskRunGroupStreamProvider, (
      _,
      next,
    ) {
      final groups = next.value ?? const [];
      _handleGroups(groups);
    });
    ref.listen<PomodoroSession?>(activePomodoroSessionProvider, (previous, next) {
      final wasActive = previous != null;
      final isActive = next != null;
      if (wasActive && !isActive) {
        _handleGroups(_lastGroups);
      }
    });
    final initial = ref.read(taskRunGroupStreamProvider).value ?? const [];
    _handleGroups(initial);
  }

  void onAppResumed() {
    _handleGroups(_lastGroups);
  }

  void clearAction() {
    if (state != null) state = null;
  }

  void _dispose() {
    _disposed = true;
    _scheduledTimer?.cancel();
    _preAlertTimer?.cancel();
    _runningExpiryTimer?.cancel();
    _scheduledNotices.clear();
  }

  void _emitOpenTimer(String groupId) {
    state = ScheduledGroupAction.openTimer(
      groupId: groupId,
      token: DateTime.now().microsecondsSinceEpoch,
    );
  }

  void _handleGroups(List<TaskRunGroup> groups) {
    _lastGroups = groups;
    if (_autoStartInFlight || _disposed) return;
    unawaited(_handleGroupsAsync(groups));
  }

  Future<void> _handleGroupsAsync(List<TaskRunGroup> groups) async {
    if (_autoStartInFlight || _disposed) return;

    final deviceId = ref.read(deviceInfoServiceProvider).deviceId;

    _scheduledTimer?.cancel();
    _scheduledTimer = null;
    _preAlertTimer?.cancel();
    _preAlertTimer = null;
    _runningExpiryTimer?.cancel();
    _runningExpiryTimer = null;
    await _pruneScheduledNotices(groups);

    if (groups.isEmpty) return;

    final running =
        groups.where((g) => g.status == TaskRunStatus.running).toList();
    if (running.isNotEmpty) {
      final activeSession = ref.read(activePomodoroSessionProvider);
      final activeGroupId = activeSession?.groupId;
      final now = DateTime.now();
      var expired = _resolveExpiredRunningGroups(running, now);
      if (activeSession != null &&
          activeSession.ownerDeviceId != deviceId &&
          activeGroupId != null) {
        expired = expired
            .where((group) => group.id != activeGroupId)
            .toList();
      }
      if (activeSession?.status == PomodoroStatus.paused &&
          activeGroupId != null) {
        expired = expired
            .where((group) => group.id != activeGroupId)
            .toList();
      }
      if (expired.isNotEmpty) {
        await _markRunningGroupsCompleted(expired, now);
      }
      if (activeSession == null) {
        final remaining = running.where((g) => !expired.contains(g)).toList();
        if (remaining.isNotEmpty) {
          final sorted = remaining
            ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          final groupId = sorted.first.id;
          ref.read(scheduledAutoStartGroupIdProvider.notifier).state = groupId;
          _emitOpenTimer(groupId);
          return;
        }
      } else {
        _scheduleRunningExpiryCheck(running, now);
        final activeGroupId = activeSession.groupId;
        final isActiveExpired =
            activeGroupId != null &&
            expired.any((group) => group.id == activeGroupId);
        final isLocalOwner = activeSession.ownerDeviceId == deviceId;
        if (isActiveExpired &&
            isLocalOwner &&
            activeSession.status.isRunning) {
          await ref.read(pomodoroSessionRepositoryProvider).clearSession();
        }
      }
      debugPrint('Scheduled auto-start suppressed (running group active).');
      return;
    }

    final scheduled =
        groups
            .where(
              (g) =>
                  g.status == TaskRunStatus.scheduled &&
                  g.scheduledStartTime != null,
            )
            .toList()
          ..sort(
            (a, b) => a.scheduledStartTime!.compareTo(b.scheduledStartTime!),
          );

    if (scheduled.isEmpty) return;

    final nextGroup = scheduled.first;
    final now = DateTime.now();
    final startTime = nextGroup.scheduledStartTime!;
    final noticeMinutes = await _resolveNoticeMinutes(nextGroup);
    await _schedulePreAlert(nextGroup, noticeMinutes);
    if (!startTime.isAfter(now)) {
      final scheduledBy = nextGroup.scheduledByDeviceId;
      if (scheduledBy != null && scheduledBy != deviceId) {
        final graceUntil = startTime.add(_ownerGrace);
        if (now.isBefore(graceUntil)) {
          final delay = graceUntil.difference(now);
          _scheduledTimer = Timer(delay, () {
            if (_disposed) return;
            _handleGroups(_lastGroups);
          });
          return;
        }
      }
      unawaited(_autoStartGroup(nextGroup.id));
      return;
    }

    final delay = startTime.difference(now);
    _scheduledTimer = Timer(delay, () {
      if (_disposed) return;
      _handleGroups(_lastGroups);
    });
  }

  Future<int> _resolveNoticeMinutes(TaskRunGroup group) async {
    final explicit = group.noticeMinutes;
    if (explicit != null) return explicit;
    return ref.read(taskRunNoticeServiceProvider).getNoticeMinutes();
  }

  List<TaskRunGroup> _resolveExpiredRunningGroups(
    Iterable<TaskRunGroup> running,
    DateTime now,
  ) {
    final expired = <TaskRunGroup>[];
    for (final group in running) {
      final endTime = _resolveTheoreticalEndTime(group);
      if (endTime != null && !endTime.isAfter(now)) {
        expired.add(group);
      }
    }
    return expired;
  }

  DateTime? _resolveTheoreticalEndTime(TaskRunGroup group) {
    final start = group.actualStartTime;
    if (start == null) return null;
    final end = group.theoreticalEndTime;
    if (end.isBefore(start)) {
      final totalSeconds =
          group.totalDurationSeconds ??
          groupDurationSecondsByMode(group.tasks, group.integrityMode);
      if (totalSeconds > 0) {
        return start.add(Duration(seconds: totalSeconds));
      }
    }
    return end;
  }

  Future<void> _markRunningGroupsCompleted(
    List<TaskRunGroup> groups,
    DateTime now,
  ) async {
    if (groups.isEmpty) return;
    final repo = ref.read(taskRunGroupRepositoryProvider);
    for (final group in groups) {
      final latest = await repo.getById(group.id) ?? group;
      if (latest.status != TaskRunStatus.running) continue;
      final endTime = _resolveTheoreticalEndTime(latest);
      if (endTime == null || endTime.isAfter(now)) continue;
      final updated = latest.copyWith(
        status: TaskRunStatus.completed,
        updatedAt: now,
      );
      await repo.save(updated);
    }
  }

  Future<void> _schedulePreAlert(TaskRunGroup group, int noticeMinutes) async {
    if (noticeMinutes <= 0) return;
    final startTime = group.scheduledStartTime;
    if (startTime == null) return;
    final now = DateTime.now();
    if (!now.isBefore(startTime)) return;

    final preAlertStart = startTime.subtract(Duration(minutes: noticeMinutes));
    if (now.isBefore(preAlertStart)) {
      await _scheduleLocalPreAlert(
        group: group,
        preAlertStart: preAlertStart,
        noticeMinutes: noticeMinutes,
      );
      final delay = preAlertStart.difference(now);
      _preAlertTimer = Timer(delay, () {
        if (_disposed) return;
        _handleGroups(_lastGroups);
      });
      return;
    }

    await _cancelLocalPreAlert(group.id);
    await _markPreAlertSentIfNeeded(group, preAlertStart);
    _emitOpenTimer(group.id);
  }

  void _scheduleRunningExpiryCheck(
    List<TaskRunGroup> running,
    DateTime now,
  ) {
    DateTime? nextEnd;
    for (final group in running) {
      final endTime = _resolveTheoreticalEndTime(group);
      if (endTime == null || !endTime.isAfter(now)) continue;
      if (nextEnd == null || endTime.isBefore(nextEnd)) {
        nextEnd = endTime;
      }
    }
    if (nextEnd == null) return;
    final delay = nextEnd.difference(now);
    _runningExpiryTimer = Timer(delay, () {
      if (_disposed) return;
      _handleGroups(_lastGroups);
    });
  }

  Future<void> _markPreAlertSentIfNeeded(
    TaskRunGroup group,
    DateTime preAlertStart,
  ) async {
    final groupRepo = ref.read(taskRunGroupRepositoryProvider);
    final latest = await groupRepo.getById(group.id) ?? group;
    if (latest.status != TaskRunStatus.scheduled) return;
    final sentAt = latest.noticeSentAt;
    if (sentAt != null && sentAt.isAfter(preAlertStart)) {
      return;
    }
    final now = DateTime.now();
    final deviceId = ref.read(deviceInfoServiceProvider).deviceId;
    final updated = latest.copyWith(
      noticeSentAt: now,
      noticeSentByDeviceId: deviceId,
      updatedAt: now,
    );
    await groupRepo.save(updated);
  }

  Future<void> _autoStartGroup(String groupId) async {
    if (_autoStartInFlight || _disposed) return;
    _autoStartInFlight = true;
    try {
      final deviceId = ref.read(deviceInfoServiceProvider).deviceId;
      final groupRepo = ref.read(taskRunGroupRepositoryProvider);
      final latest = await groupRepo.getById(groupId);
      if (latest == null) return;
      if (latest.status != TaskRunStatus.scheduled) return;
      final scheduledStart = latest.scheduledStartTime;
      if (scheduledStart == null) return;

      final now = DateTime.now();
      if (scheduledStart.isAfter(now)) return;
      final scheduledBy = latest.scheduledByDeviceId;
      if (scheduledBy != null && scheduledBy != deviceId) {
        final graceUntil = scheduledStart.add(_ownerGrace);
        if (now.isBefore(graceUntil)) return;
      }

      final totalSeconds =
          latest.totalDurationSeconds ??
          groupDurationSecondsByMode(latest.tasks, latest.integrityMode);

      final updated = latest.copyWith(
        status: TaskRunStatus.running,
        actualStartTime: now,
        theoreticalEndTime: now.add(Duration(seconds: totalSeconds)),
        updatedAt: now,
      );
      await groupRepo.save(updated);

      ref.read(scheduledAutoStartGroupIdProvider.notifier).state = groupId;
      await _cancelLocalPreAlert(groupId);
      _emitOpenTimer(groupId);
    } catch (e) {
      debugPrint('Scheduled auto-start failed: $e');
    } finally {
      _autoStartInFlight = false;
    }
  }

  Future<void> _scheduleLocalPreAlert({
    required TaskRunGroup group,
    required DateTime preAlertStart,
    required int noticeMinutes,
  }) async {
    final scheduledBy = group.scheduledByDeviceId;
    if (scheduledBy != null) {
      final deviceId = ref.read(deviceInfoServiceProvider).deviceId;
      if (scheduledBy != deviceId) return;
    }
    final lastScheduled = _scheduledNotices[group.id];
    if (lastScheduled != null && lastScheduled == preAlertStart) {
      return;
    }
    final name = group.tasks.isNotEmpty ? group.tasks.first.name : 'Task group';
    final ok = await ref
        .read(notificationServiceProvider)
        .scheduleGroupPreAlert(
          groupId: group.id,
          groupName: name,
          scheduledFor: preAlertStart,
          remainingSeconds: noticeMinutes * 60,
        );
    if (ok) {
      _scheduledNotices[group.id] = preAlertStart;
    }
  }

  Future<void> _cancelLocalPreAlert(String groupId) async {
    if (!_scheduledNotices.containsKey(groupId)) return;
    await ref.read(notificationServiceProvider).cancelGroupPreAlert(groupId);
    _scheduledNotices.remove(groupId);
  }

  Future<void> _pruneScheduledNotices(List<TaskRunGroup> groups) async {
    if (_scheduledNotices.isEmpty) return;
    final scheduledIds = groups
        .where(
          (g) => g.status == TaskRunStatus.scheduled && g.scheduledStartTime != null,
        )
        .map((g) => g.id)
        .toSet();
    final now = DateTime.now();
    final toRemove = <String>[];
    for (final entry in _scheduledNotices.entries) {
      if (!scheduledIds.contains(entry.key)) {
        toRemove.add(entry.key);
        continue;
      }
      if (!entry.value.isAfter(now)) {
        toRemove.add(entry.key);
      }
    }
    for (final groupId in toRemove) {
      await ref.read(notificationServiceProvider).cancelGroupPreAlert(groupId);
      _scheduledNotices.remove(groupId);
    }
  }
}
