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
}) {
  return PomodoroSession(
    taskId: taskId,
    groupId: groupId,
    currentTaskId: taskId,
    currentTaskIndex: 0,
    totalTasks: 1,
    dataVersion: kCurrentDataVersion,
    sessionRevision: 1,
    ownerDeviceId: 'owner-device',
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
  );
}

void main() {
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
