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

class RecordingSessionRepository implements PomodoroSessionRepository {
  RecordingSessionRepository(this._session, {this.tryClaimResult = true});

  final PomodoroSession? _session;
  String? lastRequester;
  String? lastRequestId;
  int requestOwnershipCalls = 0;
  bool tryClaimResult;
  int tryClaimCalls = 0;
  PomodoroSession? lastTryClaimSession;
  int fetchSessionCalls = 0;
  int respondCalls = 0;
  String? lastRespondOwner;
  String? lastRespondRequester;
  bool? lastRespondApproved;
  Map<String, dynamic>? lastCursorSnapshot;
  int publishSessionCalls = 0;
  PomodoroSession? lastPublishedSession;

  @override
  Stream<PomodoroSession?> watchSession() => Stream.value(_session);

  @override
  Future<PomodoroSession?> fetchSession({bool preferServer = false}) async {
    fetchSessionCalls += 1;
    return _session;
  }

  @override
  Future<void> publishSession(PomodoroSession session) async {
    publishSessionCalls += 1;
    lastPublishedSession = session;
  }

  @override
  Future<bool> tryClaimSession(PomodoroSession session) async {
    tryClaimCalls += 1;
    lastTryClaimSession = session;
    return tryClaimResult;
  }

  @override
  Future<void> clearSessionAsOwner() async {}

  @override
  Future<void> clearSessionIfStale({required DateTime now}) async {}

  @override
  Future<void> clearSessionIfGroupNotRunning() async {}

  Future<void> clearSessionIfInactive({String? expectedGroupId}) async {}

  @override
  Future<void> requestOwnership({
    required String requesterDeviceId,
    required String requestId,
  }) async {
    requestOwnershipCalls += 1;
    lastRequester = requesterDeviceId;
    lastRequestId = requestId;
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
    Map<String, dynamic>? cursorSnapshot,
  }) async {
    respondCalls += 1;
    lastRespondOwner = ownerDeviceId;
    lastRespondRequester = requesterDeviceId;
    lastRespondApproved = approved;
    lastCursorSnapshot = cursorSnapshot;
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

  final Duration? _offsetOverride;

  @override
  Duration? get offset => _offsetOverride;

  @override
  Future<Duration?> refresh({bool force = false}) async => _offsetOverride;
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
  OwnershipRequest? ownershipRequest,
  PomodoroStatus status = PomodoroStatus.pomodoroRunning,
  PomodoroPhase phase = PomodoroPhase.pomodoro,
  int remainingSeconds = 1200,
  DateTime? pausedAt,
  String? pauseReason,
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
    status: status,
    phase: phase,
    currentPomodoro: 1,
    totalPomodoros: 2,
    phaseDurationSeconds: 25 * 60,
    remainingSeconds: remainingSeconds,
    accumulatedPausedSeconds: 0,
    phaseStartedAt: now.subtract(const Duration(minutes: 5)),
    currentTaskStartedAt: now.subtract(const Duration(minutes: 5)),
    pausedAt: pausedAt,
    lastUpdatedAt: now,
    finishedAt: null,
    pauseReason: pauseReason,
    ownershipRequest: ownershipRequest,
  );
}

Future<void> _pumpQueue() async {
  await Future<void>.delayed(const Duration(milliseconds: 20));
  await Future<void>.delayed(const Duration(milliseconds: 20));
}

void main() {
  test(
    'start blocks non-initiator when running group was started by another device',
    () async {
      final now = DateTime.now();
      final deviceInfo = DeviceInfoService.ephemeral();
      final group = _buildRunningGroup(
        id: 'group-start-non-initiator',
        start: now,
      ).copyWith(scheduledByDeviceId: 'initiator-device');

      final groupRepo = FakeTaskRunGroupRepository()..seed(group);
      final sessionRepo = RecordingSessionRepository(null);
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

      vm.start();
      await _pumpQueue();

      expect(sessionRepo.tryClaimCalls, 0);
      expect(
        container.read(pomodoroViewModelProvider).status,
        PomodoroStatus.idle,
      );
      sub.close();
    },
  );

  test(
    'start remains idle when claim fails (single-owner race protection)',
    () async {
      final now = DateTime.now();
      final deviceInfo = DeviceInfoService.ephemeral();
      final group = _buildRunningGroup(
        id: 'group-start-claim-fails',
        start: now,
      ).copyWith(scheduledByDeviceId: deviceInfo.deviceId);

      final groupRepo = FakeTaskRunGroupRepository()..seed(group);
      final sessionRepo = RecordingSessionRepository(
        null,
        tryClaimResult: false,
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

      vm.start();
      await _pumpQueue();

      expect(sessionRepo.tryClaimCalls, 1);
      expect(
        sessionRepo.lastTryClaimSession?.ownerDeviceId,
        deviceInfo.deviceId,
      );
      expect(
        container.read(pomodoroViewModelProvider).status,
        PomodoroStatus.idle,
      );
      sub.close();
    },
  );

  test(
    'startFromAutoStart syncs first and does not start when another device owns active session',
    () async {
      final now = DateTime.now();
      final deviceInfo = DeviceInfoService.ephemeral();
      final group = _buildRunningGroup(
        id: 'group-autostart-sync-check',
        start: now,
      ).copyWith(scheduledByDeviceId: deviceInfo.deviceId);
      final remoteSession = _buildRunningSession(
        groupId: group.id,
        taskId: group.tasks.first.sourceTaskId,
        ownerDeviceId: 'owner-other-device',
        now: now,
      );

      final groupRepo = FakeTaskRunGroupRepository()..seed(group);
      final sessionRepo = RecordingSessionRepository(remoteSession);
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

      final statusBefore = container.read(pomodoroViewModelProvider).status;
      final fetchCallsBefore = sessionRepo.fetchSessionCalls;

      await vm.startFromAutoStart();
      await _pumpQueue();

      expect(sessionRepo.fetchSessionCalls, greaterThan(fetchCallsBefore));
      expect(sessionRepo.tryClaimCalls, 0);
      expect(container.read(pomodoroViewModelProvider).status, statusBefore);
      sub.close();
    },
  );

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
  });

  test('requestOwnership includes requestId for optimistic reconciliation', () async {
    final now = DateTime.now();
    final deviceInfo = DeviceInfoService.ephemeral();
    final group = _buildRunningGroup(id: 'group-request-id', start: now);
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

    final vm = container.read(pomodoroViewModelProvider.notifier);
    final result = await vm.loadGroup(group.id);
    expect(result, PomodoroGroupLoadResult.loaded);
    await _pumpQueue();

    await vm.requestOwnership();
    await _pumpQueue();

    expect(sessionRepo.requestOwnershipCalls, 1);
    expect(sessionRepo.lastRequester, deviceInfo.deviceId);
    expect(sessionRepo.lastRequestId, isNotNull);
    expect(sessionRepo.lastRequestId, isNotEmpty);
    expect(vm.ownershipRequest?.requestId, sessionRepo.lastRequestId);
    expect(vm.isOwnershipRequestPendingForThisDevice, isTrue);
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

  test('requestOwnership triggers post-request resync fetch', () async {
    final now = DateTime.now();
    final deviceInfo = DeviceInfoService.ephemeral();
    final group = _buildRunningGroup(id: 'group-request-resync', start: now);
    final session = _buildRunningSession(
      groupId: group.id,
      taskId: group.tasks.first.sourceTaskId,
      ownerDeviceId: 'owner-device',
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
          FakeTimeSyncService(offset: Duration.zero),
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
    final fetchCallsBeforeRequest = sessionRepo.fetchSessionCalls;

    await vm.requestOwnership();
    await _pumpQueue();
    await _pumpQueue();

    expect(sessionRepo.requestOwnershipCalls, 1);
    expect(sessionRepo.lastRequester, deviceInfo.deviceId);
    expect(sessionRepo.fetchSessionCalls, greaterThan(fetchCallsBeforeRequest));
  });

  test('approveOwnershipRequest triggers post-request resync fetch', () async {
    final now = DateTime.now();
    final deviceInfo = DeviceInfoService.ephemeral();
    final group = _buildRunningGroup(id: 'group-approve-resync', start: now);
    final pendingRequest = OwnershipRequest(
      requestId: 'request-approve',
      requesterDeviceId: 'requester-device',
      requestedAt: now.subtract(const Duration(seconds: 15)),
      status: OwnershipRequestStatus.pending,
      respondedAt: null,
      respondedByDeviceId: null,
    );
    final session = _buildRunningSession(
      groupId: group.id,
      taskId: group.tasks.first.sourceTaskId,
      ownerDeviceId: deviceInfo.deviceId,
      now: now,
      ownershipRequest: pendingRequest,
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
          FakeTimeSyncService(offset: Duration.zero),
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
    final fetchCallsBeforeApprove = sessionRepo.fetchSessionCalls;

    await vm.approveOwnershipRequest();
    await _pumpQueue();
    await _pumpQueue();

    expect(sessionRepo.respondCalls, 1);
    expect(sessionRepo.lastRespondOwner, deviceInfo.deviceId);
    expect(sessionRepo.lastRespondRequester, 'requester-device');
    expect(sessionRepo.lastRespondApproved, isTrue);
    expect(sessionRepo.fetchSessionCalls, greaterThan(fetchCallsBeforeApprove));
  });

  test('rejectOwnershipRequest triggers post-request resync fetch', () async {
    final now = DateTime.now();
    final deviceInfo = DeviceInfoService.ephemeral();
    final group = _buildRunningGroup(id: 'group-reject-resync', start: now);
    final pendingRequest = OwnershipRequest(
      requestId: 'request-reject',
      requesterDeviceId: 'requester-device',
      requestedAt: now.subtract(const Duration(seconds: 15)),
      status: OwnershipRequestStatus.pending,
      respondedAt: null,
      respondedByDeviceId: null,
    );
    final session = _buildRunningSession(
      groupId: group.id,
      taskId: group.tasks.first.sourceTaskId,
      ownerDeviceId: deviceInfo.deviceId,
      now: now,
      ownershipRequest: pendingRequest,
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
          FakeTimeSyncService(offset: Duration.zero),
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
    final fetchCallsBeforeReject = sessionRepo.fetchSessionCalls;

    await vm.rejectOwnershipRequest();
    await _pumpQueue();
    await _pumpQueue();

    expect(sessionRepo.respondCalls, 1);
    expect(sessionRepo.lastRespondOwner, deviceInfo.deviceId);
    expect(sessionRepo.lastRespondRequester, 'requester-device');
    expect(sessionRepo.lastRespondApproved, isFalse);
    expect(sessionRepo.fetchSessionCalls, greaterThan(fetchCallsBeforeReject));
  });

  test(
    'paused owner publishes periodic heartbeat snapshots',
    () async {
      final now = DateTime.now();
      final deviceInfo = DeviceInfoService.ephemeral();
      final group = _buildRunningGroup(
        id: 'group-paused-heartbeat',
        start: now,
      ).copyWith(scheduledByDeviceId: deviceInfo.deviceId);
      final pausedOwnerSession = _buildRunningSession(
        groupId: group.id,
        taskId: group.tasks.first.sourceTaskId,
        ownerDeviceId: deviceInfo.deviceId,
        now: now,
        status: PomodoroStatus.paused,
        pausedAt: now.subtract(const Duration(minutes: 1)),
        pauseReason: 'manual_owner_action',
      );

      final groupRepo = FakeTaskRunGroupRepository()..seed(group);
      final sessionRepo = RecordingSessionRepository(
        pausedOwnerSession,
        tryClaimResult: true,
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

      final publishesAfterHydration = sessionRepo.publishSessionCalls;
      expect(
        sessionRepo.lastPublishedSession?.status,
        PomodoroStatus.paused,
        reason:
            'Hydration must keep a paused owner snapshot authoritative before periodic heartbeats.',
      );

      await Future<void>.delayed(const Duration(seconds: 32));
      await _pumpQueue();

      expect(
        sessionRepo.publishSessionCalls,
        greaterThan(publishesAfterHydration),
        reason:
            'Paused heartbeat must publish at least one additional snapshot after 30s.',
      );
      expect(sessionRepo.lastPublishedSession?.status, PomodoroStatus.paused);
      sub.close();
    },
    timeout: const Timeout(Duration(seconds: 90)),
  );
}
