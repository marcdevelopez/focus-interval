import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/task_run_group.dart';
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
    await _pruneScheduledNotices(groups);

    if (groups.isEmpty) return;

    final running = groups.where((g) => g.status == TaskRunStatus.running);
    if (running.isNotEmpty) {
      final activeSession = ref.read(activePomodoroSessionProvider);
      if (activeSession == null) {
        final sorted = running.toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        final groupId = sorted.first.id;
        ref.read(scheduledAutoStartGroupIdProvider.notifier).state = groupId;
        _emitOpenTimer(groupId);
        return;
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
    await _sendPreAlertIfNeeded(group, preAlertStart, noticeMinutes);
    _emitOpenTimer(group.id);
  }

  Future<void> _sendPreAlertIfNeeded(
    TaskRunGroup group,
    DateTime preAlertStart,
    int noticeMinutes,
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

    final name = updated.tasks.isNotEmpty
        ? updated.tasks.first.name
        : 'Task group';
    final scheduledStart =
        updated.scheduledStartTime ?? group.scheduledStartTime;
    final remainingSeconds = scheduledStart != null
        ? scheduledStart.difference(now).inSeconds
        : noticeMinutes * 60;
    final clampedRemaining = remainingSeconds < 0 ? 0 : remainingSeconds;
    await ref.read(notificationServiceProvider).notifyGroupPreAlert(
          groupName: name,
          remainingSeconds: clampedRemaining,
        );
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
          groupDurationSecondsWithFinalBreaks(latest.tasks);

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
