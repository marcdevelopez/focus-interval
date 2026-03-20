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
import 'package:focus_interval/data/services/sound_service.dart';
import 'package:focus_interval/data/services/time_sync_service.dart';
import 'package:focus_interval/domain/pomodoro_machine.dart';
import 'package:focus_interval/presentation/providers.dart';
import 'package:focus_interval/presentation/viewmodels/pomodoro_view_model.dart';

class FakeTaskRunGroupRepository implements TaskRunGroupRepository {
  final Map<String, TaskRunGroup> _store = {};
  final List<TaskRunGroup> saved = [];

  void seed(TaskRunGroup group) {
    _store[group.id] = group;
  }

  @override
  Stream<List<TaskRunGroup>> watchAll() => Stream.value(_store.values.toList());

  @override
  Future<List<TaskRunGroup>> getAll() async => _store.values.toList();

  @override
  Future<TaskRunGroup?> getById(String id) async => _store[id];

  @override
  Future<void> save(TaskRunGroup group) async {
    saved.add(group);
    _store[group.id] = group;
  }

  @override
  Future<void> saveAll(List<TaskRunGroup> groups) async {
    for (final group in groups) {
      saved.add(group);
      _store[group.id] = group;
    }
  }

  @override
  Future<void> delete(String id) async {
    _store.remove(id);
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
  }) async {}

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
}

class FakePomodoroSessionRepository implements PomodoroSessionRepository {
  FakePomodoroSessionRepository(this._session);

  final PomodoroSession? _session;
  int tryClaimCalls = 0;
  int clearSessionIfStaleCalls = 0;

  @override
  Stream<PomodoroSession?> watchSession() => Stream.value(_session);

  @override
  Future<PomodoroSession?> fetchSession({bool preferServer = false}) async {
    return _session;
  }

  @override
  Future<void> publishSession(PomodoroSession session) async {}

  @override
  Future<bool> tryClaimSession(PomodoroSession session) async {
    tryClaimCalls += 1;
    return true;
  }

  @override
  Future<void> clearSessionAsOwner() async {}

  @override
  Future<void> clearSessionIfStale({required DateTime now}) async {
    clearSessionIfStaleCalls += 1;
  }

  @override
  Future<void> clearSessionIfGroupNotRunning() async {}

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
}

class FakeSoundService implements SoundService {
  @override
  Future<void> play(SelectedSound sound, {SelectedSound? fallback}) async {}

  @override
  Future<void> dispose() async {}
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

TaskRunItem _buildTaskItem({
  required String id,
  required String name,
  required int pomodoroMinutes,
  required int totalPomodoros,
}) {
  return TaskRunItem(
    sourceTaskId: id,
    name: name,
    presetId: null,
    pomodoroMinutes: pomodoroMinutes,
    shortBreakMinutes: 5,
    longBreakMinutes: 15,
    totalPomodoros: totalPomodoros,
    longBreakInterval: 4,
    startSound: const SelectedSound.builtIn('default_chime'),
    startBreakSound: const SelectedSound.builtIn('default_chime_break'),
    finishTaskSound: const SelectedSound.builtIn('default_chime_finish'),
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

TaskRunGroup _buildTimelineRunningGroup({
  required String id,
  required DateTime start,
}) {
  final tasks = [
    _buildTaskItem(
      id: '8399506a-dbbd-4397-aa82-b3a0c96decf8',
      name: 'Proyecto Focus Interval (mañana)',
      pomodoroMinutes: 25,
      totalPomodoros: 5,
    ),
    _buildTaskItem(
      id: '654e32e7-a5a7-49a2-b6ff-08e76025e8a7',
      name: 'Almorzar',
      pomodoroMinutes: 60,
      totalPomodoros: 1,
    ),
    _buildTaskItem(
      id: '802f7fe0-8294-4057-aa98-68e2e5efb8dd',
      name: 'Trading',
      pomodoroMinutes: 25,
      totalPomodoros: 4,
    ),
    _buildTaskItem(
      id: '7b75ec77-da9a-47b7-bf72-4c24f7fb2849',
      name: 'Impuestos',
      pomodoroMinutes: 25,
      totalPomodoros: 2,
    ),
    _buildTaskItem(
      id: '8108e3ef-b142-4a58-9ee1-3092ffded235',
      name: 'Proyecto Focus Interval (tarde)',
      pomodoroMinutes: 25,
      totalPomodoros: 6,
    ),
  ];
  final totalDurationSeconds = groupDurationSecondsByMode(
    tasks,
    TaskRunIntegrityMode.individual,
  );
  return TaskRunGroup(
    id: id,
    ownerUid: 'user-1',
    dataVersion: kCurrentDataVersion,
    integrityMode: TaskRunIntegrityMode.individual,
    tasks: tasks,
    createdAt: start,
    scheduledStartTime: null,
    scheduledByDeviceId: 'macOS-c7c721ea-7217-47a1-890a-d7787091efa5',
    noticeSentAt: null,
    noticeSentByDeviceId: null,
    actualStartTime: start,
    theoreticalEndTime: start.add(Duration(seconds: totalDurationSeconds)),
    status: TaskRunStatus.running,
    noticeMinutes: 5,
    totalTasks: tasks.length,
    totalPomodoros: tasks.fold<int>(
      0,
      (sum, item) => sum + item.totalPomodoros,
    ),
    totalDurationSeconds: totalDurationSeconds,
    updatedAt: start,
  );
}

PomodoroSession _buildPausedSession({
  required String groupId,
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
    ownerDeviceId: 'device-1',
    status: PomodoroStatus.paused,
    phase: PomodoroPhase.pomodoro,
    currentPomodoro: 1,
    totalPomodoros: 2,
    phaseDurationSeconds: 25 * 60,
    remainingSeconds: 1200,
    accumulatedPausedSeconds: 0,
    phaseStartedAt: now.subtract(const Duration(minutes: 40)),
    currentTaskStartedAt: now.subtract(const Duration(minutes: 40)),
    pausedAt: now.subtract(const Duration(minutes: 30)),
    lastUpdatedAt: now,
    finishedAt: null,
    pauseReason: 'user',
  );
}

PomodoroSession _buildInvalidCursorSession({
  required String groupId,
  required DateTime now,
}) {
  return PomodoroSession(
    taskId: '654e32e7-a5a7-49a2-b6ff-08e76025e8a7',
    groupId: groupId,
    currentTaskId: '654e32e7-a5a7-49a2-b6ff-08e76025e8a7',
    currentTaskIndex: 1,
    totalTasks: 5,
    dataVersion: kCurrentDataVersion,
    sessionRevision: 22,
    ownerDeviceId: 'other-device',
    status: PomodoroStatus.pomodoroRunning,
    phase: PomodoroPhase.pomodoro,
    currentPomodoro: 2,
    totalPomodoros: 1,
    phaseDurationSeconds: 60 * 60,
    remainingSeconds: 1164,
    accumulatedPausedSeconds: 0,
    phaseStartedAt: now.subtract(const Duration(minutes: 39)),
    currentTaskStartedAt: now.subtract(const Duration(minutes: 39)),
    pausedAt: null,
    lastUpdatedAt: now,
    finishedAt: null,
    pauseReason: null,
  );
}

PomodoroSession _buildFinishedInvalidCursorSession({
  required String groupId,
  required DateTime now,
}) {
  return PomodoroSession(
    taskId: '654e32e7-a5a7-49a2-b6ff-08e76025e8a7',
    groupId: groupId,
    currentTaskId: '654e32e7-a5a7-49a2-b6ff-08e76025e8a7',
    currentTaskIndex: 1,
    totalTasks: 5,
    dataVersion: kCurrentDataVersion,
    sessionRevision: 22,
    ownerDeviceId: 'other-device',
    status: PomodoroStatus.finished,
    phase: null,
    currentPomodoro: 2,
    totalPomodoros: 1,
    phaseDurationSeconds: 0,
    remainingSeconds: 0,
    accumulatedPausedSeconds: 0,
    phaseStartedAt: null,
    currentTaskStartedAt: now.subtract(const Duration(minutes: 61)),
    pausedAt: null,
    lastUpdatedAt: now.subtract(const Duration(minutes: 5)),
    finishedAt: now.subtract(const Duration(minutes: 5)),
    pauseReason: null,
  );
}

Future<void> _pumpQueue() async {
  await Future<void>.delayed(const Duration(milliseconds: 20));
  await Future<void>.delayed(const Duration(milliseconds: 20));
}

void main() {
  test('paused session does not auto-complete on load', () async {
    final now = DateTime.now();
    final group = _buildRunningGroup(
      id: 'group-pause-expiry',
      start: now.subtract(const Duration(hours: 2)),
      theoreticalEnd: now.subtract(const Duration(minutes: 30)),
    );
    final session = _buildPausedSession(groupId: group.id, now: now);

    final groupRepo = FakeTaskRunGroupRepository()..seed(group);
    final sessionRepo = FakePomodoroSessionRepository(session);
    final appModeService = AppModeService.memory();

    final container = ProviderContainer(
      overrides: [
        taskRunGroupRepositoryProvider.overrideWithValue(groupRepo),
        pomodoroSessionRepositoryProvider.overrideWithValue(sessionRepo),
        appModeServiceProvider.overrideWithValue(appModeService),
        soundServiceProvider.overrideWithValue(FakeSoundService()),
        timeSyncServiceProvider.overrideWithValue(
          TimeSyncService(enabled: false),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(appModeProvider.notifier).setAccount();
    await _pumpQueue();

    final vm = container.read(pomodoroViewModelProvider.notifier);
    final result = await vm.loadGroup(group.id);

    expect(result, PomodoroGroupLoadResult.loaded);
    expect(groupRepo.saved, isEmpty);
    expect((await groupRepo.getById(group.id))?.status, TaskRunStatus.running);
  });

  test(
    'loadGroup repairs invalid task cursor and lands on expected running task',
    () async {
      final now = DateTime.now();
      final group = _buildTimelineRunningGroup(
        id: 'group-cursor-repair',
        start: now.subtract(const Duration(minutes: 230)),
      );
      final session = _buildInvalidCursorSession(groupId: group.id, now: now);

      final groupRepo = FakeTaskRunGroupRepository()..seed(group);
      final sessionRepo = FakePomodoroSessionRepository(session);
      final appModeService = AppModeService.memory();

      final container = ProviderContainer(
        overrides: [
          taskRunGroupRepositoryProvider.overrideWithValue(groupRepo),
          pomodoroSessionRepositoryProvider.overrideWithValue(sessionRepo),
          appModeServiceProvider.overrideWithValue(appModeService),
          soundServiceProvider.overrideWithValue(FakeSoundService()),
          timeSyncServiceProvider.overrideWithValue(
            TimeSyncService(enabled: false),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(appModeProvider.notifier).setAccount();
      await _pumpQueue();

      final vm = container.read(pomodoroViewModelProvider.notifier);
      final result = await vm.loadGroup(group.id);
      final state = container.read(pomodoroViewModelProvider);

      expect(result, PomodoroGroupLoadResult.loaded);
      expect(vm.currentTaskIndex, 2);
      expect(
        vm.currentItem?.sourceTaskId,
        '802f7fe0-8294-4057-aa98-68e2e5efb8dd',
      );
      expect(state.totalPomodoros, 4);
      expect(state.currentPomodoro, inInclusiveRange(1, 4));
    },
  );

  test(
    'loadGroup repairs finished invalid cursor when group is still running',
    () async {
      final now = DateTime.now();
      final group = _buildTimelineRunningGroup(
        id: 'group-cursor-repair-finished',
        start: now.subtract(const Duration(minutes: 230)),
      );
      final session = _buildFinishedInvalidCursorSession(
        groupId: group.id,
        now: now,
      );

      final groupRepo = FakeTaskRunGroupRepository()..seed(group);
      final sessionRepo = FakePomodoroSessionRepository(session);
      final appModeService = AppModeService.memory();

      final container = ProviderContainer(
        overrides: [
          taskRunGroupRepositoryProvider.overrideWithValue(groupRepo),
          pomodoroSessionRepositoryProvider.overrideWithValue(sessionRepo),
          appModeServiceProvider.overrideWithValue(appModeService),
          soundServiceProvider.overrideWithValue(FakeSoundService()),
          timeSyncServiceProvider.overrideWithValue(
            TimeSyncService(enabled: false),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(appModeProvider.notifier).setAccount();
      await _pumpQueue();

      final vm = container.read(pomodoroViewModelProvider.notifier);
      final result = await vm.loadGroup(group.id);
      final state = container.read(pomodoroViewModelProvider);
      final deviceId = container.read(deviceInfoServiceProvider).deviceId;

      expect(result, PomodoroGroupLoadResult.loaded);
      expect(vm.currentTaskIndex, 2);
      expect(
        vm.currentItem?.sourceTaskId,
        '802f7fe0-8294-4057-aa98-68e2e5efb8dd',
      );
      expect(state.status.isActiveExecution, isTrue);
      expect(state.status, isNot(PomodoroStatus.finished));
      expect(state.totalPomodoros, 4);
      expect(state.currentPomodoro, inInclusiveRange(1, 4));
      expect(vm.activeSessionForCurrentGroup?.ownerDeviceId, deviceId);
      expect(vm.isOwnerForCurrentSession, isTrue);
    },
  );

  test(
    'expired running-group + stale finished session is completed instead of re-claimed',
    () async {
      final now = DateTime.now();
      final group = _buildTimelineRunningGroup(
        id: 'group-expired-finished-stale',
        start: now.subtract(const Duration(hours: 11)),
      );
      final session = _buildFinishedInvalidCursorSession(
        groupId: group.id,
        now: now,
      );

      final groupRepo = FakeTaskRunGroupRepository()..seed(group);
      final sessionRepo = FakePomodoroSessionRepository(session);
      final appModeService = AppModeService.memory();

      final container = ProviderContainer(
        overrides: [
          taskRunGroupRepositoryProvider.overrideWithValue(groupRepo),
          pomodoroSessionRepositoryProvider.overrideWithValue(sessionRepo),
          appModeServiceProvider.overrideWithValue(appModeService),
          soundServiceProvider.overrideWithValue(FakeSoundService()),
          timeSyncServiceProvider.overrideWithValue(
            TimeSyncService(enabled: false),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(appModeProvider.notifier).setAccount();
      await _pumpQueue();

      final vm = container.read(pomodoroViewModelProvider.notifier);
      final result = await vm.loadGroup(group.id);
      final reloadedGroup = await groupRepo.getById(group.id);

      expect(result, PomodoroGroupLoadResult.loaded);
      expect(reloadedGroup?.status, TaskRunStatus.completed);
      expect(vm.activeSessionForCurrentGroup, isNull);
      expect(vm.isOwnerForCurrentSession, isFalse);
      expect(sessionRepo.tryClaimCalls, 0);
      expect(sessionRepo.clearSessionIfStaleCalls, greaterThanOrEqualTo(1));
    },
  );
}
