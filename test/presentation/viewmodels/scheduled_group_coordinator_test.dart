import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:focus_interval/data/models/pomodoro_session.dart';
import 'package:focus_interval/data/models/schema_version.dart';
import 'package:focus_interval/data/models/selected_sound.dart';
import 'package:focus_interval/data/models/task_run_group.dart';
import 'package:focus_interval/data/repositories/pomodoro_session_repository.dart';
import 'package:focus_interval/data/repositories/task_run_group_repository.dart';
import 'package:focus_interval/data/services/app_mode_service.dart';
import 'package:focus_interval/data/services/device_info_service.dart';
import 'package:focus_interval/domain/pomodoro_machine.dart';
import 'package:focus_interval/presentation/providers.dart';
import 'package:focus_interval/presentation/viewmodels/scheduled_group_coordinator.dart';

class FakeTaskRunGroupRepository implements TaskRunGroupRepository {
  final Map<String, TaskRunGroup> _store = {};
  final StreamController<List<TaskRunGroup>> _controller =
      StreamController<List<TaskRunGroup>>.broadcast();

  void seed(TaskRunGroup group) {
    _store[group.id] = group;
    _emit();
  }

  void _emit() {
    _controller.add(_store.values.toList());
  }

  @override
  Stream<List<TaskRunGroup>> watchAll() => _controller.stream;

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

  void emit(PomodoroSession? session) {
    _lastSession = session;
    _controller.add(session);
  }

  @override
  Stream<PomodoroSession?> watchSession() => _controller.stream;

  @override
  Future<PomodoroSession?> fetchSession({bool preferServer = false}) async {
    return _lastSession;
  }

  @override
  Future<void> publishSession(PomodoroSession session) async {}

  @override
  Future<bool> tryClaimSession(PomodoroSession session) async => true;

  @override
  Future<void> clearSessionAsOwner() async {}

  @override
  Future<void> clearSessionIfStale({required DateTime now}) async {}

  @override
  Future<void> clearSessionIfGroupNotRunning() async {}

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
  }) async {}

  void dispose() {
    _controller.close();
  }
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
    theoreticalEndTime:
        scheduledStart.add(Duration(minutes: durationMinutes)),
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
    ownerDeviceId: ownerId,
    status: PomodoroStatus.paused,
    phase: PomodoroPhase.pomodoro,
    currentPomodoro: 1,
    totalPomodoros: 2,
    phaseDurationSeconds: 25 * 60,
    remainingSeconds: 1200,
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
}) {
  return PomodoroSession(
    taskId: 'task-1',
    groupId: groupId,
    currentTaskId: 'task-1',
    currentTaskIndex: 0,
    totalTasks: 1,
    dataVersion: kCurrentDataVersion,
    ownerDeviceId: ownerId,
    status: PomodoroStatus.pomodoroRunning,
    phase: PomodoroPhase.pomodoro,
    currentPomodoro: 1,
    totalPomodoros: 2,
    phaseDurationSeconds: 25 * 60,
    remainingSeconds: 1200,
    phaseStartedAt: now.subtract(const Duration(minutes: 10)),
    currentTaskStartedAt: now.subtract(const Duration(minutes: 10)),
    pausedAt: null,
    lastUpdatedAt: now,
    finishedAt: null,
    pauseReason: null,
  );
}

Future<void> _pumpQueue() async {
  await Future<void>.delayed(const Duration(milliseconds: 50));
  await Future<void>.delayed(const Duration(milliseconds: 50));
}

void main() {
  group('ScheduledGroupCoordinator paused expiry guard', () {
    test('does not complete running group while session stream is loading',
        () async {
      final groupRepo = FakeTaskRunGroupRepository();
      final sessionRepo = FakePomodoroSessionRepository();
      final container = ProviderContainer(
        overrides: [
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
    });

    test('does not complete running group when active session is paused',
        () async {
      final groupRepo = FakeTaskRunGroupRepository();
      final sessionRepo = FakePomodoroSessionRepository();
      final container = ProviderContainer(
        overrides: [
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
    });

    test('does not complete when first snapshot is null then paused',
        () async {
      final groupRepo = FakeTaskRunGroupRepository();
      final sessionRepo = FakePomodoroSessionRepository();
      final container = ProviderContainer(
        overrides: [
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

    test('does not complete when active session belongs to another group',
        () async {
      final groupRepo = FakeTaskRunGroupRepository();
      final sessionRepo = FakePomodoroSessionRepository();
      final container = ProviderContainer(
        overrides: [
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
    });
  });

  group('ScheduledGroupCoordinator late-start queue', () {
    test('emits late-start queue when multiple overdue groups exist', () async {
      final groupRepo = FakeTaskRunGroupRepository();
      final sessionRepo = FakePomodoroSessionRepository();
      final actionCompleter = Completer<ScheduledGroupAction>();
      final container = ProviderContainer(
        overrides: [
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

      await _pumpQueue();

      final action = await actionCompleter.future.timeout(
        const Duration(seconds: 1),
      );
      expect(action.type, ScheduledGroupActionType.lateStartQueue);
      expect(action.groupIds, ['group-a', 'group-b']);
      expect(action.anchor, isNotNull);
    });

    test('emits late-start queue when three overdue groups exist', () async {
      final groupRepo = FakeTaskRunGroupRepository();
      final sessionRepo = FakePomodoroSessionRepository();
      final actionCompleter = Completer<ScheduledGroupAction>();
      final container = ProviderContainer(
        overrides: [
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

      await _pumpQueue();

      final action = await actionCompleter.future.timeout(
        const Duration(seconds: 1),
      );
      expect(action.type, ScheduledGroupActionType.lateStartQueue);
      expect(action.groupIds, ['group-a', 'group-b', 'group-c']);
      expect(action.anchor, isNotNull);
    });
  });

  group('ScheduledGroupCoordinator running overlap decision', () {
    test('sets running overlap decision before pre-run window when overlap exists',
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

      final coordinator =
          container.read(scheduledGroupCoordinatorProvider.notifier);

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
      final preRunStart =
          scheduled.scheduledStartTime!.subtract(Duration(minutes: 5));
      expect(running.theoreticalEndTime.isAfter(preRunStart), isTrue);
      expect(DateTime.now().isBefore(preRunStart), isTrue);

      coordinator.debugEvaluateRunningOverlap(
        running: [running],
        scheduled: [scheduled],
        allGroups: [running, scheduled],
        session: null,
        now: DateTime.now(),
      );

      final decision = container.read(runningOverlapDecisionProvider);
      expect(decision, isNotNull);
      expect(decision?.runningGroupId, running.id);
      expect(decision?.scheduledGroupId, scheduled.id);
    });

    test('sets running overlap decision in account mode for non-owner',
        () async {
      final now = DateTime.now();
      final running = _buildRunningGroup(
        id: 'running-2',
        start: now.subtract(const Duration(minutes: 30)),
        theoreticalEnd: now.add(const Duration(minutes: 30)),
      );
      final scheduled = _buildScheduledGroup(
        id: 'scheduled-2',
        scheduledStart: now.add(const Duration(minutes: 2)),
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

      final coordinator =
          container.read(scheduledGroupCoordinatorProvider.notifier);
      await container.read(appModeProvider.notifier).setAccount();

      coordinator.debugEvaluateRunningOverlap(
        running: [running],
        scheduled: [scheduled],
        allGroups: [running, scheduled],
        session: session,
        now: DateTime.now(),
      );

      final decision = container.read(runningOverlapDecisionProvider);
      expect(decision, isNotNull);
      expect(decision?.runningGroupId, running.id);
      expect(decision?.scheduledGroupId, scheduled.id);
    });

    test('uses paused session projection to trigger overlap earlier', () async {
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

      final coordinator =
          container.read(scheduledGroupCoordinatorProvider.notifier);

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

      final decision = container.read(runningOverlapDecisionProvider);
      expect(decision, isNotNull);
      expect(decision?.runningGroupId, running.id);
      expect(decision?.scheduledGroupId, scheduled.id);
    });

    test('does not flag overlap when scheduled group follows running group',
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

      final coordinator =
          container.read(scheduledGroupCoordinatorProvider.notifier);

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

      final decision = container.read(runningOverlapDecisionProvider);
      expect(decision, isNull);
    });
  });
}
