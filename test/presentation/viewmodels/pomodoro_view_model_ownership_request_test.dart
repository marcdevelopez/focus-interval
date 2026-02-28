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
  Stream<List<TaskRunGroup>> watchAll() =>
      Stream.value(_store.values.toList());

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

class RecordingSessionRepository implements PomodoroSessionRepository {
  RecordingSessionRepository(this._session);

  final PomodoroSession? _session;
  String? lastRequester;

  @override
  Stream<PomodoroSession?> watchSession() => Stream.value(_session);

  @override
  Future<PomodoroSession?> fetchSession({bool preferServer = false}) async {
    return _session;
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
  }) async {
    lastRequester = requesterDeviceId;
  }

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

TaskRunGroup _buildRunningGroup({
  required String id,
  required DateTime start,
}) {
  return TaskRunGroup(
    id: id,
    ownerUid: 'user-1',
    dataVersion: kCurrentDataVersion,
    integrityMode: TaskRunIntegrityMode.shared,
    tasks: [_buildItem()],
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
    lastUpdatedAt: now,
    finishedAt: null,
    pauseReason: null,
  );
}

Future<void> _pumpQueue() async {
  await Future<void>.delayed(const Duration(milliseconds: 20));
  await Future<void>.delayed(const Duration(milliseconds: 20));
}

void main() {
  test('requestOwnership shows pending immediately', () async {
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
    final sessionRepo = RecordingSessionRepository(session);
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
    addTearDown(container.dispose);

    await container.read(appModeProvider.notifier).setAccount();
    await _pumpQueue();

    final sub = container.listen<PomodoroState>(
      pomodoroViewModelProvider,
      (_, __) {},
    );
    final vm = container.read(pomodoroViewModelProvider.notifier);
    final result = await vm.loadGroup(group.id);
    expect(result, PomodoroGroupLoadResult.loaded);
    await _pumpQueue();
    expect(vm.activeSessionForCurrentGroup, isNotNull);
    expect(vm.isSessionMissingWhileRunning, isFalse);

    await vm.requestOwnership();
    await _pumpQueue();

    expect(vm.isOwnershipRequestPendingForThisDevice, isTrue);
    expect(vm.ownershipRequest?.requesterDeviceId, deviceInfo.deviceId);
    expect(sessionRepo.lastRequester, deviceInfo.deviceId);
    sub.close();
  });

  test('requestOwnership keeps pending after prior rejection', () async {
    final now = DateTime.now();
    final deviceInfo = DeviceInfoService.ephemeral();
    final group = _buildRunningGroup(id: 'group-2', start: now);
    final rejection = OwnershipRequest(
      requestId: 'old-request',
      requesterDeviceId: deviceInfo.deviceId,
      requestedAt: now.subtract(const Duration(minutes: 2)),
      status: OwnershipRequestStatus.rejected,
      respondedAt: now.subtract(const Duration(minutes: 1)),
      respondedByDeviceId: 'owner-device',
    );
    final session = PomodoroSession(
      taskId: group.tasks.first.sourceTaskId,
      groupId: group.id,
      currentTaskId: group.tasks.first.sourceTaskId,
      currentTaskIndex: 0,
      totalTasks: 1,
      dataVersion: kCurrentDataVersion,
      sessionRevision: 1,
      ownerDeviceId: 'other-device',
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
      lastUpdatedAt: now,
      finishedAt: null,
      pauseReason: null,
      ownershipRequest: rejection,
    );

    final groupRepo = FakeTaskRunGroupRepository()..seed(group);
    final sessionRepo = RecordingSessionRepository(session);
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
    addTearDown(container.dispose);

    await container.read(appModeProvider.notifier).setAccount();
    await _pumpQueue();

    final vm = container.read(pomodoroViewModelProvider.notifier);
    final result = await vm.loadGroup(group.id);
    expect(result, PomodoroGroupLoadResult.loaded);
    await _pumpQueue();
    expect(vm.activeSessionForCurrentGroup, isNotNull);
    expect(vm.isSessionMissingWhileRunning, isFalse);

    await vm.requestOwnership();
    await _pumpQueue();

    expect(vm.isOwnershipRequestPendingForThisDevice, isTrue);
    expect(vm.hasLocalPendingOwnershipRequest, isTrue);
    expect(sessionRepo.lastRequester, deviceInfo.deviceId);
  });
}
