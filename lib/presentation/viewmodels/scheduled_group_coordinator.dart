import 'dart:async';

import 'package:flutter/foundation.dart'
    show debugPrint, kDebugMode, visibleForTesting;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/pomodoro_session.dart';
import '../../data/models/schema_version.dart';
import '../../data/models/task_run_group.dart';
import '../../data/services/app_mode_service.dart';
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
  static const Duration _lateStartOwnerStale = Duration(seconds: 45);
  static const Duration _lateStartHeartbeatInterval = Duration(seconds: 20);
  static const Duration _noticeFallbackTtl = Duration(seconds: 30);

  Timer? _scheduledTimer;
  Timer? _preAlertTimer;
  Timer? _runningExpiryTimer;
  Timer? _runningOverlapTimer;
  Timer? _lateStartHeartbeatTimer;
  bool _autoStartInFlight = false;
  bool _initialized = false;
  bool _disposed = false;
  bool _sessionStreamReady = false;
  String? _lastLateStartQueueKey;
  String? _lastRunningOverlapKey;
  String? _lateStartHeartbeatQueueId;
  String? _lateStartHeartbeatOwnerId;
  List<String> _lateStartHeartbeatGroupIds = const [];
  final Map<String, DateTime> _scheduledNotices = {};
  List<TaskRunGroup> _lastGroups = const [];
  final Uuid _uuid = const Uuid();
  int? _noticeFallbackMinutes;
  DateTime? _noticeFallbackFetchedAt;

  bool get _canUseRef => !_disposed;

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
    ref.listen<AppMode>(appModeProvider, (previous, next) {
      if (previous == next) return;
      _resetForModeChange();
      final groups = ref.read(taskRunGroupStreamProvider).value ?? const [];
      _handleGroups(groups);
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
    _lateStartHeartbeatTimer?.cancel();
    _scheduledNotices.clear();
  }

  void _resetForModeChange() {
    if (!_canUseRef) return;
    _scheduledTimer?.cancel();
    _scheduledTimer = null;
    _preAlertTimer?.cancel();
    _preAlertTimer = null;
    _runningExpiryTimer?.cancel();
    _runningExpiryTimer = null;
    _runningOverlapTimer?.cancel();
    _runningOverlapTimer = null;
    _stopLateStartHeartbeat();
    _scheduledNotices.clear();
    _lastLateStartQueueKey = null;
    _lastRunningOverlapKey = null;
    _autoStartInFlight = false;
    _sessionStreamReady = false;
    _lastGroups = const [];
    if (state != null) state = null;
    ref.read(scheduledAutoStartGroupIdProvider.notifier).state = null;
    _clearRunningOverlapDecisionIfNeeded();
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

    if (!_canUseRef) return;
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
    final noticeFallback = await _refreshNoticeFallback();
    if (!_canUseRef) return;
    PomodoroSession? session;
    try {
      session = ref.read(activePomodoroSessionProvider);
    } catch (_) {
      return;
    }
    await _pruneScheduledNotices(
      groups,
      activeSession: session,
      now: now,
      noticeFallbackMinutes: noticeFallback,
    );
    if (!_canUseRef) return;
    final clearedStale = await _clearStaleActiveSessionIfNeeded(groups);
    if (!_canUseRef) return;
    if (clearedStale) {
      session = null;
    }

    if (groups.isEmpty) {
      _stopLateStartHeartbeat();
      return;
    }
    final finalized = await _finalizePostponedGroupsIfNeeded(
      groups: groups,
      activeSession: session,
      now: now,
      noticeFallbackMinutes: noticeFallback,
    );
    if (!_canUseRef) return;
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
                  fallbackNoticeMinutes: noticeFallback,
                ) ??
                a.scheduledStartTime!;
            final bStart =
                resolveEffectiveScheduledStart(
                  group: b,
                  allGroups: groups,
                  activeSession: session,
                  now: now,
                  fallbackNoticeMinutes: noticeFallback,
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
        noticeFallbackMinutes: noticeFallback,
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
      _stopLateStartHeartbeat();
      return;
    }

    final lateStartConflicts = resolveLateStartConflictSet(
      scheduled: scheduled,
      allGroups: groups,
      activeSession: session,
      now: now,
      fallbackNoticeMinutes: noticeFallback,
    );
    if (lateStartConflicts.isNotEmpty) {
      final anchor = resolveLateStartAnchor(lateStartConflicts);
      final queueId = resolveLateStartQueueId(lateStartConflicts);
      final ownerId = resolveLateStartOwnerDeviceId(lateStartConflicts);
      final ownerHeartbeat = resolveLateStartOwnerHeartbeat(lateStartConflicts);
      final pendingRequestId =
          resolveLateStartClaimRequestId(lateStartConflicts);
      final pendingRequester =
          resolveLateStartClaimRequesterDeviceId(lateStartConflicts);
      final hasPendingRequest =
          pendingRequestId != null && pendingRequester != null;
      final isPendingForSelf = hasPendingRequest && pendingRequester == deviceId;
      final hasOwner = ownerId != null && ownerId.isNotEmpty;
      final staleByHeartbeat =
          ownerHeartbeat != null &&
          now.difference(ownerHeartbeat) >= _lateStartOwnerStale;
      final staleByAnchor =
          ownerHeartbeat == null &&
          anchor != null &&
          now.difference(anchor) >= _lateStartOwnerStale;
      final ownerStale = _isLateStartOwnerStale(
        ownerDeviceId: ownerId,
        ownerHeartbeat: ownerHeartbeat,
        anchor: anchor,
        now: now,
      );
      final shouldAutoClaim =
          (!hasOwner || staleByHeartbeat || staleByAnchor) &&
          (!hasPendingRequest || isPendingForSelf);
      final repo = ref.read(taskRunGroupRepositoryProvider);
      if (shouldAutoClaim && ownerId != deviceId) {
        try {
          await repo.claimLateStartQueue(
            groups: lateStartConflicts,
            ownerDeviceId: deviceId,
            queueId: queueId ?? _uuid.v4(),
            orderedIds: lateStartConflicts.map((g) => g.id).toList(),
            allowOverride: !hasOwner || ownerStale,
          );
          return;
        } catch (error) {
          debugPrint('[LateStartQueue] Claim failed: $error');
        }
      }
      if (anchor == null && ownerId == deviceId) {
        try {
          await repo.claimLateStartQueue(
            groups: lateStartConflicts,
            ownerDeviceId: deviceId,
            queueId: queueId ?? _uuid.v4(),
            orderedIds: lateStartConflicts.map((g) => g.id).toList(),
            allowOverride: true,
          );
          return;
        } catch (error) {
          debugPrint('[LateStartQueue] Claim retry failed: $error');
        }
      }
      _syncLateStartHeartbeat(
        lateStartConflicts,
        ownerDeviceId: ownerId,
        deviceId: deviceId,
      );
      final resolvedAnchor = anchor ?? ownerHeartbeat ?? now;
      if (anchor == null && ownerHeartbeat == null && kDebugMode) {
        debugPrint('[LateStartQueue] Missing anchor; using local time for queue');
      }
      if (kDebugMode) {
        debugPrint(
          '[LateStartQueue] overdue=${lateStartConflicts.length} '
          'owner=${ownerId ?? 'n/a'} '
          'anchor=$resolvedAnchor '
          'groupIds=${lateStartConflicts.map((g) => g.id).join(',')}',
        );
      }
      final key = _lateStartQueueKey(lateStartConflicts);
      if (key != _lastLateStartQueueKey) {
        _lastLateStartQueueKey = key;
        _emitLateStartQueue(
          lateStartConflicts.map((g) => g.id).toList(),
          resolvedAnchor,
        );
      }
      return;
    }
    _stopLateStartHeartbeat();
    _lastLateStartQueueKey = null;

    final nextGroup = scheduled.first;
    final startTime =
        resolveEffectiveScheduledStart(
          group: nextGroup,
          allGroups: groups,
          activeSession: session,
          now: now,
          fallbackNoticeMinutes: noticeFallback,
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
    if (!_canUseRef) return false;
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
      if (!_canUseRef) return false;
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
    final fallback = await _refreshNoticeFallback();
    return resolveNoticeMinutes(group, fallback: fallback);
  }

  void _updateRunningOverlapDecision({
    required List<TaskRunGroup> running,
    required List<TaskRunGroup> scheduled,
    required List<TaskRunGroup> allGroups,
    required PomodoroSession? session,
    required DateTime now,
    int? noticeFallbackMinutes,
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
          fallbackNoticeMinutes: noticeFallbackMinutes,
        ) ??
        nextScheduled.scheduledStartTime!;
    final noticeMinutes = resolveNoticeMinutes(
      nextScheduled,
      fallback: noticeFallbackMinutes,
    );
    final preRunStart = noticeMinutes > 0
        ? scheduledStart.subtract(Duration(minutes: noticeMinutes))
        : scheduledStart;
    final runningEnd = resolveProjectedRunningEnd(
      runningGroup: runningGroup,
      activeSession: session,
      now: now,
    );
    final overlapThreshold = resolveRunningOverlapThreshold(preRunStart);
    final hasOverlap =
        runningEnd != null &&
        isRunningOverlapBeyondGrace(
          runningEnd: runningEnd,
          preRunStart: preRunStart,
        );
    if (!hasOverlap) {
      _clearRunningOverlapDecisionIfNeeded();
      _scheduleRunningOverlapRecheck(
        runningGroup: runningGroup,
        runningEnd: runningEnd,
        overlapThreshold: overlapThreshold,
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
      noticeFallbackMinutes: _noticeFallbackMinutes,
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
    required DateTime overlapThreshold,
    required PomodoroSession? session,
    required DateTime now,
  }) {
    _runningOverlapTimer?.cancel();
    if (runningEnd == null) return;
    if (session == null) return;
    if (session.groupId != runningGroup.id) return;
    if (session.status != PomodoroStatus.paused) return;
    if (!overlapThreshold.isAfter(runningEnd)) return;
    final delay = overlapThreshold.difference(runningEnd);
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
    int? noticeFallbackMinutes,
  }) async {
    if (!_canUseRef) return false;
    final repo = ref.read(taskRunGroupRepositoryProvider);
    final updates = <TaskRunGroup>[];
    for (final group in groups) {
      if (group.status != TaskRunStatus.scheduled) continue;
      final anchorId = group.postponedAfterGroupId;
      if (anchorId == null) continue;
      final latest = await repo.getById(group.id) ?? group;
      if (!_canUseRef) return false;
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
        allGroups: groups,
        activeSession: activeSession,
        now: now,
        fallbackNoticeMinutes: noticeFallbackMinutes,
      );
      if (anchorEnd == null) continue;
      final noticeMinutes = resolveNoticeMinutes(
        latest,
        fallback: noticeFallbackMinutes,
      );
      final scheduledStart = ceilToMinute(
        anchorEnd.add(Duration(minutes: noticeMinutes)),
      );
      final durationSeconds = resolveGroupDurationSeconds(latest);
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
    if (!_canUseRef) return false;
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

  String _lateStartQueueKey(List<TaskRunGroup> groups) {
    final ids = groups.map((g) => g.id).toList()..sort();
    return ids.join('|');
  }

  void _syncLateStartHeartbeat(
    List<TaskRunGroup> groups, {
    required String? ownerDeviceId,
    required String deviceId,
  }) {
    if (ownerDeviceId == null || ownerDeviceId != deviceId) {
      _stopLateStartHeartbeat();
      return;
    }
    final queueId = resolveLateStartQueueId(groups);
    if (queueId == null) {
      _stopLateStartHeartbeat();
      return;
    }
    final ids = groups.map((g) => g.id).toList()..sort();
    final key = '$queueId|${ids.join(',')}';
    if (_lateStartHeartbeatTimer != null &&
        _lateStartHeartbeatQueueId == key &&
        _lateStartHeartbeatOwnerId == ownerDeviceId) {
      return;
    }
    _lateStartHeartbeatQueueId = key;
    _lateStartHeartbeatOwnerId = ownerDeviceId;
    _lateStartHeartbeatGroupIds = ids;
    _lateStartHeartbeatTimer?.cancel();
    _lateStartHeartbeatTimer = Timer.periodic(
      _lateStartHeartbeatInterval,
      (_) => _touchLateStartHeartbeat(),
    );
    _touchLateStartHeartbeat();
  }

  void _stopLateStartHeartbeat() {
    _lateStartHeartbeatTimer?.cancel();
    _lateStartHeartbeatTimer = null;
    _lateStartHeartbeatQueueId = null;
    _lateStartHeartbeatOwnerId = null;
    _lateStartHeartbeatGroupIds = const [];
  }

  Future<void> _touchLateStartHeartbeat() async {
    if (!_canUseRef) return;
    if (_lateStartHeartbeatGroupIds.isEmpty) return;
    final ownerDeviceId = _lateStartHeartbeatOwnerId;
    if (ownerDeviceId == null) return;
    final groups = _lastGroups
        .where((g) => _lateStartHeartbeatGroupIds.contains(g.id))
        .toList();
    if (groups.isEmpty) return;
    await ref
        .read(taskRunGroupRepositoryProvider)
        .updateLateStartOwnerHeartbeat(
          groups: groups,
          ownerDeviceId: ownerDeviceId,
        );
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

  bool _isLateStartOwnerStale({
    required String? ownerDeviceId,
    required DateTime? ownerHeartbeat,
    required DateTime? anchor,
    required DateTime now,
  }) {
    if (ownerDeviceId == null || ownerDeviceId.isEmpty) return false;
    final lastSeen = ownerHeartbeat ?? anchor;
    if (lastSeen == null) return false;
    return now.difference(lastSeen) >= _lateStartOwnerStale;
  }

  Future<int?> _refreshNoticeFallback() async {
    if (_disposed) return _noticeFallbackMinutes;
    final cached = _noticeFallbackMinutes;
    final fetchedAt = _noticeFallbackFetchedAt;
    if (cached != null &&
        fetchedAt != null &&
        DateTime.now().difference(fetchedAt) < _noticeFallbackTtl) {
      return cached;
    }
    try {
      final resolved =
          await ref.read(taskRunNoticeServiceProvider).getNoticeMinutes();
      _noticeFallbackMinutes = resolved;
      _noticeFallbackFetchedAt = DateTime.now();
      return resolved;
    } catch (_) {
      return cached;
    }
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
    if (!_canUseRef) return;
    final repo = ref.read(taskRunGroupRepositoryProvider);
    for (final group in groups) {
      final latest = await repo.getById(group.id) ?? group;
      if (!_canUseRef) return;
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
    if (!_canUseRef) return;
    final groupRepo = ref.read(taskRunGroupRepositoryProvider);
    final latest = await groupRepo.getById(group.id) ?? group;
    if (!_canUseRef) return;
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
      if (!_canUseRef) return;
      final deviceId = ref.read(deviceInfoServiceProvider).deviceId;
      final groupRepo = ref.read(taskRunGroupRepositoryProvider);
      final latest = await groupRepo.getById(groupId);
      if (!_canUseRef) return;
      if (latest == null) return;
      if (latest.status != TaskRunStatus.scheduled) return;
      final now = await _resolveServerNow(force: true);
      final scheduledStart =
          resolveEffectiveScheduledStart(
            group: latest,
            allGroups: _lastGroups,
            activeSession: ref.read(activePomodoroSessionProvider),
            now: now,
            fallbackNoticeMinutes: _noticeFallbackMinutes,
          ) ??
          latest.scheduledStartTime;
      if (scheduledStart == null) return;
      if (scheduledStart.isAfter(now)) return;

      final totalSeconds =
          latest.totalDurationSeconds ??
          groupDurationSecondsByMode(latest.tasks, latest.integrityMode);
      final shouldUpdateScheduledStart =
          latest.postponedAfterGroupId != null &&
          (latest.scheduledStartTime == null ||
              !latest.scheduledStartTime!.isAtSameMomentAs(scheduledStart));

      final updated = latest.copyWith(
        status: TaskRunStatus.running,
        scheduledStartTime: shouldUpdateScheduledStart
            ? scheduledStart
            : latest.scheduledStartTime,
        postponedAfterGroupId: shouldUpdateScheduledStart
            ? null
            : latest.postponedAfterGroupId,
        actualStartTime: now,
        theoreticalEndTime: now.add(Duration(seconds: totalSeconds)),
        scheduledByDeviceId: latest.scheduledByDeviceId ?? deviceId,
        updatedAt: now,
      );
      await groupRepo.save(updated);
      if (!_canUseRef) return;
      await _publishInitialSession(updated, startedAt: now);

      ref.read(scheduledAutoStartGroupIdProvider.notifier).state = groupId;
      await _cancelLocalPreAlert(groupId);
      _emitOpenTimer(groupId);
    } catch (e) {
      debugPrint('Scheduled auto-start failed: $e');
    } finally {
      _autoStartInFlight = false;
    }
  }

  Future<void> _publishInitialSession(
    TaskRunGroup group, {
    required DateTime startedAt,
  }) async {
    if (group.tasks.isEmpty) return;
    if (!_canUseRef) return;
    final task = group.tasks.first;
    final session = PomodoroSession(
      taskId: task.sourceTaskId,
      groupId: group.id,
      currentTaskId: task.sourceTaskId,
      currentTaskIndex: 0,
      totalTasks: group.tasks.length,
      dataVersion: kCurrentDataVersion,
      sessionRevision: 1,
      ownerDeviceId: ref.read(deviceInfoServiceProvider).deviceId,
      status: PomodoroStatus.pomodoroRunning,
      phase: PomodoroPhase.pomodoro,
      currentPomodoro: 1,
      totalPomodoros: task.totalPomodoros,
      phaseDurationSeconds: task.pomodoroMinutes * 60,
      remainingSeconds: task.pomodoroMinutes * 60,
      accumulatedPausedSeconds: 0,
      phaseStartedAt: startedAt,
      currentTaskStartedAt: startedAt,
      pausedAt: null,
      lastUpdatedAt: startedAt,
      finishedAt: null,
      pauseReason: null,
    );
    await ref.read(pomodoroSessionRepositoryProvider).publishSession(session);
  }

  Future<DateTime> _resolveServerNow({bool force = false}) async {
    final appMode = ref.read(appModeProvider);
    if (appMode != AppMode.account) return DateTime.now();
    final timeSync = ref.read(timeSyncServiceProvider);
    final offset = await timeSync.refresh(force: force);
    if (offset == null) return DateTime.now();
    return DateTime.now().add(offset);
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
    int? noticeFallbackMinutes,
  }) async {
    if (_scheduledNotices.isEmpty) return;
    if (!_canUseRef) return;
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
      final noticeMinutes = resolveNoticeMinutes(
        group,
        fallback: noticeFallbackMinutes,
      );
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
            fallbackNoticeMinutes: noticeFallbackMinutes,
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
      if (!_canUseRef) return;
      await ref.read(notificationServiceProvider).cancelGroupPreAlert(groupId);
      _scheduledNotices.remove(groupId);
    }
  }
}
