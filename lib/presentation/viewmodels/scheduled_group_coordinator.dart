import 'dart:async';

import 'package:flutter/foundation.dart'
    show debugPrint, kDebugMode, visibleForTesting;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/pomodoro_session.dart';
import '../../data/models/task_run_group.dart';
import '../../domain/pomodoro_machine.dart';
import '../providers.dart';
import '../utils/scheduled_group_timing.dart';

final scheduledGroupCoordinatorProvider =
    NotifierProvider<ScheduledGroupCoordinator, ScheduledGroupAction?>(
      ScheduledGroupCoordinator.new,
    );

enum ScheduledGroupActionType { openTimer, lateStartQueue }

class ScheduledGroupAction {
  final ScheduledGroupActionType type;
  final String? groupId;
  final List<String>? groupIds;
  final DateTime? anchor;
  final int token;

  const ScheduledGroupAction.openTimer({
    required this.groupId,
    required this.token,
  }) : type = ScheduledGroupActionType.openTimer,
       groupIds = null,
       anchor = null;

  const ScheduledGroupAction.lateStartQueue({
    required this.groupIds,
    required this.anchor,
    required this.token,
  }) : type = ScheduledGroupActionType.lateStartQueue,
       groupId = null;
}

class ScheduledGroupCoordinator extends Notifier<ScheduledGroupAction?> {
  static const Duration _staleSessionGrace = Duration(seconds: 45);

  Timer? _scheduledTimer;
  Timer? _preAlertTimer;
  Timer? _runningExpiryTimer;
  Timer? _runningOverlapTimer;
  bool _autoStartInFlight = false;
  bool _initialized = false;
  bool _disposed = false;
  bool _sessionStreamReady = false;
  String? _lastLateStartQueueKey;
  String? _lastRunningOverlapKey;
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
      final wasPaused = previous?.status == PomodoroStatus.paused;
      final isPaused = next?.status == PomodoroStatus.paused;
      final pausedAtChanged = previous?.pausedAt != next?.pausedAt;
      final heartbeatChanged =
          previous?.lastUpdatedAt != next?.lastUpdatedAt;
      if (isPaused && (!wasPaused || pausedAtChanged || heartbeatChanged)) {
        _handleGroups(_lastGroups);
      }
      if (wasActive && !isActive) {
        _handleGroups(_lastGroups);
      }
    });
    ref.listen<AsyncValue<PomodoroSession?>>(
      pomodoroSessionStreamProvider,
      (previous, next) {
        final wasReady = _sessionStreamReady;
        _sessionStreamReady = !next.isLoading;
        if (!wasReady && _sessionStreamReady) {
          _handleGroups(_lastGroups);
        }
      },
    );
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
    _runningOverlapTimer?.cancel();
    _scheduledNotices.clear();
  }

  void _emitOpenTimer(String groupId) {
    state = ScheduledGroupAction.openTimer(
      groupId: groupId,
      token: DateTime.now().microsecondsSinceEpoch,
    );
  }

  void _emitLateStartQueue(List<String> groupIds, DateTime anchor) {
    state = ScheduledGroupAction.lateStartQueue(
      groupIds: groupIds,
      anchor: anchor,
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
    _runningOverlapTimer?.cancel();
    _runningOverlapTimer = null;
    final now = DateTime.now();
    final session = ref.read(activePomodoroSessionProvider);
    await _pruneScheduledNotices(
      groups,
      activeSession: session,
      now: now,
    );
    final clearedStale = await _clearStaleActiveSessionIfNeeded(groups);
    if (clearedStale) {
      return;
    }

    if (groups.isEmpty) return;
    final finalized = await _finalizePostponedGroupsIfNeeded(
      groups: groups,
      activeSession: session,
      now: now,
    );
    if (finalized) {
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
          ..sort((a, b) {
            final aStart =
                resolveEffectiveScheduledStart(
                  group: a,
                  allGroups: groups,
                  activeSession: session,
                  now: now,
                ) ??
                a.scheduledStartTime!;
            final bStart =
                resolveEffectiveScheduledStart(
                  group: b,
                  allGroups: groups,
                  activeSession: session,
                  now: now,
                ) ??
                b.scheduledStartTime!;
            return aStart.compareTo(bStart);
          });
    final running =
        groups.where((g) => g.status == TaskRunStatus.running).toList();
    if (running.isNotEmpty) {
      _updateRunningOverlapDecision(
        running: running,
        scheduled: scheduled,
        allGroups: groups,
        session: session,
        now: now,
      );
      if (!_sessionStreamReady) {
        _debugLogExpiryDecision(
          reason: 'skip-expiry-session-loading',
          now: now,
          session: session,
        );
        return;
      }
      final activeSession = session;
      final activeGroupId = session?.groupId;
      var expired = <TaskRunGroup>[];
      TaskRunGroup? activeGroup;
      if (activeSession == null) {
        _debugLogExpiryDecision(
          reason: 'skip-expiry-no-active-session',
          now: now,
          session: null,
        );
      } else if (!activeSession.status.isRunning) {
        _debugLogExpiryDecision(
          reason: 'skip-expiry-session-not-running',
          now: now,
          session: activeSession,
        );
      } else if (activeGroupId == null) {
        _debugLogExpiryDecision(
          reason: 'skip-expiry-missing-group-id',
          now: now,
          session: activeSession,
        );
      } else {
        expired = _resolveExpiredRunningGroups(running, now)
            .where((group) => group.id == activeGroupId)
            .toList();
      }
      if (activeGroupId != null) {
        for (final group in running) {
          if (group.id == activeGroupId) {
            activeGroup = group;
            break;
          }
        }
      }
      final allowExpireActive = activeSession != null &&
          activeGroup != null &&
          _shouldExpireActiveSession(activeSession, activeGroup, now);
      if (!allowExpireActive) {
        expired = <TaskRunGroup>[];
      }
      if (expired.isNotEmpty) {
        _debugLogExpiryDecision(
          reason: 'expire-running-groups',
          now: now,
          session: activeSession,
          group: activeGroup,
          theoreticalEndTime: _resolveTheoreticalEndTime(activeGroup ?? expired.first),
        );
        await _markRunningGroupsCompleted(expired, now);
      }
      if (activeSession == null) {
        final remaining = running
            .where((g) => !expired.contains(g))
            .toList()
            ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        if (remaining.isNotEmpty) {
          final candidate = remaining.first;
          final groupId = candidate.id;
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
        final shouldClearActive = isActiveExpired &&
            activeSession.status.isRunning &&
            (isLocalOwner || _isSessionStale(activeSession, now));
        if (shouldClearActive) {
          final sessionRepo = ref.read(pomodoroSessionRepositoryProvider);
          if (isLocalOwner) {
            await sessionRepo.clearSessionAsOwner();
          } else {
            await sessionRepo.clearSessionIfStale(now: now);
          }
        }
      }
      debugPrint('Scheduled auto-start suppressed (running group active).');
      return;
    }
    _clearRunningOverlapDecisionIfNeeded();

    if (scheduled.isEmpty) {
      _lastLateStartQueueKey = null;
      return;
    }

    final lateStartConflicts = _resolveLateStartConflictSet(
      scheduled: scheduled,
      allGroups: groups,
      session: session,
      now: now,
    );
    if (lateStartConflicts.isNotEmpty) {
      final key = _lateStartQueueKey(lateStartConflicts);
      if (key != _lastLateStartQueueKey) {
        _lastLateStartQueueKey = key;
        _emitLateStartQueue(
          lateStartConflicts.map((g) => g.id).toList(),
          now,
        );
      }
      return;
    }
    _lastLateStartQueueKey = null;

    final nextGroup = scheduled.first;
    final startTime =
        resolveEffectiveScheduledStart(
          group: nextGroup,
          allGroups: groups,
          activeSession: session,
          now: now,
        ) ??
        nextGroup.scheduledStartTime!;
    final noticeMinutes = await _resolveNoticeMinutes(nextGroup);
    await _schedulePreAlert(
      nextGroup,
      noticeMinutes,
      scheduledStart: startTime,
      allGroups: groups,
      activeSession: session,
      now: now,
    );
    if (!startTime.isAfter(now)) {
      unawaited(_autoStartGroup(nextGroup.id));
      return;
    }

    final delay = startTime.difference(now);
    _scheduledTimer = Timer(delay, () {
      if (_disposed) return;
      _handleGroups(_lastGroups);
    });
  }

  void _debugLogExpiryDecision({
    required String reason,
    required DateTime now,
    PomodoroSession? session,
    TaskRunGroup? group,
    DateTime? theoreticalEndTime,
  }) {
    if (!kDebugMode) return;
    final updatedAt = session?.lastUpdatedAt;
    final isRunning = session?.status.isRunning ?? false;
    final isStale = updatedAt == null
        ? null
        : now.difference(updatedAt) >= _staleSessionGrace;
    final endDeltaSeconds = theoreticalEndTime?.difference(now).inSeconds;
    debugPrint(
      '[ExpiryCheck][$reason] now=$now '
      'groupId=${group?.id ?? 'n/a'} '
      'groupStatus=${group?.status.name ?? 'n/a'} '
      'theoreticalEndTime=${theoreticalEndTime ?? 'n/a'} '
      'endDeltaSeconds=${endDeltaSeconds ?? 'n/a'} '
      'sessionStatus=${session?.status.name ?? 'n/a'} '
      'sessionGroupId=${session?.groupId ?? 'n/a'} '
      'isRunning=$isRunning '
      'isStale=${isStale ?? 'n/a'} '
      'pausedAt=${session?.pausedAt ?? 'n/a'} '
      'phaseStartedAt=${session?.phaseStartedAt ?? 'n/a'} '
      'remainingSeconds=${session?.remainingSeconds ?? 'n/a'} '
      'lastUpdatedAt=${session?.lastUpdatedAt ?? 'n/a'} '
      'ownerDeviceId=${session?.ownerDeviceId ?? 'n/a'}',
    );
  }

  Future<bool> _clearStaleActiveSessionIfNeeded(
    List<TaskRunGroup> groups,
  ) async {
    final session = ref.read(activePomodoroSessionProvider);
    if (session == null) return false;
    final groupId = session.groupId;
    if (groupId == null || groupId.isEmpty) return false;

    TaskRunGroup? group;
    for (final candidate in groups) {
      if (candidate.id == groupId) {
        group = candidate;
        break;
      }
    }

    if (group == null) {
      final repo = ref.read(taskRunGroupRepositoryProvider);
      final latest = await repo.getById(groupId);
      if (latest == null || latest.status != TaskRunStatus.running) {
        await ref
            .read(pomodoroSessionRepositoryProvider)
            .clearSessionIfGroupNotRunning();
        return true;
      }
      return false;
    }

    if (group.status != TaskRunStatus.running) {
      await ref
          .read(pomodoroSessionRepositoryProvider)
          .clearSessionIfGroupNotRunning();
      return true;
    }

    return false;
  }

  Future<int> _resolveNoticeMinutes(TaskRunGroup group) async {
    final explicit = group.noticeMinutes;
    if (explicit != null) return explicit;
    return ref.read(taskRunNoticeServiceProvider).getNoticeMinutes();
  }

  void _updateRunningOverlapDecision({
    required List<TaskRunGroup> running,
    required List<TaskRunGroup> scheduled,
    required List<TaskRunGroup> allGroups,
    required PomodoroSession? session,
    required DateTime now,
  }) {
    if (running.isEmpty || scheduled.isEmpty) {
      _clearRunningOverlapDecisionIfNeeded();
      return;
    }
    final runningGroup = _resolveActiveRunningGroup(running, session);
    if (runningGroup == null) {
      _clearRunningOverlapDecisionIfNeeded();
      return;
    }
    final nextScheduled = scheduled.first;
    final scheduledStart =
        resolveEffectiveScheduledStart(
          group: nextScheduled,
          allGroups: allGroups,
          activeSession: session,
          now: now,
        ) ??
        nextScheduled.scheduledStartTime!;
    final noticeMinutes = resolveNoticeMinutes(nextScheduled);
    final preRunStart = noticeMinutes > 0
        ? scheduledStart.subtract(Duration(minutes: noticeMinutes))
        : scheduledStart;
    final runningEnd = resolveProjectedRunningEnd(
      runningGroup: runningGroup,
      activeSession: session,
      now: now,
    );
    if (runningEnd == null || !runningEnd.isAfter(preRunStart)) {
      _clearRunningOverlapDecisionIfNeeded();
      _scheduleRunningOverlapRecheck(
        runningGroup: runningGroup,
        runningEnd: runningEnd,
        preRunStart: preRunStart,
        session: session,
        now: now,
      );
      return;
    }
    final key = '${runningGroup.id}_${nextScheduled.id}';
    if (key == _lastRunningOverlapKey &&
        ref.read(runningOverlapDecisionProvider) != null) {
      return;
    }
    _lastRunningOverlapKey = key;
    ref.read(runningOverlapDecisionProvider.notifier).state =
        RunningOverlapDecision(
          runningGroupId: runningGroup.id,
          scheduledGroupId: nextScheduled.id,
          token: DateTime.now().microsecondsSinceEpoch,
        );
  }

  @visibleForTesting
  void debugEvaluateRunningOverlap({
    required List<TaskRunGroup> running,
    required List<TaskRunGroup> scheduled,
    required List<TaskRunGroup> allGroups,
    required DateTime now,
    PomodoroSession? session,
  }) {
    _updateRunningOverlapDecision(
      running: running,
      scheduled: scheduled,
      allGroups: allGroups,
      session: session,
      now: now,
    );
  }

  void _clearRunningOverlapDecisionIfNeeded() {
    if (_lastRunningOverlapKey != null) {
      _lastRunningOverlapKey = null;
    }
    if (ref.read(runningOverlapDecisionProvider) != null) {
      ref.read(runningOverlapDecisionProvider.notifier).state = null;
    }
  }

  void _scheduleRunningOverlapRecheck({
    required TaskRunGroup runningGroup,
    required DateTime? runningEnd,
    required DateTime preRunStart,
    required PomodoroSession? session,
    required DateTime now,
  }) {
    _runningOverlapTimer?.cancel();
    if (runningEnd == null) return;
    if (session == null) return;
    if (session.groupId != runningGroup.id) return;
    if (session.status != PomodoroStatus.paused) return;
    if (!preRunStart.isAfter(runningEnd)) return;
    final delay = preRunStart.difference(runningEnd);
    if (delay.inSeconds <= 0) return;
    _runningOverlapTimer = Timer(delay, () {
      if (_disposed) return;
      _handleGroups(_lastGroups);
    });
  }

  Future<bool> _finalizePostponedGroupsIfNeeded({
    required List<TaskRunGroup> groups,
    required PomodoroSession? activeSession,
    required DateTime now,
  }) async {
    final repo = ref.read(taskRunGroupRepositoryProvider);
    final updates = <TaskRunGroup>[];
    for (final group in groups) {
      if (group.status != TaskRunStatus.scheduled) continue;
      final anchorId = group.postponedAfterGroupId;
      if (anchorId == null) continue;
      final latest = await repo.getById(group.id) ?? group;
      if (latest.status != TaskRunStatus.scheduled) continue;
      if (latest.postponedAfterGroupId != anchorId) continue;
      final anchor = findGroupById(groups, anchorId);
      if (anchor == null) {
        updates.add(
          latest.copyWith(
            postponedAfterGroupId: null,
            updatedAt: now,
          ),
        );
        continue;
      }
      if (anchor.status == TaskRunStatus.running) {
        continue;
      }
      final anchorEnd = resolvePostponedAnchorEnd(
        anchor: anchor,
        activeSession: activeSession,
        now: now,
      );
      if (anchorEnd == null) continue;
      final noticeMinutes = resolveNoticeMinutes(latest);
      final scheduledStart = anchorEnd.add(Duration(minutes: noticeMinutes));
      final durationSeconds = _groupDurationSeconds(latest);
      updates.add(
        latest.copyWith(
          scheduledStartTime: scheduledStart,
          theoreticalEndTime: scheduledStart.add(
            Duration(seconds: durationSeconds),
          ),
          noticeSentAt: null,
          noticeSentByDeviceId: null,
          postponedAfterGroupId: null,
          updatedAt: now,
        ),
      );
    }

    if (updates.isEmpty) return false;

    await repo.saveAll(updates);
    for (final group in updates) {
      await _cancelLocalPreAlert(group.id);
    }
    return true;
  }

  TaskRunGroup? _resolveActiveRunningGroup(
    List<TaskRunGroup> running,
    PomodoroSession? session,
  ) {
    final activeId = session?.groupId;
    if (activeId != null) {
      for (final group in running) {
        if (group.id == activeId) return group;
      }
    }
    if (running.isEmpty) return null;
    running.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return running.first;
  }

  List<TaskRunGroup> _resolveLateStartConflictSet({
    required List<TaskRunGroup> scheduled,
    required List<TaskRunGroup> allGroups,
    required PomodoroSession? session,
    required DateTime now,
  }) {
    if (scheduled.isEmpty) return const [];
    final overdue = scheduled
        .where((group) {
          final effectiveStart =
              resolveEffectiveScheduledStart(
                group: group,
                allGroups: allGroups,
                activeSession: session,
                now: now,
              ) ??
              group.scheduledStartTime!;
          return !effectiveStart.isAfter(now);
        })
        .toList()
      ..sort((a, b) {
        final aStart =
            resolveEffectiveScheduledStart(
              group: a,
              allGroups: allGroups,
              activeSession: session,
              now: now,
            ) ??
            a.scheduledStartTime!;
        final bStart =
            resolveEffectiveScheduledStart(
              group: b,
              allGroups: allGroups,
              activeSession: session,
              now: now,
            ) ??
            b.scheduledStartTime!;
        return aStart.compareTo(bStart);
      });
    if (overdue.isEmpty) return const [];

    if (overdue.length == 1) {
      final horizonEnd = now.add(
        Duration(seconds: _groupDurationSeconds(overdue.first)),
      );
      final conflict = _collectLateStartConflicts(
        scheduled: scheduled,
        overdueIds: {overdue.first.id},
        windowStart: now,
        windowEnd: horizonEnd,
        allGroups: allGroups,
        session: session,
        now: now,
      );
      return conflict.length > 1 ? conflict : const [];
    }

    final horizonEnd = _projectedQueueEnd(overdue, now);
    return _collectLateStartConflicts(
      scheduled: scheduled,
      overdueIds: overdue.map((g) => g.id).toSet(),
      windowStart: now,
      windowEnd: horizonEnd,
      allGroups: allGroups,
      session: session,
      now: now,
    );
  }

  List<TaskRunGroup> _collectLateStartConflicts({
    required List<TaskRunGroup> scheduled,
    required Set<String> overdueIds,
    required DateTime windowStart,
    required DateTime windowEnd,
    required List<TaskRunGroup> allGroups,
    required PomodoroSession? session,
    required DateTime now,
  }) {
    final conflicts = <TaskRunGroup>{};
    for (final group in scheduled) {
      if (overdueIds.contains(group.id)) {
        conflicts.add(group);
        continue;
      }
      final start = _scheduledWindowStart(
        group,
        allGroups: allGroups,
        session: session,
        now: now,
      );
      final end = _scheduledWindowEnd(
        group,
        allGroups: allGroups,
        session: session,
        now: now,
      );
      if (_overlaps(windowStart, windowEnd, start, end)) {
        conflicts.add(group);
      }
    }
    final list = conflicts.toList()
      ..sort((a, b) => a.scheduledStartTime!.compareTo(b.scheduledStartTime!));
    return list;
  }

  DateTime _projectedQueueEnd(List<TaskRunGroup> overdue, DateTime now) {
    var cursor = now;
    for (var index = 0; index < overdue.length; index += 1) {
      if (index > 0) {
        final notice = _noticeMinutesOrDefault(overdue[index]);
        cursor = cursor.add(Duration(minutes: notice));
      }
      cursor = cursor.add(
        Duration(seconds: _groupDurationSeconds(overdue[index])),
      );
    }
    return cursor;
  }

  String _lateStartQueueKey(List<TaskRunGroup> groups) {
    final ids = groups.map((g) => g.id).toList()..sort();
    return ids.join('|');
  }

  int _groupDurationSeconds(TaskRunGroup group) {
    return group.totalDurationSeconds ??
        groupDurationSecondsByMode(group.tasks, group.integrityMode);
  }

  int _noticeMinutesOrDefault(TaskRunGroup group) {
    return resolveNoticeMinutes(group);
  }

  DateTime _scheduledWindowStart(
    TaskRunGroup group, {
    required List<TaskRunGroup> allGroups,
    required PomodoroSession? session,
    required DateTime now,
  }) {
    final start =
        resolveEffectiveScheduledStart(
          group: group,
          allGroups: allGroups,
          activeSession: session,
          now: now,
        ) ??
        group.scheduledStartTime!;
    final notice = resolveNoticeMinutes(group);
    if (notice <= 0) return start;
    return start.subtract(Duration(minutes: notice));
  }

  DateTime _scheduledWindowEnd(
    TaskRunGroup group, {
    required List<TaskRunGroup> allGroups,
    required PomodoroSession? session,
    required DateTime now,
  }) {
    final scheduledStart =
        resolveEffectiveScheduledStart(
          group: group,
          allGroups: allGroups,
          activeSession: session,
          now: now,
        ) ??
        group.scheduledStartTime!;
    final duration = _groupDurationSeconds(group);
    return scheduledStart.add(Duration(seconds: duration));
  }

  bool _overlaps(
    DateTime aStart,
    DateTime aEnd,
    DateTime bStart,
    DateTime bEnd,
  ) {
    final safeAEnd = aEnd.isBefore(aStart) ? aStart : aEnd;
    final safeBEnd = bEnd.isBefore(bStart) ? bStart : bEnd;
    return aStart.isBefore(safeBEnd) && safeAEnd.isAfter(bStart);
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

  bool _isSessionStale(PomodoroSession session, DateTime now) {
    final updatedAt = session.lastUpdatedAt;
    if (updatedAt == null) return false;
    return now.difference(updatedAt) >= _staleSessionGrace;
  }

  bool _shouldExpireActiveSession(
    PomodoroSession session,
    TaskRunGroup group,
    DateTime now,
  ) {
    if (!session.status.isRunning) return false;
    final endTime = _resolveTheoreticalEndTime(group);
    if (endTime == null || endTime.isAfter(now)) return false;
    return _isSessionStale(session, now);
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
      _debugLogExpiryDecision(
        reason: 'mark-running-group-completed',
        now: now,
        session: ref.read(activePomodoroSessionProvider),
        group: latest,
        theoreticalEndTime: endTime,
      );
      final updated = latest.copyWith(
        status: TaskRunStatus.completed,
        updatedAt: now,
      );
      await repo.save(updated);
    }
  }

  Future<void> _schedulePreAlert(
    TaskRunGroup group,
    int noticeMinutes, {
    required DateTime scheduledStart,
    required List<TaskRunGroup> allGroups,
    required PomodoroSession? activeSession,
    required DateTime now,
  }) async {
    if (noticeMinutes <= 0) return;
    final anchorId = group.postponedAfterGroupId;
    if (anchorId != null) {
      final anchor = findGroupById(allGroups, anchorId);
      if (anchor != null && anchor.status == TaskRunStatus.running) {
        return;
      }
    }
    if (!now.isBefore(scheduledStart)) return;

    final preAlertStart =
        scheduledStart.subtract(Duration(minutes: noticeMinutes));
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

      final totalSeconds =
          latest.totalDurationSeconds ??
          groupDurationSecondsByMode(latest.tasks, latest.integrityMode);

      final updated = latest.copyWith(
        status: TaskRunStatus.running,
        actualStartTime: now,
        theoreticalEndTime: now.add(Duration(seconds: totalSeconds)),
        scheduledByDeviceId: latest.scheduledByDeviceId ?? deviceId,
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

  Future<void> _pruneScheduledNotices(
    List<TaskRunGroup> groups, {
    required PomodoroSession? activeSession,
    required DateTime now,
  }) async {
    if (_scheduledNotices.isEmpty) return;
    final scheduledGroups = groups
        .where(
          (g) =>
              g.status == TaskRunStatus.scheduled &&
              g.scheduledStartTime != null,
        )
        .toList(growable: false);
    final scheduledById = {
      for (final group in scheduledGroups) group.id: group,
    };
    final toRemove = <String>[];
    for (final entry in _scheduledNotices.entries) {
      final group = scheduledById[entry.key];
      if (group == null) {
        toRemove.add(entry.key);
        continue;
      }
      final noticeMinutes = resolveNoticeMinutes(group);
      if (noticeMinutes <= 0) {
        toRemove.add(entry.key);
        continue;
      }
      final scheduledStart =
          resolveEffectiveScheduledStart(
            group: group,
            allGroups: groups,
            activeSession: activeSession,
            now: now,
          ) ??
          group.scheduledStartTime!;
      final expectedPreAlertStart =
          scheduledStart.subtract(Duration(minutes: noticeMinutes));
      if (entry.value != expectedPreAlertStart) {
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
