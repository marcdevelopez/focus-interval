import 'dart:async';

import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:focus_interval/data/models/pomodoro_session.dart';
import 'package:focus_interval/data/models/schema_version.dart';
import 'package:focus_interval/data/models/selected_sound.dart';
import 'package:focus_interval/data/models/task_run_group.dart';
import 'package:focus_interval/data/repositories/pomodoro_session_repository.dart';
import 'package:focus_interval/data/repositories/task_run_group_repository.dart';
import 'package:focus_interval/data/services/app_mode_service.dart';
import 'package:focus_interval/data/services/device_info_service.dart';
import 'package:focus_interval/data/services/time_sync_service.dart';
import 'package:focus_interval/domain/pomodoro_machine.dart';
import 'package:focus_interval/presentation/providers.dart';
import 'package:focus_interval/presentation/viewmodels/scheduled_group_coordinator.dart';

class FakeTaskRunGroupRepository implements TaskRunGroupRepository {
  final Map<String, TaskRunGroup> _store = {};
  final StreamController<List<TaskRunGroup>> _controller =
      StreamController<List<TaskRunGroup>>.broadcast();
  int claimLateStartCalls = 0;
  String? lastClaimOwnerDeviceId;

  void seed(TaskRunGroup group) {
    _store[group.id] = group;
    _emit();
  }

  void _emit() {
    _controller.add(_store.values.toList());
  }

  @override
  Stream<List<TaskRunGroup>> watchAll() async* {
    yield _store.values.toList();
    yield* _controller.stream;
  }

  @override
  Future<List<TaskRunGroup>> getAll() async => _store.values.toList();

  @override
  Future<TaskRunGroup?> getById(String id) async => _store[id];

  @override
  Future<void> save(TaskRunGroup group) async {
    _store[group.id] = group;
    _emit();
  }

  @override
  Future<void> saveAll(List<TaskRunGroup> groups) async {
    for (final group in groups) {
      _store[group.id] = group;
    }
    _emit();
  }

  @override
  Future<void> delete(String id) async {
    _store.remove(id);
    _emit();
  }

  @override
  Future<void> prune({int? keepCompleted}) async {}

  @override
  Future<void> claimLateStartQueue({
    required List<TaskRunGroup> groups,
    required String ownerDeviceId,
    required String queueId,
    required List<String> orderedIds,
    required bool allowOverride,
  }) async {
    if (groups.isEmpty) return;
    claimLateStartCalls += 1;
    lastClaimOwnerDeviceId = ownerDeviceId;
    final now = DateTime.now();
    final orderLookup = <String, int>{};
    for (var i = 0; i < orderedIds.length; i += 1) {
      orderLookup[orderedIds[i]] = i;
    }
    for (final group in groups) {
      final updated = group.copyWith(
        lateStartAnchorAt: now,
        lateStartQueueId: queueId,
        lateStartQueueOrder: orderLookup[group.id],
        lateStartOwnerDeviceId: ownerDeviceId,
        lateStartOwnerHeartbeatAt: now,
      );
      _store[group.id] = updated;
    }
    _emit();
  }

  @override
  Future<void> updateLateStartOwnerHeartbeat({
    required List<TaskRunGroup> groups,
    required String ownerDeviceId,
  }) async {}

  @override
  Future<void> requestLateStartOwnership({
    required List<TaskRunGroup> groups,
    required String requesterDeviceId,
    required String requestId,
  }) async {}

  @override
  Future<void> respondLateStartOwnershipRequest({
    required List<TaskRunGroup> groups,
    required String ownerDeviceId,
    required String requesterDeviceId,
    required String requestId,
    required bool approved,
  }) async {}

  void dispose() {
    _controller.close();
  }
}

class FakePomodoroSessionRepository implements PomodoroSessionRepository {
  final StreamController<PomodoroSession?> _controller =
      StreamController<PomodoroSession?>.broadcast();
  PomodoroSession? _lastSession;
  PomodoroSession? serverSessionOverride;
  bool useServerSessionOverride = false;
  int publishCount = 0;
  PomodoroSession? lastPublishedSession;
  int clearSessionAsOwnerCount = 0;
  int clearSessionIfStaleCount = 0;
  int clearSessionIfGroupNotRunningCount = 0;
  bool clearSessionAsOwnerEmitsNull = false;
  bool clearSessionIfStaleEmitsNull = false;
  bool clearSessionIfGroupNotRunningEmitsNull = false;

  void emit(PomodoroSession? session) {
    _lastSession = session;
    _controller.add(session);
  }

  @override
  Stream<PomodoroSession?> watchSession() async* {
    yield _lastSession;
    yield* _controller.stream;
  }

  @override
  Future<PomodoroSession?> fetchSession({bool preferServer = false}) async {
    if (preferServer && useServerSessionOverride) {
      return serverSessionOverride;
    }
    return _lastSession;
  }

  @override
  Future<void> publishSession(PomodoroSession session) async {
    publishCount += 1;
    lastPublishedSession = session;
    _lastSession = session;
    _controller.add(session);
  }

  @override
  Future<bool> tryClaimSession(PomodoroSession session) async => true;

  @override
  Future<void> clearSessionAsOwner() async {
    clearSessionAsOwnerCount += 1;
    if (clearSessionAsOwnerEmitsNull) {
      emit(null);
    }
  }

  @override
  Future<void> clearSessionIfStale({required DateTime now}) async {
    clearSessionIfStaleCount += 1;
    if (clearSessionIfStaleEmitsNull) {
      emit(null);
    }
  }

  @override
  Future<void> clearSessionIfGroupNotRunning() async {
    clearSessionIfGroupNotRunningCount += 1;
    if (clearSessionIfGroupNotRunningEmitsNull) {
      emit(null);
    }
  }

  Future<void> clearSessionIfInactive({String? expectedGroupId}) async {}

  @override
  Future<void> requestOwnership({
    required String requesterDeviceId,
    required String requestId,
  }) async {}

  @override
  Future<bool> tryAutoClaimStaleOwner({
    required String requesterDeviceId,
  }) async {
    return false;
  }

  @override
  Future<void> respondToOwnershipRequest({
    required String ownerDeviceId,
    required String requesterDeviceId,
    required bool approved,
    Map<String, dynamic>? cursorSnapshot,
  }) async {}

  void dispose() {
    _controller.close();
  }
}

class FakeTimeSyncService extends TimeSyncService {
  FakeTimeSyncService({Duration? initialOffset})
    : _offset = initialOffset,
      super(enabled: false);

  Duration? _offset;

  void setOffset(Duration? value) {
    _offset = value;
  }

  @override
  Duration? get offset => _offset;

  @override
  Future<Duration?> refresh({bool force = false}) async => _offset;
}

TaskRunItem _buildItem() {
  return const TaskRunItem(
    sourceTaskId: 'task-1',
    name: 'Test task',
    presetId: null,
    pomodoroMinutes: 25,
    shortBreakMinutes: 5,
    longBreakMinutes: 15,
    totalPomodoros: 2,
    longBreakInterval: 2,
    startSound: SelectedSound.builtIn('default_chime'),
    startBreakSound: SelectedSound.builtIn('default_chime_break'),
    finishTaskSound: SelectedSound.builtIn('default_chime_finish'),
  );
}

TaskRunGroup _buildRunningGroup({
  required String id,
  required DateTime start,
  required DateTime theoreticalEnd,
}) {
  final item = _buildItem();
  return TaskRunGroup(
    id: id,
    ownerUid: 'user-1',
    dataVersion: kCurrentDataVersion,
    integrityMode: TaskRunIntegrityMode.individual,
    tasks: [item],
    createdAt: start,
    scheduledStartTime: null,
    scheduledByDeviceId: null,
    noticeSentAt: null,
    noticeSentByDeviceId: null,
    actualStartTime: start,
    theoreticalEndTime: theoreticalEnd,
    status: TaskRunStatus.running,
    noticeMinutes: null,
    totalTasks: 1,
    totalPomodoros: 2,
    totalDurationSeconds: item.durationSeconds(includeFinalBreak: true),
    updatedAt: start,
  );
}

TaskRunGroup _buildScheduledGroup({
  required String id,
  required DateTime scheduledStart,
  int durationMinutes = 60,
  int noticeMinutes = 5,
}) {
  final item = _buildItem();
  final createdAt = scheduledStart.subtract(const Duration(minutes: 1));
  return TaskRunGroup(
    id: id,
    ownerUid: 'user-1',
    dataVersion: kCurrentDataVersion,
    integrityMode: TaskRunIntegrityMode.shared,
    tasks: [item],
    createdAt: createdAt,
    scheduledStartTime: scheduledStart,
    scheduledByDeviceId: 'device-1',
    noticeSentAt: null,
    noticeSentByDeviceId: null,
    actualStartTime: null,
    theoreticalEndTime: scheduledStart.add(Duration(minutes: durationMinutes)),
    status: TaskRunStatus.scheduled,
    noticeMinutes: noticeMinutes,
    totalTasks: 1,
    totalPomodoros: item.totalPomodoros,
    totalDurationSeconds: durationMinutes * 60,
    updatedAt: createdAt,
  );
}

PomodoroSession _buildPausedSession({
  required String groupId,
  required String ownerId,
  required DateTime now,
}) {
  return PomodoroSession(
    taskId: 'task-1',
    groupId: groupId,
    currentTaskId: 'task-1',
    currentTaskIndex: 0,
    totalTasks: 1,
    dataVersion: kCurrentDataVersion,
    sessionRevision: 1,
    ownerDeviceId: ownerId,
    status: PomodoroStatus.paused,
    phase: PomodoroPhase.pomodoro,
    currentPomodoro: 1,
    totalPomodoros: 2,
    phaseDurationSeconds: 25 * 60,
    remainingSeconds: 1200,
    accumulatedPausedSeconds: 0,
    phaseStartedAt: now.subtract(const Duration(minutes: 10)),
    currentTaskStartedAt: now.subtract(const Duration(minutes: 10)),
    pausedAt: now.subtract(const Duration(minutes: 5)),
    lastUpdatedAt: now,
    finishedAt: null,
    pauseReason: 'user',
  );
}

PomodoroSession _buildRunningSession({
  required String groupId,
  required String ownerId,
  required DateTime now,
  DateTime? lastUpdatedAt,
}) {
  return PomodoroSession(
    taskId: 'task-1',
    groupId: groupId,
    currentTaskId: 'task-1',
    currentTaskIndex: 0,
    totalTasks: 1,
    dataVersion: kCurrentDataVersion,
    sessionRevision: 1,
    ownerDeviceId: ownerId,
    status: PomodoroStatus.pomodoroRunning,
    phase: PomodoroPhase.pomodoro,
    currentPomodoro: 1,
    totalPomodoros: 2,
    phaseDurationSeconds: 25 * 60,
    remainingSeconds: 1200,
    accumulatedPausedSeconds: 0,
    phaseStartedAt: now.subtract(const Duration(minutes: 10)),
    currentTaskStartedAt: now.subtract(const Duration(minutes: 10)),
    pausedAt: null,
    lastUpdatedAt: lastUpdatedAt ?? now,
    finishedAt: null,
    pauseReason: null,
  );
}

Future<void> _pumpQueue() async {
  await Future<void>.delayed(const Duration(milliseconds: 50));
  await Future<void>.delayed(const Duration(milliseconds: 50));
}

Future<List<TaskRunGroup>> _awaitLostGroups({
  required FakeTaskRunGroupRepository repo,
  required List<String> groupIds,
  Duration timeout = const Duration(seconds: 1),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    final all = await repo.getAll();
    final byId = {for (final group in all) group.id: group};
    final allLost = groupIds.every((id) {
      final group = byId[id];
      return group != null &&
          group.status == TaskRunStatus.canceled &&
          group.canceledReason == 'lost';
    });
    if (allLost) {
      return groupIds.map((id) => byId[id]!).toList();
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }

  final all = await repo.getAll();
  final byId = {for (final group in all) group.id: group};
  return groupIds.map((id) => byId[id]).whereType<TaskRunGroup>().toList();
}

Future<void> _expectNoScheduledAction(
  Completer<ScheduledGroupAction> actionCompleter, {
  Duration timeout = const Duration(milliseconds: 300),
}) async {
  await expectLater(
    actionCompleter.future.timeout(timeout),
    throwsA(isA<TimeoutException>()),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ScheduledGroupCoordinator paused expiry guard', () {
    test(
      'does not complete running group while session stream is loading',
      () async {
        final groupRepo = FakeTaskRunGroupRepository();
        final sessionRepo = FakePomodoroSessionRepository();
        final container = ProviderContainer(
          overrides: [
            appModeServiceProvider.overrideWithValue(AppModeService.memory()),
            taskRunGroupRepositoryProvider.overrideWithValue(groupRepo),
            pomodoroSessionRepositoryProvider.overrideWithValue(sessionRepo),
          ],
        );
        addTearDown(() {
          groupRepo.dispose();
          sessionRepo.dispose();
          container.dispose();
        });

        container.read(scheduledGroupCoordinatorProvider);

        final now = DateTime.now();
        final group = _buildRunningGroup(
          id: 'group-1',
          start: now.subtract(const Duration(hours: 2)),
          theoreticalEnd: now.subtract(const Duration(minutes: 30)),
        );
        groupRepo.seed(group);

        await _pumpQueue();

        final stored = await groupRepo.getById(group.id);
        expect(stored?.status, TaskRunStatus.running);
      },
    );

    test(
      'does not complete running group when active session is paused',
      () async {
        final groupRepo = FakeTaskRunGroupRepository();
        final sessionRepo = FakePomodoroSessionRepository();
        final container = ProviderContainer(
          overrides: [
            appModeServiceProvider.overrideWithValue(AppModeService.memory()),
            taskRunGroupRepositoryProvider.overrideWithValue(groupRepo),
            pomodoroSessionRepositoryProvider.overrideWithValue(sessionRepo),
          ],
        );
        addTearDown(() {
          groupRepo.dispose();
          sessionRepo.dispose();
          container.dispose();
        });

        container.read(scheduledGroupCoordinatorProvider);

        final now = DateTime.now();
        final group = _buildRunningGroup(
          id: 'group-2',
          start: now.subtract(const Duration(hours: 2)),
          theoreticalEnd: now.subtract(const Duration(minutes: 30)),
        );
        final pausedSession = _buildPausedSession(
          groupId: group.id,
          ownerId: 'device-1',
          now: now,
        );

        sessionRepo.emit(pausedSession);
        groupRepo.seed(group);

        await _pumpQueue();

        final stored = await groupRepo.getById(group.id);
        expect(stored?.status, TaskRunStatus.running);
      },
    );

    test('does not complete when first snapshot is null then paused', () async {
      final groupRepo = FakeTaskRunGroupRepository();
      final sessionRepo = FakePomodoroSessionRepository();
      final container = ProviderContainer(
        overrides: [
          appModeServiceProvider.overrideWithValue(AppModeService.memory()),
          taskRunGroupRepositoryProvider.overrideWithValue(groupRepo),
          pomodoroSessionRepositoryProvider.overrideWithValue(sessionRepo),
        ],
      );
      addTearDown(() {
        groupRepo.dispose();
        sessionRepo.dispose();
        container.dispose();
      });

      container.read(scheduledGroupCoordinatorProvider);

      final now = DateTime.now();
      final group = _buildRunningGroup(
        id: 'group-3',
        start: now.subtract(const Duration(hours: 2)),
        theoreticalEnd: now.subtract(const Duration(minutes: 30)),
      );

      sessionRepo.emit(null);
      groupRepo.seed(group);
      await _pumpQueue();

      final pausedSession = _buildPausedSession(
        groupId: group.id,
        ownerId: 'device-1',
        now: now,
      );
      sessionRepo.emit(pausedSession);
      await _pumpQueue();

      final stored = await groupRepo.getById(group.id);
      expect(stored?.status, TaskRunStatus.running);
    });

    test(
      'does not complete expired running group when stream is null but server has paused session for same group',
      () async {
        final groupRepo = FakeTaskRunGroupRepository();
        final sessionRepo = FakePomodoroSessionRepository();
        final container = ProviderContainer(
          overrides: [
            appModeServiceProvider.overrideWithValue(AppModeService.memory()),
            taskRunGroupRepositoryProvider.overrideWithValue(groupRepo),
            pomodoroSessionRepositoryProvider.overrideWithValue(sessionRepo),
          ],
        );
        addTearDown(() {
          groupRepo.dispose();
          sessionRepo.dispose();
          container.dispose();
        });

        container.read(scheduledGroupCoordinatorProvider);

        final now = DateTime.now();
        final group = _buildRunningGroup(
          id: 'group-3b',
          start: now.subtract(const Duration(hours: 2)),
          theoreticalEnd: now.subtract(const Duration(minutes: 30)),
        );

        sessionRepo.emit(null);
        sessionRepo.useServerSessionOverride = true;
        sessionRepo.serverSessionOverride = _buildPausedSession(
          groupId: group.id,
          ownerId: 'device-1',
          now: now,
        );

        groupRepo.seed(group);
        await _pumpQueue();

        final stored = await groupRepo.getById(group.id);
        expect(stored?.status, TaskRunStatus.running);
      },
    );

    test(
      'completes expired running group when stream is null but server session is for another group',
      () async {
        final now = DateTime.now();
        final groupRepo = FakeTaskRunGroupRepository();
        final sessionRepo = FakePomodoroSessionRepository();
        final actionCompleter = Completer<ScheduledGroupAction>();
        final container = ProviderContainer(
          overrides: [
            appModeServiceProvider.overrideWithValue(AppModeService.memory()),
            taskRunGroupRepositoryProvider.overrideWithValue(groupRepo),
            pomodoroSessionRepositoryProvider.overrideWithValue(sessionRepo),
          ],
        );
        addTearDown(() {
          groupRepo.dispose();
          sessionRepo.dispose();
          container.dispose();
        });

        final sub = container.listen<ScheduledGroupAction?>(
          scheduledGroupCoordinatorProvider,
          (_, next) {
            if (next != null && !actionCompleter.isCompleted) {
              actionCompleter.complete(next);
            }
          },
        );
        addTearDown(sub.close);

        container.read(scheduledGroupCoordinatorProvider);
        sessionRepo.emit(null);
        sessionRepo.useServerSessionOverride = true;
        sessionRepo.serverSessionOverride = _buildRunningSession(
          groupId: 'another-group',
          ownerId: 'device-1',
          now: now,
        );
        await _pumpQueue();

        await groupRepo.save(
          _buildRunningGroup(
            id: 'group-expired-no-session-foreign-server',
            start: now.subtract(const Duration(hours: 2)),
            theoreticalEnd: now.subtract(const Duration(minutes: 30)),
          ),
        );
        await _pumpQueue();

        final action = await actionCompleter.future.timeout(
          const Duration(seconds: 1),
        );
        expect(action.type, ScheduledGroupActionType.openGroupsHub);

        final stored = await groupRepo.getById(
          'group-expired-no-session-foreign-server',
        );
        expect(stored?.status, TaskRunStatus.completed);
      },
    );

    test(
      'does not complete when active session belongs to another group',
      () async {
        final groupRepo = FakeTaskRunGroupRepository();
        final sessionRepo = FakePomodoroSessionRepository();
        final container = ProviderContainer(
          overrides: [
            appModeServiceProvider.overrideWithValue(AppModeService.memory()),
            taskRunGroupRepositoryProvider.overrideWithValue(groupRepo),
            pomodoroSessionRepositoryProvider.overrideWithValue(sessionRepo),
          ],
        );
        addTearDown(() {
          groupRepo.dispose();
          sessionRepo.dispose();
          container.dispose();
        });

        container.read(scheduledGroupCoordinatorProvider);

        final now = DateTime.now();
        final group = _buildRunningGroup(
          id: 'group-4',
          start: now.subtract(const Duration(hours: 2)),
          theoreticalEnd: now.subtract(const Duration(minutes: 30)),
        );
        final runningSession = _buildRunningSession(
          groupId: 'other-group',
          ownerId: 'device-1',
          now: now,
        );

        sessionRepo.emit(runningSession);
        groupRepo.seed(group);
        await _pumpQueue();

        final stored = await groupRepo.getById(group.id);
        expect(stored?.status, TaskRunStatus.running);
      },
    );

    test(
      '[PHASE5] stale-clear diagnostics must include instance token and clear decision metadata',
      () async {
        final groupRepo = FakeTaskRunGroupRepository();
        final sessionRepo = FakePomodoroSessionRepository();
        final appModeService = AppModeService.memory();
        final logs = <String>[];
        final previousDebugPrint = foundation.debugPrint;
        foundation.debugPrint = (String? message, {int? wrapWidth}) {
          if (message != null) logs.add(message);
        };

        final container = ProviderContainer(
          overrides: [
            appModeServiceProvider.overrideWithValue(appModeService),
            taskRunGroupRepositoryProvider.overrideWithValue(groupRepo),
            pomodoroSessionRepositoryProvider.overrideWithValue(sessionRepo),
          ],
        );
        addTearDown(() {
          foundation.debugPrint = previousDebugPrint;
          groupRepo.dispose();
          sessionRepo.dispose();
          container.dispose();
        });

        container.read(scheduledGroupCoordinatorProvider);

        final now = DateTime.now();
        final group = _buildRunningGroup(
          id: 'group-phase5-stale-clear',
          start: now.subtract(const Duration(hours: 2)),
          theoreticalEnd: now.add(const Duration(hours: 2)),
        );
        final runningSession = _buildRunningSession(
          groupId: 'group-phase5-other',
          ownerId: 'device-1',
          now: now,
        );

        sessionRepo.emit(runningSession);
        groupRepo.seed(group);
        await _pumpQueue();
        foundation.debugPrint = previousDebugPrint;

        final merged = logs.join('\n');
        expect(
          merged.contains('[StaleClearDiag]'),
          isTrue,
          reason:
              'Phase-5 diagnostics contract: stale-clear evaluation must emit a dedicated diagnostic event.',
        );
        expect(
          merged.contains('vmToken='),
          isTrue,
          reason:
              'Phase-5 diagnostics contract: stale-clear diagnostics must include instance token correlation.',
        );
        expect(
          merged.contains('decision='),
          isTrue,
          reason:
              'Phase-5 diagnostics contract: stale-clear diagnostics must include clear/keep decision metadata.',
        );
        expect(
          merged.contains('sessionGroupId='),
          isTrue,
          reason:
              'Phase-5 diagnostics contract: stale-clear diagnostics must include evaluated session groupId metadata.',
        );
      },
    );
  });

  group('ScheduledGroupCoordinator overdue scheduled handling', () {
    test(
      'marks multiple overdue groups as lost without emitting actions',
      () async {
        final groupRepo = FakeTaskRunGroupRepository();
        final sessionRepo = FakePomodoroSessionRepository();
        final actionCompleter = Completer<ScheduledGroupAction>();
        final container = ProviderContainer(
          overrides: [
            appModeServiceProvider.overrideWithValue(AppModeService.memory()),
            taskRunGroupRepositoryProvider.overrideWithValue(groupRepo),
            pomodoroSessionRepositoryProvider.overrideWithValue(sessionRepo),
          ],
        );
        addTearDown(() {
          groupRepo.dispose();
          sessionRepo.dispose();
          container.dispose();
        });

        final sub = container.listen<ScheduledGroupAction?>(
          scheduledGroupCoordinatorProvider,
          (_, next) {
            if (next != null && !actionCompleter.isCompleted) {
              actionCompleter.complete(next);
            }
          },
        );
        addTearDown(sub.close);

        container.read(scheduledGroupCoordinatorProvider);

        final now = DateTime.now();
        final first = _buildScheduledGroup(
          id: 'group-a',
          scheduledStart: now.subtract(const Duration(hours: 2)),
          durationMinutes: 30,
          noticeMinutes: 5,
        );
        final second = _buildScheduledGroup(
          id: 'group-b',
          scheduledStart: now.subtract(const Duration(hours: 1)),
          durationMinutes: 30,
          noticeMinutes: 5,
        );

        sessionRepo.emit(null);
        await groupRepo.saveAll([first, second]);

        final lostGroups = await _awaitLostGroups(
          repo: groupRepo,
          groupIds: ['group-a', 'group-b'],
        );
        expect(lostGroups, hasLength(2));
        expect(
          lostGroups.map((group) => group.status),
          everyElement(TaskRunStatus.canceled),
        );
        expect(
          lostGroups.map((group) => group.canceledReason),
          everyElement('lost'),
        );
        expect(groupRepo.claimLateStartCalls, 0);
        await _expectNoScheduledAction(actionCompleter);
      },
    );

    test(
      '[PHASE5] no scheduled-action diagnostics are emitted for deterministic lost transitions',
      () async {
        final groupRepo = FakeTaskRunGroupRepository();
        final sessionRepo = FakePomodoroSessionRepository();
        final appModeService = AppModeService.memory();
        final logs = <String>[];
        final previousDebugPrint = foundation.debugPrint;
        foundation.debugPrint = (String? message, {int? wrapWidth}) {
          if (message != null) logs.add(message);
        };
        final actionCompleter = Completer<ScheduledGroupAction>();
        final container = ProviderContainer(
          overrides: [
            appModeServiceProvider.overrideWithValue(appModeService),
            taskRunGroupRepositoryProvider.overrideWithValue(groupRepo),
            pomodoroSessionRepositoryProvider.overrideWithValue(sessionRepo),
          ],
        );
        addTearDown(() {
          foundation.debugPrint = previousDebugPrint;
          groupRepo.dispose();
          sessionRepo.dispose();
          container.dispose();
        });

        final sub = container.listen<ScheduledGroupAction?>(
          scheduledGroupCoordinatorProvider,
          (_, next) {
            if (next != null && !actionCompleter.isCompleted) {
              actionCompleter.complete(next);
            }
          },
        );
        addTearDown(sub.close);

        container.read(scheduledGroupCoordinatorProvider);

        final now = DateTime.now();
        final first = _buildScheduledGroup(
          id: 'group-phase5-action-a',
          scheduledStart: now.subtract(const Duration(hours: 2)),
          durationMinutes: 30,
          noticeMinutes: 5,
        );
        final second = _buildScheduledGroup(
          id: 'group-phase5-action-b',
          scheduledStart: now.subtract(const Duration(hours: 1)),
          durationMinutes: 30,
          noticeMinutes: 5,
        );

        sessionRepo.emit(null);
        await groupRepo.saveAll([first, second]);
        final lostGroups = await _awaitLostGroups(
          repo: groupRepo,
          groupIds: ['group-phase5-action-a', 'group-phase5-action-b'],
        );
        expect(lostGroups, hasLength(2));
        await _expectNoScheduledAction(actionCompleter);

        final merged = logs.join('\n');
        expect(
          merged.contains('[ScheduledActionDiag]'),
          isFalse,
          reason:
              'Phase-5 diagnostics contract: deterministic overdue handling must not emit legacy scheduled-action diagnostics.',
        );
        expect(
          merged.contains('[ScheduledGroups][evaluate]'),
          isTrue,
          reason:
              'Phase-5 diagnostics contract: scheduled processing still logs evaluation snapshots during deterministic transitions.',
        );
      },
    );

    test('marks three overdue groups as lost in chronological order', () async {
      final groupRepo = FakeTaskRunGroupRepository();
      final sessionRepo = FakePomodoroSessionRepository();
      final actionCompleter = Completer<ScheduledGroupAction>();
      final container = ProviderContainer(
        overrides: [
          appModeServiceProvider.overrideWithValue(AppModeService.memory()),
          taskRunGroupRepositoryProvider.overrideWithValue(groupRepo),
          pomodoroSessionRepositoryProvider.overrideWithValue(sessionRepo),
        ],
      );
      addTearDown(() {
        groupRepo.dispose();
        sessionRepo.dispose();
        container.dispose();
      });

      final sub = container.listen<ScheduledGroupAction?>(
        scheduledGroupCoordinatorProvider,
        (_, next) {
          if (next != null && !actionCompleter.isCompleted) {
            actionCompleter.complete(next);
          }
        },
      );
      addTearDown(sub.close);

      container.read(scheduledGroupCoordinatorProvider);

      final now = DateTime.now();
      final first = _buildScheduledGroup(
        id: 'group-a',
        scheduledStart: now.subtract(const Duration(hours: 4)),
        durationMinutes: 15,
        noticeMinutes: 1,
      );
      final second = _buildScheduledGroup(
        id: 'group-b',
        scheduledStart: now.subtract(const Duration(hours: 3, minutes: 30)),
        durationMinutes: 15,
        noticeMinutes: 1,
      );
      final third = _buildScheduledGroup(
        id: 'group-c',
        scheduledStart: now.subtract(const Duration(hours: 3)),
        durationMinutes: 15,
        noticeMinutes: 1,
      );

      sessionRepo.emit(null);
      await groupRepo.saveAll([first, second, third]);

      final lostGroups = await _awaitLostGroups(
        repo: groupRepo,
        groupIds: ['group-a', 'group-b', 'group-c'],
      );
      expect(lostGroups.map((group) => group.id), [
        'group-a',
        'group-b',
        'group-c',
      ]);
      expect(
        lostGroups.map((group) => group.canceledReason),
        everyElement('lost'),
      );
      expect(groupRepo.claimLateStartCalls, 0);
      await _expectNoScheduledAction(actionCompleter);
    });

    test(
      'does not auto-claim when heartbeat is missing and anchor is fresh',
      () async {
        final groupRepo = FakeTaskRunGroupRepository();
        final sessionRepo = FakePomodoroSessionRepository();
        final container = ProviderContainer(
          overrides: [
            appModeServiceProvider.overrideWithValue(AppModeService.memory()),
            taskRunGroupRepositoryProvider.overrideWithValue(groupRepo),
            pomodoroSessionRepositoryProvider.overrideWithValue(sessionRepo),
          ],
        );
        addTearDown(() {
          groupRepo.dispose();
          sessionRepo.dispose();
          container.dispose();
        });

        final sub = container.listen<ScheduledGroupAction?>(
          scheduledGroupCoordinatorProvider,
          (_, __) {},
        );
        addTearDown(sub.close);

        container.read(scheduledGroupCoordinatorProvider);

        final now = DateTime.now();
        final anchor = now.subtract(const Duration(seconds: 10));
        final first =
            _buildScheduledGroup(
              id: 'group-stale-1',
              scheduledStart: now.subtract(const Duration(hours: 2)),
              durationMinutes: 15,
              noticeMinutes: 1,
            ).copyWith(
              lateStartAnchorAt: anchor,
              lateStartQueueId: 'queue-1',
              lateStartQueueOrder: 0,
              lateStartOwnerDeviceId: 'device-other',
              lateStartOwnerHeartbeatAt: null,
            );
        final second =
            _buildScheduledGroup(
              id: 'group-stale-1b',
              scheduledStart: now.subtract(
                const Duration(hours: 1, minutes: 45),
              ),
              durationMinutes: 15,
              noticeMinutes: 1,
            ).copyWith(
              lateStartAnchorAt: anchor,
              lateStartQueueId: 'queue-1',
              lateStartQueueOrder: 1,
              lateStartOwnerDeviceId: 'device-other',
              lateStartOwnerHeartbeatAt: null,
            );

        sessionRepo.emit(null);
        await groupRepo.saveAll([first, second]);

        final lostGroups = await _awaitLostGroups(
          repo: groupRepo,
          groupIds: ['group-stale-1', 'group-stale-1b'],
        );
        expect(lostGroups, hasLength(2));
        expect(
          lostGroups.map((group) => group.canceledReason),
          everyElement('lost'),
        );
        expect(groupRepo.claimLateStartCalls, 0);

        final stored = await groupRepo.getById(first.id);
        expect(stored?.lateStartOwnerDeviceId, 'device-other');
      },
    );

    test(
      'does not auto-claim when heartbeat is missing and anchor is stale',
      () async {
        final groupRepo = FakeTaskRunGroupRepository();
        final sessionRepo = FakePomodoroSessionRepository();
        final actionCompleter = Completer<ScheduledGroupAction>();
        final container = ProviderContainer(
          overrides: [
            appModeServiceProvider.overrideWithValue(AppModeService.memory()),
            taskRunGroupRepositoryProvider.overrideWithValue(groupRepo),
            pomodoroSessionRepositoryProvider.overrideWithValue(sessionRepo),
          ],
        );
        addTearDown(() {
          groupRepo.dispose();
          sessionRepo.dispose();
          container.dispose();
        });

        final sub = container.listen<ScheduledGroupAction?>(
          scheduledGroupCoordinatorProvider,
          (_, next) {
            if (next != null && !actionCompleter.isCompleted) {
              actionCompleter.complete(next);
            }
          },
        );
        addTearDown(sub.close);

        container.read(scheduledGroupCoordinatorProvider);

        final now = DateTime.now();
        final anchor = now.subtract(const Duration(seconds: 60));
        final first =
            _buildScheduledGroup(
              id: 'group-stale-2',
              scheduledStart: now.subtract(const Duration(hours: 2)),
              durationMinutes: 15,
              noticeMinutes: 1,
            ).copyWith(
              lateStartAnchorAt: anchor,
              lateStartQueueId: 'queue-2',
              lateStartQueueOrder: 0,
              lateStartOwnerDeviceId: 'device-other',
              lateStartOwnerHeartbeatAt: null,
            );
        final second =
            _buildScheduledGroup(
              id: 'group-stale-2b',
              scheduledStart: now.subtract(
                const Duration(hours: 1, minutes: 45),
              ),
              durationMinutes: 15,
              noticeMinutes: 1,
            ).copyWith(
              lateStartAnchorAt: anchor,
              lateStartQueueId: 'queue-2',
              lateStartQueueOrder: 1,
              lateStartOwnerDeviceId: 'device-other',
              lateStartOwnerHeartbeatAt: null,
            );

        sessionRepo.emit(null);
        await groupRepo.saveAll([first, second]);

        final lostGroups = await _awaitLostGroups(
          repo: groupRepo,
          groupIds: ['group-stale-2', 'group-stale-2b'],
        );
        expect(lostGroups, hasLength(2));
        expect(
          lostGroups.map((group) => group.status),
          everyElement(TaskRunStatus.canceled),
        );
        expect(
          lostGroups.map((group) => group.canceledReason),
          everyElement('lost'),
        );
        expect(groupRepo.claimLateStartCalls, 0);
        await _expectNoScheduledAction(actionCompleter);

        final stored = await groupRepo.getById(first.id);
        expect(stored?.lateStartOwnerDeviceId, 'device-other');
      },
    );
  });

  group('ScheduledGroupCoordinator auto-start catch-up', () {
    test(
      'launch catch-up auto-starts overdue scheduled group and emits openTimer action',
      () async {
        final now = DateTime.now();
        final groupRepo = FakeTaskRunGroupRepository();
        final sessionRepo = FakePomodoroSessionRepository();
        final appModeService = AppModeService.memory();
        final actionCompleter = Completer<ScheduledGroupAction>();
        final container = ProviderContainer(
          overrides: [
            appModeServiceProvider.overrideWithValue(appModeService),
            taskRunGroupRepositoryProvider.overrideWithValue(groupRepo),
            pomodoroSessionRepositoryProvider.overrideWithValue(sessionRepo),
          ],
        );
        addTearDown(() {
          groupRepo.dispose();
          sessionRepo.dispose();
          container.dispose();
        });

        final sub = container.listen<ScheduledGroupAction?>(
          scheduledGroupCoordinatorProvider,
          (_, next) {
            if (next != null && !actionCompleter.isCompleted) {
              actionCompleter.complete(next);
            }
          },
        );
        addTearDown(sub.close);

        container.read(scheduledGroupCoordinatorProvider);
        sessionRepo.emit(null);
        groupRepo.seed(
          _buildScheduledGroup(
            id: 'group-launch-catch-up',
            scheduledStart: now.subtract(const Duration(minutes: 2)),
            durationMinutes: 30,
            noticeMinutes: 0,
          ),
        );

        await _pumpQueue();

        final action = await actionCompleter.future.timeout(
          const Duration(seconds: 1),
        );
        expect(action.type, ScheduledGroupActionType.openTimer);
        expect(action.groupId, 'group-launch-catch-up');

        final stored = await groupRepo.getById('group-launch-catch-up');
        expect(stored?.status, TaskRunStatus.running);
        expect(stored?.actualStartTime, isNotNull);
        expect(sessionRepo.publishCount, 1);
        expect(
          sessionRepo.lastPublishedSession?.groupId,
          'group-launch-catch-up',
        );
      },
    );

    test(
      'resume catch-up starts overdue scheduled group once timeSync becomes available in account mode',
      () async {
        final now = DateTime.now();
        final groupRepo = FakeTaskRunGroupRepository();
        final sessionRepo = FakePomodoroSessionRepository();
        final appModeService = AppModeService.memory();
        final timeSync = FakeTimeSyncService(initialOffset: null);
        final coordinatorAction = Completer<ScheduledGroupAction>();
        final container = ProviderContainer(
          overrides: [
            appModeServiceProvider.overrideWithValue(appModeService),
            taskRunGroupRepositoryProvider.overrideWithValue(groupRepo),
            pomodoroSessionRepositoryProvider.overrideWithValue(sessionRepo),
            timeSyncServiceProvider.overrideWithValue(timeSync),
          ],
        );
        addTearDown(() {
          groupRepo.dispose();
          sessionRepo.dispose();
          container.dispose();
        });

        final sub = container.listen<ScheduledGroupAction?>(
          scheduledGroupCoordinatorProvider,
          (_, next) {
            if (next != null && !coordinatorAction.isCompleted) {
              coordinatorAction.complete(next);
            }
          },
        );
        addTearDown(sub.close);

        final coordinator = container.read(
          scheduledGroupCoordinatorProvider.notifier,
        );
        await container.read(appModeProvider.notifier).setAccount();
        await _pumpQueue();

        sessionRepo.emit(null);
        groupRepo.seed(
          _buildScheduledGroup(
            id: 'group-resume-catch-up',
            scheduledStart: now.subtract(const Duration(minutes: 3)),
            durationMinutes: 30,
            noticeMinutes: 0,
          ),
        );
        await _pumpQueue();

        final beforeResume = await groupRepo.getById('group-resume-catch-up');
        expect(beforeResume?.status, TaskRunStatus.scheduled);
        expect(sessionRepo.publishCount, 0);

        timeSync.setOffset(Duration.zero);
        coordinator.onAppResumed();
        await _pumpQueue();

        final action = await coordinatorAction.future.timeout(
          const Duration(seconds: 1),
        );
        expect(action.type, ScheduledGroupActionType.openTimer);
        expect(action.groupId, 'group-resume-catch-up');

        final afterResume = await groupRepo.getById('group-resume-catch-up');
        expect(afterResume?.status, TaskRunStatus.running);
        expect(afterResume?.actualStartTime, isNotNull);
        expect(sessionRepo.publishCount, 1);
        expect(
          sessionRepo.lastPublishedSession?.groupId,
          'group-resume-catch-up',
        );
      },
    );

    test(
      'rechecks overdue scheduled auto-start when active session ends',
      () async {
        final now = DateTime.now();
        final groupRepo = FakeTaskRunGroupRepository();
        final sessionRepo = FakePomodoroSessionRepository();
        final appModeService = AppModeService.memory();
        final timeSync = FakeTimeSyncService(initialOffset: null);
        final coordinatorAction = Completer<ScheduledGroupAction>();
        final container = ProviderContainer(
          overrides: [
            appModeServiceProvider.overrideWithValue(appModeService),
            taskRunGroupRepositoryProvider.overrideWithValue(groupRepo),
            pomodoroSessionRepositoryProvider.overrideWithValue(sessionRepo),
            timeSyncServiceProvider.overrideWithValue(timeSync),
          ],
        );
        addTearDown(() {
          groupRepo.dispose();
          sessionRepo.dispose();
          container.dispose();
        });

        final sub = container.listen<ScheduledGroupAction?>(
          scheduledGroupCoordinatorProvider,
          (_, next) {
            if (next != null && !coordinatorAction.isCompleted) {
              coordinatorAction.complete(next);
            }
          },
        );
        addTearDown(sub.close);

        container.read(scheduledGroupCoordinatorProvider);
        await container.read(appModeProvider.notifier).setAccount();
        await _pumpQueue();

        sessionRepo.emit(
          _buildRunningSession(
            groupId: 'legacy-session',
            ownerId: 'device-legacy',
            now: now,
          ),
        );
        await _pumpQueue();

        groupRepo.seed(
          _buildScheduledGroup(
            id: 'group-recheck-active-end',
            scheduledStart: now.subtract(const Duration(minutes: 2)),
            durationMinutes: 30,
            noticeMinutes: 0,
          ),
        );
        await _pumpQueue();

        final beforeResume = await groupRepo.getById(
          'group-recheck-active-end',
        );
        expect(beforeResume?.status, TaskRunStatus.scheduled);
        expect(sessionRepo.publishCount, 0);

        timeSync.setOffset(Duration.zero);
        sessionRepo.emit(null);

        final action = await coordinatorAction.future.timeout(
          const Duration(seconds: 1),
        );
        expect(action.type, ScheduledGroupActionType.openTimer);
        expect(action.groupId, 'group-recheck-active-end');

        final afterResume = await groupRepo.getById('group-recheck-active-end');
        expect(afterResume?.status, TaskRunStatus.running);
        expect(afterResume?.actualStartTime, isNotNull);
        expect(sessionRepo.publishCount, 1);
        expect(
          sessionRepo.lastPublishedSession?.groupId,
          'group-recheck-active-end',
        );
      },
    );
  });

  group('ScheduledGroupCoordinator running expiry auto-complete', () {
    test(
      'completes expired running group and unblocks overdue scheduled auto-start',
      () async {
        final now = DateTime.now();
        final groupRepo = FakeTaskRunGroupRepository();
        final sessionRepo = FakePomodoroSessionRepository();
        final actionCompleter = Completer<ScheduledGroupAction>();
        final container = ProviderContainer(
          overrides: [
            appModeServiceProvider.overrideWithValue(AppModeService.memory()),
            taskRunGroupRepositoryProvider.overrideWithValue(groupRepo),
            pomodoroSessionRepositoryProvider.overrideWithValue(sessionRepo),
          ],
        );
        addTearDown(() {
          groupRepo.dispose();
          sessionRepo.dispose();
          container.dispose();
        });

        final sub = container.listen<ScheduledGroupAction?>(
          scheduledGroupCoordinatorProvider,
          (_, next) {
            if (next != null && !actionCompleter.isCompleted) {
              actionCompleter.complete(next);
            }
          },
        );
        addTearDown(sub.close);

        container.read(scheduledGroupCoordinatorProvider);

        final ownerId = container.read(deviceInfoServiceProvider).deviceId;
        sessionRepo.emit(
          _buildRunningSession(
            groupId: 'group-expired-running',
            ownerId: ownerId,
            now: now,
            lastUpdatedAt: now.subtract(const Duration(minutes: 2)),
          ),
        );
        await _pumpQueue();

        final expiredRunning = _buildRunningGroup(
          id: 'group-expired-running',
          start: now.subtract(const Duration(hours: 2)),
          theoreticalEnd: now.subtract(const Duration(minutes: 30)),
        );
        final overdueScheduled = _buildScheduledGroup(
          id: 'group-unblocked-scheduled',
          scheduledStart: now.subtract(const Duration(minutes: 5)),
          durationMinutes: 30,
          noticeMinutes: 0,
        );
        await groupRepo.saveAll([expiredRunning, overdueScheduled]);
        await _pumpQueue();

        final action = await actionCompleter.future.timeout(
          const Duration(seconds: 1),
        );
        expect(action.type, ScheduledGroupActionType.openTimer);
        expect(action.groupId, 'group-unblocked-scheduled');

        final expiredStored = await groupRepo.getById('group-expired-running');
        final unblockedStored = await groupRepo.getById(
          'group-unblocked-scheduled',
        );
        expect(expiredStored?.status, TaskRunStatus.completed);
        expect(unblockedStored?.status, TaskRunStatus.running);
        expect(sessionRepo.clearSessionAsOwnerCount, greaterThan(0));
        expect(sessionRepo.publishCount, 1);
        expect(
          sessionRepo.lastPublishedSession?.groupId,
          'group-unblocked-scheduled',
        );
      },
    );

    test(
      'clears stale non-owner active session when expired running group unblocks overdue scheduled start',
      () async {
        final now = DateTime.now();
        final groupRepo = FakeTaskRunGroupRepository();
        final sessionRepo = FakePomodoroSessionRepository();
        final actionCompleter = Completer<ScheduledGroupAction>();
        final container = ProviderContainer(
          overrides: [
            appModeServiceProvider.overrideWithValue(AppModeService.memory()),
            taskRunGroupRepositoryProvider.overrideWithValue(groupRepo),
            pomodoroSessionRepositoryProvider.overrideWithValue(sessionRepo),
          ],
        );
        addTearDown(() {
          groupRepo.dispose();
          sessionRepo.dispose();
          container.dispose();
        });

        final sub = container.listen<ScheduledGroupAction?>(
          scheduledGroupCoordinatorProvider,
          (_, next) {
            if (next != null && !actionCompleter.isCompleted) {
              actionCompleter.complete(next);
            }
          },
        );
        addTearDown(sub.close);

        container.read(scheduledGroupCoordinatorProvider);

        sessionRepo.emit(
          _buildRunningSession(
            groupId: 'group-expired-running-stale',
            ownerId: 'device-other',
            now: now,
            lastUpdatedAt: now.subtract(const Duration(minutes: 2)),
          ),
        );
        await _pumpQueue();

        final expiredRunning = _buildRunningGroup(
          id: 'group-expired-running-stale',
          start: now.subtract(const Duration(hours: 2)),
          theoreticalEnd: now.subtract(const Duration(minutes: 30)),
        );
        final overdueScheduled = _buildScheduledGroup(
          id: 'group-unblocked-stale',
          scheduledStart: now.subtract(const Duration(minutes: 5)),
          durationMinutes: 30,
          noticeMinutes: 0,
        );
        await groupRepo.saveAll([expiredRunning, overdueScheduled]);
        await _pumpQueue();

        final action = await actionCompleter.future.timeout(
          const Duration(seconds: 1),
        );
        expect(action.type, ScheduledGroupActionType.openTimer);
        expect(action.groupId, 'group-unblocked-stale');

        final expiredStored = await groupRepo.getById(
          'group-expired-running-stale',
        );
        final unblockedStored = await groupRepo.getById(
          'group-unblocked-stale',
        );
        expect(expiredStored?.status, TaskRunStatus.completed);
        expect(unblockedStored?.status, TaskRunStatus.running);
        expect(sessionRepo.clearSessionIfStaleCount, greaterThan(0));
        expect(sessionRepo.clearSessionAsOwnerCount, 0);
        expect(sessionRepo.publishCount, 1);
        expect(
          sessionRepo.lastPublishedSession?.groupId,
          'group-unblocked-stale',
        );
      },
    );

    test(
      'completes expired running group without active session and routes to Groups Hub',
      () async {
        final now = DateTime.now();
        final groupRepo = FakeTaskRunGroupRepository();
        final sessionRepo = FakePomodoroSessionRepository();
        final actionCompleter = Completer<ScheduledGroupAction>();
        final container = ProviderContainer(
          overrides: [
            appModeServiceProvider.overrideWithValue(AppModeService.memory()),
            taskRunGroupRepositoryProvider.overrideWithValue(groupRepo),
            pomodoroSessionRepositoryProvider.overrideWithValue(sessionRepo),
          ],
        );
        addTearDown(() {
          groupRepo.dispose();
          sessionRepo.dispose();
          container.dispose();
        });

        final sub = container.listen<ScheduledGroupAction?>(
          scheduledGroupCoordinatorProvider,
          (_, next) {
            if (next != null && !actionCompleter.isCompleted) {
              actionCompleter.complete(next);
            }
          },
        );
        addTearDown(sub.close);

        container.read(scheduledGroupCoordinatorProvider);
        sessionRepo.emit(null);
        await _pumpQueue();

        await groupRepo.save(
          _buildRunningGroup(
            id: 'group-expired-no-session',
            start: now.subtract(const Duration(hours: 2)),
            theoreticalEnd: now.subtract(const Duration(minutes: 30)),
          ),
        );
        await _pumpQueue();

        final action = await actionCompleter.future.timeout(
          const Duration(seconds: 1),
        );
        expect(action.type, ScheduledGroupActionType.openGroupsHub);

        final stored = await groupRepo.getById('group-expired-no-session');
        expect(stored?.status, TaskRunStatus.completed);
        expect(sessionRepo.publishCount, 0);
      },
    );
  });

  group('ScheduledGroupCoordinator at-risk scheduled projection', () {
    test(
      'marks scheduled groups as at-risk when execution window is active',
      () async {
        final groupRepo = FakeTaskRunGroupRepository();
        final sessionRepo = FakePomodoroSessionRepository();
        final appModeService = AppModeService.memory();
        final container = ProviderContainer(
          overrides: [
            appModeServiceProvider.overrideWithValue(appModeService),
            taskRunGroupRepositoryProvider.overrideWithValue(groupRepo),
            pomodoroSessionRepositoryProvider.overrideWithValue(sessionRepo),
          ],
        );
        addTearDown(() {
          groupRepo.dispose();
          sessionRepo.dispose();
          container.dispose();
        });

        final sub = container.listen<ScheduledGroupAction?>(
          scheduledGroupCoordinatorProvider,
          (_, __) {},
        );
        addTearDown(sub.close);

        final coordinator = container.read(
          scheduledGroupCoordinatorProvider.notifier,
        );

        final now = DateTime.now();
        final scheduled = _buildScheduledGroup(
          id: 'scheduled-boundary',
          scheduledStart: now.subtract(const Duration(minutes: 1)),
          durationMinutes: 30,
          noticeMinutes: 5,
        );
        final running = _buildRunningGroup(
          id: 'running-boundary',
          start: now.subtract(const Duration(minutes: 30)),
          theoreticalEnd: now.add(const Duration(minutes: 30)),
        );

        coordinator.debugEvaluateRunningOverlap(
          running: [running],
          scheduled: [scheduled],
          allGroups: [running, scheduled],
          session: null,
          now: now,
        );

        final atRiskIds = container.read(atRiskScheduledGroupIdsProvider);
        final decision = container.read(runningOverlapDecisionProvider);
        expect(atRiskIds, contains(scheduled.id));
        expect(decision, isNull);
      },
    );

    test(
      'marks at-risk set before execution window when projected end reaches start',
      () async {
        final groupRepo = FakeTaskRunGroupRepository();
        final sessionRepo = FakePomodoroSessionRepository();
        final appModeService = AppModeService.memory();
        final container = ProviderContainer(
          overrides: [
            appModeServiceProvider.overrideWithValue(appModeService),
            taskRunGroupRepositoryProvider.overrideWithValue(groupRepo),
            pomodoroSessionRepositoryProvider.overrideWithValue(sessionRepo),
          ],
        );
        addTearDown(() {
          groupRepo.dispose();
          sessionRepo.dispose();
          container.dispose();
        });

        final sub = container.listen<ScheduledGroupAction?>(
          scheduledGroupCoordinatorProvider,
          (_, __) {},
        );
        addTearDown(sub.close);

        final coordinator = container.read(
          scheduledGroupCoordinatorProvider.notifier,
        );

        final now = DateTime.now();
        final running = _buildRunningGroup(
          id: 'running-1',
          start: now.subtract(const Duration(minutes: 30)),
          theoreticalEnd: now.add(const Duration(minutes: 30)),
        );
        final scheduled = _buildScheduledGroup(
          id: 'scheduled-1',
          scheduledStart: now.add(const Duration(minutes: 10)),
          durationMinutes: 30,
          noticeMinutes: 5,
        );
        final preRunStart = scheduled.scheduledStartTime!.subtract(
          Duration(minutes: 5),
        );
        expect(running.theoreticalEndTime.isAfter(preRunStart), isTrue);
        expect(now.isBefore(preRunStart), isTrue);

        coordinator.debugEvaluateRunningOverlap(
          running: [running],
          scheduled: [scheduled],
          allGroups: [running, scheduled],
          session: null,
          now: now,
        );

        final atRiskIds = container.read(atRiskScheduledGroupIdsProvider);
        final decision = container.read(runningOverlapDecisionProvider);
        expect(atRiskIds, contains(scheduled.id));
        expect(decision, isNull);
      },
    );

    test(
      'keeps at-risk set empty before execution window when projected end is before start',
      () async {
        final groupRepo = FakeTaskRunGroupRepository();
        final sessionRepo = FakePomodoroSessionRepository();
        final appModeService = AppModeService.memory();
        final container = ProviderContainer(
          overrides: [
            appModeServiceProvider.overrideWithValue(appModeService),
            taskRunGroupRepositoryProvider.overrideWithValue(groupRepo),
            pomodoroSessionRepositoryProvider.overrideWithValue(sessionRepo),
          ],
        );
        addTearDown(() {
          groupRepo.dispose();
          sessionRepo.dispose();
          container.dispose();
        });

        final sub = container.listen<ScheduledGroupAction?>(
          scheduledGroupCoordinatorProvider,
          (_, __) {},
        );
        addTearDown(sub.close);

        final coordinator = container.read(
          scheduledGroupCoordinatorProvider.notifier,
        );

        final now = DateTime.now();
        final running = _buildRunningGroup(
          id: 'running-1',
          start: now.subtract(const Duration(minutes: 30)),
          theoreticalEnd: now.add(const Duration(minutes: 5)),
        );
        final scheduled = _buildScheduledGroup(
          id: 'scheduled-1',
          scheduledStart: now.add(const Duration(minutes: 12)),
          durationMinutes: 30,
          noticeMinutes: 5,
        );
        final preRunStart = scheduled.scheduledStartTime!.subtract(
          Duration(minutes: 5),
        );
        expect(
          running.theoreticalEndTime.isBefore(scheduled.scheduledStartTime!),
          isTrue,
        );
        expect(now.isBefore(preRunStart), isTrue);

        coordinator.debugEvaluateRunningOverlap(
          running: [running],
          scheduled: [scheduled],
          allGroups: [running, scheduled],
          session: null,
          now: now,
        );

        final atRiskIds = container.read(atRiskScheduledGroupIdsProvider);
        final decision = container.read(runningOverlapDecisionProvider);
        expect(atRiskIds, isEmpty);
        expect(decision, isNull);
      },
    );

    test(
      'marks at-risk set for non-owner session when window is active',
      () async {
        final now = DateTime.now();
        final running = _buildRunningGroup(
          id: 'running-2',
          start: now.subtract(const Duration(minutes: 30)),
          theoreticalEnd: now.add(const Duration(minutes: 30)),
        );
        final scheduled = _buildScheduledGroup(
          id: 'scheduled-2',
          scheduledStart: now.subtract(const Duration(minutes: 1)),
          durationMinutes: 30,
          noticeMinutes: 5,
        );
        final groupRepo = FakeTaskRunGroupRepository();
        final sessionRepo = FakePomodoroSessionRepository();
        final appModeService = AppModeService.memory();
        final deviceInfo = DeviceInfoService.ephemeral();
        final session = _buildRunningSession(
          groupId: running.id,
          ownerId: '${deviceInfo.deviceId}-other',
          now: now,
        );
        final container = ProviderContainer(
          overrides: [
            appModeServiceProvider.overrideWithValue(appModeService),
            taskRunGroupRepositoryProvider.overrideWithValue(groupRepo),
            pomodoroSessionRepositoryProvider.overrideWithValue(sessionRepo),
            deviceInfoServiceProvider.overrideWithValue(deviceInfo),
            activePomodoroSessionProvider.overrideWithValue(session),
          ],
        );
        addTearDown(() {
          groupRepo.dispose();
          sessionRepo.dispose();
          container.dispose();
        });

        final sub = container.listen<ScheduledGroupAction?>(
          scheduledGroupCoordinatorProvider,
          (_, __) {},
        );
        addTearDown(sub.close);

        final coordinator = container.read(
          scheduledGroupCoordinatorProvider.notifier,
        );

        coordinator.debugEvaluateRunningOverlap(
          running: [running],
          scheduled: [scheduled],
          allGroups: [running, scheduled],
          session: session,
          now: now,
        );

        final atRiskIds = container.read(atRiskScheduledGroupIdsProvider);
        final decision = container.read(runningOverlapDecisionProvider);
        expect(atRiskIds, contains(scheduled.id));
        expect(decision, isNull);
      },
    );

    test(
      'uses paused session projection for postponed groups before at-risk marking',
      () async {
        final groupRepo = FakeTaskRunGroupRepository();
        final sessionRepo = FakePomodoroSessionRepository();
        final appModeService = AppModeService.memory();
        final container = ProviderContainer(
          overrides: [
            appModeServiceProvider.overrideWithValue(appModeService),
            taskRunGroupRepositoryProvider.overrideWithValue(groupRepo),
            pomodoroSessionRepositoryProvider.overrideWithValue(sessionRepo),
          ],
        );
        addTearDown(() {
          groupRepo.dispose();
          sessionRepo.dispose();
          container.dispose();
        });

        final sub = container.listen<ScheduledGroupAction?>(
          scheduledGroupCoordinatorProvider,
          (_, __) {},
        );
        addTearDown(sub.close);

        final coordinator = container.read(
          scheduledGroupCoordinatorProvider.notifier,
        );

        final now = DateTime.now();
        final running = _buildRunningGroup(
          id: 'running-paused',
          start: now.subtract(const Duration(minutes: 30)),
          theoreticalEnd: now.add(const Duration(minutes: 2)),
        );
        final scheduled = _buildScheduledGroup(
          id: 'scheduled-paused',
          scheduledStart: now.add(const Duration(minutes: 10)),
          durationMinutes: 30,
          noticeMinutes: 5,
        ).copyWith(postponedAfterGroupId: running.id);
        final session = _buildPausedSession(
          groupId: running.id,
          ownerId: container.read(deviceInfoServiceProvider).deviceId,
          now: now,
        );

        coordinator.debugEvaluateRunningOverlap(
          running: [running],
          scheduled: [scheduled],
          allGroups: [running, scheduled],
          session: session,
          now: now,
        );

        final atRiskIds = container.read(atRiskScheduledGroupIdsProvider);
        final decision = container.read(runningOverlapDecisionProvider);
        expect(atRiskIds, isEmpty);
        expect(decision, isNull);
      },
    );

    test(
      'marks at-risk set when paused projection reaches scheduled start',
      () async {
        final groupRepo = FakeTaskRunGroupRepository();
        final sessionRepo = FakePomodoroSessionRepository();
        final appModeService = AppModeService.memory();
        final container = ProviderContainer(
          overrides: [
            appModeServiceProvider.overrideWithValue(appModeService),
            taskRunGroupRepositoryProvider.overrideWithValue(groupRepo),
            pomodoroSessionRepositoryProvider.overrideWithValue(sessionRepo),
          ],
        );
        addTearDown(() {
          groupRepo.dispose();
          sessionRepo.dispose();
          container.dispose();
        });

        final sub = container.listen<ScheduledGroupAction?>(
          scheduledGroupCoordinatorProvider,
          (_, __) {},
        );
        addTearDown(sub.close);

        final coordinator = container.read(
          scheduledGroupCoordinatorProvider.notifier,
        );

        final now = DateTime.now();
        final running = _buildRunningGroup(
          id: 'running-paused-predictive',
          start: now.subtract(const Duration(minutes: 30)),
          theoreticalEnd: now.add(const Duration(minutes: 2)),
        );
        final scheduled = _buildScheduledGroup(
          id: 'scheduled-paused-predictive',
          scheduledStart: now.add(const Duration(minutes: 6)),
          durationMinutes: 30,
          noticeMinutes: 5,
        );
        final session = _buildPausedSession(
          groupId: running.id,
          ownerId: container.read(deviceInfoServiceProvider).deviceId,
          now: now,
        );

        coordinator.debugEvaluateRunningOverlap(
          running: [running],
          scheduled: [scheduled],
          allGroups: [running, scheduled],
          session: session,
          now: now,
        );

        final atRiskIds = container.read(atRiskScheduledGroupIdsProvider);
        final decision = container.read(runningOverlapDecisionProvider);
        expect(now.isBefore(scheduled.scheduledStartTime!), isTrue);
        expect(atRiskIds, contains(scheduled.id));
        expect(decision, isNull);
      },
    );

    test(
      'does not flag overlap when scheduled group follows running group',
      () async {
        final groupRepo = FakeTaskRunGroupRepository();
        final sessionRepo = FakePomodoroSessionRepository();
        final appModeService = AppModeService.memory();
        final container = ProviderContainer(
          overrides: [
            appModeServiceProvider.overrideWithValue(appModeService),
            taskRunGroupRepositoryProvider.overrideWithValue(groupRepo),
            pomodoroSessionRepositoryProvider.overrideWithValue(sessionRepo),
          ],
        );
        addTearDown(() {
          groupRepo.dispose();
          sessionRepo.dispose();
          container.dispose();
        });

        final sub = container.listen<ScheduledGroupAction?>(
          scheduledGroupCoordinatorProvider,
          (_, __) {},
        );
        addTearDown(sub.close);

        final coordinator = container.read(
          scheduledGroupCoordinatorProvider.notifier,
        );

        final now = DateTime.now();
        final running = _buildRunningGroup(
          id: 'running-follow',
          start: now.subtract(const Duration(minutes: 30)),
          theoreticalEnd: now.add(const Duration(minutes: 20)),
        );
        final scheduled = _buildScheduledGroup(
          id: 'scheduled-follow',
          scheduledStart: now.add(const Duration(minutes: 10)),
          durationMinutes: 30,
          noticeMinutes: 5,
        ).copyWith(postponedAfterGroupId: running.id);

        coordinator.debugEvaluateRunningOverlap(
          running: [running],
          scheduled: [scheduled],
          allGroups: [running, scheduled],
          session: _buildRunningSession(
            groupId: running.id,
            ownerId: container.read(deviceInfoServiceProvider).deviceId,
            now: now,
          ),
          now: now,
        );

        final atRiskIds = container.read(atRiskScheduledGroupIdsProvider);
        final decision = container.read(runningOverlapDecisionProvider);
        expect(atRiskIds, isEmpty);
        expect(decision, isNull);
      },
    );
  });
}
