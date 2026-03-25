import 'dart:async';

import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:focus_interval/data/models/pomodoro_session.dart';
import 'package:focus_interval/data/models/schema_version.dart';
import 'package:focus_interval/data/models/selected_sound.dart';
import 'package:focus_interval/data/models/task_run_group.dart';
import 'package:focus_interval/data/repositories/pomodoro_session_repository.dart';
import 'package:focus_interval/data/repositories/task_run_group_repository.dart';
import 'package:focus_interval/data/services/app_mode_service.dart';
import 'package:focus_interval/data/services/device_info_service.dart';
import 'package:focus_interval/data/services/sound_service.dart';
import 'package:focus_interval/data/services/time_sync_service.dart';
import 'package:focus_interval/domain/pomodoro_machine.dart';
import 'package:focus_interval/presentation/providers.dart';
import 'package:focus_interval/presentation/viewmodels/pomodoro_view_model.dart';

class FakeTaskRunGroupRepository implements TaskRunGroupRepository {
  final Map<String, TaskRunGroup> _store = {};

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
    _store[group.id] = group;
  }

  @override
  Future<void> saveAll(List<TaskRunGroup> groups) async {
    for (final group in groups) {
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
  FakePomodoroSessionRepository(
    this._initialSession, {
    Duration fetchDelay = Duration.zero,
  }) : _fetchDelay = fetchDelay;

  final StreamController<PomodoroSession?> _controller =
      StreamController<PomodoroSession?>.broadcast();
  PomodoroSession? _lastSession;
  PomodoroSession? _initialSession;
  final Duration _fetchDelay;
  int publishCount = 0;
  PomodoroSession? lastPublished;

  @override
  Stream<PomodoroSession?> watchSession() async* {
    if (_initialSession != null) {
      _lastSession = _initialSession;
      yield _initialSession;
      _initialSession = null;
    }
    yield* _controller.stream;
  }

  void emit(PomodoroSession? session) {
    _lastSession = session;
    _controller.add(session);
  }

  void emitError(Object error, [StackTrace? stackTrace]) {
    _controller.addError(error, stackTrace);
  }

  @override
  Future<PomodoroSession?> fetchSession({bool preferServer = false}) async {
    if (_fetchDelay > Duration.zero) {
      await Future<void>.delayed(_fetchDelay);
    }
    return _lastSession;
  }

  @override
  Future<void> publishSession(PomodoroSession session) async {
    publishCount += 1;
    lastPublished = session;
  }

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
    Map<String, dynamic>? cursorSnapshot,
  }) async {}

  void dispose() {
    _controller.close();
  }
}

class FakeSoundService implements SoundService {
  @override
  Future<void> play(SelectedSound sound, {SelectedSound? fallback}) async {}

  @override
  Future<void> dispose() async {}
}

class FakeTimeSyncService extends TimeSyncService {
  FakeTimeSyncService({Duration? offset})
    : _offsetOverride = offset,
      super(enabled: false);

  Duration? _offsetOverride;
  int refreshCalls = 0;
  int forcedRefreshCalls = 0;

  @override
  Duration? get offset => _offsetOverride;

  @override
  Future<Duration?> refresh({bool force = false}) async {
    refreshCalls += 1;
    if (force) {
      forcedRefreshCalls += 1;
    }
    return _offsetOverride;
  }

  void setOffset(Duration? value) {
    _offsetOverride = value;
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

TaskRunGroup _buildRunningGroup({required String id, required DateTime start}) {
  final item = _buildItem();
  return TaskRunGroup(
    id: id,
    ownerUid: 'user-1',
    dataVersion: kCurrentDataVersion,
    integrityMode: TaskRunIntegrityMode.shared,
    tasks: [item],
    createdAt: start,
    scheduledStartTime: null,
    scheduledByDeviceId: 'device-1',
    theoreticalEndTime: start.add(const Duration(minutes: 60)),
    status: TaskRunStatus.running,
    noticeMinutes: null,
    totalTasks: 1,
    totalPomodoros: 2,
    totalDurationSeconds: 3600,
    updatedAt: start,
    actualStartTime: start,
  );
}

TaskRunGroup _buildTwoTaskRunningGroup({
  required String id,
  required DateTime start,
}) {
  const taskOne = TaskRunItem(
    sourceTaskId: 'task-1',
    name: 'Task one',
    presetId: null,
    pomodoroMinutes: 25,
    shortBreakMinutes: 5,
    longBreakMinutes: 15,
    totalPomodoros: 1,
    longBreakInterval: 2,
    startSound: SelectedSound.builtIn('default_chime'),
    startBreakSound: SelectedSound.builtIn('default_chime_break'),
    finishTaskSound: SelectedSound.builtIn('default_chime_finish'),
  );
  const taskTwo = TaskRunItem(
    sourceTaskId: 'task-2',
    name: 'Task two',
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
  final tasks = const [taskOne, taskTwo];
  final totalDurationSeconds = groupDurationSecondsByMode(
    tasks,
    TaskRunIntegrityMode.shared,
  );
  return TaskRunGroup(
    id: id,
    ownerUid: 'user-1',
    dataVersion: kCurrentDataVersion,
    integrityMode: TaskRunIntegrityMode.shared,
    tasks: tasks,
    createdAt: start,
    scheduledStartTime: null,
    scheduledByDeviceId: 'device-1',
    theoreticalEndTime: start.add(Duration(seconds: totalDurationSeconds)),
    status: TaskRunStatus.running,
    noticeMinutes: null,
    totalTasks: tasks.length,
    totalPomodoros: tasks.fold<int>(
      0,
      (sum, item) => sum + item.totalPomodoros,
    ),
    totalDurationSeconds: totalDurationSeconds,
    updatedAt: start,
    actualStartTime: start,
  );
}

TaskRunGroup _buildTwoSinglePomodoroRunningGroup({
  required String id,
  required DateTime start,
}) {
  const taskOne = TaskRunItem(
    sourceTaskId: 'task-1',
    name: 'Task one',
    presetId: null,
    pomodoroMinutes: 15,
    shortBreakMinutes: 5,
    longBreakMinutes: 15,
    totalPomodoros: 1,
    longBreakInterval: 2,
    startSound: SelectedSound.builtIn('default_chime'),
    startBreakSound: SelectedSound.builtIn('default_chime_break'),
    finishTaskSound: SelectedSound.builtIn('default_chime_finish'),
  );
  const taskTwo = TaskRunItem(
    sourceTaskId: 'task-2',
    name: 'Task two',
    presetId: null,
    pomodoroMinutes: 15,
    shortBreakMinutes: 5,
    longBreakMinutes: 15,
    totalPomodoros: 1,
    longBreakInterval: 2,
    startSound: SelectedSound.builtIn('default_chime'),
    startBreakSound: SelectedSound.builtIn('default_chime_break'),
    finishTaskSound: SelectedSound.builtIn('default_chime_finish'),
  );
  final tasks = const [taskOne, taskTwo];
  final totalDurationSeconds = groupDurationSecondsByMode(
    tasks,
    TaskRunIntegrityMode.shared,
  );
  return TaskRunGroup(
    id: id,
    ownerUid: 'user-1',
    dataVersion: kCurrentDataVersion,
    integrityMode: TaskRunIntegrityMode.shared,
    tasks: tasks,
    createdAt: start,
    scheduledStartTime: null,
    scheduledByDeviceId: 'device-1',
    theoreticalEndTime: start.add(Duration(seconds: totalDurationSeconds)),
    status: TaskRunStatus.running,
    noticeMinutes: null,
    totalTasks: tasks.length,
    totalPomodoros: tasks.fold<int>(
      0,
      (sum, item) => sum + item.totalPomodoros,
    ),
    totalDurationSeconds: totalDurationSeconds,
    updatedAt: start,
    actualStartTime: start,
  );
}

PomodoroSession _buildRunningSession({
  required String groupId,
  required String taskId,
  required String ownerDeviceId,
  required DateTime now,
}) {
  return PomodoroSession(
    taskId: taskId,
    groupId: groupId,
    currentTaskId: taskId,
    currentTaskIndex: 0,
    totalTasks: 1,
    dataVersion: kCurrentDataVersion,
    sessionRevision: 1,
    ownerDeviceId: ownerDeviceId,
    status: PomodoroStatus.pomodoroRunning,
    phase: PomodoroPhase.pomodoro,
    currentPomodoro: 1,
    totalPomodoros: 2,
    phaseDurationSeconds: 25 * 60,
    remainingSeconds: 1200,
    accumulatedPausedSeconds: 0,
    phaseStartedAt: now.subtract(const Duration(minutes: 5)),
    currentTaskStartedAt: now.subtract(const Duration(minutes: 5)),
    pausedAt: null,
    lastUpdatedAt: null,
    finishedAt: null,
    pauseReason: null,
  );
}

Future<void> _pumpQueue() async {
  await Future<void>.delayed(const Duration(milliseconds: 20));
  await Future<void>.delayed(const Duration(milliseconds: 20));
}

String _ownershipSyncStateName(PomodoroViewModel vm) {
  try {
    final dynamic dynamicVm = vm;
    final dynamic value = dynamicVm.ownershipSyncState;
    if (value == null) return '__missing__';
    if (value is Enum) return value.name;
    return value.toString();
  } catch (_) {
    return '__missing__';
  }
}

void main() {
  test('missing session holds sync when lastUpdatedAt is null', () async {
    final now = DateTime.now();
    final deviceInfo = DeviceInfoService.ephemeral();
    final group = _buildRunningGroup(id: 'group-1', start: now);
    final session = _buildRunningSession(
      groupId: group.id,
      taskId: group.tasks.first.sourceTaskId,
      ownerDeviceId: 'other-device',
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
        deviceInfoServiceProvider.overrideWithValue(deviceInfo),
        soundServiceProvider.overrideWithValue(FakeSoundService()),
        timeSyncServiceProvider.overrideWithValue(
          TimeSyncService(enabled: false),
        ),
      ],
    );
    addTearDown(() {
      sessionRepo.dispose();
      container.dispose();
    });

    await container.read(appModeProvider.notifier).setAccount();
    await _pumpQueue();

    container.listen<PomodoroState>(pomodoroViewModelProvider, (_, __) {});
    final vm = container.read(pomodoroViewModelProvider.notifier);
    final result = await vm.loadGroup(group.id);
    expect(result, PomodoroGroupLoadResult.loaded);
    await _pumpQueue();
    expect(vm.activeSessionForCurrentGroup, isNotNull);

    sessionRepo.emit(null);
    await _pumpQueue();
    await Future<void>.delayed(const Duration(seconds: 4));
    await _pumpQueue();

    expect(vm.isSessionMissingWhileRunning, isTrue);
  });

  test(
    'Account without timeSync does not publish and forces refresh',
    () async {
      final now = DateTime.now();
      final deviceInfo = DeviceInfoService.ephemeral();
      final group = _buildRunningGroup(id: 'group-1', start: now);
      final session = _buildRunningSession(
        groupId: group.id,
        taskId: group.tasks.first.sourceTaskId,
        ownerDeviceId: deviceInfo.deviceId,
        now: now,
      );

      final groupRepo = FakeTaskRunGroupRepository()..seed(group);
      final sessionRepo = FakePomodoroSessionRepository(session);
      final appModeService = AppModeService.memory();
      final timeSyncService = FakeTimeSyncService(offset: null);

      final container = ProviderContainer(
        overrides: [
          taskRunGroupRepositoryProvider.overrideWithValue(groupRepo),
          pomodoroSessionRepositoryProvider.overrideWithValue(sessionRepo),
          appModeServiceProvider.overrideWithValue(appModeService),
          deviceInfoServiceProvider.overrideWithValue(deviceInfo),
          soundServiceProvider.overrideWithValue(FakeSoundService()),
          timeSyncServiceProvider.overrideWithValue(timeSyncService),
        ],
      );
      addTearDown(() {
        sessionRepo.dispose();
        container.dispose();
      });

      await container.read(appModeProvider.notifier).setAccount();
      await _pumpQueue();

      container.listen<PomodoroState>(pomodoroViewModelProvider, (_, __) {});
      final vm = container.read(pomodoroViewModelProvider.notifier);
      final result = await vm.loadGroup(group.id);
      expect(result, PomodoroGroupLoadResult.loaded);
      await _pumpQueue();

      sessionRepo.publishCount = 0;
      timeSyncService.refreshCalls = 0;
      timeSyncService.forcedRefreshCalls = 0;

      vm.pause();
      await _pumpQueue();

      expect(sessionRepo.publishCount, 0);
      expect(timeSyncService.forcedRefreshCalls, greaterThan(0));
    },
  );

  test('Account session render ignores machine stream updates', () async {
    final now = DateTime.now();
    final deviceInfo = DeviceInfoService.ephemeral();
    final group = _buildRunningGroup(id: 'group-1', start: now);
    final session = _buildRunningSession(
      groupId: group.id,
      taskId: group.tasks.first.sourceTaskId,
      ownerDeviceId: 'other-device',
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
        deviceInfoServiceProvider.overrideWithValue(deviceInfo),
        soundServiceProvider.overrideWithValue(FakeSoundService()),
        timeSyncServiceProvider.overrideWithValue(
          FakeTimeSyncService(offset: Duration.zero),
        ),
      ],
    );
    addTearDown(() {
      sessionRepo.dispose();
      container.dispose();
    });

    await container.read(appModeProvider.notifier).setAccount();
    await _pumpQueue();

    container.listen<PomodoroState>(pomodoroViewModelProvider, (_, __) {});
    final vm = container.read(pomodoroViewModelProvider.notifier);
    final result = await vm.loadGroup(group.id);
    expect(result, PomodoroGroupLoadResult.loaded);
    await _pumpQueue();

    final before = container.read(pomodoroViewModelProvider);
    expect(before.status.isActiveExecution, isTrue);

    final machine = container.read(pomodoroMachineProvider);
    machine.cancel();
    await _pumpQueue();

    final after = container.read(pomodoroViewModelProvider);
    expect(after.status.isActiveExecution, isTrue);
    expect(after.status, isNot(PomodoroStatus.idle));
  });

  test(
    'owner handoff applies timeline even when updatedAt regresses',
    () async {
      final now = DateTime.now();
      final deviceInfo = DeviceInfoService.ephemeral();
      final group = _buildTwoTaskRunningGroup(
        id: 'group-owner-handoff-regressed-time',
        start: now.subtract(const Duration(minutes: 30)),
      );

      final firstTask = group.tasks[0];
      final secondTask = group.tasks[1];
      final sessionBeforeHandoff = PomodoroSession(
        taskId: firstTask.sourceTaskId,
        groupId: group.id,
        currentTaskId: firstTask.sourceTaskId,
        currentTaskIndex: 0,
        totalTasks: group.tasks.length,
        dataVersion: kCurrentDataVersion,
        sessionRevision: 33,
        ownerDeviceId: deviceInfo.deviceId,
        status: PomodoroStatus.pomodoroRunning,
        phase: PomodoroPhase.pomodoro,
        currentPomodoro: 1,
        totalPomodoros: firstTask.totalPomodoros,
        phaseDurationSeconds: firstTask.pomodoroMinutes * 60,
        remainingSeconds: 240,
        accumulatedPausedSeconds: 0,
        phaseStartedAt: now.subtract(const Duration(minutes: 4)),
        currentTaskStartedAt: now.subtract(const Duration(minutes: 4)),
        pausedAt: null,
        lastUpdatedAt: now.add(const Duration(minutes: 2)),
        finishedAt: null,
        pauseReason: null,
      );
      final sessionAfterHandoff = PomodoroSession(
        taskId: secondTask.sourceTaskId,
        groupId: group.id,
        currentTaskId: secondTask.sourceTaskId,
        currentTaskIndex: 1,
        totalTasks: group.tasks.length,
        dataVersion: kCurrentDataVersion,
        sessionRevision: 33,
        ownerDeviceId: 'android-owner',
        status: PomodoroStatus.shortBreakRunning,
        phase: PomodoroPhase.shortBreak,
        currentPomodoro: 1,
        totalPomodoros: secondTask.totalPomodoros,
        phaseDurationSeconds: secondTask.shortBreakMinutes * 60,
        remainingSeconds: 180,
        accumulatedPausedSeconds: 0,
        phaseStartedAt: now.subtract(const Duration(minutes: 1)),
        currentTaskStartedAt: now.subtract(const Duration(minutes: 6)),
        pausedAt: null,
        lastUpdatedAt: now,
        finishedAt: null,
        pauseReason: null,
      );

      final groupRepo = FakeTaskRunGroupRepository()..seed(group);
      final sessionRepo = FakePomodoroSessionRepository(sessionBeforeHandoff);
      final appModeService = AppModeService.memory();

      final container = ProviderContainer(
        overrides: [
          taskRunGroupRepositoryProvider.overrideWithValue(groupRepo),
          pomodoroSessionRepositoryProvider.overrideWithValue(sessionRepo),
          appModeServiceProvider.overrideWithValue(appModeService),
          deviceInfoServiceProvider.overrideWithValue(deviceInfo),
          soundServiceProvider.overrideWithValue(FakeSoundService()),
          timeSyncServiceProvider.overrideWithValue(
            FakeTimeSyncService(offset: Duration.zero),
          ),
        ],
      );
      addTearDown(() {
        sessionRepo.dispose();
        container.dispose();
      });

      await container.read(appModeProvider.notifier).setAccount();
      await _pumpQueue();

      container.listen<PomodoroState>(pomodoroViewModelProvider, (_, __) {});
      final vm = container.read(pomodoroViewModelProvider.notifier);
      final result = await vm.loadGroup(group.id);
      expect(result, PomodoroGroupLoadResult.loaded);
      await _pumpQueue();

      sessionRepo.emit(sessionAfterHandoff);
      await _pumpQueue();

      final state = container.read(pomodoroViewModelProvider);
      expect(vm.currentTaskIndex, 1);
      expect(vm.currentItem?.sourceTaskId, secondTask.sourceTaskId);
      expect(vm.activeSessionForCurrentGroup, isNotNull);
      expect(vm.activeSessionForCurrentGroup?.ownerDeviceId, 'android-owner');
      expect(vm.isSessionMissingWhileRunning, isFalse);
      expect(state.status, PomodoroStatus.shortBreakRunning);
    },
  );

  test(
    'owner hydration with stale session past task boundary does not publish finished during resync',
    () async {
      final now = DateTime.now();
      final deviceInfo = DeviceInfoService.ephemeral();
      final group = _buildTwoTaskRunningGroup(
        id: 'group-bug015-owner-hydration-resync',
        start: now.subtract(const Duration(minutes: 40)),
      );
      final initialMirrorSession = _buildRunningSession(
        groupId: group.id,
        taskId: group.tasks.first.sourceTaskId,
        ownerDeviceId: 'other-device',
        now: now,
      );

      final groupRepo = FakeTaskRunGroupRepository()..seed(group);
      final sessionRepo = FakePomodoroSessionRepository(initialMirrorSession);
      final appModeService = AppModeService.memory();

      final container = ProviderContainer(
        overrides: [
          taskRunGroupRepositoryProvider.overrideWithValue(groupRepo),
          pomodoroSessionRepositoryProvider.overrideWithValue(sessionRepo),
          appModeServiceProvider.overrideWithValue(appModeService),
          deviceInfoServiceProvider.overrideWithValue(deviceInfo),
          soundServiceProvider.overrideWithValue(FakeSoundService()),
          timeSyncServiceProvider.overrideWithValue(
            FakeTimeSyncService(offset: Duration.zero),
          ),
        ],
      );
      addTearDown(() {
        sessionRepo.dispose();
        container.dispose();
      });

      await container.read(appModeProvider.notifier).setAccount();
      await _pumpQueue();

      container.listen<PomodoroState>(pomodoroViewModelProvider, (_, __) {});
      final vm = container.read(pomodoroViewModelProvider.notifier);
      final result = await vm.loadGroup(group.id);
      expect(result, PomodoroGroupLoadResult.loaded);
      await _pumpQueue();

      final firstTask = group.tasks.first;
      final staleOwnerSession = PomodoroSession(
        taskId: firstTask.sourceTaskId,
        groupId: group.id,
        currentTaskId: firstTask.sourceTaskId,
        currentTaskIndex: 0,
        totalTasks: group.tasks.length,
        dataVersion: kCurrentDataVersion,
        sessionRevision: 12,
        ownerDeviceId: deviceInfo.deviceId,
        status: PomodoroStatus.pomodoroRunning,
        phase: PomodoroPhase.pomodoro,
        currentPomodoro: 1,
        totalPomodoros: firstTask.totalPomodoros,
        phaseDurationSeconds: firstTask.pomodoroMinutes * 60,
        remainingSeconds: 10,
        accumulatedPausedSeconds: 0,
        phaseStartedAt: now.subtract(const Duration(minutes: 40)),
        currentTaskStartedAt: now.subtract(const Duration(minutes: 40)),
        pausedAt: null,
        lastUpdatedAt: now.subtract(const Duration(minutes: 40)),
        finishedAt: null,
        pauseReason: null,
      );

      // Pre-fix BUG-015 behavior published `finished` here because
      // _applyGroupTimelineProjection was blocked by _controlsEnabled while
      // syncWithRemoteSession kept _resyncInProgress=true.
      sessionRepo._lastSession = staleOwnerSession;
      await vm.syncWithRemoteSession(
        preferServer: true,
        reason: 'bug-015-owner-hydration-resync',
      );
      await _pumpQueue();

      final state = container.read(pomodoroViewModelProvider);
      expect(state.status, isNot(PomodoroStatus.finished));
      expect(state.status.isActiveExecution, isTrue);
      expect(vm.currentTaskIndex, 1);
      expect(vm.currentItem?.sourceTaskId, group.tasks[1].sourceTaskId);
      expect(sessionRepo.lastPublished, isNotNull);
      expect(sessionRepo.lastPublished?.status, isNot(PomodoroStatus.finished));
      expect(sessionRepo.lastPublished?.currentTaskIndex, 1);
    },
  );

  test(
    'stream snapshot with inconsistent cursor is repaired before ingest',
    () async {
      final now = DateTime.now();
      final deviceInfo = DeviceInfoService.ephemeral();
      final group = _buildTwoSinglePomodoroRunningGroup(
        id: 'group-bug015-stream-cursor-repair',
        start: now.subtract(const Duration(minutes: 33)),
      );

      final secondTask = group.tasks[1];
      final initialSession = PomodoroSession(
        taskId: secondTask.sourceTaskId,
        groupId: group.id,
        currentTaskId: secondTask.sourceTaskId,
        currentTaskIndex: 1,
        totalTasks: group.tasks.length,
        dataVersion: kCurrentDataVersion,
        sessionRevision: 20,
        ownerDeviceId: 'android-owner',
        status: PomodoroStatus.pomodoroRunning,
        phase: PomodoroPhase.pomodoro,
        currentPomodoro: 1,
        totalPomodoros: secondTask.totalPomodoros,
        phaseDurationSeconds: secondTask.pomodoroMinutes * 60,
        remainingSeconds: 150,
        accumulatedPausedSeconds: 0,
        phaseStartedAt: now.subtract(const Duration(minutes: 12, seconds: 30)),
        currentTaskStartedAt: now.subtract(const Duration(minutes: 13)),
        pausedAt: null,
        lastUpdatedAt: now.subtract(const Duration(seconds: 30)),
        finishedAt: null,
        pauseReason: null,
      );

      final groupRepo = FakeTaskRunGroupRepository()..seed(group);
      final sessionRepo = FakePomodoroSessionRepository(initialSession);
      final appModeService = AppModeService.memory();

      final container = ProviderContainer(
        overrides: [
          taskRunGroupRepositoryProvider.overrideWithValue(groupRepo),
          pomodoroSessionRepositoryProvider.overrideWithValue(sessionRepo),
          appModeServiceProvider.overrideWithValue(appModeService),
          deviceInfoServiceProvider.overrideWithValue(deviceInfo),
          soundServiceProvider.overrideWithValue(FakeSoundService()),
          timeSyncServiceProvider.overrideWithValue(
            FakeTimeSyncService(offset: Duration.zero),
          ),
        ],
      );
      addTearDown(() {
        sessionRepo.dispose();
        container.dispose();
      });

      await container.read(appModeProvider.notifier).setAccount();
      await _pumpQueue();

      container.listen<PomodoroState>(pomodoroViewModelProvider, (_, __) {});
      final vm = container.read(pomodoroViewModelProvider.notifier);
      final result = await vm.loadGroup(group.id);
      expect(result, PomodoroGroupLoadResult.loaded);
      await _pumpQueue();

      // BUG-015 stream case: active snapshot arrives with invalid cursor.
      // Pre-fix this could project to finished/Ready 00:00 in mirror mode.
      final corrupted = PomodoroSession(
        taskId: group.tasks.first.sourceTaskId,
        groupId: group.id,
        currentTaskId: group.tasks.first.sourceTaskId,
        currentTaskIndex: 0,
        totalTasks: group.tasks.length,
        dataVersion: kCurrentDataVersion,
        sessionRevision: 21,
        ownerDeviceId: 'android-owner',
        status: PomodoroStatus.pomodoroRunning,
        phase: PomodoroPhase.pomodoro,
        currentPomodoro: 2,
        totalPomodoros: 1,
        phaseDurationSeconds: 15 * 60,
        remainingSeconds: 0,
        accumulatedPausedSeconds: 0,
        phaseStartedAt: now.subtract(const Duration(minutes: 18)),
        currentTaskStartedAt: group.actualStartTime,
        pausedAt: null,
        lastUpdatedAt: now,
        finishedAt: null,
        pauseReason: null,
      );

      sessionRepo.emit(corrupted);
      await _pumpQueue();

      final state = container.read(pomodoroViewModelProvider);
      final active = vm.activeSessionForCurrentGroup;
      expect(state.status, isNot(PomodoroStatus.finished));
      expect(state.status.isActiveExecution, isTrue);
      expect(vm.currentTaskIndex, 1);
      expect(vm.currentItem?.sourceTaskId, secondTask.sourceTaskId);
      expect(active, isNotNull);
      expect(active!.currentTaskIndex, 1);
      expect(active.currentPomodoro, lessThanOrEqualTo(active.totalPomodoros));
    },
  );

  test(
    'owner hot-swap fallback publish is one-shot for repeated snapshots',
    () async {
      final now = DateTime.now();
      final deviceInfo = DeviceInfoService.ephemeral();
      final group = _buildRunningGroup(
        id: 'group-owner-hot-swap-once',
        start: now,
      );
      final taskId = group.tasks.first.sourceTaskId;
      final mirrorSession = PomodoroSession(
        taskId: taskId,
        groupId: group.id,
        currentTaskId: taskId,
        currentTaskIndex: 0,
        totalTasks: 1,
        dataVersion: kCurrentDataVersion,
        sessionRevision: 40,
        ownerDeviceId: 'other-device',
        status: PomodoroStatus.pomodoroRunning,
        phase: PomodoroPhase.pomodoro,
        currentPomodoro: 1,
        totalPomodoros: 2,
        phaseDurationSeconds: 25 * 60,
        remainingSeconds: 1400,
        accumulatedPausedSeconds: 0,
        phaseStartedAt: now.subtract(const Duration(minutes: 2)),
        currentTaskStartedAt: now.subtract(const Duration(minutes: 2)),
        pausedAt: null,
        lastUpdatedAt: now,
        finishedAt: null,
        pauseReason: null,
      );

      final groupRepo = FakeTaskRunGroupRepository()..seed(group);
      final sessionRepo = FakePomodoroSessionRepository(mirrorSession);
      final appModeService = AppModeService.memory();
      final container = ProviderContainer(
        overrides: [
          taskRunGroupRepositoryProvider.overrideWithValue(groupRepo),
          pomodoroSessionRepositoryProvider.overrideWithValue(sessionRepo),
          appModeServiceProvider.overrideWithValue(appModeService),
          deviceInfoServiceProvider.overrideWithValue(deviceInfo),
          soundServiceProvider.overrideWithValue(FakeSoundService()),
          timeSyncServiceProvider.overrideWithValue(
            FakeTimeSyncService(offset: Duration.zero),
          ),
        ],
      );
      addTearDown(() {
        sessionRepo.dispose();
        container.dispose();
      });

      await container.read(appModeProvider.notifier).setAccount();
      await _pumpQueue();

      final vm = container.read(pomodoroViewModelProvider.notifier);
      final result = await vm.loadGroup(group.id);
      expect(result, PomodoroGroupLoadResult.loaded);
      await _pumpQueue();

      final baselinePublishes = sessionRepo.publishCount;

      for (var i = 0; i < 5; i += 1) {
        final ownerSnapshot = PomodoroSession(
          taskId: taskId,
          groupId: group.id,
          currentTaskId: taskId,
          currentTaskIndex: 0,
          totalTasks: 1,
          dataVersion: kCurrentDataVersion,
          sessionRevision: 41,
          ownerDeviceId: deviceInfo.deviceId,
          status: PomodoroStatus.pomodoroRunning,
          phase: PomodoroPhase.pomodoro,
          currentPomodoro: 1,
          totalPomodoros: 2,
          phaseDurationSeconds: 25 * 60,
          remainingSeconds: 1390 - i,
          accumulatedPausedSeconds: 0,
          phaseStartedAt: now.subtract(const Duration(minutes: 2)),
          currentTaskStartedAt: now.subtract(const Duration(minutes: 2)),
          pausedAt: null,
          lastUpdatedAt: now.add(Duration(seconds: i + 1)),
          finishedAt: null,
          pauseReason: null,
        );
        sessionRepo.emit(ownerSnapshot);
        await _pumpQueue();
      }

      expect(
        sessionRepo.publishCount - baselinePublishes,
        lessThanOrEqualTo(1),
        reason:
            'Hot-swap fallback publish must run at most once per ownership '
            'acquisition; repeated same-revision snapshots must not trigger '
            'a write loop.',
      );
    },
  );

  // ─── Sync contract tests (specs 10.4.8.b) ─────────────────────────────────
  // These tests define the expected behavior after the sync-core refactor.
  // A test marked [REFACTOR] describes behavior that the current code (b085ea6)
  // does NOT fully satisfy. It must pass after the refactor is complete.

  test(
    '[REFACTOR] missing-session exit resets watermark so subsequent stream events pass gate (AP-4 full fix)',
    () async {
      // Scenario: loadGroup sets watermark to T_future (fresh server fetch).
      // Stream emits null → 3s debounce → latch.
      // Stream emits a cached session with T_cached < T_future.
      // Expected (per specs 10.4.8.b single-shot bypass):
      //   - latch is cleared
      //   - watermarks reset to T_cached
      //   - a follow-up session with T_cached+1s passes the gate normally
      final now = DateTime.now();
      final deviceInfo = DeviceInfoService.ephemeral();
      final group = _buildRunningGroup(id: 'group-ap4', start: now);

      // Fresh session: lastUpdatedAt far in the future (simulates server fetch)
      final tFuture = now.add(const Duration(minutes: 5));
      final freshSession = PomodoroSession(
        taskId: group.tasks.first.sourceTaskId,
        groupId: group.id,
        currentTaskId: group.tasks.first.sourceTaskId,
        currentTaskIndex: 0,
        totalTasks: 1,
        dataVersion: kCurrentDataVersion,
        sessionRevision: 10,
        ownerDeviceId: 'other-device',
        status: PomodoroStatus.pomodoroRunning,
        phase: PomodoroPhase.pomodoro,
        currentPomodoro: 1,
        totalPomodoros: 2,
        phaseDurationSeconds: 25 * 60,
        remainingSeconds: 1400,
        accumulatedPausedSeconds: 0,
        phaseStartedAt: now.subtract(const Duration(minutes: 1, seconds: 40)),
        currentTaskStartedAt: now.subtract(
          const Duration(minutes: 1, seconds: 40),
        ),
        pausedAt: null,
        lastUpdatedAt: tFuture,
        finishedAt: null,
        pauseReason: null,
      );

      // Cached (stale) session: same revision, lastUpdatedAt in the past
      final tCached = now.subtract(const Duration(minutes: 1));
      final cachedSession = PomodoroSession(
        taskId: freshSession.taskId,
        groupId: freshSession.groupId,
        currentTaskId: freshSession.currentTaskId,
        currentTaskIndex: freshSession.currentTaskIndex,
        totalTasks: freshSession.totalTasks,
        dataVersion: freshSession.dataVersion,
        sessionRevision: freshSession.sessionRevision, // same revision
        ownerDeviceId: freshSession.ownerDeviceId,
        status: freshSession.status,
        phase: freshSession.phase,
        currentPomodoro: freshSession.currentPomodoro,
        totalPomodoros: freshSession.totalPomodoros,
        phaseDurationSeconds: freshSession.phaseDurationSeconds,
        remainingSeconds: 1380,
        accumulatedPausedSeconds: freshSession.accumulatedPausedSeconds,
        phaseStartedAt: freshSession.phaseStartedAt,
        currentTaskStartedAt: freshSession.currentTaskStartedAt,
        pausedAt: null,
        lastUpdatedAt: tCached, // older than T_future
        finishedAt: null,
        pauseReason: null,
      );

      // Follow-up session: revision+1, just 1s newer than cached
      final followUpSession = PomodoroSession(
        taskId: freshSession.taskId,
        groupId: freshSession.groupId,
        currentTaskId: freshSession.currentTaskId,
        currentTaskIndex: freshSession.currentTaskIndex,
        totalTasks: freshSession.totalTasks,
        dataVersion: freshSession.dataVersion,
        sessionRevision: 11, // higher revision
        ownerDeviceId: freshSession.ownerDeviceId,
        status: freshSession.status,
        phase: freshSession.phase,
        currentPomodoro: freshSession.currentPomodoro,
        totalPomodoros: freshSession.totalPomodoros,
        phaseDurationSeconds: freshSession.phaseDurationSeconds,
        remainingSeconds: 1370,
        accumulatedPausedSeconds: freshSession.accumulatedPausedSeconds,
        phaseStartedAt: freshSession.phaseStartedAt,
        currentTaskStartedAt: freshSession.currentTaskStartedAt,
        pausedAt: null,
        lastUpdatedAt: tCached.add(const Duration(seconds: 1)),
        finishedAt: null,
        pauseReason: null,
      );

      final groupRepo = FakeTaskRunGroupRepository()..seed(group);
      final sessionRepo = FakePomodoroSessionRepository(freshSession);
      final appModeService = AppModeService.memory();

      final container = ProviderContainer(
        overrides: [
          taskRunGroupRepositoryProvider.overrideWithValue(groupRepo),
          pomodoroSessionRepositoryProvider.overrideWithValue(sessionRepo),
          appModeServiceProvider.overrideWithValue(appModeService),
          deviceInfoServiceProvider.overrideWithValue(deviceInfo),
          soundServiceProvider.overrideWithValue(FakeSoundService()),
          timeSyncServiceProvider.overrideWithValue(
            FakeTimeSyncService(offset: Duration.zero),
          ),
        ],
      );
      addTearDown(() {
        sessionRepo.dispose();
        container.dispose();
      });

      await container.read(appModeProvider.notifier).setAccount();
      await _pumpQueue();

      container.listen<PomodoroState>(pomodoroViewModelProvider, (_, __) {});
      final vm = container.read(pomodoroViewModelProvider.notifier);
      final result = await vm.loadGroup(group.id);
      expect(result, PomodoroGroupLoadResult.loaded);
      await _pumpQueue();

      // Trigger null → debounce → latch
      sessionRepo.emit(null);
      await _pumpQueue();
      await Future<void>.delayed(const Duration(seconds: 4));
      await _pumpQueue();
      expect(
        vm.isSessionMissingWhileRunning,
        isTrue,
        reason: 'latch must fire after debounce',
      );

      // Deliver cached session (T_cached < T_future → old code blocks the gate)
      sessionRepo.emit(cachedSession);
      await _pumpQueue();

      // The latch must be cleared by the single-shot bypass
      expect(
        vm.isSessionMissingWhileRunning,
        isFalse,
        reason: 'AP-4: stale snapshot must exit hold regardless of gate',
      );
      final stateAfterExit = container.read(pomodoroViewModelProvider);
      final expectedProjected =
          (cachedSession.phaseDurationSeconds -
                  DateTime.now()
                      .difference(cachedSession.phaseStartedAt!)
                      .inSeconds)
              .clamp(0, cachedSession.phaseDurationSeconds)
              .toInt();
      expect(
        stateAfterExit.remainingSeconds,
        isNot(cachedSession.remainingSeconds),
        reason:
            'Hold exit must project remaining time from phase start, not from stale snapshot remainingSeconds.',
      );
      expect(
        (stateAfterExit.remainingSeconds - expectedProjected).abs(),
        lessThanOrEqualTo(5),
        reason:
            'Hold exit remainingSeconds must be timeline-projected (phaseStartedAt + elapsed).',
      );

      // [REFACTOR] After bypass, watermarks must be reset to T_cached.
      // Verify by emitting a follow-up session slightly newer than T_cached:
      // it must be accepted (would be blocked if watermarks still pointed to T_future).
      sessionRepo.emit(followUpSession);
      await _pumpQueue();
      expect(
        vm.activeSessionForCurrentGroup?.sessionRevision,
        followUpSession.sessionRevision,
        reason:
            '[REFACTOR] watermarks reset to cached values; follow-up session must be applied',
      );
    },
  );

  test(
    'stream null within debounce window does not latch if real session arrives first (AP-2)',
    () async {
      final now = DateTime.now();
      final deviceInfo = DeviceInfoService.ephemeral();
      final group = _buildRunningGroup(id: 'group-ap2', start: now);
      final session = _buildRunningSession(
        groupId: group.id,
        taskId: group.tasks.first.sourceTaskId,
        ownerDeviceId: 'other-device',
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
          deviceInfoServiceProvider.overrideWithValue(deviceInfo),
          soundServiceProvider.overrideWithValue(FakeSoundService()),
          timeSyncServiceProvider.overrideWithValue(
            FakeTimeSyncService(offset: Duration.zero),
          ),
        ],
      );
      addTearDown(() {
        sessionRepo.dispose();
        container.dispose();
      });

      await container.read(appModeProvider.notifier).setAccount();
      await _pumpQueue();

      container.listen<PomodoroState>(pomodoroViewModelProvider, (_, __) {});
      final vm = container.read(pomodoroViewModelProvider.notifier);
      final result = await vm.loadGroup(group.id);
      expect(result, PomodoroGroupLoadResult.loaded);
      await _pumpQueue();

      // Emit null to start the 3s debounce
      sessionRepo.emit(null);
      await _pumpQueue();
      // Wait only 1s (within debounce window) then send valid session
      await Future<void>.delayed(const Duration(seconds: 1));
      final recoveredSession = PomodoroSession(
        taskId: session.taskId,
        groupId: session.groupId,
        currentTaskId: session.currentTaskId,
        currentTaskIndex: session.currentTaskIndex,
        totalTasks: session.totalTasks,
        dataVersion: session.dataVersion,
        sessionRevision: 2,
        ownerDeviceId: session.ownerDeviceId,
        status: session.status,
        phase: session.phase,
        currentPomodoro: session.currentPomodoro,
        totalPomodoros: session.totalPomodoros,
        phaseDurationSeconds: session.phaseDurationSeconds,
        remainingSeconds: session.remainingSeconds,
        accumulatedPausedSeconds: session.accumulatedPausedSeconds,
        phaseStartedAt: session.phaseStartedAt,
        currentTaskStartedAt: session.currentTaskStartedAt,
        pausedAt: null,
        lastUpdatedAt: session.lastUpdatedAt,
        finishedAt: null,
        pauseReason: null,
      );
      sessionRepo.emit(recoveredSession);
      await _pumpQueue();
      // Wait out the rest of the debounce window
      await Future<void>.delayed(const Duration(seconds: 3));
      await _pumpQueue();

      expect(
        vm.isSessionMissingWhileRunning,
        isFalse,
        reason:
            'AP-2: debounce cancelled by real session; no latch should fire',
      );
      expect(vm.activeSessionForCurrentGroup, isNotNull);
    },
  );

  test(
    'terminal session snapshot with terminal group corroboration does not enter hold loop',
    () async {
      final now = DateTime.now();
      final deviceInfo = DeviceInfoService.ephemeral();
      final runningGroup = _buildRunningGroup(
        id: 'group-terminal-boundary',
        start: now,
      );
      final runningSession = _buildRunningSession(
        groupId: runningGroup.id,
        taskId: runningGroup.tasks.first.sourceTaskId,
        ownerDeviceId: 'other-device',
        now: now,
      );
      final terminalSession = PomodoroSession(
        taskId: runningSession.taskId,
        groupId: runningSession.groupId,
        currentTaskId: runningSession.currentTaskId,
        currentTaskIndex: runningSession.currentTaskIndex,
        totalTasks: runningSession.totalTasks,
        dataVersion: runningSession.dataVersion,
        sessionRevision: runningSession.sessionRevision + 1,
        ownerDeviceId: runningSession.ownerDeviceId,
        status: PomodoroStatus.finished,
        phase: runningSession.phase,
        currentPomodoro: runningSession.currentPomodoro,
        totalPomodoros: runningSession.totalPomodoros,
        phaseDurationSeconds: runningSession.phaseDurationSeconds,
        remainingSeconds: 0,
        accumulatedPausedSeconds: runningSession.accumulatedPausedSeconds,
        phaseStartedAt: runningSession.phaseStartedAt,
        currentTaskStartedAt: runningSession.currentTaskStartedAt,
        pausedAt: null,
        lastUpdatedAt: now.add(const Duration(seconds: 1)),
        finishedAt: now.add(const Duration(seconds: 1)),
        pauseReason: null,
      );

      final groupRepo = FakeTaskRunGroupRepository()..seed(runningGroup);
      final sessionRepo = FakePomodoroSessionRepository(runningSession);
      final appModeService = AppModeService.memory();

      final container = ProviderContainer(
        overrides: [
          taskRunGroupRepositoryProvider.overrideWithValue(groupRepo),
          pomodoroSessionRepositoryProvider.overrideWithValue(sessionRepo),
          appModeServiceProvider.overrideWithValue(appModeService),
          deviceInfoServiceProvider.overrideWithValue(deviceInfo),
          soundServiceProvider.overrideWithValue(FakeSoundService()),
          timeSyncServiceProvider.overrideWithValue(
            FakeTimeSyncService(offset: Duration.zero),
          ),
        ],
      );
      addTearDown(() {
        sessionRepo.dispose();
        container.dispose();
      });

      await container.read(appModeProvider.notifier).setAccount();
      await _pumpQueue();

      container.listen<PomodoroState>(pomodoroViewModelProvider, (_, __) {});
      final vm = container.read(pomodoroViewModelProvider.notifier);
      final result = await vm.loadGroup(runningGroup.id);
      expect(result, PomodoroGroupLoadResult.loaded);
      await _pumpQueue();

      await groupRepo.save(
        runningGroup.copyWith(
          status: TaskRunStatus.completed,
          updatedAt: now.add(const Duration(seconds: 1)),
        ),
      );
      sessionRepo.emit(terminalSession);
      await _pumpQueue();

      sessionRepo.emit(null);
      await _pumpQueue();
      await Future<void>.delayed(const Duration(seconds: 4));
      await _pumpQueue();

      expect(
        vm.isSessionMissingWhileRunning,
        isFalse,
        reason:
            'Terminal boundary must not leave VM in missing-session hold when group is already terminal.',
      );
      expect(
        container.read(sessionSyncServiceProvider).holdActive,
        isFalse,
        reason:
            'SessionSyncService must clear/suppress hold once terminal snapshot is corroborated.',
      );
    },
  );

  test('stream AsyncError does not trigger missing-session hold latch', () async {
    final now = DateTime.now();
    final group = _buildRunningGroup(
      id: 'group-stream-error-ignore',
      start: now,
    );
    final session = _buildRunningSession(
      groupId: group.id,
      taskId: group.tasks.first.sourceTaskId,
      ownerDeviceId: 'other-device',
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
          FakeTimeSyncService(offset: Duration.zero),
        ),
      ],
    );
    addTearDown(() {
      sessionRepo.dispose();
      container.dispose();
    });

    await container.read(appModeProvider.notifier).setAccount();
    await _pumpQueue();

    container.listen<PomodoroState>(pomodoroViewModelProvider, (_, __) {});
    final vm = container.read(pomodoroViewModelProvider.notifier);
    final result = await vm.loadGroup(group.id);
    expect(result, PomodoroGroupLoadResult.loaded);
    await _pumpQueue();

    sessionRepo.emitError(StateError('stream-error'));
    await _pumpQueue();
    await Future<void>.delayed(const Duration(seconds: 4));
    await _pumpQueue();

    expect(
      vm.isSessionMissingWhileRunning,
      isFalse,
      reason:
          'AsyncError must be ignored by SessionSyncService and never treated as null session.',
    );
  });

  test(
    'stream AsyncLoading does not trigger missing-session hold latch',
    () async {
      final now = DateTime.now();
      final group = _buildRunningGroup(
        id: 'group-stream-loading-ignore',
        start: now,
      );
      final session = _buildRunningSession(
        groupId: group.id,
        taskId: group.tasks.first.sourceTaskId,
        ownerDeviceId: 'other-device',
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
            FakeTimeSyncService(offset: Duration.zero),
          ),
        ],
      );
      addTearDown(() {
        sessionRepo.dispose();
        container.dispose();
      });

      await container.read(appModeProvider.notifier).setAccount();
      await _pumpQueue();

      container.listen<PomodoroState>(pomodoroViewModelProvider, (_, __) {});
      final vm = container.read(pomodoroViewModelProvider.notifier);
      final result = await vm.loadGroup(group.id);
      expect(result, PomodoroGroupLoadResult.loaded);
      await _pumpQueue();

      container.invalidate(pomodoroSessionStreamProvider);
      await _pumpQueue();
      await Future<void>.delayed(const Duration(seconds: 4));
      await _pumpQueue();

      expect(
        vm.isSessionMissingWhileRunning,
        isFalse,
        reason:
            'AsyncLoading must be ignored by SessionSyncService and never treated as null session.',
      );
    },
  );

  test(
    'recovery clears latch when server session is active and owner is different device (AP-3)',
    () async {
      // Scenario: this device was the owner. Stream drops (null). Device tries
      // to reclaim (tryClaimSession → false: another device took over).
      // fetchSession returns active session with new owner.
      // Expected: latch cleared, new owner session applied.
      final now = DateTime.now();
      final deviceInfo = DeviceInfoService.ephemeral();
      final group = _buildRunningGroup(id: 'group-ap3', start: now);
      final remoteOwner = 'remote-owner-device';

      // This device starts as owner
      final ownerSession = _buildRunningSession(
        groupId: group.id,
        taskId: group.tasks.first.sourceTaskId,
        ownerDeviceId: deviceInfo.deviceId, // this device owns it
        now: now,
      );
      // Server session: another device has taken over (new owner)
      final serverSession = PomodoroSession(
        taskId: ownerSession.taskId,
        groupId: ownerSession.groupId,
        currentTaskId: ownerSession.currentTaskId,
        currentTaskIndex: ownerSession.currentTaskIndex,
        totalTasks: ownerSession.totalTasks,
        dataVersion: ownerSession.dataVersion,
        sessionRevision: ownerSession.sessionRevision + 1,
        ownerDeviceId: remoteOwner, // new owner
        status: PomodoroStatus.pomodoroRunning,
        phase: PomodoroPhase.pomodoro,
        currentPomodoro: ownerSession.currentPomodoro,
        totalPomodoros: ownerSession.totalPomodoros,
        phaseDurationSeconds: ownerSession.phaseDurationSeconds,
        remainingSeconds: 1100,
        accumulatedPausedSeconds: 0,
        phaseStartedAt: now.subtract(const Duration(minutes: 3)),
        currentTaskStartedAt: now.subtract(const Duration(minutes: 3)),
        pausedAt: null,
        lastUpdatedAt: now,
        finishedAt: null,
        pauseReason: null,
      );

      final groupRepo = FakeTaskRunGroupRepository()..seed(group);
      // tryClaimSession returns false (remote device now owns the session).
      // fetchSession always returns serverSession (server has the active session).
      final sessionRepo = _FakeSessionRepoClaimFails.withServer(
        ownerSession,
        serverSession,
      );
      final appModeService = AppModeService.memory();

      final container = ProviderContainer(
        overrides: [
          taskRunGroupRepositoryProvider.overrideWithValue(groupRepo),
          pomodoroSessionRepositoryProvider.overrideWithValue(sessionRepo),
          appModeServiceProvider.overrideWithValue(appModeService),
          deviceInfoServiceProvider.overrideWithValue(deviceInfo),
          soundServiceProvider.overrideWithValue(FakeSoundService()),
          timeSyncServiceProvider.overrideWithValue(
            FakeTimeSyncService(offset: Duration.zero),
          ),
        ],
      );
      addTearDown(() {
        sessionRepo.dispose();
        container.dispose();
      });

      await container.read(appModeProvider.notifier).setAccount();
      await _pumpQueue();

      container.listen<PomodoroState>(pomodoroViewModelProvider, (_, __) {});
      final vm = container.read(pomodoroViewModelProvider.notifier);
      final result = await vm.loadGroup(group.id);
      expect(result, PomodoroGroupLoadResult.loaded);
      await _pumpQueue();

      // Trigger latch: emit null, wait for debounce.
      // fetchSession already returns the active server session throughout,
      // so the first recovery attempt (fired by the latch) can find it.
      sessionRepo.emit(null);
      await _pumpQueue();
      await Future<void>.delayed(const Duration(seconds: 4));
      await _pumpQueue();

      // After debounce + recovery: latch must be cleared by the server fetch
      expect(
        vm.isSessionMissingWhileRunning,
        isFalse,
        reason:
            'AP-3: server fetch during recovery must clear latch when remote session is active',
      );
      expect(
        vm.activeSessionForCurrentGroup?.ownerDeviceId,
        remoteOwner,
        reason:
            'AP-3: discovered remote session must be applied after recovery',
      );
    },
  );

  test(
    'projection_uses_phase_start_not_snapshot_remaining_on_hold_exit',
    () async {
      final now = DateTime.now();
      final deviceInfo = DeviceInfoService.ephemeral();
      final group = _buildRunningGroup(
        id: 'group-projection-phase-start',
        start: now,
      );

      final freshSession = PomodoroSession(
        taskId: group.tasks.first.sourceTaskId,
        groupId: group.id,
        currentTaskId: group.tasks.first.sourceTaskId,
        currentTaskIndex: 0,
        totalTasks: 1,
        dataVersion: kCurrentDataVersion,
        sessionRevision: 20,
        ownerDeviceId: 'other-device',
        status: PomodoroStatus.pomodoroRunning,
        phase: PomodoroPhase.pomodoro,
        currentPomodoro: 1,
        totalPomodoros: 2,
        phaseDurationSeconds: 25 * 60,
        remainingSeconds: 1300,
        accumulatedPausedSeconds: 0,
        phaseStartedAt: now.subtract(const Duration(minutes: 3, seconds: 30)),
        currentTaskStartedAt: now.subtract(
          const Duration(minutes: 3, seconds: 30),
        ),
        pausedAt: null,
        lastUpdatedAt: now.add(const Duration(minutes: 2)),
        finishedAt: null,
        pauseReason: null,
      );
      final exitSnapshot = PomodoroSession(
        taskId: freshSession.taskId,
        groupId: freshSession.groupId,
        currentTaskId: freshSession.currentTaskId,
        currentTaskIndex: freshSession.currentTaskIndex,
        totalTasks: freshSession.totalTasks,
        dataVersion: freshSession.dataVersion,
        sessionRevision: freshSession.sessionRevision,
        ownerDeviceId: freshSession.ownerDeviceId,
        status: freshSession.status,
        phase: freshSession.phase,
        currentPomodoro: freshSession.currentPomodoro,
        totalPomodoros: freshSession.totalPomodoros,
        phaseDurationSeconds: freshSession.phaseDurationSeconds,
        // Intentionally stale and inconsistent with phaseStartedAt + elapsed.
        remainingSeconds: 1450,
        accumulatedPausedSeconds: 0,
        phaseStartedAt: freshSession.phaseStartedAt,
        currentTaskStartedAt: freshSession.currentTaskStartedAt,
        pausedAt: null,
        lastUpdatedAt: now.subtract(const Duration(minutes: 1)),
        finishedAt: null,
        pauseReason: null,
      );

      final groupRepo = FakeTaskRunGroupRepository()..seed(group);
      final sessionRepo = FakePomodoroSessionRepository(freshSession);
      final appModeService = AppModeService.memory();

      final container = ProviderContainer(
        overrides: [
          taskRunGroupRepositoryProvider.overrideWithValue(groupRepo),
          pomodoroSessionRepositoryProvider.overrideWithValue(sessionRepo),
          appModeServiceProvider.overrideWithValue(appModeService),
          deviceInfoServiceProvider.overrideWithValue(deviceInfo),
          soundServiceProvider.overrideWithValue(FakeSoundService()),
          timeSyncServiceProvider.overrideWithValue(
            FakeTimeSyncService(offset: Duration.zero),
          ),
        ],
      );
      addTearDown(() {
        sessionRepo.dispose();
        container.dispose();
      });

      await container.read(appModeProvider.notifier).setAccount();
      await _pumpQueue();

      container.listen<PomodoroState>(pomodoroViewModelProvider, (_, __) {});
      final vm = container.read(pomodoroViewModelProvider.notifier);
      final result = await vm.loadGroup(group.id);
      expect(result, PomodoroGroupLoadResult.loaded);
      await _pumpQueue();

      sessionRepo.emit(null);
      await _pumpQueue();
      await Future<void>.delayed(const Duration(seconds: 4));
      await _pumpQueue();
      expect(vm.isSessionMissingWhileRunning, isTrue);

      sessionRepo.emit(exitSnapshot);
      await _pumpQueue();

      final state = container.read(pomodoroViewModelProvider);
      final expectedProjected =
          (exitSnapshot.phaseDurationSeconds -
                  DateTime.now()
                      .difference(exitSnapshot.phaseStartedAt!)
                      .inSeconds)
              .clamp(0, exitSnapshot.phaseDurationSeconds)
              .toInt();
      expect(vm.isSessionMissingWhileRunning, isFalse);
      expect(
        state.remainingSeconds,
        isNot(exitSnapshot.remainingSeconds),
        reason: 'Projection must not use stale snapshot remainingSeconds.',
      );
      expect(
        (state.remainingSeconds - expectedProjected).abs(),
        lessThanOrEqualTo(5),
        reason:
            'Projection must be derived from phaseStartedAt + elapsed when exiting hold.',
      );
    },
  );

  test(
    '[PHASE4] active projection must continue with local fallback when timeSync is unavailable',
    () async {
      final now = DateTime.now();
      final deviceInfo = DeviceInfoService.ephemeral();
      final group = _buildRunningGroup(
        id: 'group-phase4-local-fallback-projection',
        start: now,
      );
      final session = _buildRunningSession(
        groupId: group.id,
        taskId: group.tasks.first.sourceTaskId,
        ownerDeviceId: 'other-device',
        now: now,
      );

      final groupRepo = FakeTaskRunGroupRepository()..seed(group);
      final sessionRepo = FakePomodoroSessionRepository(session);
      final appModeService = AppModeService.memory();
      final timeSyncService = FakeTimeSyncService(offset: null);

      final container = ProviderContainer(
        overrides: [
          taskRunGroupRepositoryProvider.overrideWithValue(groupRepo),
          pomodoroSessionRepositoryProvider.overrideWithValue(sessionRepo),
          appModeServiceProvider.overrideWithValue(appModeService),
          deviceInfoServiceProvider.overrideWithValue(deviceInfo),
          soundServiceProvider.overrideWithValue(FakeSoundService()),
          timeSyncServiceProvider.overrideWithValue(timeSyncService),
        ],
      );
      addTearDown(() {
        sessionRepo.dispose();
        container.dispose();
      });

      await container.read(appModeProvider.notifier).setAccount();
      await _pumpQueue();

      container.listen<PomodoroState>(pomodoroViewModelProvider, (_, __) {});
      final vm = container.read(pomodoroViewModelProvider.notifier);
      final result = await vm.loadGroup(group.id);
      expect(result, PomodoroGroupLoadResult.loaded);
      await _pumpQueue();

      expect(vm.isTimeSyncReady, isFalse);
      expect(vm.activeSessionForCurrentGroup, isNotNull);

      final before = container.read(pomodoroViewModelProvider);
      final beforeSeconds = before.remainingSeconds;
      expect(before.status.isActiveExecution, isTrue);

      await Future<void>.delayed(const Duration(seconds: 2));
      await _pumpQueue();

      final after = container.read(pomodoroViewModelProvider);
      expect(
        after.remainingSeconds,
        lessThan(beforeSeconds),
        reason:
            'Phase-4 contract: active render projection must continue with local fallback and must not freeze on snapshotRemaining when timeSync is unavailable.',
      );
    },
  );

  test('post-resume resync callback does not use disposed ref', () async {
    final errors = <Object>[];
    await runZonedGuarded(
      () async {
        final now = DateTime.now();
        final deviceInfo = DeviceInfoService.ephemeral();
        final group = _buildRunningGroup(
          id: 'group-dispose-safe-resync',
          start: now,
        );
        final session = _buildRunningSession(
          groupId: group.id,
          taskId: group.tasks.first.sourceTaskId,
          ownerDeviceId: 'other-device',
          now: now,
        );

        final groupRepo = FakeTaskRunGroupRepository()..seed(group);
        final sessionRepo = FakePomodoroSessionRepository(
          session,
          fetchDelay: const Duration(milliseconds: 600),
        );
        final appModeService = AppModeService.memory();

        final container = ProviderContainer(
          overrides: [
            taskRunGroupRepositoryProvider.overrideWithValue(groupRepo),
            pomodoroSessionRepositoryProvider.overrideWithValue(sessionRepo),
            appModeServiceProvider.overrideWithValue(appModeService),
            deviceInfoServiceProvider.overrideWithValue(deviceInfo),
            soundServiceProvider.overrideWithValue(FakeSoundService()),
            timeSyncServiceProvider.overrideWithValue(
              FakeTimeSyncService(offset: Duration.zero),
            ),
          ],
        );

        final vmSub = container.listen<PomodoroState>(
          pomodoroViewModelProvider,
          (_, __) {},
        );
        var disposed = false;
        try {
          await container.read(appModeProvider.notifier).setAccount();
          await _pumpQueue();

          final vm = container.read(pomodoroViewModelProvider.notifier);
          final result = await vm.loadGroup(group.id);
          expect(result, PomodoroGroupLoadResult.loaded);
          await _pumpQueue();

          vm.handleAppResumed();
          await Future<void>.delayed(const Duration(milliseconds: 2100));
          await _pumpQueue();

          container.dispose();
          sessionRepo.dispose();
          disposed = true;

          await Future<void>.delayed(const Duration(seconds: 1));
          await _pumpQueue();
        } finally {
          if (!disposed) {
            container.dispose();
            sessionRepo.dispose();
          }
          vmSub.close();
        }
      },
      (error, _) {
        errors.add(error);
      },
    );

    expect(
      errors,
      isEmpty,
      reason:
          'Post-resume sync callbacks must be no-op after dispose and never touch invalid Ref.',
    );
  });

  test(
    '[PHASE5] VM lifecycle/session-sub diagnostics must include vmToken and lifecycle reasons',
    () async {
      final now = DateTime.now();
      final deviceInfo = DeviceInfoService.ephemeral();
      final group = _buildRunningGroup(
        id: 'group-phase5-vm-lifecycle',
        start: now,
      );
      final session = _buildRunningSession(
        groupId: group.id,
        taskId: group.tasks.first.sourceTaskId,
        ownerDeviceId: 'owner-device',
        now: now,
      );

      final groupRepo = FakeTaskRunGroupRepository()..seed(group);
      final sessionRepo = FakePomodoroSessionRepository(session);
      final appModeService = AppModeService.memory();

      final logs = <String>[];
      final previousDebugPrint = foundation.debugPrint;
      foundation.debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) logs.add(message);
      };

      final container = ProviderContainer(
        overrides: [
          taskRunGroupRepositoryProvider.overrideWithValue(groupRepo),
          pomodoroSessionRepositoryProvider.overrideWithValue(sessionRepo),
          appModeServiceProvider.overrideWithValue(appModeService),
          deviceInfoServiceProvider.overrideWithValue(deviceInfo),
          soundServiceProvider.overrideWithValue(FakeSoundService()),
          timeSyncServiceProvider.overrideWithValue(
            FakeTimeSyncService(offset: Duration.zero),
          ),
        ],
      );
      addTearDown(() {
        foundation.debugPrint = previousDebugPrint;
        sessionRepo.dispose();
        container.dispose();
      });

      await container.read(appModeProvider.notifier).setAccount();
      await _pumpQueue();

      container.listen<PomodoroState>(pomodoroViewModelProvider, (_, __) {});
      final vm = container.read(pomodoroViewModelProvider.notifier);
      final first = await vm.loadGroup(group.id);
      expect(first, PomodoroGroupLoadResult.loaded);
      await _pumpQueue();

      final second = await vm.loadGroup(group.id);
      expect(second, PomodoroGroupLoadResult.loaded);
      await _pumpQueue();

      final merged = logs.join('\n');
      expect(
        merged.contains('[VMLifecycle] init'),
        isTrue,
        reason:
            'Phase-5 diagnostics contract: ViewModel lifecycle must emit init diagnostics.',
      );
      expect(
        merged.contains('[SessionSub] open'),
        isTrue,
        reason:
            'Phase-5 diagnostics contract: session subscription open must be logged.',
      );
      expect(
        merged.contains('[SessionSub] close'),
        isTrue,
        reason:
            'Phase-5 diagnostics contract: session subscription close must be logged.',
      );
      expect(
        merged.contains('vmToken='),
        isTrue,
        reason:
            'Phase-5 diagnostics contract: lifecycle/subscription logs must include vmToken correlation.',
      );
      expect(
        merged.contains('reason='),
        isTrue,
        reason:
            'Phase-5 diagnostics contract: session-sub diagnostics must include explicit close/open reason metadata.',
      );
    },
  );

  test(
    '[PHASE3] transitional non-active snapshot must not clear hold without terminal corroboration',
    () async {
      final now = DateTime.now();
      final deviceInfo = DeviceInfoService.ephemeral();
      final group = _buildRunningGroup(
        id: 'group-phase3-transitional',
        start: now,
      );
      final runningSession = _buildRunningSession(
        groupId: group.id,
        taskId: group.tasks.first.sourceTaskId,
        ownerDeviceId: 'other-device',
        now: now,
      );
      final transitionalFinishedSnapshot = PomodoroSession(
        taskId: runningSession.taskId,
        groupId: runningSession.groupId,
        currentTaskId: runningSession.currentTaskId,
        currentTaskIndex: runningSession.currentTaskIndex,
        totalTasks: runningSession.totalTasks,
        dataVersion: runningSession.dataVersion,
        sessionRevision: runningSession.sessionRevision + 1,
        ownerDeviceId: runningSession.ownerDeviceId,
        status: PomodoroStatus.finished,
        phase: null,
        currentPomodoro: runningSession.currentPomodoro,
        totalPomodoros: runningSession.totalPomodoros,
        phaseDurationSeconds: runningSession.phaseDurationSeconds,
        remainingSeconds: 0,
        accumulatedPausedSeconds: runningSession.accumulatedPausedSeconds,
        phaseStartedAt: runningSession.phaseStartedAt,
        currentTaskStartedAt: runningSession.currentTaskStartedAt,
        pausedAt: null,
        lastUpdatedAt: now,
        finishedAt: now,
        pauseReason: null,
      );

      final groupRepo = FakeTaskRunGroupRepository()..seed(group);
      final sessionRepo = FakePomodoroSessionRepository(runningSession);
      final appModeService = AppModeService.memory();

      final container = ProviderContainer(
        overrides: [
          taskRunGroupRepositoryProvider.overrideWithValue(groupRepo),
          pomodoroSessionRepositoryProvider.overrideWithValue(sessionRepo),
          appModeServiceProvider.overrideWithValue(appModeService),
          deviceInfoServiceProvider.overrideWithValue(deviceInfo),
          soundServiceProvider.overrideWithValue(FakeSoundService()),
          timeSyncServiceProvider.overrideWithValue(
            FakeTimeSyncService(offset: Duration.zero),
          ),
        ],
      );
      addTearDown(() {
        sessionRepo.dispose();
        container.dispose();
      });

      await container.read(appModeProvider.notifier).setAccount();
      await _pumpQueue();

      container.listen<PomodoroState>(pomodoroViewModelProvider, (_, __) {});
      final vm = container.read(pomodoroViewModelProvider.notifier);
      final result = await vm.loadGroup(group.id);
      expect(result, PomodoroGroupLoadResult.loaded);
      await _pumpQueue();

      sessionRepo.emit(null);
      await _pumpQueue();
      await Future<void>.delayed(const Duration(seconds: 4));
      await _pumpQueue();
      expect(vm.isSessionMissingWhileRunning, isTrue);

      sessionRepo.emit(transitionalFinishedSnapshot);
      await _pumpQueue();

      expect(
        vm.isSessionMissingWhileRunning,
        isTrue,
        reason:
            'Phase-3 contract: non-active transitional snapshots must extend hold unless group terminality is corroborated.',
      );
    },
  );

  test(
    '[PHASE3] non-owner recovery may read server and exit hold without write ownership',
    () async {
      final now = DateTime.now();
      final deviceInfo = DeviceInfoService.ephemeral();
      final group = _buildRunningGroup(
        id: 'group-phase3-non-owner-recovery',
        start: now,
      );
      final mirroredSession = _buildRunningSession(
        groupId: group.id,
        taskId: group.tasks.first.sourceTaskId,
        ownerDeviceId: 'owner-device',
        now: now,
      );
      final serverSession = PomodoroSession(
        taskId: mirroredSession.taskId,
        groupId: mirroredSession.groupId,
        currentTaskId: mirroredSession.currentTaskId,
        currentTaskIndex: mirroredSession.currentTaskIndex,
        totalTasks: mirroredSession.totalTasks,
        dataVersion: mirroredSession.dataVersion,
        sessionRevision: mirroredSession.sessionRevision + 1,
        ownerDeviceId: 'owner-device',
        status: PomodoroStatus.pomodoroRunning,
        phase: PomodoroPhase.pomodoro,
        currentPomodoro: mirroredSession.currentPomodoro,
        totalPomodoros: mirroredSession.totalPomodoros,
        phaseDurationSeconds: mirroredSession.phaseDurationSeconds,
        remainingSeconds: 1050,
        accumulatedPausedSeconds: 0,
        phaseStartedAt: now.subtract(const Duration(minutes: 4)),
        currentTaskStartedAt: now.subtract(const Duration(minutes: 4)),
        pausedAt: null,
        lastUpdatedAt: now,
        finishedAt: null,
        pauseReason: null,
      );

      final groupRepo = FakeTaskRunGroupRepository()..seed(group);
      final sessionRepo = _FakeSessionRepoClaimFails.withServer(
        mirroredSession,
        serverSession,
      );
      final appModeService = AppModeService.memory();

      final container = ProviderContainer(
        overrides: [
          taskRunGroupRepositoryProvider.overrideWithValue(groupRepo),
          pomodoroSessionRepositoryProvider.overrideWithValue(sessionRepo),
          appModeServiceProvider.overrideWithValue(appModeService),
          deviceInfoServiceProvider.overrideWithValue(deviceInfo),
          soundServiceProvider.overrideWithValue(FakeSoundService()),
          timeSyncServiceProvider.overrideWithValue(
            FakeTimeSyncService(offset: Duration.zero),
          ),
        ],
      );
      addTearDown(() {
        sessionRepo.dispose();
        container.dispose();
      });

      await container.read(appModeProvider.notifier).setAccount();
      await _pumpQueue();

      container.listen<PomodoroState>(pomodoroViewModelProvider, (_, __) {});
      final vm = container.read(pomodoroViewModelProvider.notifier);
      final result = await vm.loadGroup(group.id);
      expect(result, PomodoroGroupLoadResult.loaded);
      await _pumpQueue();

      sessionRepo.emit(null);
      await _pumpQueue();
      await Future<void>.delayed(const Duration(seconds: 4));
      await _pumpQueue();

      expect(
        vm.isSessionMissingWhileRunning,
        isFalse,
        reason:
            'Phase-3 contract: non-owner devices may recover hold via server read and shared ingest path.',
      );
      expect(
        vm.activeSessionForCurrentGroup?.ownerDeviceId,
        serverSession.ownerDeviceId,
      );
    },
  );

  test(
    '[PHASE6] _shouldKeepAlive returns true within grace window after last active snapshot',
    () async {
      PomodoroViewModel.debugKeepAliveGraceWindowOverride = const Duration(
        milliseconds: 200,
      );
      final now = DateTime.now();
      final deviceInfo = DeviceInfoService.ephemeral();
      final group = _buildRunningGroup(
        id: 'group-phase6-keepalive-grace',
        start: now,
      );
      final session = _buildRunningSession(
        groupId: group.id,
        taskId: group.tasks.first.sourceTaskId,
        ownerDeviceId: 'other-device',
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
          deviceInfoServiceProvider.overrideWithValue(deviceInfo),
          soundServiceProvider.overrideWithValue(FakeSoundService()),
          timeSyncServiceProvider.overrideWithValue(
            FakeTimeSyncService(offset: Duration.zero),
          ),
        ],
      );
      final vmSub = container.listen<PomodoroState>(
        pomodoroViewModelProvider,
        (_, __) {},
      );
      addTearDown(() {
        PomodoroViewModel.debugKeepAliveGraceWindowOverride = null;
        vmSub.close();
        sessionRepo.dispose();
        container.dispose();
      });

      await container.read(appModeProvider.notifier).setAccount();
      await _pumpQueue();

      final vm = container.read(pomodoroViewModelProvider.notifier);
      final result = await vm.loadGroup(group.id);
      expect(result, PomodoroGroupLoadResult.loaded);
      await _pumpQueue();

      vm.updateGroup(
        group.copyWith(
          status: TaskRunStatus.completed,
          updatedAt: now.add(const Duration(seconds: 1)),
        ),
      );
      sessionRepo.emit(null);
      await _pumpQueue();

      vmSub.close();
      await _pumpQueue();

      expect(
        container.exists(pomodoroViewModelProvider),
        isTrue,
        reason:
            'Phase-6 contract: provider must stay alive inside grace window after last active snapshot.',
      );
    },
  );

  test(
    '[PHASE6] _shouldKeepAlive returns false after grace window expires with no active state',
    () async {
      PomodoroViewModel.debugKeepAliveGraceWindowOverride = const Duration(
        milliseconds: 200,
      );
      final now = DateTime.now();
      final deviceInfo = DeviceInfoService.ephemeral();
      final group = _buildRunningGroup(
        id: 'group-phase6-keepalive-expiry',
        start: now,
      );
      final session = _buildRunningSession(
        groupId: group.id,
        taskId: group.tasks.first.sourceTaskId,
        ownerDeviceId: 'other-device',
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
          deviceInfoServiceProvider.overrideWithValue(deviceInfo),
          soundServiceProvider.overrideWithValue(FakeSoundService()),
          timeSyncServiceProvider.overrideWithValue(
            FakeTimeSyncService(offset: Duration.zero),
          ),
        ],
      );
      final vmSub = container.listen<PomodoroState>(
        pomodoroViewModelProvider,
        (_, __) {},
      );
      addTearDown(() {
        PomodoroViewModel.debugKeepAliveGraceWindowOverride = null;
        vmSub.close();
        sessionRepo.dispose();
        container.dispose();
      });

      await container.read(appModeProvider.notifier).setAccount();
      await _pumpQueue();

      final vm = container.read(pomodoroViewModelProvider.notifier);
      final result = await vm.loadGroup(group.id);
      expect(result, PomodoroGroupLoadResult.loaded);
      await _pumpQueue();

      vm.updateGroup(
        group.copyWith(
          status: TaskRunStatus.completed,
          updatedAt: now.add(const Duration(seconds: 1)),
        ),
      );
      sessionRepo.emit(null);
      await _pumpQueue();

      vmSub.close();
      await _pumpQueue();
      expect(container.exists(pomodoroViewModelProvider), isTrue);

      await Future<void>.delayed(const Duration(milliseconds: 650));
      await _pumpQueue();

      expect(
        container.exists(pomodoroViewModelProvider),
        isFalse,
        reason:
            'Phase-6 contract: provider must release keepAlive once grace expires and no active signal remains.',
      );
    },
  );

  // ─── Rewrite contract tests (specs 10.4.10.7) ────────────────────────────
  // These tests define rewrite-target behavior before runtime implementation.
  // [REWRITE-CORE] tests are expected to be red until TimerService/SessionSyncService
  // architecture is introduced.

  test(
    '[REWRITE-CORE] stream null must not freeze countdown progression (Invariant 1)',
    () async {
      final now = DateTime.now();
      final deviceInfo = DeviceInfoService.ephemeral();
      final group = _buildRunningGroup(id: 'group-rewrite-core-1', start: now);
      final session = _buildRunningSession(
        groupId: group.id,
        taskId: group.tasks.first.sourceTaskId,
        ownerDeviceId: 'other-device',
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
          deviceInfoServiceProvider.overrideWithValue(deviceInfo),
          soundServiceProvider.overrideWithValue(FakeSoundService()),
          timeSyncServiceProvider.overrideWithValue(
            FakeTimeSyncService(offset: Duration.zero),
          ),
        ],
      );
      addTearDown(() {
        sessionRepo.dispose();
        container.dispose();
      });

      await container.read(appModeProvider.notifier).setAccount();
      await _pumpQueue();

      final vmSub = container.listen<PomodoroState>(
        pomodoroViewModelProvider,
        (_, __) {},
      );
      addTearDown(vmSub.close);

      final vm = container.read(pomodoroViewModelProvider.notifier);
      final result = await vm.loadGroup(group.id);
      expect(result, PomodoroGroupLoadResult.loaded);
      await _pumpQueue();

      sessionRepo.emit(null);
      await _pumpQueue();
      await Future<void>.delayed(const Duration(seconds: 4));
      await _pumpQueue();

      final duringGap = container
          .read(pomodoroViewModelProvider)
          .remainingSeconds;

      await Future<void>.delayed(const Duration(seconds: 2));
      await _pumpQueue();

      final later = container.read(pomodoroViewModelProvider).remainingSeconds;
      expect(
        later,
        lessThan(duringGap),
        reason:
            'Invariant 1: countdown must keep progressing even while session stream is null.',
      );
    },
  );

  test(
    '[REWRITE-CORE] syncing state must be informational and preserve active execution (Invariant 2)',
    () async {
      final now = DateTime.now();
      final deviceInfo = DeviceInfoService.ephemeral();
      final group = _buildRunningGroup(id: 'group-rewrite-core-2', start: now);
      final session = _buildRunningSession(
        groupId: group.id,
        taskId: group.tasks.first.sourceTaskId,
        ownerDeviceId: 'other-device',
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
          deviceInfoServiceProvider.overrideWithValue(deviceInfo),
          soundServiceProvider.overrideWithValue(FakeSoundService()),
          timeSyncServiceProvider.overrideWithValue(
            FakeTimeSyncService(offset: Duration.zero),
          ),
        ],
      );
      addTearDown(() {
        sessionRepo.dispose();
        container.dispose();
      });

      await container.read(appModeProvider.notifier).setAccount();
      await _pumpQueue();

      final vmSub = container.listen<PomodoroState>(
        pomodoroViewModelProvider,
        (_, __) {},
      );
      addTearDown(vmSub.close);

      final vm = container.read(pomodoroViewModelProvider.notifier);
      final result = await vm.loadGroup(group.id);
      expect(result, PomodoroGroupLoadResult.loaded);
      await _pumpQueue();

      sessionRepo.emit(null);
      await _pumpQueue();
      await Future<void>.delayed(const Duration(seconds: 4));
      await _pumpQueue();

      final state = container.read(pomodoroViewModelProvider);
      expect(
        state.status.isActiveExecution,
        isTrue,
        reason:
            'Invariant 2: syncing/degraded state must remain informational and keep active execution status.',
      );
    },
  );

  test(
    '[REWRITE-CORE] authoritative runtime transitions must originate from TimerService (Invariant 3)',
    () async {
      final now = DateTime.now();
      final deviceInfo = DeviceInfoService.ephemeral();
      final group = _buildRunningGroup(id: 'group-rewrite-core-3', start: now);
      final ownerSession = _buildRunningSession(
        groupId: group.id,
        taskId: group.tasks.first.sourceTaskId,
        ownerDeviceId: deviceInfo.deviceId,
        now: now,
      );

      final groupRepo = FakeTaskRunGroupRepository()..seed(group);
      final sessionRepo = FakePomodoroSessionRepository(ownerSession);
      final appModeService = AppModeService.memory();

      final container = ProviderContainer(
        overrides: [
          taskRunGroupRepositoryProvider.overrideWithValue(groupRepo),
          pomodoroSessionRepositoryProvider.overrideWithValue(sessionRepo),
          appModeServiceProvider.overrideWithValue(appModeService),
          deviceInfoServiceProvider.overrideWithValue(deviceInfo),
          soundServiceProvider.overrideWithValue(FakeSoundService()),
          timeSyncServiceProvider.overrideWithValue(
            FakeTimeSyncService(offset: Duration.zero),
          ),
        ],
      );
      addTearDown(() {
        sessionRepo.dispose();
        container.dispose();
      });

      await container.read(appModeProvider.notifier).setAccount();
      await _pumpQueue();

      final vmSub = container.listen<PomodoroState>(
        pomodoroViewModelProvider,
        (_, __) {},
      );
      addTearDown(vmSub.close);

      final vm = container.read(pomodoroViewModelProvider.notifier);
      final result = await vm.loadGroup(group.id);
      expect(result, PomodoroGroupLoadResult.loaded);
      await _pumpQueue();

      final runtimeBeforePause = container.read(timerServiceProvider);
      expect(runtimeBeforePause.status.isActiveExecution, isTrue);

      vm.pause();
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await _pumpQueue();

      final publishedAfterPause = sessionRepo.lastPublished;
      expect(
        publishedAfterPause?.status,
        PomodoroStatus.paused,
        reason:
            'Invariant 3 setup: VM pause command path must publish a paused authoritative session snapshot.',
      );

      final runtimeAfterPause = container.read(timerServiceProvider);
      expect(
        runtimeAfterPause.status,
        PomodoroStatus.paused,
        reason:
            'Invariant 3: vm.pause() must produce the corresponding authoritative transition in TimerService.',
      );
    },
  );

  test(
    '[REWRITE-CORE] ownership recovery must be deterministic via explicit recovery states (Invariant 4)',
    () async {
      final now = DateTime.now();
      final deviceInfo = DeviceInfoService.ephemeral();
      final group = _buildRunningGroup(id: 'group-rewrite-core-4', start: now);
      final runningSnapshot = _buildRunningSession(
        groupId: group.id,
        taskId: group.tasks.first.sourceTaskId,
        ownerDeviceId: 'other-device',
        now: now,
      );

      final groupRepo = FakeTaskRunGroupRepository()..seed(group);
      final sessionRepo = FakePomodoroSessionRepository(runningSnapshot);
      final appModeService = AppModeService.memory();

      final container = ProviderContainer(
        overrides: [
          taskRunGroupRepositoryProvider.overrideWithValue(groupRepo),
          pomodoroSessionRepositoryProvider.overrideWithValue(sessionRepo),
          appModeServiceProvider.overrideWithValue(appModeService),
          deviceInfoServiceProvider.overrideWithValue(deviceInfo),
          soundServiceProvider.overrideWithValue(FakeSoundService()),
          timeSyncServiceProvider.overrideWithValue(
            FakeTimeSyncService(offset: Duration.zero),
          ),
        ],
      );
      addTearDown(() {
        sessionRepo.dispose();
        container.dispose();
      });

      await container.read(appModeProvider.notifier).setAccount();
      await _pumpQueue();

      final vmSub = container.listen<PomodoroState>(
        pomodoroViewModelProvider,
        (_, __) {},
      );
      addTearDown(vmSub.close);

      final vm = container.read(pomodoroViewModelProvider.notifier);
      final result = await vm.loadGroup(group.id);
      expect(result, PomodoroGroupLoadResult.loaded);
      await _pumpQueue();

      final initialOwnershipState = _ownershipSyncStateName(vm);
      expect(
        initialOwnershipState,
        isNot('__missing__'),
        reason:
            'Invariant 4: PomodoroViewModel must expose ownershipSyncState as observable state.',
      );

      sessionRepo.emit(null);
      await _pumpQueue();
      await Future<void>.delayed(const Duration(seconds: 4));
      await _pumpQueue();

      final degradedState = _ownershipSyncStateName(vm);
      expect(
        degradedState,
        equals('degraded'),
        reason:
            'Invariant 4: null-stream debounce expiry must transition to degraded.',
      );

      sessionRepo.emit(
        PomodoroSession(
          taskId: runningSnapshot.taskId,
          groupId: runningSnapshot.groupId,
          currentTaskId: runningSnapshot.currentTaskId,
          currentTaskIndex: runningSnapshot.currentTaskIndex,
          totalTasks: runningSnapshot.totalTasks,
          dataVersion: runningSnapshot.dataVersion,
          sessionRevision: runningSnapshot.sessionRevision + 1,
          ownerDeviceId: runningSnapshot.ownerDeviceId,
          status: runningSnapshot.status,
          phase: runningSnapshot.phase,
          currentPomodoro: runningSnapshot.currentPomodoro,
          totalPomodoros: runningSnapshot.totalPomodoros,
          phaseDurationSeconds: runningSnapshot.phaseDurationSeconds,
          remainingSeconds: runningSnapshot.remainingSeconds,
          accumulatedPausedSeconds: runningSnapshot.accumulatedPausedSeconds,
          phaseStartedAt: runningSnapshot.phaseStartedAt,
          currentTaskStartedAt: runningSnapshot.currentTaskStartedAt,
          pausedAt: runningSnapshot.pausedAt,
          lastUpdatedAt: now.add(const Duration(seconds: 10)),
          finishedAt: runningSnapshot.finishedAt,
          pauseReason: runningSnapshot.pauseReason,
          ownershipRequest: runningSnapshot.ownershipRequest,
        ),
      );
      await _pumpQueue();

      final recoveredState = _ownershipSyncStateName(vm);
      expect(
        recoveredState,
        equals(initialOwnershipState),
        reason:
            'Invariant 4: valid snapshot recovery must deterministically exit degraded to stable ownership state.',
      );
    },
  );

  test(
    '[REWRITE-CORE] VM dispose/rebuild must not reset runtime continuity (Invariant 5)',
    () async {
      final now = DateTime.now();
      final deviceInfo = DeviceInfoService.ephemeral();
      final group = _buildRunningGroup(id: 'group-rewrite-core-5', start: now);
      final session = _buildRunningSession(
        groupId: group.id,
        taskId: group.tasks.first.sourceTaskId,
        ownerDeviceId: 'other-device',
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
          deviceInfoServiceProvider.overrideWithValue(deviceInfo),
          soundServiceProvider.overrideWithValue(FakeSoundService()),
          timeSyncServiceProvider.overrideWithValue(
            FakeTimeSyncService(offset: Duration.zero),
          ),
        ],
      );
      addTearDown(() {
        sessionRepo.dispose();
        container.dispose();
      });

      await container.read(appModeProvider.notifier).setAccount();
      await _pumpQueue();

      final vmSub = container.listen<PomodoroState>(
        pomodoroViewModelProvider,
        (_, __) {},
      );
      addTearDown(vmSub.close);

      final vm = container.read(pomodoroViewModelProvider.notifier);
      final result = await vm.loadGroup(group.id);
      expect(result, PomodoroGroupLoadResult.loaded);
      await _pumpQueue();

      sessionRepo.emit(null);
      await _pumpQueue();
      await Future<void>.delayed(const Duration(seconds: 4));
      await _pumpQueue();

      final runtimeDuringGap = container.read(timerServiceProvider);
      expect(
        runtimeDuringGap.remainingSeconds,
        greaterThan(0),
        reason:
            'Invariant 5 setup: timer runtime must be active before VM dispose.',
      );

      // Force VM dispose/rebuild boundary while keeping ProviderContainer alive.
      vmSub.close();
      container.invalidate(pomodoroViewModelProvider);
      await _pumpQueue();
      expect(container.exists(pomodoroViewModelProvider), isFalse);

      await Future<void>.delayed(const Duration(seconds: 2));
      await _pumpQueue();

      final runtimeAfterDispose = container.read(timerServiceProvider);
      expect(
        runtimeAfterDispose.remainingSeconds,
        lessThan(runtimeDuringGap.remainingSeconds),
        reason:
            'Invariant 5: runtime countdown must continue while VM is disposed.',
      );

      final rebuiltVmSub = container.listen<PomodoroState>(
        pomodoroViewModelProvider,
        (_, __) {},
      );
      addTearDown(rebuiltVmSub.close);
      await _pumpQueue();
      expect(container.exists(pomodoroViewModelProvider), isTrue);

      final runtimeAfterRebuild = container.read(timerServiceProvider);
      expect(
        runtimeAfterRebuild.remainingSeconds,
        lessThan(runtimeDuringGap.remainingSeconds),
        reason:
            'Invariant 5: VM rebuild must not reset TimerService runtime continuity.',
      );
    },
  );

  test(
    '[PHASE3] hold diagnostics must emit enter/extend/exit with projectionSource',
    () async {
      final now = DateTime.now();
      final deviceInfo = DeviceInfoService.ephemeral();
      final group = _buildRunningGroup(
        id: 'group-phase3-diagnostics',
        start: now,
      );
      final session = _buildRunningSession(
        groupId: group.id,
        taskId: group.tasks.first.sourceTaskId,
        ownerDeviceId: 'other-device',
        now: now,
      );

      final groupRepo = FakeTaskRunGroupRepository()..seed(group);
      final sessionRepo = FakePomodoroSessionRepository(session);
      final appModeService = AppModeService.memory();

      final logs = <String>[];
      final previousDebugPrint = foundation.debugPrint;
      foundation.debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) logs.add(message);
      };

      final container = ProviderContainer(
        overrides: [
          taskRunGroupRepositoryProvider.overrideWithValue(groupRepo),
          pomodoroSessionRepositoryProvider.overrideWithValue(sessionRepo),
          appModeServiceProvider.overrideWithValue(appModeService),
          deviceInfoServiceProvider.overrideWithValue(deviceInfo),
          soundServiceProvider.overrideWithValue(FakeSoundService()),
          timeSyncServiceProvider.overrideWithValue(
            FakeTimeSyncService(offset: Duration.zero),
          ),
        ],
      );
      addTearDown(() {
        foundation.debugPrint = previousDebugPrint;
        sessionRepo.dispose();
        container.dispose();
      });

      await container.read(appModeProvider.notifier).setAccount();
      await _pumpQueue();

      container.listen<PomodoroState>(pomodoroViewModelProvider, (_, __) {});
      final vm = container.read(pomodoroViewModelProvider.notifier);
      final result = await vm.loadGroup(group.id);
      expect(result, PomodoroGroupLoadResult.loaded);
      await _pumpQueue();

      sessionRepo.emit(null);
      await _pumpQueue();
      await Future<void>.delayed(const Duration(seconds: 4));
      await _pumpQueue();
      sessionRepo.emit(session);
      await _pumpQueue();
      expect(vm.activeSessionForCurrentGroup, isNotNull);

      final merged = logs.join('\n');
      expect(
        merged.contains('hold-enter'),
        isTrue,
        reason: 'Diagnostics contract requires explicit hold-enter event.',
      );
      expect(
        merged.contains('hold-extend'),
        isTrue,
        reason: 'Diagnostics contract requires explicit hold-extend event.',
      );
      expect(
        merged.contains('hold-exit'),
        isTrue,
        reason: 'Diagnostics contract requires explicit hold-exit event.',
      );
      expect(
        merged.contains('projectionSource='),
        isTrue,
        reason:
            'Diagnostics contract requires projectionSource metadata on hold-exit lifecycle events.',
      );
    },
  );
}

// Variant that always fails tryClaimSession (simulates ownership by another device).
// fetchSession always returns [serverSession] regardless of stream state,
// simulating a server that has the active session even when the stream is null.
class _FakeSessionRepoClaimFails extends FakePomodoroSessionRepository {
  _FakeSessionRepoClaimFails(super.initialSession)
    : _serverSession = initialSession!;

  _FakeSessionRepoClaimFails.withServer(
    super.initialSession,
    PomodoroSession serverSession,
  ) : _serverSession = serverSession;

  final PomodoroSession _serverSession;

  @override
  Future<bool> tryClaimSession(PomodoroSession session) async => false;

  @override
  Future<PomodoroSession?> fetchSession({bool preferServer = false}) async {
    return _serverSession;
  }
}
