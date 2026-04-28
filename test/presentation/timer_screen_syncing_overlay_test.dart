import 'dart:async';

import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:focus_interval/data/models/pomodoro_session.dart';
import 'package:focus_interval/data/models/schema_version.dart';
import 'package:focus_interval/data/models/selected_sound.dart';
import 'package:focus_interval/data/models/task_run_group.dart';
import 'package:focus_interval/data/repositories/pomodoro_session_repository.dart';
import 'package:focus_interval/data/repositories/task_run_group_repository.dart';
import 'package:focus_interval/data/services/app_mode_service.dart';
import 'package:focus_interval/data/services/device_info_service.dart';
import 'package:focus_interval/data/services/sound_service.dart';
import 'package:focus_interval/data/services/task_run_notice_service.dart';
import 'package:focus_interval/data/services/time_sync_service.dart';
import 'package:focus_interval/data/services/firebase_auth_service.dart';
import 'package:focus_interval/data/services/firestore_service.dart';
import 'package:focus_interval/domain/pomodoro_machine.dart';
import 'package:focus_interval/presentation/providers.dart';
import 'package:focus_interval/presentation/screens/timer_screen.dart';
import 'package:focus_interval/presentation/viewmodels/pomodoro_view_model.dart';
import 'package:focus_interval/widgets/timer_display.dart';
import 'package:focus_interval/widgets/active_session_auto_opener.dart';

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
  FakePomodoroSessionRepository(this._initialSession);

  final StreamController<PomodoroSession?> _controller =
      StreamController<PomodoroSession?>.broadcast();
  PomodoroSession? _lastSession;
  PomodoroSession? _initialSession;
  bool _initialSnapshotEmitted = false;
  int requestOwnershipCalls = 0;
  String? lastRequesterDeviceId;
  String? lastRequestId;

  @override
  Stream<PomodoroSession?> watchSession() async* {
    if (!_initialSnapshotEmitted) {
      _initialSnapshotEmitted = true;
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

  @override
  Future<PomodoroSession?> fetchSession({bool preferServer = false}) async {
    if (_lastSession != null) return _lastSession;
    if (!_initialSnapshotEmitted) return _initialSession;
    return null;
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

  Future<void> clearSessionIfInactive({String? expectedGroupId}) async {}

  @override
  Future<void> requestOwnership({
    required String requesterDeviceId,
    required String requestId,
  }) async {
    requestOwnershipCalls += 1;
    lastRequesterDeviceId = requesterDeviceId;
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

  final Duration? _offsetOverride;

  @override
  Duration? get offset => _offsetOverride;

  @override
  Future<Duration?> refresh({bool force = false}) async => _offsetOverride;
}

class FakeTaskRunNoticeService extends TaskRunNoticeService {
  FakeTaskRunNoticeService({this.minutes = 0}) : super(useAccount: false);

  int minutes;

  @override
  Future<int> getNoticeMinutes() async => minutes;

  @override
  Future<int> setNoticeMinutes(int value) async {
    minutes = value;
    return minutes;
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
    totalPomodoros: 1,
    longBreakInterval: 2,
    startSound: SelectedSound.builtIn('default_chime'),
    startBreakSound: SelectedSound.builtIn('default_chime_break'),
    finishTaskSound: SelectedSound.builtIn('default_chime_finish'),
  );
}

TaskRunGroup _buildScheduledGroup({
  required String id,
  required DateTime scheduledStart,
}) {
  final item = _buildItem();
  final totalSeconds = item.pomodoroMinutes * 60;
  return TaskRunGroup(
    id: id,
    ownerUid: 'user-1',
    dataVersion: kCurrentDataVersion,
    integrityMode: TaskRunIntegrityMode.shared,
    tasks: [item],
    createdAt: scheduledStart.subtract(const Duration(minutes: 1)),
    scheduledStartTime: scheduledStart,
    actualStartTime: null,
    theoreticalEndTime: scheduledStart.add(Duration(seconds: totalSeconds)),
    status: TaskRunStatus.scheduled,
    noticeMinutes: 0,
    totalTasks: 1,
    totalPomodoros: item.totalPomodoros,
    totalDurationSeconds: totalSeconds,
    updatedAt: scheduledStart.subtract(const Duration(minutes: 1)),
  );
}

TaskRunGroup _buildRunningGroup({required String id, required DateTime start}) {
  final item = _buildItem();
  final totalSeconds = item.pomodoroMinutes * 60;
  return TaskRunGroup(
    id: id,
    ownerUid: 'user-1',
    dataVersion: kCurrentDataVersion,
    integrityMode: TaskRunIntegrityMode.shared,
    tasks: [item],
    createdAt: start,
    scheduledStartTime: null,
    actualStartTime: start,
    theoreticalEndTime: start.add(Duration(seconds: totalSeconds)),
    status: TaskRunStatus.running,
    noticeMinutes: 0,
    totalTasks: 1,
    totalPomodoros: item.totalPomodoros,
    totalDurationSeconds: totalSeconds,
    updatedAt: start,
  );
}

PomodoroSession _buildRunningSession({
  required String groupId,
  required String taskId,
  required DateTime now,
  String ownerDeviceId = 'owner-device',
  OwnershipRequest? ownershipRequest,
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
    totalPomodoros: 1,
    phaseDurationSeconds: 25 * 60,
    remainingSeconds: 1200,
    accumulatedPausedSeconds: 0,
    phaseStartedAt: now.subtract(const Duration(minutes: 5)),
    currentTaskStartedAt: now.subtract(const Duration(minutes: 5)),
    pausedAt: null,
    lastUpdatedAt: now,
    finishedAt: null,
    pauseReason: null,
    ownershipRequest: ownershipRequest,
  );
}

void main() {
  testWidgets(
    'ownership indicator stays visible with syncing variant and controls gate when session snapshot is missing',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final now = DateTime.now();
      final deviceInfo = DeviceInfoService.ephemeral();
      final group = _buildRunningGroup(
        id: 'group-ownership-syncing-indicator',
        start: now,
      );
      final session = _buildRunningSession(
        groupId: group.id,
        taskId: group.tasks.first.sourceTaskId,
        now: now,
        ownerDeviceId: deviceInfo.deviceId,
      );

      final groupRepo = FakeTaskRunGroupRepository()..seed(group);
      final sessionRepo = FakePomodoroSessionRepository(session);
      final appModeService = AppModeService.memory();
      final timeSyncService = FakeTimeSyncService(offset: Duration.zero);
      final noticeService = FakeTaskRunNoticeService();
      var disposed = false;

      final container = ProviderContainer(
        overrides: [
          firebaseAuthServiceProvider.overrideWithValue(StubAuthService()),
          firestoreServiceProvider.overrideWithValue(StubFirestoreService()),
          taskRunGroupRepositoryProvider.overrideWithValue(groupRepo),
          pomodoroSessionRepositoryProvider.overrideWithValue(sessionRepo),
          appModeServiceProvider.overrideWithValue(appModeService),
          deviceInfoServiceProvider.overrideWithValue(deviceInfo),
          soundServiceProvider.overrideWithValue(FakeSoundService()),
          timeSyncServiceProvider.overrideWithValue(timeSyncService),
          taskRunNoticeServiceProvider.overrideWithValue(noticeService),
        ],
      );
      try {
        await container.read(appModeProvider.notifier).setAccount();

        final router = GoRouter(
          initialLocation: '/timer/${group.id}',
          routes: [
            GoRoute(
              path: '/timer/:id',
              builder: (context, state) {
                final id = state.pathParameters['id']!;
                return TimerScreen(groupId: id);
              },
            ),
            GoRoute(
              path: '/groups',
              builder: (_, __) => const Scaffold(body: SizedBox.shrink()),
            ),
            GoRoute(
              path: '/tasks',
              builder: (_, __) => const Scaffold(body: SizedBox.shrink()),
            ),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        final ownerIndicator = find.byTooltip('Owner device');
        for (var i = 0; i < 20 && ownerIndicator.evaluate().isEmpty; i += 1) {
          await tester.pump(const Duration(milliseconds: 100));
        }

        final vm = container.read(pomodoroViewModelProvider.notifier);
        expect(ownerIndicator, findsOneWidget);
        expect(vm.canControlSession, isTrue);

        sessionRepo.emit(null);
        await tester.pump();
        await tester.pump(const Duration(seconds: 4));
        await tester.pump(const Duration(milliseconds: 120));

        expect(find.byTooltip('Syncing session'), findsOneWidget);
        expect(find.text('Retry sync'), findsNothing);
        expect(find.text('Sync now'), findsNothing);
        expect(vm.canControlSession, isFalse);

        await tester.tap(find.byTooltip('Syncing session'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('Session ownership'), findsOneWidget);
        expect(find.text('Syncing session ownership...'), findsOneWidget);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 100));
        sessionRepo.dispose();
        container.dispose();
        disposed = true;
      } finally {
        if (!disposed) {
          sessionRepo.dispose();
          container.dispose();
        }
      }
    },
  );

  testWidgets(
    'ownership indicator shows neutral state when no session exists',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final now = DateTime.now();
      final group = _buildScheduledGroup(
        id: 'group-ownership-no-session',
        scheduledStart: now.add(const Duration(minutes: 5)),
      );

      final groupRepo = FakeTaskRunGroupRepository()..seed(group);
      final sessionRepo = FakePomodoroSessionRepository(null);
      final appModeService = AppModeService.memory();
      final timeSyncService = FakeTimeSyncService(offset: Duration.zero);
      final noticeService = FakeTaskRunNoticeService();

      final container = ProviderContainer(
        overrides: [
          firebaseAuthServiceProvider.overrideWithValue(StubAuthService()),
          firestoreServiceProvider.overrideWithValue(StubFirestoreService()),
          taskRunGroupRepositoryProvider.overrideWithValue(groupRepo),
          pomodoroSessionRepositoryProvider.overrideWithValue(sessionRepo),
          appModeServiceProvider.overrideWithValue(appModeService),
          deviceInfoServiceProvider.overrideWithValue(
            DeviceInfoService.ephemeral(),
          ),
          soundServiceProvider.overrideWithValue(FakeSoundService()),
          timeSyncServiceProvider.overrideWithValue(timeSyncService),
          taskRunNoticeServiceProvider.overrideWithValue(noticeService),
        ],
      );
      addTearDown(() {
        sessionRepo.dispose();
        container.dispose();
      });

      await container.read(appModeProvider.notifier).setAccount();
      final vm = container.read(pomodoroViewModelProvider.notifier);
      final loadResult = await vm.loadGroup(group.id);
      expect(loadResult, PomodoroGroupLoadResult.loaded);

      final router = GoRouter(
        initialLocation: '/timer/${group.id}',
        routes: [
          GoRoute(
            path: '/timer/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return TimerScreen(groupId: id);
            },
          ),
          GoRoute(
            path: '/groups',
            builder: (_, __) => const Scaffold(body: SizedBox.shrink()),
          ),
          GoRoute(
            path: '/tasks',
            builder: (_, __) => const Scaffold(body: SizedBox.shrink()),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump(const Duration(milliseconds: 120));

      final neutralIndicator = find.byTooltip('No active session yet');
      for (var i = 0; i < 20 && neutralIndicator.evaluate().isEmpty; i += 1) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(neutralIndicator, findsOneWidget);
      expect(find.byTooltip('Syncing session'), findsNothing);

      await tester.tap(neutralIndicator);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Session ownership'), findsOneWidget);
      expect(find.text('No active session yet.'), findsOneWidget);
    },
  );

  testWidgets('sync-gap neutralizes stale mirror ownership derivation', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final now = DateTime.now();
    final deviceInfo = DeviceInfoService.ephemeral();
    final group = _buildRunningGroup(
      id: 'group-ownership-mirror-sync-gap',
      start: now,
    );
    final session = _buildRunningSession(
      groupId: group.id,
      taskId: group.tasks.first.sourceTaskId,
      now: now,
      ownerDeviceId: 'remote-owner-device',
    );

    final groupRepo = FakeTaskRunGroupRepository()..seed(group);
    final sessionRepo = FakePomodoroSessionRepository(session);
    final appModeService = AppModeService.memory();
    final timeSyncService = FakeTimeSyncService(offset: Duration.zero);
    final noticeService = FakeTaskRunNoticeService();
    var disposed = false;

    final container = ProviderContainer(
      overrides: [
        firebaseAuthServiceProvider.overrideWithValue(StubAuthService()),
        firestoreServiceProvider.overrideWithValue(StubFirestoreService()),
        taskRunGroupRepositoryProvider.overrideWithValue(groupRepo),
        pomodoroSessionRepositoryProvider.overrideWithValue(sessionRepo),
        appModeServiceProvider.overrideWithValue(appModeService),
        deviceInfoServiceProvider.overrideWithValue(deviceInfo),
        soundServiceProvider.overrideWithValue(FakeSoundService()),
        timeSyncServiceProvider.overrideWithValue(timeSyncService),
        taskRunNoticeServiceProvider.overrideWithValue(noticeService),
      ],
    );
    try {
      await container.read(appModeProvider.notifier).setAccount();

      final router = GoRouter(
        initialLocation: '/timer/${group.id}',
        routes: [
          GoRoute(
            path: '/timer/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return TimerScreen(groupId: id);
            },
          ),
          GoRoute(
            path: '/groups',
            builder: (_, __) => const Scaffold(body: SizedBox.shrink()),
          ),
          GoRoute(
            path: '/tasks',
            builder: (_, __) => const Scaffold(body: SizedBox.shrink()),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      final mirrorIndicator = find.byTooltip('Mirror device');
      for (var i = 0; i < 20 && mirrorIndicator.evaluate().isEmpty; i += 1) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      final vm = container.read(pomodoroViewModelProvider.notifier);
      expect(mirrorIndicator, findsOneWidget);
      expect(vm.isMirrorMode, isTrue);
      expect(vm.canRequestOwnership, isTrue);

      sessionRepo.emit(null);
      await tester.pump();
      await tester.pump(const Duration(seconds: 4));
      await tester.pump(const Duration(milliseconds: 120));

      expect(find.byTooltip('Syncing session'), findsOneWidget);
      expect(find.byTooltip('Mirror device'), findsNothing);
      expect(find.byTooltip('Owner device'), findsNothing);
      expect(vm.isSessionMissingWhileRunning, isTrue);
      expect(vm.isMirrorMode, isFalse);
      expect(vm.currentOwnerDeviceId, isNull);
      expect(vm.canRequestOwnership, isFalse);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
      sessionRepo.dispose();
      container.dispose();
      disposed = true;
    } finally {
      if (!disposed) {
        sessionRepo.dispose();
        container.dispose();
      }
    }
  });

  testWidgets(
    'requester pending indicator overrides syncing and no-session visuals during sync-gap',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final now = DateTime.now();
      final deviceInfo = DeviceInfoService.ephemeral();
      final group = _buildRunningGroup(
        id: 'group-requester-pending-priority',
        start: now,
      );
      final session = _buildRunningSession(
        groupId: group.id,
        taskId: group.tasks.first.sourceTaskId,
        now: now,
        ownerDeviceId: 'remote-owner-device',
      );

      final groupRepo = FakeTaskRunGroupRepository()..seed(group);
      final sessionRepo = FakePomodoroSessionRepository(session);
      final appModeService = AppModeService.memory();
      final timeSyncService = FakeTimeSyncService(offset: Duration.zero);
      final noticeService = FakeTaskRunNoticeService();
      var disposed = false;

      final container = ProviderContainer(
        overrides: [
          firebaseAuthServiceProvider.overrideWithValue(StubAuthService()),
          firestoreServiceProvider.overrideWithValue(StubFirestoreService()),
          taskRunGroupRepositoryProvider.overrideWithValue(groupRepo),
          pomodoroSessionRepositoryProvider.overrideWithValue(sessionRepo),
          appModeServiceProvider.overrideWithValue(appModeService),
          deviceInfoServiceProvider.overrideWithValue(deviceInfo),
          soundServiceProvider.overrideWithValue(FakeSoundService()),
          timeSyncServiceProvider.overrideWithValue(timeSyncService),
          taskRunNoticeServiceProvider.overrideWithValue(noticeService),
        ],
      );
      try {
        await container.read(appModeProvider.notifier).setAccount();

        final router = GoRouter(
          initialLocation: '/timer/${group.id}',
          routes: [
            GoRoute(
              path: '/timer/:id',
              builder: (context, state) {
                final id = state.pathParameters['id']!;
                return TimerScreen(groupId: id);
              },
            ),
            GoRoute(
              path: '/groups',
              builder: (_, __) => const Scaffold(body: SizedBox.shrink()),
            ),
            GoRoute(
              path: '/tasks',
              builder: (_, __) => const Scaffold(body: SizedBox.shrink()),
            ),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(routerConfig: router),
          ),
        );

        final mirrorIndicator = find.byTooltip('Mirror device');
        for (var i = 0; i < 20 && mirrorIndicator.evaluate().isEmpty; i += 1) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(mirrorIndicator, findsOneWidget);

        final vm = container.read(pomodoroViewModelProvider.notifier);
        await vm.requestOwnership();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 120));

        expect(find.byTooltip('Ownership request pending'), findsOneWidget);

        sessionRepo.emit(null);
        await tester.pump();
        await tester.pump(const Duration(seconds: 4));
        await tester.pump(const Duration(milliseconds: 120));

        expect(vm.isSessionMissingWhileRunning, isTrue);
        expect(vm.isOwnershipRequestPendingForThisDevice, isTrue);
        expect(vm.hasLocalPendingOwnershipRequest, isTrue);
        expect(find.byTooltip('Ownership request pending'), findsOneWidget);
        expect(find.byTooltip('Syncing session'), findsNothing);
        expect(find.byTooltip('No active session yet'), findsNothing);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 100));
        sessionRepo.dispose();
        container.dispose();
        disposed = true;
      } finally {
        if (!disposed) {
          sessionRepo.dispose();
          container.dispose();
        }
      }
    },
  );

  testWidgets(
    'optimistic pending survives owner-state reset before mirror snapshot',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final now = DateTime.now();
      final deviceInfo = DeviceInfoService.ephemeral();
      final group = _buildRunningGroup(
        id: 'group-optimistic-owner-mirror-reset',
        start: now,
      );
      final session = _buildRunningSession(
        groupId: group.id,
        taskId: group.tasks.first.sourceTaskId,
        now: now,
        ownerDeviceId: 'remote-owner-device',
      );

      final groupRepo = FakeTaskRunGroupRepository()..seed(group);
      final sessionRepo = FakePomodoroSessionRepository(session);
      final appModeService = AppModeService.memory();
      final timeSyncService = FakeTimeSyncService(offset: Duration.zero);
      final noticeService = FakeTaskRunNoticeService();
      var disposed = false;

      final container = ProviderContainer(
        overrides: [
          firebaseAuthServiceProvider.overrideWithValue(StubAuthService()),
          firestoreServiceProvider.overrideWithValue(StubFirestoreService()),
          taskRunGroupRepositoryProvider.overrideWithValue(groupRepo),
          pomodoroSessionRepositoryProvider.overrideWithValue(sessionRepo),
          appModeServiceProvider.overrideWithValue(appModeService),
          deviceInfoServiceProvider.overrideWithValue(deviceInfo),
          soundServiceProvider.overrideWithValue(FakeSoundService()),
          timeSyncServiceProvider.overrideWithValue(timeSyncService),
          taskRunNoticeServiceProvider.overrideWithValue(noticeService),
        ],
      );
      try {
        await container.read(appModeProvider.notifier).setAccount();

        final router = GoRouter(
          initialLocation: '/timer/${group.id}',
          routes: [
            GoRoute(
              path: '/timer/:id',
              builder: (context, state) {
                final id = state.pathParameters['id']!;
                return TimerScreen(groupId: id);
              },
            ),
            GoRoute(
              path: '/groups',
              builder: (_, __) => const Scaffold(body: SizedBox.shrink()),
            ),
            GoRoute(
              path: '/tasks',
              builder: (_, __) => const Scaffold(body: SizedBox.shrink()),
            ),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(routerConfig: router),
          ),
        );

        final mirrorIndicator = find.byTooltip('Mirror device');
        for (var i = 0; i < 20 && mirrorIndicator.evaluate().isEmpty; i += 1) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(mirrorIndicator, findsOneWidget);

        final vm = container.read(pomodoroViewModelProvider.notifier);
        await vm.requestOwnership();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 120));

        expect(find.byTooltip('Ownership request pending'), findsOneWidget);
        expect(vm.hasLocalPendingOwnershipRequest, isTrue);

        sessionRepo.emit(null);
        await tester.pump();
        await tester.pump(const Duration(seconds: 4));
        await tester.pump(const Duration(milliseconds: 120));

        expect(vm.isSessionMissingWhileRunning, isTrue);
        expect(vm.isMirrorMode, isFalse);
        expect(find.byTooltip('Ownership request pending'), findsOneWidget);
        expect(find.byTooltip('Syncing session'), findsNothing);

        final mirrorSessionAfterReset = _buildRunningSession(
          groupId: group.id,
          taskId: group.tasks.first.sourceTaskId,
          now: now.add(const Duration(seconds: 4)),
          ownerDeviceId: 'remote-owner-device',
        );
        sessionRepo.emit(mirrorSessionAfterReset);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 120));

        expect(vm.isMirrorMode, isTrue);
        expect(vm.hasLocalPendingOwnershipRequest, isTrue);
        expect(vm.isOwnershipRequestPendingForThisDevice, isTrue);
        expect(find.byTooltip('Ownership request pending'), findsOneWidget);
        expect(find.byTooltip('Mirror device'), findsNothing);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 100));
        sessionRepo.dispose();
        container.dispose();
        disposed = true;
      } finally {
        if (!disposed) {
          sessionRepo.dispose();
          container.dispose();
        }
      }
    },
  );

  testWidgets(
    'optimistic pending overrides stale rejected snapshot from stream',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final now = DateTime.now();
      final deviceInfo = DeviceInfoService.ephemeral();
      final group = _buildRunningGroup(
        id: 'group-optimistic-stale-rejected-override',
        start: now,
      );
      final staleRejected = OwnershipRequest(
        requestId: 'old-request',
        requesterDeviceId: deviceInfo.deviceId,
        requestedAt: now.subtract(const Duration(minutes: 2)),
        status: OwnershipRequestStatus.rejected,
        respondedAt: now.subtract(const Duration(minutes: 1)),
        respondedByDeviceId: 'remote-owner-device',
      );
      final session = _buildRunningSession(
        groupId: group.id,
        taskId: group.tasks.first.sourceTaskId,
        now: now,
        ownerDeviceId: 'remote-owner-device',
        ownershipRequest: staleRejected,
      );

      final groupRepo = FakeTaskRunGroupRepository()..seed(group);
      final sessionRepo = FakePomodoroSessionRepository(session);
      final appModeService = AppModeService.memory();
      final timeSyncService = FakeTimeSyncService(offset: Duration.zero);
      final noticeService = FakeTaskRunNoticeService();
      var disposed = false;

      final container = ProviderContainer(
        overrides: [
          firebaseAuthServiceProvider.overrideWithValue(StubAuthService()),
          firestoreServiceProvider.overrideWithValue(StubFirestoreService()),
          taskRunGroupRepositoryProvider.overrideWithValue(groupRepo),
          pomodoroSessionRepositoryProvider.overrideWithValue(sessionRepo),
          appModeServiceProvider.overrideWithValue(appModeService),
          deviceInfoServiceProvider.overrideWithValue(deviceInfo),
          soundServiceProvider.overrideWithValue(FakeSoundService()),
          timeSyncServiceProvider.overrideWithValue(timeSyncService),
          taskRunNoticeServiceProvider.overrideWithValue(noticeService),
        ],
      );
      try {
        await container.read(appModeProvider.notifier).setAccount();

        final router = GoRouter(
          initialLocation: '/timer/${group.id}',
          routes: [
            GoRoute(
              path: '/timer/:id',
              builder: (context, state) {
                final id = state.pathParameters['id']!;
                return TimerScreen(groupId: id);
              },
            ),
            GoRoute(
              path: '/groups',
              builder: (_, __) => const Scaffold(body: SizedBox.shrink()),
            ),
            GoRoute(
              path: '/tasks',
              builder: (_, __) => const Scaffold(body: SizedBox.shrink()),
            ),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(routerConfig: router),
          ),
        );

        final mirrorIndicator = find.byTooltip('Mirror device');
        for (var i = 0; i < 20 && mirrorIndicator.evaluate().isEmpty; i += 1) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(mirrorIndicator, findsOneWidget);

        final vm = container.read(pomodoroViewModelProvider.notifier);
        expect(vm.isOwnershipRequestRejectedForThisDevice, isTrue);

        await vm.requestOwnership();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 120));

        expect(vm.isOwnershipRequestPendingForThisDevice, isTrue);
        expect(vm.hasLocalPendingOwnershipRequest, isTrue);
        expect(vm.isOwnershipRequestRejectedForThisDevice, isFalse);
        expect(find.byTooltip('Ownership request pending'), findsOneWidget);

        final staleRejectedReplay = _buildRunningSession(
          groupId: group.id,
          taskId: group.tasks.first.sourceTaskId,
          now: now.add(const Duration(seconds: 2)),
          ownerDeviceId: 'remote-owner-device',
          ownershipRequest: staleRejected,
        );
        sessionRepo.emit(staleRejectedReplay);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 120));

        expect(vm.isOwnershipRequestPendingForThisDevice, isTrue);
        expect(vm.hasLocalPendingOwnershipRequest, isTrue);
        expect(vm.isOwnershipRequestRejectedForThisDevice, isFalse);
        expect(find.byTooltip('Ownership request pending'), findsOneWidget);
        expect(find.byTooltip('Mirror device'), findsNothing);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 100));
        sessionRepo.dispose();
        container.dispose();
        disposed = true;
      } finally {
        if (!disposed) {
          sessionRepo.dispose();
          container.dispose();
        }
      }
    },
  );

  testWidgets(
    'optimistic pending is not cleared by stale rejected snapshot from another device',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final now = DateTime.now();
      final deviceInfo = DeviceInfoService.ephemeral();
      final group = _buildRunningGroup(
        id: 'group-optimistic-stale-rejected-other-device',
        start: now,
      );
      final session = _buildRunningSession(
        groupId: group.id,
        taskId: group.tasks.first.sourceTaskId,
        now: now,
        ownerDeviceId: 'remote-owner-device',
      );

      final staleRejectedFromOther = OwnershipRequest(
        requestId: 'other-device-old-request',
        requesterDeviceId: 'third-device',
        requestedAt: now.subtract(const Duration(minutes: 3)),
        status: OwnershipRequestStatus.rejected,
        respondedAt: now.subtract(const Duration(minutes: 2)),
        respondedByDeviceId: 'remote-owner-device',
      );

      final groupRepo = FakeTaskRunGroupRepository()..seed(group);
      final sessionRepo = FakePomodoroSessionRepository(session);
      final appModeService = AppModeService.memory();
      final timeSyncService = FakeTimeSyncService(offset: Duration.zero);
      final noticeService = FakeTaskRunNoticeService();
      var disposed = false;

      final container = ProviderContainer(
        overrides: [
          firebaseAuthServiceProvider.overrideWithValue(StubAuthService()),
          firestoreServiceProvider.overrideWithValue(StubFirestoreService()),
          taskRunGroupRepositoryProvider.overrideWithValue(groupRepo),
          pomodoroSessionRepositoryProvider.overrideWithValue(sessionRepo),
          appModeServiceProvider.overrideWithValue(appModeService),
          deviceInfoServiceProvider.overrideWithValue(deviceInfo),
          soundServiceProvider.overrideWithValue(FakeSoundService()),
          timeSyncServiceProvider.overrideWithValue(timeSyncService),
          taskRunNoticeServiceProvider.overrideWithValue(noticeService),
        ],
      );
      try {
        await container.read(appModeProvider.notifier).setAccount();

        final router = GoRouter(
          initialLocation: '/timer/${group.id}',
          routes: [
            GoRoute(
              path: '/timer/:id',
              builder: (context, state) {
                final id = state.pathParameters['id']!;
                return TimerScreen(groupId: id);
              },
            ),
            GoRoute(
              path: '/groups',
              builder: (_, __) => const Scaffold(body: SizedBox.shrink()),
            ),
            GoRoute(
              path: '/tasks',
              builder: (_, __) => const Scaffold(body: SizedBox.shrink()),
            ),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(routerConfig: router),
          ),
        );

        final mirrorIndicator = find.byTooltip('Mirror device');
        for (var i = 0; i < 20 && mirrorIndicator.evaluate().isEmpty; i += 1) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(mirrorIndicator, findsOneWidget);

        final vm = container.read(pomodoroViewModelProvider.notifier);
        await vm.requestOwnership();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 120));

        expect(vm.isOwnershipRequestPendingForThisDevice, isTrue);
        expect(vm.hasLocalPendingOwnershipRequest, isTrue);
        expect(vm.isOwnershipRequestRejectedForThisDevice, isFalse);
        expect(find.byTooltip('Ownership request pending'), findsOneWidget);

        final staleRejectedReplay = _buildRunningSession(
          groupId: group.id,
          taskId: group.tasks.first.sourceTaskId,
          now: now.add(const Duration(seconds: 2)),
          ownerDeviceId: 'remote-owner-device',
          ownershipRequest: staleRejectedFromOther,
        );
        sessionRepo.emit(staleRejectedReplay);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 120));

        expect(vm.isOwnershipRequestPendingForThisDevice, isTrue);
        expect(vm.hasLocalPendingOwnershipRequest, isTrue);
        expect(vm.isOwnershipRequestRejectedForThisDevice, isFalse);
        expect(vm.ownershipRequest?.requesterDeviceId, deviceInfo.deviceId);
        expect(find.byTooltip('Ownership request pending'), findsOneWidget);
        expect(find.byTooltip('Mirror device'), findsNothing);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 100));
        sessionRepo.dispose();
        container.dispose();
        disposed = true;
      } finally {
        if (!disposed) {
          sessionRepo.dispose();
          container.dispose();
        }
      }
    },
  );

  testWidgets(
    'local pending gating disables duplicate ownership taps while snapshot lags',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final now = DateTime.now();
      final deviceInfo = DeviceInfoService.ephemeral();
      final group = _buildRunningGroup(
        id: 'group-local-pending-gating-no-duplicate',
        start: now,
      );
      final session = _buildRunningSession(
        groupId: group.id,
        taskId: group.tasks.first.sourceTaskId,
        now: now,
        ownerDeviceId: 'remote-owner-device',
      );

      final groupRepo = FakeTaskRunGroupRepository()..seed(group);
      final sessionRepo = FakePomodoroSessionRepository(session);
      final appModeService = AppModeService.memory();
      final timeSyncService = FakeTimeSyncService(offset: Duration.zero);
      final noticeService = FakeTaskRunNoticeService();
      var disposed = false;

      final container = ProviderContainer(
        overrides: [
          firebaseAuthServiceProvider.overrideWithValue(StubAuthService()),
          firestoreServiceProvider.overrideWithValue(StubFirestoreService()),
          taskRunGroupRepositoryProvider.overrideWithValue(groupRepo),
          pomodoroSessionRepositoryProvider.overrideWithValue(sessionRepo),
          appModeServiceProvider.overrideWithValue(appModeService),
          deviceInfoServiceProvider.overrideWithValue(deviceInfo),
          soundServiceProvider.overrideWithValue(FakeSoundService()),
          timeSyncServiceProvider.overrideWithValue(timeSyncService),
          taskRunNoticeServiceProvider.overrideWithValue(noticeService),
        ],
      );
      try {
        await container.read(appModeProvider.notifier).setAccount();

        final router = GoRouter(
          initialLocation: '/timer/${group.id}',
          routes: [
            GoRoute(
              path: '/timer/:id',
              builder: (context, state) {
                final id = state.pathParameters['id']!;
                return TimerScreen(groupId: id);
              },
            ),
            GoRoute(
              path: '/groups',
              builder: (_, __) => const Scaffold(body: SizedBox.shrink()),
            ),
            GoRoute(
              path: '/tasks',
              builder: (_, __) => const Scaffold(body: SizedBox.shrink()),
            ),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(routerConfig: router),
          ),
        );

        final mirrorIndicator = find.byTooltip('Mirror device');
        for (var i = 0; i < 20 && mirrorIndicator.evaluate().isEmpty; i += 1) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(mirrorIndicator, findsOneWidget);

        final vm = container.read(pomodoroViewModelProvider.notifier);
        expect(vm.canRequestOwnership, isTrue);

        await tester.tap(mirrorIndicator);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        final firstRequestButton = find.widgetWithText(
          ElevatedButton,
          'Request ownership',
        );
        expect(firstRequestButton, findsOneWidget);
        expect(
          tester.widget<ElevatedButton>(firstRequestButton).onPressed,
          isNotNull,
        );

        await tester.tap(firstRequestButton);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 120));

        expect(sessionRepo.requestOwnershipCalls, 1);
        expect(sessionRepo.lastRequesterDeviceId, deviceInfo.deviceId);
        expect(sessionRepo.lastRequestId, isNotNull);
        expect(vm.isOwnershipRequestPendingForThisDevice, isTrue);
        expect(vm.hasLocalPendingOwnershipRequest, isTrue);
        expect(vm.canRequestOwnership, isFalse);
        expect(find.byTooltip('Ownership request pending'), findsOneWidget);

        await tester.tap(find.byTooltip('Ownership request pending'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        final requestSentButton = find.widgetWithText(
          ElevatedButton,
          'Request sent',
        );
        expect(requestSentButton, findsOneWidget);
        expect(
          tester.widget<ElevatedButton>(requestSentButton).onPressed,
          isNull,
        );

        await tester.tap(requestSentButton);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 120));

        expect(sessionRepo.requestOwnershipCalls, 1);
        expect(vm.isOwnershipRequestPendingForThisDevice, isTrue);
        expect(vm.hasLocalPendingOwnershipRequest, isTrue);
        expect(find.byTooltip('Ownership request pending'), findsOneWidget);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 100));
        sessionRepo.dispose();
        container.dispose();
        disposed = true;
      } finally {
        if (!disposed) {
          sessionRepo.dispose();
          container.dispose();
        }
      }
    },
  );

  testWidgets(
    'requester pending stays active until owner rejection response arrives',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final now = DateTime.now();
      final deviceInfo = DeviceInfoService.ephemeral();
      final group = _buildRunningGroup(
        id: 'group-pending-until-owner-response',
        start: now,
      );
      final session = _buildRunningSession(
        groupId: group.id,
        taskId: group.tasks.first.sourceTaskId,
        now: now,
        ownerDeviceId: 'remote-owner-device',
      );

      final groupRepo = FakeTaskRunGroupRepository()..seed(group);
      final sessionRepo = FakePomodoroSessionRepository(session);
      final appModeService = AppModeService.memory();
      final timeSyncService = FakeTimeSyncService(offset: Duration.zero);
      final noticeService = FakeTaskRunNoticeService();
      var disposed = false;

      final container = ProviderContainer(
        overrides: [
          firebaseAuthServiceProvider.overrideWithValue(StubAuthService()),
          firestoreServiceProvider.overrideWithValue(StubFirestoreService()),
          taskRunGroupRepositoryProvider.overrideWithValue(groupRepo),
          pomodoroSessionRepositoryProvider.overrideWithValue(sessionRepo),
          appModeServiceProvider.overrideWithValue(appModeService),
          deviceInfoServiceProvider.overrideWithValue(deviceInfo),
          soundServiceProvider.overrideWithValue(FakeSoundService()),
          timeSyncServiceProvider.overrideWithValue(timeSyncService),
          taskRunNoticeServiceProvider.overrideWithValue(noticeService),
        ],
      );
      try {
        await container.read(appModeProvider.notifier).setAccount();

        final router = GoRouter(
          initialLocation: '/timer/${group.id}',
          routes: [
            GoRoute(
              path: '/timer/:id',
              builder: (context, state) {
                final id = state.pathParameters['id']!;
                return TimerScreen(groupId: id);
              },
            ),
            GoRoute(
              path: '/groups',
              builder: (_, __) => const Scaffold(body: SizedBox.shrink()),
            ),
            GoRoute(
              path: '/tasks',
              builder: (_, __) => const Scaffold(body: SizedBox.shrink()),
            ),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(routerConfig: router),
          ),
        );

        final mirrorIndicator = find.byTooltip('Mirror device');
        for (var i = 0; i < 20 && mirrorIndicator.evaluate().isEmpty; i += 1) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(mirrorIndicator, findsOneWidget);

        final vm = container.read(pomodoroViewModelProvider.notifier);
        await vm.requestOwnership();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 120));

        final requestId = sessionRepo.lastRequestId;
        expect(requestId, isNotNull);
        expect(requestId, isNotEmpty);
        expect(vm.isOwnershipRequestPendingForThisDevice, isTrue);
        expect(vm.hasLocalPendingOwnershipRequest, isTrue);
        expect(find.byTooltip('Ownership request pending'), findsOneWidget);

        final confirmedPending = OwnershipRequest(
          requestId: requestId,
          requesterDeviceId: deviceInfo.deviceId,
          requestedAt: now.add(const Duration(seconds: 1)),
          status: OwnershipRequestStatus.pending,
          respondedAt: null,
          respondedByDeviceId: null,
        );
        final pendingSnapshot = _buildRunningSession(
          groupId: group.id,
          taskId: group.tasks.first.sourceTaskId,
          now: now.add(const Duration(seconds: 1)),
          ownerDeviceId: 'remote-owner-device',
          ownershipRequest: confirmedPending,
        );
        sessionRepo.emit(pendingSnapshot);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 120));

        expect(vm.isOwnershipRequestPendingForThisDevice, isTrue);
        expect(vm.hasLocalPendingOwnershipRequest, isTrue);
        expect(find.byTooltip('Ownership request pending'), findsOneWidget);

        final rejectedSnapshot = _buildRunningSession(
          groupId: group.id,
          taskId: group.tasks.first.sourceTaskId,
          now: now.add(const Duration(seconds: 2)),
          ownerDeviceId: 'remote-owner-device',
          ownershipRequest: OwnershipRequest(
            requestId: requestId,
            requesterDeviceId: deviceInfo.deviceId,
            requestedAt: now.add(const Duration(seconds: 1)),
            status: OwnershipRequestStatus.rejected,
            respondedAt: now.add(const Duration(seconds: 2)),
            respondedByDeviceId: 'remote-owner-device',
          ),
        );
        sessionRepo.emit(rejectedSnapshot);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 120));

        expect(vm.isOwnershipRequestPendingForThisDevice, isFalse);
        expect(vm.hasLocalPendingOwnershipRequest, isFalse);
        expect(vm.isOwnershipRequestRejectedForThisDevice, isTrue);
        expect(find.byTooltip('Ownership request pending'), findsNothing);
        expect(find.byTooltip('Mirror device'), findsOneWidget);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 100));
        sessionRepo.dispose();
        container.dispose();
        disposed = true;
      } finally {
        if (!disposed) {
          sessionRepo.dispose();
          container.dispose();
        }
      }
    },
  );

  testWidgets(
    'requester pending yields when another device pending request appears',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final now = DateTime.now();
      final deviceInfo = DeviceInfoService.ephemeral();
      final group = _buildRunningGroup(
        id: 'group-pending-yields-to-other-pending',
        start: now,
      );
      final session = _buildRunningSession(
        groupId: group.id,
        taskId: group.tasks.first.sourceTaskId,
        now: now,
        ownerDeviceId: 'remote-owner-device',
      );

      final groupRepo = FakeTaskRunGroupRepository()..seed(group);
      final sessionRepo = FakePomodoroSessionRepository(session);
      final appModeService = AppModeService.memory();
      final timeSyncService = FakeTimeSyncService(offset: Duration.zero);
      final noticeService = FakeTaskRunNoticeService();
      var disposed = false;

      final container = ProviderContainer(
        overrides: [
          firebaseAuthServiceProvider.overrideWithValue(StubAuthService()),
          firestoreServiceProvider.overrideWithValue(StubFirestoreService()),
          taskRunGroupRepositoryProvider.overrideWithValue(groupRepo),
          pomodoroSessionRepositoryProvider.overrideWithValue(sessionRepo),
          appModeServiceProvider.overrideWithValue(appModeService),
          deviceInfoServiceProvider.overrideWithValue(deviceInfo),
          soundServiceProvider.overrideWithValue(FakeSoundService()),
          timeSyncServiceProvider.overrideWithValue(timeSyncService),
          taskRunNoticeServiceProvider.overrideWithValue(noticeService),
        ],
      );
      try {
        await container.read(appModeProvider.notifier).setAccount();

        final router = GoRouter(
          initialLocation: '/timer/${group.id}',
          routes: [
            GoRoute(
              path: '/timer/:id',
              builder: (context, state) {
                final id = state.pathParameters['id']!;
                return TimerScreen(groupId: id);
              },
            ),
            GoRoute(
              path: '/groups',
              builder: (_, __) => const Scaffold(body: SizedBox.shrink()),
            ),
            GoRoute(
              path: '/tasks',
              builder: (_, __) => const Scaffold(body: SizedBox.shrink()),
            ),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(routerConfig: router),
          ),
        );

        final mirrorIndicator = find.byTooltip('Mirror device');
        for (var i = 0; i < 20 && mirrorIndicator.evaluate().isEmpty; i += 1) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(mirrorIndicator, findsOneWidget);

        final vm = container.read(pomodoroViewModelProvider.notifier);
        await vm.requestOwnership();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 120));

        expect(vm.isOwnershipRequestPendingForThisDevice, isTrue);
        expect(vm.hasLocalPendingOwnershipRequest, isTrue);
        expect(find.byTooltip('Ownership request pending'), findsOneWidget);

        final otherPendingSnapshot = _buildRunningSession(
          groupId: group.id,
          taskId: group.tasks.first.sourceTaskId,
          now: now.add(const Duration(seconds: 2)),
          ownerDeviceId: 'remote-owner-device',
          ownershipRequest: OwnershipRequest(
            requestId: 'pending-other-device',
            requesterDeviceId: 'third-device',
            requestedAt: now.add(const Duration(seconds: 1)),
            status: OwnershipRequestStatus.pending,
            respondedAt: null,
            respondedByDeviceId: null,
          ),
        );
        sessionRepo.emit(otherPendingSnapshot);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 120));

        expect(vm.isOwnershipRequestPendingForThisDevice, isFalse);
        expect(vm.hasLocalPendingOwnershipRequest, isFalse);
        expect(vm.isOwnershipRequestPendingForOther, isTrue);
        expect(find.byTooltip('Ownership request pending'), findsNothing);
        expect(find.byTooltip('Mirror device'), findsOneWidget);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 100));
        sessionRepo.dispose();
        container.dispose();
        disposed = true;
      } finally {
        if (!disposed) {
          sessionRepo.dispose();
          container.dispose();
        }
      }
    },
  );

  testWidgets(
    'rejection clears local pending and old rejected requestId does not suppress a new request',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final now = DateTime.now();
      final deviceInfo = DeviceInfoService.ephemeral();
      final group = _buildRunningGroup(
        id: 'group-reject-clears-pending-requestid-guard',
        start: now,
      );
      final session = _buildRunningSession(
        groupId: group.id,
        taskId: group.tasks.first.sourceTaskId,
        now: now,
        ownerDeviceId: 'remote-owner-device',
      );

      final groupRepo = FakeTaskRunGroupRepository()..seed(group);
      final sessionRepo = FakePomodoroSessionRepository(session);
      final appModeService = AppModeService.memory();
      final timeSyncService = FakeTimeSyncService(offset: Duration.zero);
      final noticeService = FakeTaskRunNoticeService();
      var disposed = false;

      final container = ProviderContainer(
        overrides: [
          firebaseAuthServiceProvider.overrideWithValue(StubAuthService()),
          firestoreServiceProvider.overrideWithValue(StubFirestoreService()),
          taskRunGroupRepositoryProvider.overrideWithValue(groupRepo),
          pomodoroSessionRepositoryProvider.overrideWithValue(sessionRepo),
          appModeServiceProvider.overrideWithValue(appModeService),
          deviceInfoServiceProvider.overrideWithValue(deviceInfo),
          soundServiceProvider.overrideWithValue(FakeSoundService()),
          timeSyncServiceProvider.overrideWithValue(timeSyncService),
          taskRunNoticeServiceProvider.overrideWithValue(noticeService),
        ],
      );
      try {
        await container.read(appModeProvider.notifier).setAccount();

        final router = GoRouter(
          initialLocation: '/timer/${group.id}',
          routes: [
            GoRoute(
              path: '/timer/:id',
              builder: (context, state) {
                final id = state.pathParameters['id']!;
                return TimerScreen(groupId: id);
              },
            ),
            GoRoute(
              path: '/groups',
              builder: (_, __) => const Scaffold(body: SizedBox.shrink()),
            ),
            GoRoute(
              path: '/tasks',
              builder: (_, __) => const Scaffold(body: SizedBox.shrink()),
            ),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(routerConfig: router),
          ),
        );

        final mirrorIndicator = find.byTooltip('Mirror device');
        for (var i = 0; i < 20 && mirrorIndicator.evaluate().isEmpty; i += 1) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(mirrorIndicator, findsOneWidget);

        final vm = container.read(pomodoroViewModelProvider.notifier);
        await vm.requestOwnership();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 120));

        final firstRequestId = sessionRepo.lastRequestId;
        expect(firstRequestId, isNotNull);
        expect(firstRequestId, isNotEmpty);
        expect(sessionRepo.requestOwnershipCalls, 1);
        expect(vm.isOwnershipRequestPendingForThisDevice, isTrue);
        expect(vm.hasLocalPendingOwnershipRequest, isTrue);
        expect(find.byTooltip('Ownership request pending'), findsOneWidget);

        final rejectedSnapshot = _buildRunningSession(
          groupId: group.id,
          taskId: group.tasks.first.sourceTaskId,
          now: now.add(const Duration(seconds: 2)),
          ownerDeviceId: 'remote-owner-device',
          ownershipRequest: OwnershipRequest(
            requestId: firstRequestId,
            requesterDeviceId: deviceInfo.deviceId,
            requestedAt: now.add(const Duration(seconds: 1)),
            status: OwnershipRequestStatus.rejected,
            respondedAt: now.add(const Duration(seconds: 2)),
            respondedByDeviceId: 'remote-owner-device',
          ),
        );
        sessionRepo.emit(rejectedSnapshot);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 120));

        expect(vm.isOwnershipRequestPendingForThisDevice, isFalse);
        expect(vm.hasLocalPendingOwnershipRequest, isFalse);
        expect(vm.isOwnershipRequestRejectedForThisDevice, isTrue);
        expect(vm.canRequestOwnership, isTrue);
        expect(find.byTooltip('Ownership request pending'), findsNothing);
        expect(find.byTooltip('Mirror device'), findsOneWidget);

        await vm.requestOwnership();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 120));

        final secondRequestId = sessionRepo.lastRequestId;
        expect(sessionRepo.requestOwnershipCalls, 2);
        expect(secondRequestId, isNotNull);
        expect(secondRequestId, isNot(firstRequestId));
        expect(vm.isOwnershipRequestPendingForThisDevice, isTrue);
        expect(vm.hasLocalPendingOwnershipRequest, isTrue);
        expect(find.byTooltip('Ownership request pending'), findsOneWidget);

        final staleRejectedReplay = _buildRunningSession(
          groupId: group.id,
          taskId: group.tasks.first.sourceTaskId,
          now: now.add(const Duration(seconds: 3)),
          ownerDeviceId: 'remote-owner-device',
          ownershipRequest: OwnershipRequest(
            requestId: firstRequestId,
            requesterDeviceId: deviceInfo.deviceId,
            requestedAt: now.add(const Duration(seconds: 1)),
            status: OwnershipRequestStatus.rejected,
            respondedAt: now.add(const Duration(seconds: 2)),
            respondedByDeviceId: 'remote-owner-device',
          ),
        );
        sessionRepo.emit(staleRejectedReplay);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 120));

        expect(vm.isOwnershipRequestPendingForThisDevice, isTrue);
        expect(vm.hasLocalPendingOwnershipRequest, isTrue);
        expect(find.byTooltip('Ownership request pending'), findsOneWidget);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 100));
        sessionRepo.dispose();
        container.dispose();
        disposed = true;
      } finally {
        if (!disposed) {
          sessionRepo.dispose();
          container.dispose();
        }
      }
    },
  );

  testWidgets('mirror mode shows request action only inside ownership sheet', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final now = DateTime.now();
    final deviceInfo = DeviceInfoService.ephemeral();
    final group = _buildRunningGroup(
      id: 'group-request-action-sheet-only',
      start: now,
    );
    final session = _buildRunningSession(
      groupId: group.id,
      taskId: group.tasks.first.sourceTaskId,
      now: now,
      ownerDeviceId: 'remote-owner-device',
    );

    final groupRepo = FakeTaskRunGroupRepository()..seed(group);
    final sessionRepo = FakePomodoroSessionRepository(session);
    final appModeService = AppModeService.memory();
    final timeSyncService = FakeTimeSyncService(offset: Duration.zero);
    final noticeService = FakeTaskRunNoticeService();
    var disposed = false;

    final container = ProviderContainer(
      overrides: [
        firebaseAuthServiceProvider.overrideWithValue(StubAuthService()),
        firestoreServiceProvider.overrideWithValue(StubFirestoreService()),
        taskRunGroupRepositoryProvider.overrideWithValue(groupRepo),
        pomodoroSessionRepositoryProvider.overrideWithValue(sessionRepo),
        appModeServiceProvider.overrideWithValue(appModeService),
        deviceInfoServiceProvider.overrideWithValue(deviceInfo),
        soundServiceProvider.overrideWithValue(FakeSoundService()),
        timeSyncServiceProvider.overrideWithValue(timeSyncService),
        taskRunNoticeServiceProvider.overrideWithValue(noticeService),
      ],
    );
    try {
      await container.read(appModeProvider.notifier).setAccount();

      final router = GoRouter(
        initialLocation: '/timer/${group.id}',
        routes: [
          GoRoute(
            path: '/timer/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return TimerScreen(groupId: id);
            },
          ),
          GoRoute(
            path: '/groups',
            builder: (_, __) => const Scaffold(body: SizedBox.shrink()),
          ),
          GoRoute(
            path: '/tasks',
            builder: (_, __) => const Scaffold(body: SizedBox.shrink()),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      final mirrorIndicator = find.byTooltip('Mirror device');
      for (var i = 0; i < 20 && mirrorIndicator.evaluate().isEmpty; i += 1) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(mirrorIndicator, findsOneWidget);

      // The main control row must not expose request ownership.
      expect(
        find.widgetWithText(ElevatedButton, 'Request ownership'),
        findsNothing,
      );
      expect(find.text('Request ownership'), findsNothing);

      await tester.tap(mirrorIndicator);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Session ownership'), findsOneWidget);
      final requestButton = find.widgetWithText(
        ElevatedButton,
        'Request ownership',
      );
      expect(requestButton, findsOneWidget);
      expect(tester.widget<ElevatedButton>(requestButton).onPressed, isNotNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
      sessionRepo.dispose();
      container.dispose();
      disposed = true;
    } finally {
      if (!disposed) {
        sessionRepo.dispose();
        container.dispose();
      }
    }
  });

  testWidgets('stale pending request shows Retry CTA inside ownership sheet', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final now = DateTime.now();
    final deviceInfo = DeviceInfoService.ephemeral();
    final group = _buildRunningGroup(
      id: 'group-stale-pending-retry-sheet',
      start: now,
    );
    final stalePendingForSelf = OwnershipRequest(
      requestId: 'stale-request-self',
      requesterDeviceId: deviceInfo.deviceId,
      requestedAt: now.subtract(const Duration(minutes: 2)),
      status: OwnershipRequestStatus.pending,
      respondedAt: null,
      respondedByDeviceId: null,
    );
    final session = _buildRunningSession(
      groupId: group.id,
      taskId: group.tasks.first.sourceTaskId,
      now: now,
      ownerDeviceId: 'remote-owner-device',
      ownershipRequest: stalePendingForSelf,
    );

    final groupRepo = FakeTaskRunGroupRepository()..seed(group);
    final sessionRepo = FakePomodoroSessionRepository(session);
    final appModeService = AppModeService.memory();
    final timeSyncService = FakeTimeSyncService(offset: Duration.zero);
    final noticeService = FakeTaskRunNoticeService();
    var disposed = false;

    final container = ProviderContainer(
      overrides: [
        firebaseAuthServiceProvider.overrideWithValue(StubAuthService()),
        firestoreServiceProvider.overrideWithValue(StubFirestoreService()),
        taskRunGroupRepositoryProvider.overrideWithValue(groupRepo),
        pomodoroSessionRepositoryProvider.overrideWithValue(sessionRepo),
        appModeServiceProvider.overrideWithValue(appModeService),
        deviceInfoServiceProvider.overrideWithValue(deviceInfo),
        soundServiceProvider.overrideWithValue(FakeSoundService()),
        timeSyncServiceProvider.overrideWithValue(timeSyncService),
        taskRunNoticeServiceProvider.overrideWithValue(noticeService),
      ],
    );
    try {
      await container.read(appModeProvider.notifier).setAccount();

      final router = GoRouter(
        initialLocation: '/timer/${group.id}',
        routes: [
          GoRoute(
            path: '/timer/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return TimerScreen(groupId: id);
            },
          ),
          GoRoute(
            path: '/groups',
            builder: (_, __) => const Scaffold(body: SizedBox.shrink()),
          ),
          GoRoute(
            path: '/tasks',
            builder: (_, __) => const Scaffold(body: SizedBox.shrink()),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      final pendingIndicator = find.byTooltip('Ownership request pending');
      for (var i = 0; i < 20 && pendingIndicator.evaluate().isEmpty; i += 1) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(pendingIndicator, findsOneWidget);

      final vm = container.read(pomodoroViewModelProvider.notifier);
      expect(vm.isMirrorMode, isTrue);
      expect(vm.isOwnershipRequestPendingForThisDevice, isTrue);
      expect(vm.hasLocalPendingOwnershipRequest, isFalse);
      expect(vm.canRequestOwnership, isTrue);

      // Retry action must not be in the main controls; it belongs to the sheet.
      expect(find.widgetWithText(ElevatedButton, 'Retry'), findsNothing);

      await tester.tap(pendingIndicator);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Session ownership'), findsOneWidget);
      final retryButton = find.widgetWithText(ElevatedButton, 'Retry');
      expect(retryButton, findsOneWidget);
      expect(tester.widget<ElevatedButton>(retryButton).onPressed, isNotNull);

      await tester.tap(retryButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));

      expect(sessionRepo.requestOwnershipCalls, 1);
      expect(sessionRepo.lastRequesterDeviceId, deviceInfo.deviceId);
      expect(sessionRepo.lastRequestId, isNotNull);
      expect(vm.hasLocalPendingOwnershipRequest, isTrue);
      expect(vm.isOwnershipRequestPendingForThisDevice, isTrue);
      expect(find.byTooltip('Ownership request pending'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
      sessionRepo.dispose();
      container.dispose();
      disposed = true;
    } finally {
      if (!disposed) {
        sessionRepo.dispose();
        container.dispose();
      }
    }
  });

  testWidgets(
    'critical ownership flow stays appbar-sheet-only and pending remains stable until owner response',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final now = DateTime.now();
      final deviceInfo = DeviceInfoService.ephemeral();
      final group = _buildRunningGroup(
        id: 'group-critical-sheet-only-pending-stable',
        start: now,
      );
      final session = _buildRunningSession(
        groupId: group.id,
        taskId: group.tasks.first.sourceTaskId,
        now: now,
        ownerDeviceId: 'remote-owner-device',
      );

      final groupRepo = FakeTaskRunGroupRepository()..seed(group);
      final sessionRepo = FakePomodoroSessionRepository(session);
      final appModeService = AppModeService.memory();
      final timeSyncService = FakeTimeSyncService(offset: Duration.zero);
      final noticeService = FakeTaskRunNoticeService();
      var disposed = false;

      final container = ProviderContainer(
        overrides: [
          firebaseAuthServiceProvider.overrideWithValue(StubAuthService()),
          firestoreServiceProvider.overrideWithValue(StubFirestoreService()),
          taskRunGroupRepositoryProvider.overrideWithValue(groupRepo),
          pomodoroSessionRepositoryProvider.overrideWithValue(sessionRepo),
          appModeServiceProvider.overrideWithValue(appModeService),
          deviceInfoServiceProvider.overrideWithValue(deviceInfo),
          soundServiceProvider.overrideWithValue(FakeSoundService()),
          timeSyncServiceProvider.overrideWithValue(timeSyncService),
          taskRunNoticeServiceProvider.overrideWithValue(noticeService),
        ],
      );
      try {
        await container.read(appModeProvider.notifier).setAccount();

        final router = GoRouter(
          initialLocation: '/timer/${group.id}',
          routes: [
            GoRoute(
              path: '/timer/:id',
              builder: (context, state) {
                final id = state.pathParameters['id']!;
                return TimerScreen(groupId: id);
              },
            ),
            GoRoute(
              path: '/groups',
              builder: (_, __) => const Scaffold(body: SizedBox.shrink()),
            ),
            GoRoute(
              path: '/tasks',
              builder: (_, __) => const Scaffold(body: SizedBox.shrink()),
            ),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(routerConfig: router),
          ),
        );

        final mirrorIndicator = find.byTooltip('Mirror device');
        for (var i = 0; i < 20 && mirrorIndicator.evaluate().isEmpty; i += 1) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(mirrorIndicator, findsOneWidget);

        final vm = container.read(pomodoroViewModelProvider.notifier);

        // AppBar sheet only: no request CTA or pending copy in main body.
        expect(
          find.widgetWithText(ElevatedButton, 'Request ownership'),
          findsNothing,
        );
        expect(find.text('Waiting for owner approval.'), findsNothing);
        expect(find.byTooltip('Ownership request pending'), findsNothing);

        // Request action is available only after opening the ownership sheet.
        await tester.tap(mirrorIndicator);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('Session ownership'), findsOneWidget);
        expect(find.text('Waiting for owner approval.'), findsNothing);

        final requestButton = find.widgetWithText(
          ElevatedButton,
          'Request ownership',
        );
        expect(requestButton, findsOneWidget);
        expect(
          tester.widget<ElevatedButton>(requestButton).onPressed,
          isNotNull,
        );

        await tester.tap(requestButton);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 120));

        final requestId = sessionRepo.lastRequestId;
        expect(requestId, isNotNull);
        expect(requestId, isNotEmpty);
        expect(vm.isOwnershipRequestPendingForThisDevice, isTrue);
        expect(vm.hasLocalPendingOwnershipRequest, isTrue);
        expect(find.byTooltip('Ownership request pending'), findsOneWidget);

        // Pending remains stable after remote pending confirmation.
        final pendingSnapshot = _buildRunningSession(
          groupId: group.id,
          taskId: group.tasks.first.sourceTaskId,
          now: now.add(const Duration(seconds: 1)),
          ownerDeviceId: 'remote-owner-device',
          ownershipRequest: OwnershipRequest(
            requestId: requestId,
            requesterDeviceId: deviceInfo.deviceId,
            requestedAt: now.add(const Duration(seconds: 1)),
            status: OwnershipRequestStatus.pending,
            respondedAt: null,
            respondedByDeviceId: null,
          ),
        );
        sessionRepo.emit(pendingSnapshot);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 120));

        expect(vm.isOwnershipRequestPendingForThisDevice, isTrue);
        expect(find.byTooltip('Ownership request pending'), findsOneWidget);

        // Sheet shows the waiting message while owner has not responded.
        await tester.tap(find.byTooltip('Ownership request pending'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('Session ownership'), findsOneWidget);
        expect(find.text('Waiting for owner approval.'), findsOneWidget);

        // Once owner rejects, pending must clear.
        final rejectedSnapshot = _buildRunningSession(
          groupId: group.id,
          taskId: group.tasks.first.sourceTaskId,
          now: now.add(const Duration(seconds: 2)),
          ownerDeviceId: 'remote-owner-device',
          ownershipRequest: OwnershipRequest(
            requestId: requestId,
            requesterDeviceId: deviceInfo.deviceId,
            requestedAt: now.add(const Duration(seconds: 1)),
            status: OwnershipRequestStatus.rejected,
            respondedAt: now.add(const Duration(seconds: 2)),
            respondedByDeviceId: 'remote-owner-device',
          ),
        );
        sessionRepo.emit(rejectedSnapshot);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 120));

        expect(vm.isOwnershipRequestPendingForThisDevice, isFalse);
        expect(vm.hasLocalPendingOwnershipRequest, isFalse);
        expect(find.byTooltip('Ownership request pending'), findsNothing);
        expect(find.byTooltip('Mirror device'), findsOneWidget);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 100));
        sessionRepo.dispose();
        container.dispose();
        disposed = true;
      } finally {
        if (!disposed) {
          sessionRepo.dispose();
          container.dispose();
        }
      }
    },
  );

  testWidgets(
    'owner reject dismissal stays hidden when pending request gets requestId materialized',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final now = DateTime.now();
      final deviceInfo = DeviceInfoService.ephemeral();
      final group = _buildRunningGroup(
        id: 'group-owner-reject-materialized-requestid',
        start: now,
      );
      final pendingWithoutRequestId = OwnershipRequest(
        requestId: null,
        requesterDeviceId: 'mirror-test-device',
        requestedAt: now,
        status: OwnershipRequestStatus.pending,
        respondedAt: null,
        respondedByDeviceId: null,
      );
      final session = _buildRunningSession(
        groupId: group.id,
        taskId: group.tasks.first.sourceTaskId,
        now: now,
        ownerDeviceId: deviceInfo.deviceId,
        ownershipRequest: pendingWithoutRequestId,
      );

      final groupRepo = FakeTaskRunGroupRepository()..seed(group);
      final sessionRepo = FakePomodoroSessionRepository(session);
      final appModeService = AppModeService.memory();
      final timeSyncService = FakeTimeSyncService(offset: Duration.zero);
      final noticeService = FakeTaskRunNoticeService();
      var disposed = false;

      final container = ProviderContainer(
        overrides: [
          firebaseAuthServiceProvider.overrideWithValue(StubAuthService()),
          firestoreServiceProvider.overrideWithValue(StubFirestoreService()),
          taskRunGroupRepositoryProvider.overrideWithValue(groupRepo),
          pomodoroSessionRepositoryProvider.overrideWithValue(sessionRepo),
          appModeServiceProvider.overrideWithValue(appModeService),
          deviceInfoServiceProvider.overrideWithValue(deviceInfo),
          soundServiceProvider.overrideWithValue(FakeSoundService()),
          timeSyncServiceProvider.overrideWithValue(timeSyncService),
          taskRunNoticeServiceProvider.overrideWithValue(noticeService),
        ],
      );
      try {
        await container.read(appModeProvider.notifier).setAccount();

        final router = GoRouter(
          initialLocation: '/timer/${group.id}',
          routes: [
            GoRoute(
              path: '/timer/:id',
              builder: (context, state) {
                final id = state.pathParameters['id']!;
                return TimerScreen(groupId: id);
              },
            ),
            GoRoute(
              path: '/groups',
              builder: (_, __) => const Scaffold(body: SizedBox.shrink()),
            ),
            GoRoute(
              path: '/tasks',
              builder: (_, __) => const Scaffold(body: SizedBox.shrink()),
            ),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(routerConfig: router),
          ),
        );

        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Ownership request'), findsOneWidget);
        final rejectButton = find.widgetWithText(OutlinedButton, 'Reject');
        expect(rejectButton, findsOneWidget);

        await tester.tap(rejectButton);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 120));
        expect(find.text('Ownership request'), findsNothing);

        final pendingWithRequestId = _buildRunningSession(
          groupId: group.id,
          taskId: group.tasks.first.sourceTaskId,
          now: now.add(const Duration(seconds: 1)),
          ownerDeviceId: deviceInfo.deviceId,
          ownershipRequest: OwnershipRequest(
            requestId: 'req-materialized-1',
            requesterDeviceId: 'mirror-test-device',
            requestedAt: now,
            status: OwnershipRequestStatus.pending,
            respondedAt: null,
            respondedByDeviceId: null,
          ),
        );
        sessionRepo.emit(pendingWithRequestId);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 120));

        expect(find.text('Ownership request'), findsNothing);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 100));
        sessionRepo.dispose();
        container.dispose();
        disposed = true;
      } finally {
        if (!disposed) {
          sessionRepo.dispose();
          container.dispose();
        }
      }
    },
  );

  testWidgets('Pending intent without snapshot shows full loader', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final now = DateTime.now();
    final group = _buildScheduledGroup(
      id: 'group-1',
      scheduledStart: now.add(const Duration(minutes: 5)),
    );

    final groupRepo = FakeTaskRunGroupRepository()..seed(group);
    final sessionRepo = FakePomodoroSessionRepository(null);
    final appModeService = AppModeService.memory();
    final timeSyncService = FakeTimeSyncService(offset: null);
    final noticeService = FakeTaskRunNoticeService();

    final container = ProviderContainer(
      overrides: [
        firebaseAuthServiceProvider.overrideWithValue(StubAuthService()),
        firestoreServiceProvider.overrideWithValue(StubFirestoreService()),
        taskRunGroupRepositoryProvider.overrideWithValue(groupRepo),
        pomodoroSessionRepositoryProvider.overrideWithValue(sessionRepo),
        appModeServiceProvider.overrideWithValue(appModeService),
        deviceInfoServiceProvider.overrideWithValue(
          DeviceInfoService.ephemeral(),
        ),
        soundServiceProvider.overrideWithValue(FakeSoundService()),
        timeSyncServiceProvider.overrideWithValue(timeSyncService),
        taskRunNoticeServiceProvider.overrideWithValue(noticeService),
      ],
    );
    addTearDown(() {
      sessionRepo.dispose();
      container.dispose();
    });

    await container.read(appModeProvider.notifier).setAccount();

    final router = GoRouter(
      initialLocation: '/timer/${group.id}',
      routes: [
        GoRoute(
          path: '/timer/:id',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return TimerScreen(groupId: id);
          },
        ),
        GoRoute(
          path: '/groups',
          builder: (_, __) => const Scaffold(body: SizedBox.shrink()),
        ),
        GoRoute(
          path: '/tasks',
          builder: (_, __) => const Scaffold(body: SizedBox.shrink()),
        ),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump(const Duration(milliseconds: 80));

    final vm = container.read(pomodoroViewModelProvider.notifier);
    vm.start();
    await tester.pump();

    expect(vm.hasPendingIntent, isTrue);
    expect(find.byType(TimerDisplay), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets(
    '[PHASE4] sync overlay diagnostics must emit explicit trigger reason (timeSyncUnready)',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final now = DateTime.now();
      final group = _buildScheduledGroup(
        id: 'group-phase4-overlay-diagnostics',
        scheduledStart: now.add(const Duration(minutes: 5)),
      );

      final groupRepo = FakeTaskRunGroupRepository()..seed(group);
      final sessionRepo = FakePomodoroSessionRepository(null);
      final appModeService = AppModeService.memory();
      final timeSyncService = FakeTimeSyncService(offset: null);
      final noticeService = FakeTaskRunNoticeService();
      final logs = <String>[];
      final previousDebugPrint = foundation.debugPrint;
      foundation.debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) logs.add(message);
      };

      final container = ProviderContainer(
        overrides: [
          firebaseAuthServiceProvider.overrideWithValue(StubAuthService()),
          firestoreServiceProvider.overrideWithValue(StubFirestoreService()),
          taskRunGroupRepositoryProvider.overrideWithValue(groupRepo),
          pomodoroSessionRepositoryProvider.overrideWithValue(sessionRepo),
          appModeServiceProvider.overrideWithValue(appModeService),
          deviceInfoServiceProvider.overrideWithValue(
            DeviceInfoService.ephemeral(),
          ),
          soundServiceProvider.overrideWithValue(FakeSoundService()),
          timeSyncServiceProvider.overrideWithValue(timeSyncService),
          taskRunNoticeServiceProvider.overrideWithValue(noticeService),
        ],
      );
      addTearDown(() {
        foundation.debugPrint = previousDebugPrint;
        sessionRepo.dispose();
        container.dispose();
      });

      await container.read(appModeProvider.notifier).setAccount();

      final router = GoRouter(
        initialLocation: '/timer/${group.id}',
        routes: [
          GoRoute(
            path: '/timer/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return TimerScreen(groupId: id);
            },
          ),
          GoRoute(
            path: '/groups',
            builder: (_, __) => const Scaffold(body: SizedBox.shrink()),
          ),
          GoRoute(
            path: '/tasks',
            builder: (_, __) => const Scaffold(body: SizedBox.shrink()),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump(const Duration(milliseconds: 80));

      final vm = container.read(pomodoroViewModelProvider.notifier);
      vm.start();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      foundation.debugPrint = previousDebugPrint;

      expect(vm.hasPendingIntent, isTrue);
      final merged = logs.join('\n');
      expect(
        merged.contains('SyncOverlay'),
        isTrue,
        reason:
            'Phase-4 diagnostics contract: overlay transitions must emit a dedicated sync-overlay diagnostic event.',
      );
      expect(
        merged.contains('timeSyncUnready'),
        isTrue,
        reason:
            'Phase-4 diagnostics contract: sync-overlay diagnostics must include explicit trigger reason(s), including timeSyncUnready.',
      );
    },
  );

  testWidgets('[PHASE6] auto-open guard clears when VM is disposed mid-session', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final now = DateTime.now();
    final group = _buildRunningGroup(
      id: 'group-phase6-auto-open-recovery',
      start: now,
    );
    final session = _buildRunningSession(
      groupId: group.id,
      taskId: group.tasks.first.sourceTaskId,
      now: now,
    );
    final nextSession = PomodoroSession(
      taskId: session.taskId,
      groupId: session.groupId,
      currentTaskId: session.currentTaskId,
      currentTaskIndex: session.currentTaskIndex,
      totalTasks: session.totalTasks,
      dataVersion: session.dataVersion,
      sessionRevision: session.sessionRevision + 1,
      ownerDeviceId: session.ownerDeviceId,
      status: session.status,
      phase: session.phase,
      currentPomodoro: session.currentPomodoro,
      totalPomodoros: session.totalPomodoros,
      phaseDurationSeconds: session.phaseDurationSeconds,
      remainingSeconds: session.remainingSeconds - 10,
      accumulatedPausedSeconds: session.accumulatedPausedSeconds,
      phaseStartedAt: session.phaseStartedAt,
      currentTaskStartedAt: session.currentTaskStartedAt,
      pausedAt: null,
      lastUpdatedAt: now.add(const Duration(seconds: 1)),
      finishedAt: null,
      pauseReason: null,
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
        deviceInfoServiceProvider.overrideWithValue(
          DeviceInfoService.ephemeral(),
        ),
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
      vmSub.close();
      sessionRepo.dispose();
      container.dispose();
    });

    await container.read(appModeProvider.notifier).setAccount();
    final vm = container.read(pomodoroViewModelProvider.notifier);
    await vm.loadGroup(group.id);
    expect(container.exists(pomodoroViewModelProvider), isTrue);

    final navigatorKey = GlobalKey<NavigatorState>();
    final router = GoRouter(
      navigatorKey: navigatorKey,
      initialLocation: '/timer/${group.id}',
      routes: [
        GoRoute(
          path: '/timer/:id',
          builder: (context, state) {
            return Scaffold(body: Text('timer-${state.pathParameters['id']}'));
          },
        ),
        GoRoute(
          path: '/groups',
          builder: (_, __) => const Scaffold(body: SizedBox.shrink()),
        ),
        GoRoute(
          path: '/tasks',
          builder: (_, __) => const Scaffold(body: SizedBox.shrink()),
        ),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: ActiveSessionAutoOpener(
          navigatorKey: navigatorKey,
          child: MaterialApp.router(routerConfig: router),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    vmSub.close();
    container.invalidate(pomodoroViewModelProvider);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(container.exists(pomodoroViewModelProvider), isFalse);

    sessionRepo.emit(nextSession);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    foundation.debugPrint = previousDebugPrint;

    final merged = logs.join('\n');
    expect(
      merged.contains('Auto-open recovery: VM disposed, clearing guard'),
      isTrue,
      reason:
          'Phase-6 contract: auto-opener must clear opened guard when VM is disposed on a live timer route.',
    );
    expect(
      merged.contains('Auto-open recovery: forcing timer refresh'),
      isTrue,
      reason:
          'Phase-6 contract: recovery path must force a timer refresh attempt.',
    );
    expect(
      router.routerDelegate.currentConfiguration.uri.queryParameters
          .containsKey('refresh'),
      isTrue,
      reason:
          'Phase-6 contract: recovery path must re-open timer route instead of staying suppressed.',
    );

    // Dispose the container before the test ends so the TimerService ticker
    // is cancelled before testWidgets checks for pending timers.
    vmSub.close();
    container.dispose();
  });

  testWidgets(
    '[BUG-030] auto-open stays suppressed after intentional departure from Run Mode',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final now = DateTime.now();
      final group = _buildRunningGroup(
        id: 'group-bug030-intentional-departure',
        start: now,
      );
      final session = _buildRunningSession(
        groupId: group.id,
        taskId: group.tasks.first.sourceTaskId,
        now: now,
      );
      final nextSession = PomodoroSession(
        taskId: session.taskId,
        groupId: session.groupId,
        currentTaskId: session.currentTaskId,
        currentTaskIndex: session.currentTaskIndex,
        totalTasks: session.totalTasks,
        dataVersion: session.dataVersion,
        sessionRevision: session.sessionRevision + 1,
        ownerDeviceId: session.ownerDeviceId,
        status: session.status,
        phase: session.phase,
        currentPomodoro: session.currentPomodoro,
        totalPomodoros: session.totalPomodoros,
        phaseDurationSeconds: session.phaseDurationSeconds,
        remainingSeconds: session.remainingSeconds - 10,
        accumulatedPausedSeconds: session.accumulatedPausedSeconds,
        phaseStartedAt: session.phaseStartedAt,
        currentTaskStartedAt: session.currentTaskStartedAt,
        pausedAt: null,
        lastUpdatedAt: now.add(const Duration(seconds: 1)),
        finishedAt: null,
        pauseReason: null,
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
          deviceInfoServiceProvider.overrideWithValue(
            DeviceInfoService.ephemeral(),
          ),
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
        vmSub.close();
        sessionRepo.dispose();
        container.dispose();
      });

      await container.read(appModeProvider.notifier).setAccount();
      final vm = container.read(pomodoroViewModelProvider.notifier);
      await vm.loadGroup(group.id);
      expect(container.exists(pomodoroViewModelProvider), isTrue);

      final navigatorKey = GlobalKey<NavigatorState>();
      final router = GoRouter(
        navigatorKey: navigatorKey,
        initialLocation: '/timer/${group.id}',
        routes: [
          GoRoute(
            path: '/timer/:id',
            builder: (context, state) {
              return Scaffold(
                body: Text('timer-${state.pathParameters['id']}'),
              );
            },
          ),
          GoRoute(
            path: '/groups',
            builder: (_, __) => const Scaffold(body: SizedBox.shrink()),
          ),
          GoRoute(
            path: '/tasks',
            builder: (_, __) => const Scaffold(body: SizedBox.shrink()),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: ActiveSessionAutoOpener(
            navigatorKey: navigatorKey,
            child: MaterialApp.router(routerConfig: router),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));

      router.go('/groups');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      expect(router.routerDelegate.currentConfiguration.uri.path, '/groups');

      vmSub.close();
      container.invalidate(pomodoroViewModelProvider);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      expect(container.exists(pomodoroViewModelProvider), isFalse);

      sessionRepo.emit(nextSession);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      foundation.debugPrint = previousDebugPrint;

      final merged = logs.join('\n');
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/groups',
        reason:
            'BUG-030 contract: after intentional departure, VM disposal ticks must not force navigation back to timer.',
      );
      expect(
        merged.contains(
          'Auto-open suppressed (VM disposed after intentional departure)',
        ),
        isTrue,
        reason:
            'BUG-030 contract: intentional-departure sentinel must suppress VM-disposal recovery path.',
      );
      expect(
        merged.contains('Auto-open recovery: forcing timer refresh'),
        isFalse,
        reason:
            'BUG-030 contract: force-refresh path must not run after intentional departure.',
      );

      vmSub.close();
      container.dispose();
    },
  );

  testWidgets(
    '[PHASE5] sync overlay diagnostics must include vmToken for lifecycle correlation',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final now = DateTime.now();
      final group = _buildScheduledGroup(
        id: 'group-phase5-overlay-vm-token',
        scheduledStart: now.add(const Duration(minutes: 5)),
      );

      final groupRepo = FakeTaskRunGroupRepository()..seed(group);
      final sessionRepo = FakePomodoroSessionRepository(null);
      final appModeService = AppModeService.memory();
      final timeSyncService = FakeTimeSyncService(offset: null);
      final noticeService = FakeTaskRunNoticeService();
      final logs = <String>[];
      final previousDebugPrint = foundation.debugPrint;
      foundation.debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) logs.add(message);
      };

      final container = ProviderContainer(
        overrides: [
          firebaseAuthServiceProvider.overrideWithValue(StubAuthService()),
          firestoreServiceProvider.overrideWithValue(StubFirestoreService()),
          taskRunGroupRepositoryProvider.overrideWithValue(groupRepo),
          pomodoroSessionRepositoryProvider.overrideWithValue(sessionRepo),
          appModeServiceProvider.overrideWithValue(appModeService),
          deviceInfoServiceProvider.overrideWithValue(
            DeviceInfoService.ephemeral(),
          ),
          soundServiceProvider.overrideWithValue(FakeSoundService()),
          timeSyncServiceProvider.overrideWithValue(timeSyncService),
          taskRunNoticeServiceProvider.overrideWithValue(noticeService),
        ],
      );
      addTearDown(() {
        foundation.debugPrint = previousDebugPrint;
        sessionRepo.dispose();
        container.dispose();
      });

      await container.read(appModeProvider.notifier).setAccount();

      final router = GoRouter(
        initialLocation: '/timer/${group.id}',
        routes: [
          GoRoute(
            path: '/timer/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return TimerScreen(groupId: id);
            },
          ),
          GoRoute(
            path: '/groups',
            builder: (_, __) => const Scaffold(body: SizedBox.shrink()),
          ),
          GoRoute(
            path: '/tasks',
            builder: (_, __) => const Scaffold(body: SizedBox.shrink()),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump(const Duration(milliseconds: 80));

      final vm = container.read(pomodoroViewModelProvider.notifier);
      vm.start();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      foundation.debugPrint = previousDebugPrint;

      expect(vm.hasPendingIntent, isTrue);
      final merged = logs.join('\n');
      expect(
        merged.contains('SyncOverlay'),
        isTrue,
        reason:
            'Phase-5 diagnostics contract: sync-overlay transitions must still emit dedicated sync-overlay diagnostics.',
      );
      expect(
        merged.contains('vmToken='),
        isTrue,
        reason:
            'Phase-5 diagnostics contract: sync-overlay diagnostics must include vmToken for cross-event lifecycle correlation.',
      );
    },
  );
}
