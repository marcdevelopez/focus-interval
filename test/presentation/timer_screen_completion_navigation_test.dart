import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:focus_interval/data/models/pomodoro_session.dart';
import 'package:focus_interval/data/models/pomodoro_preset.dart';
import 'package:focus_interval/data/models/pomodoro_task.dart';
import 'package:focus_interval/data/models/schema_version.dart';
import 'package:focus_interval/data/models/selected_sound.dart';
import 'package:focus_interval/data/models/task_run_group.dart';
import 'package:focus_interval/data/repositories/pomodoro_session_repository.dart';
import 'package:focus_interval/data/repositories/pomodoro_preset_repository.dart';
import 'package:focus_interval/data/repositories/task_repository.dart';
import 'package:focus_interval/data/repositories/task_run_group_repository.dart';
import 'package:focus_interval/data/services/app_mode_service.dart';
import 'package:focus_interval/data/services/device_info_service.dart';
import 'package:focus_interval/data/services/firebase_auth_service.dart';
import 'package:focus_interval/data/services/firestore_service.dart';
import 'package:focus_interval/data/services/sound_service.dart';
import 'package:focus_interval/data/services/time_sync_service.dart';
import 'package:focus_interval/domain/pomodoro_machine.dart';
import 'package:focus_interval/presentation/providers.dart';
import 'package:focus_interval/presentation/screens/groups_hub_screen.dart';
import 'package:focus_interval/presentation/screens/task_group_planning_screen.dart';
import 'package:focus_interval/presentation/screens/task_list_screen.dart';
import 'package:focus_interval/presentation/screens/timer_screen.dart';

class FakeTaskRunGroupRepository implements TaskRunGroupRepository {
  final Map<String, TaskRunGroup> _store = {};
  final StreamController<List<TaskRunGroup>> _controller =
      StreamController<List<TaskRunGroup>>.broadcast();

  void seed(TaskRunGroup group) {
    _store[group.id] = group;
  }

  void emit(TaskRunGroup group) {
    _store[group.id] = group;
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
    emit(group);
  }

  @override
  Future<void> saveAll(List<TaskRunGroup> groups) async {
    for (final group in groups) {
      _store[group.id] = group;
    }
    _controller.add(_store.values.toList());
  }

  @override
  Future<void> delete(String id) async {
    _store.remove(id);
    _controller.add(_store.values.toList());
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

  void dispose() {
    _controller.close();
  }
}

class FakePomodoroSessionRepository implements PomodoroSessionRepository {
  FakePomodoroSessionRepository(this._initialSession);

  final StreamController<PomodoroSession?> _controller =
      StreamController<PomodoroSession?>.broadcast();
  PomodoroSession? _lastSession;
  PomodoroSession? _initialSession;
  int clearSessionIfGroupNotRunningCalls = 0;

  @override
  Stream<PomodoroSession?> watchSession() async* {
    if (_initialSession != null) {
      _lastSession = _initialSession;
      yield _initialSession;
      _initialSession = null;
    }
    yield* _controller.stream;
  }

  @override
  Future<PomodoroSession?> fetchSession({bool preferServer = false}) async {
    return _lastSession;
  }

  @override
  Future<void> publishSession(PomodoroSession session) async {
    _lastSession = session;
  }

  @override
  Future<bool> tryClaimSession(PomodoroSession session) async {
    _lastSession = session;
    return true;
  }

  @override
  Future<void> clearSessionAsOwner() async {}

  @override
  Future<void> clearSessionIfStale({required DateTime now}) async {}

  @override
  Future<void> clearSessionIfGroupNotRunning() async {
    clearSessionIfGroupNotRunningCalls += 1;
    _lastSession = null;
    _controller.add(null);
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

class FakeSoundService implements SoundService {
  @override
  Future<void> play(SelectedSound sound, {SelectedSound? fallback}) async {}

  @override
  Future<void> dispose() async {}
}

class FakeTimeSyncService extends TimeSyncService {
  FakeTimeSyncService() : super(enabled: false);
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

TaskRunGroup _buildRunningGroup({required String id, required DateTime now}) {
  final item = _buildItem();
  final totalSeconds = item.pomodoroMinutes * 60;
  return TaskRunGroup(
    id: id,
    ownerUid: 'user-1',
    dataVersion: kCurrentDataVersion,
    integrityMode: TaskRunIntegrityMode.shared,
    tasks: [item],
    createdAt: now,
    scheduledStartTime: null,
    actualStartTime: now,
    theoreticalEndTime: now.add(Duration(seconds: totalSeconds)),
    status: TaskRunStatus.running,
    noticeMinutes: 0,
    totalTasks: 1,
    totalPomodoros: item.totalPomodoros,
    totalDurationSeconds: totalSeconds,
    updatedAt: now,
  );
}

TaskRunGroup _buildScheduledGroup({required String id, required DateTime now}) {
  final running = _buildRunningGroup(id: id, now: now);
  return running.copyWith(
    status: TaskRunStatus.scheduled,
    scheduledStartTime: now.add(const Duration(minutes: 20)),
    actualStartTime: null,
    theoreticalEndTime: now.add(const Duration(minutes: 45)),
    noticeMinutes: 0,
    updatedAt: now,
  );
}

TaskRunGroup _buildCompletedGroup({required String id, required DateTime now}) {
  final running = _buildRunningGroup(id: id, now: now);
  return running.copyWith(status: TaskRunStatus.completed, updatedAt: now);
}

TaskRunGroup _buildCanceledGroup({required String id, required DateTime now}) {
  final running = _buildRunningGroup(id: id, now: now);
  return running.copyWith(
    status: TaskRunStatus.canceled,
    canceledReason: TaskRunCanceledReason.user,
    updatedAt: now,
  );
}

PomodoroTask _buildTask({
  required String id,
  required String name,
  required DateTime now,
}) {
  return PomodoroTask(
    id: id,
    name: name,
    dataVersion: kCurrentDataVersion,
    pomodoroMinutes: 25,
    shortBreakMinutes: 5,
    longBreakMinutes: 15,
    totalPomodoros: 1,
    longBreakInterval: 1,
    order: 0,
    startSound: const SelectedSound.builtIn('default_chime'),
    startBreakSound: const SelectedSound.builtIn('default_chime_break'),
    finishTaskSound: const SelectedSound.builtIn('default_chime_finish'),
    createdAt: now,
    updatedAt: now,
  );
}

class _PlanningResultRoute extends StatefulWidget {
  const _PlanningResultRoute({required this.result});

  final TaskGroupPlanningResult? result;

  @override
  State<_PlanningResultRoute> createState() => _PlanningResultRouteState();
}

class _PlanningResultRouteState extends State<_PlanningResultRoute> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pop(widget.result);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

PomodoroSession _buildRunningSession({
  required String groupId,
  required String ownerDeviceId,
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
    ownerDeviceId: ownerDeviceId,
    status: PomodoroStatus.pomodoroRunning,
    phase: PomodoroPhase.pomodoro,
    currentPomodoro: 1,
    totalPomodoros: 1,
    phaseDurationSeconds: 25 * 60,
    remainingSeconds: 60,
    accumulatedPausedSeconds: 0,
    phaseStartedAt: now.subtract(const Duration(minutes: 24)),
    currentTaskStartedAt: now.subtract(const Duration(minutes: 24)),
    pausedAt: null,
    lastUpdatedAt: now,
    finishedAt: null,
    pauseReason: null,
  );
}

Future<void> _pumpTimerScreen({
  required WidgetTester tester,
  required ProviderContainer container,
  required String groupId,
}) async {
  final router = GoRouter(
    initialLocation: '/timer/$groupId',
    routes: [
      GoRoute(
        path: '/timer/:id',
        builder: (context, state) {
          return TimerScreen(groupId: state.pathParameters['id']!);
        },
      ),
      GoRoute(
        path: '/groups',
        builder: (_, __) => const Scaffold(body: Text('groups-screen')),
      ),
      GoRoute(
        path: '/tasks',
        builder: (_, __) => const Scaffold(body: Text('tasks-screen')),
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
}

Future<void> _pumpTaskListScreen({
  required WidgetTester tester,
  required ProviderContainer container,
  TaskGroupPlanningResult? planningResult,
  Widget Function(String groupId)? timerBuilder,
}) async {
  final router = GoRouter(
    initialLocation: '/tasks',
    routes: [
      GoRoute(path: '/tasks', builder: (_, __) => const TaskListScreen()),
      GoRoute(
        path: '/tasks/plan',
        builder: (_, __) => _PlanningResultRoute(result: planningResult),
      ),
      GoRoute(
        path: '/groups',
        builder: (_, __) => const Scaffold(body: Text('groups-screen')),
      ),
      GoRoute(path: '/login', builder: (_, __) => const SizedBox.shrink()),
      GoRoute(path: '/settings', builder: (_, __) => const SizedBox.shrink()),
      GoRoute(
        path: '/timer/:id',
        builder: (context, state) {
          final groupId = state.pathParameters['id']!;
          final builder = timerBuilder;
          if (builder != null) return builder(groupId);
          return TimerScreen(groupId: groupId);
        },
      ),
    ],
  );

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pump(const Duration(milliseconds: 200));
}

Future<void> _pumpGroupsHubScreen({
  required WidgetTester tester,
  required ProviderContainer container,
  Widget Function(String groupId)? timerBuilder,
}) async {
  final router = GoRouter(
    initialLocation: '/groups',
    routes: [
      GoRoute(path: '/groups', builder: (_, __) => const GroupsHubScreen()),
      GoRoute(
        path: '/tasks',
        builder: (_, __) => const Scaffold(body: Text('tasks-screen')),
      ),
      GoRoute(
        path: '/timer/:id',
        builder: (context, state) {
          final groupId = state.pathParameters['id']!;
          final builder = timerBuilder;
          if (builder != null) return builder(groupId);
          return TimerScreen(groupId: groupId);
        },
      ),
    ],
  );

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pump(const Duration(milliseconds: 200));
}

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  int maxTicks = 40,
}) async {
  for (var i = 0; i < maxTicks; i++) {
    if (finder.evaluate().isNotEmpty) return;
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _dragUntilFound(
  WidgetTester tester, {
  required Finder scrollable,
  required Finder target,
  int maxDrags = 8,
}) async {
  for (var i = 0; i < maxDrags; i++) {
    if (target.evaluate().isNotEmpty) return;
    await tester.drag(scrollable, const Offset(0, -320));
    await tester.pump(const Duration(milliseconds: 200));
  }
}

void main() {
  testWidgets(
    'owner sees completion modal and navigates to Groups Hub after confirming',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final now = DateTime.now();
      final deviceInfo = DeviceInfoService.ephemeral();
      final group = _buildRunningGroup(id: 'owner-completion-group', now: now);

      final groupRepo = FakeTaskRunGroupRepository()..seed(group);
      final sessionRepo = FakePomodoroSessionRepository(
        _buildRunningSession(
          groupId: group.id,
          ownerDeviceId: deviceInfo.deviceId,
          now: now,
        ),
      );
      final appModeService = AppModeService.memory();
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
          timeSyncServiceProvider.overrideWithValue(FakeTimeSyncService()),
        ],
      );
      try {
        await container.read(appModeProvider.notifier).setAccount();
        await _pumpTimerScreen(
          tester: tester,
          container: container,
          groupId: group.id,
        );

        groupRepo.emit(
          group.copyWith(
            status: TaskRunStatus.completed,
            updatedAt: now.add(const Duration(seconds: 2)),
          ),
        );
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.text('✅ Tasks group completed'), findsOneWidget);
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();

        expect(find.text('groups-screen'), findsOneWidget);

        container.dispose();
        sessionRepo.dispose();
        groupRepo.dispose();
        disposed = true;
      } finally {
        if (!disposed) {
          container.dispose();
          sessionRepo.dispose();
          groupRepo.dispose();
        }
      }
    },
  );

  testWidgets(
    'mirror sees completion modal and navigates to Groups Hub after confirming',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final now = DateTime.now();
      final deviceInfo = DeviceInfoService.ephemeral();
      final group = _buildRunningGroup(id: 'mirror-completion-group', now: now);

      final groupRepo = FakeTaskRunGroupRepository()..seed(group);
      final sessionRepo = FakePomodoroSessionRepository(
        _buildRunningSession(
          groupId: group.id,
          ownerDeviceId: 'remote-owner-device',
          now: now,
        ),
      );
      final appModeService = AppModeService.memory();
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
          timeSyncServiceProvider.overrideWithValue(FakeTimeSyncService()),
        ],
      );
      try {
        await container.read(appModeProvider.notifier).setAccount();
        await _pumpTimerScreen(
          tester: tester,
          container: container,
          groupId: group.id,
        );

        final vm = container.read(pomodoroViewModelProvider.notifier);
        expect(vm.isMirrorMode, isTrue);

        groupRepo.emit(
          group.copyWith(
            status: TaskRunStatus.completed,
            updatedAt: now.add(const Duration(seconds: 2)),
          ),
        );
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.text('✅ Tasks group completed'), findsOneWidget);
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();

        expect(find.text('groups-screen'), findsOneWidget);

        container.dispose();
        sessionRepo.dispose();
        groupRepo.dispose();
        disposed = true;
      } finally {
        if (!disposed) {
          container.dispose();
          sessionRepo.dispose();
          groupRepo.dispose();
        }
      }
    },
  );

  testWidgets(
    'cancel requests confirmation and navigates to Groups Hub only after confirm',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final now = DateTime.now();
      final deviceInfo = DeviceInfoService.ephemeral();
      final group = _buildRunningGroup(id: 'owner-cancel-group', now: now);

      final groupRepo = FakeTaskRunGroupRepository()..seed(group);
      final sessionRepo = FakePomodoroSessionRepository(
        _buildRunningSession(
          groupId: group.id,
          ownerDeviceId: deviceInfo.deviceId,
          now: now,
        ),
      );
      final appModeService = AppModeService.memory();
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
          timeSyncServiceProvider.overrideWithValue(FakeTimeSyncService()),
        ],
      );
      try {
        await container.read(appModeProvider.notifier).setAccount();
        await _pumpTimerScreen(
          tester: tester,
          container: container,
          groupId: group.id,
        );

        await tester.tap(find.widgetWithText(ElevatedButton, 'Cancel'));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('Cancel group?'), findsOneWidget);
        expect(find.text('Keep running'), findsOneWidget);
        expect(find.text('Cancel group'), findsOneWidget);

        await tester.tap(find.text('Keep running'));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('Cancel group?'), findsNothing);
        expect(find.text('groups-screen'), findsNothing);

        await tester.tap(find.widgetWithText(ElevatedButton, 'Cancel'));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(find.text('Cancel group'));
        await _pumpUntilFound(tester, find.text('groups-screen'));

        expect(find.text('groups-screen'), findsOneWidget);
        final canceled = await groupRepo.getById(group.id);
        expect(canceled?.status, TaskRunStatus.canceled);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 100));
        container.dispose();
        sessionRepo.dispose();
        groupRepo.dispose();
        disposed = true;
      } finally {
        if (!disposed) {
          container.dispose();
          sessionRepo.dispose();
          groupRepo.dispose();
        }
      }
    },
  );

  testWidgets('Run Mode planned-groups indicator opens Groups Hub', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final now = DateTime.now();
    final deviceInfo = DeviceInfoService.ephemeral();
    final running = _buildRunningGroup(id: 'run-indicator-group', now: now);
    final scheduled = _buildScheduledGroup(
      id: 'run-indicator-scheduled',
      now: now,
    );

    final groupRepo = FakeTaskRunGroupRepository()
      ..seed(running)
      ..seed(scheduled);
    final sessionRepo = FakePomodoroSessionRepository(
      _buildRunningSession(
        groupId: running.id,
        ownerDeviceId: deviceInfo.deviceId,
        now: now,
      ),
    );
    final appModeService = AppModeService.memory();
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
        timeSyncServiceProvider.overrideWithValue(FakeTimeSyncService()),
      ],
    );
    try {
      await container.read(appModeProvider.notifier).setAccount();
      await _pumpTimerScreen(
        tester: tester,
        container: container,
        groupId: running.id,
      );

      await tester.tap(find.byTooltip('Planned groups'));
      await _pumpUntilFound(tester, find.text('groups-screen'));
      expect(find.text('groups-screen'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
      container.dispose();
      sessionRepo.dispose();
      groupRepo.dispose();
      disposed = true;
    } finally {
      if (!disposed) {
        container.dispose();
        sessionRepo.dispose();
        groupRepo.dispose();
      }
    }
  });

  testWidgets('Task List Groups Hub CTA opens Groups Hub', (tester) async {
    SharedPreferences.setMockInitialValues({
      'linux_sync_notice_seen': true,
      'web_local_notice_seen': true,
    });
    final groupRepo = FakeTaskRunGroupRepository();
    final sessionRepo = FakePomodoroSessionRepository(null);
    final appModeService = AppModeService.memory();
    var disposed = false;

    final container = ProviderContainer(
      overrides: [
        firebaseAuthServiceProvider.overrideWithValue(StubAuthService()),
        firestoreServiceProvider.overrideWithValue(StubFirestoreService()),
        taskRunGroupRepositoryProvider.overrideWithValue(groupRepo),
        pomodoroSessionRepositoryProvider.overrideWithValue(sessionRepo),
        appModeServiceProvider.overrideWithValue(appModeService),
        soundServiceProvider.overrideWithValue(FakeSoundService()),
        timeSyncServiceProvider.overrideWithValue(FakeTimeSyncService()),
      ],
    );
    try {
      await _pumpTaskListScreen(tester: tester, container: container);
      await _pumpUntilFound(tester, find.text('View Groups Hub'));
      expect(find.text('View Groups Hub'), findsOneWidget);

      await tester.tap(find.text('View Groups Hub'));
      await _pumpUntilFound(tester, find.text('groups-screen'));
      expect(find.text('groups-screen'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
      container.dispose();
      sessionRepo.dispose();
      groupRepo.dispose();
      disposed = true;
    } finally {
      if (!disposed) {
        container.dispose();
        sessionRepo.dispose();
        groupRepo.dispose();
      }
    }
  });

  testWidgets(
    'Task List falls back to running group banner when active session is null in Local Mode',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'linux_sync_notice_seen': true,
        'web_local_notice_seen': true,
      });
      final now = DateTime.now();
      final running = _buildRunningGroup(
        id: 'local-fallback-running',
        now: now,
      ).copyWith(updatedAt: now);
      final groupRepo = FakeTaskRunGroupRepository()..seed(running);
      final sessionRepo = FakePomodoroSessionRepository(null);
      final appModeService = AppModeService.memory();
      var disposed = false;

      final container = ProviderContainer(
        overrides: [
          firebaseAuthServiceProvider.overrideWithValue(StubAuthService()),
          firestoreServiceProvider.overrideWithValue(StubFirestoreService()),
          taskRunGroupRepositoryProvider.overrideWithValue(groupRepo),
          pomodoroSessionRepositoryProvider.overrideWithValue(sessionRepo),
          appModeServiceProvider.overrideWithValue(appModeService),
          soundServiceProvider.overrideWithValue(FakeSoundService()),
          timeSyncServiceProvider.overrideWithValue(FakeTimeSyncService()),
        ],
      );
      try {
        await container.read(appModeProvider.notifier).setLocal();
        await _pumpTaskListScreen(
          tester: tester,
          container: container,
          timerBuilder: (groupId) =>
              Scaffold(body: Text('timer-screen-$groupId')),
        );
        await _pumpUntilFound(tester, find.text('Group Running'));
        expect(find.text('Group Running'), findsOneWidget);
        expect(find.text(running.tasks.first.name), findsOneWidget);
        expect(
          find.widgetWithText(ElevatedButton, 'Open Run Mode'),
          findsOneWidget,
        );

        await tester.tap(find.widgetWithText(ElevatedButton, 'Open Run Mode'));
        await _pumpUntilFound(tester, find.text('timer-screen-${running.id}'));
        expect(find.text('timer-screen-${running.id}'), findsOneWidget);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 100));
        container.dispose();
        sessionRepo.dispose();
        groupRepo.dispose();
        disposed = true;
      } finally {
        if (!disposed) {
          container.dispose();
          sessionRepo.dispose();
          groupRepo.dispose();
        }
      }
    },
  );

  testWidgets('Task List pre-run banner opens Timer via Open Pre-Run', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'linux_sync_notice_seen': true,
      'web_local_notice_seen': true,
    });
    final now = DateTime.now();
    final preRunGroup =
        _buildScheduledGroup(id: 'task-list-pre-run-group', now: now).copyWith(
          scheduledStartTime: now.add(const Duration(minutes: 5)),
          theoreticalEndTime: now.add(const Duration(minutes: 30)),
          noticeMinutes: 10,
        );
    final groupRepo = FakeTaskRunGroupRepository()..seed(preRunGroup);
    final sessionRepo = FakePomodoroSessionRepository(null);
    final appModeService = AppModeService.memory();
    var disposed = false;

    final container = ProviderContainer(
      overrides: [
        firebaseAuthServiceProvider.overrideWithValue(StubAuthService()),
        firestoreServiceProvider.overrideWithValue(StubFirestoreService()),
        taskRunGroupRepositoryProvider.overrideWithValue(groupRepo),
        pomodoroSessionRepositoryProvider.overrideWithValue(sessionRepo),
        appModeServiceProvider.overrideWithValue(appModeService),
        soundServiceProvider.overrideWithValue(FakeSoundService()),
        timeSyncServiceProvider.overrideWithValue(FakeTimeSyncService()),
      ],
    );
    try {
      await _pumpTaskListScreen(
        tester: tester,
        container: container,
        timerBuilder: (groupId) =>
            Scaffold(body: Text('timer-screen-$groupId')),
      );
      await _pumpUntilFound(
        tester,
        find.textContaining('Pre-Run active · Starts in'),
      );
      expect(
        find.widgetWithText(ElevatedButton, 'Open Pre-Run'),
        findsOneWidget,
      );

      await tester.tap(find.widgetWithText(ElevatedButton, 'Open Pre-Run'));
      await _pumpUntilFound(
        tester,
        find.text('timer-screen-${preRunGroup.id}'),
      );
      expect(find.text('timer-screen-${preRunGroup.id}'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
      container.dispose();
      sessionRepo.dispose();
      groupRepo.dispose();
      disposed = true;
    } finally {
      if (!disposed) {
        container.dispose();
        sessionRepo.dispose();
        groupRepo.dispose();
      }
    }
  });

  testWidgets(
    'Groups Hub shows Open Pre-Run action for active pre-run scheduled group',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final now = DateTime.now();
      final preRunGroup =
          _buildScheduledGroup(
            id: 'groups-hub-pre-run-group',
            now: now,
          ).copyWith(
            scheduledStartTime: now.add(const Duration(minutes: 5)),
            theoreticalEndTime: now.add(const Duration(minutes: 30)),
            noticeMinutes: 10,
          );
      final groupRepo = FakeTaskRunGroupRepository()..seed(preRunGroup);
      final sessionRepo = FakePomodoroSessionRepository(null);
      final appModeService = AppModeService.memory();
      var disposed = false;

      final container = ProviderContainer(
        overrides: [
          firebaseAuthServiceProvider.overrideWithValue(StubAuthService()),
          firestoreServiceProvider.overrideWithValue(StubFirestoreService()),
          taskRunGroupRepositoryProvider.overrideWithValue(groupRepo),
          pomodoroSessionRepositoryProvider.overrideWithValue(sessionRepo),
          appModeServiceProvider.overrideWithValue(appModeService),
          soundServiceProvider.overrideWithValue(FakeSoundService()),
          timeSyncServiceProvider.overrideWithValue(FakeTimeSyncService()),
        ],
      );
      try {
        await _pumpGroupsHubScreen(
          tester: tester,
          container: container,
          timerBuilder: (groupId) =>
              Scaffold(body: Text('timer-screen-$groupId')),
        );
        await _pumpUntilFound(tester, find.text('Open Pre-Run'));
        expect(find.text('Open Pre-Run'), findsOneWidget);
        expect(find.text('Start now'), findsNothing);

        await tester.tap(find.text('Open Pre-Run'));
        await _pumpUntilFound(
          tester,
          find.text('timer-screen-${preRunGroup.id}'),
        );
        expect(find.text('timer-screen-${preRunGroup.id}'), findsOneWidget);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 100));
        container.dispose();
        sessionRepo.dispose();
        groupRepo.dispose();
        disposed = true;
      } finally {
        if (!disposed) {
          container.dispose();
          sessionRepo.dispose();
          groupRepo.dispose();
        }
      }
    },
  );

  testWidgets(
    'Groups Hub hides scheduled and pre-run metadata for start-now scheduled groups',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final now = DateTime.now();
      final startNowGroup =
          _buildScheduledGroup(
            id: 'groups-hub-start-now-group',
            now: now,
          ).copyWith(
            scheduledStartTime: null,
            theoreticalEndTime: now.add(const Duration(minutes: 30)),
            noticeMinutes: 10,
          );
      final groupRepo = FakeTaskRunGroupRepository()..seed(startNowGroup);
      final sessionRepo = FakePomodoroSessionRepository(null);
      final appModeService = AppModeService.memory();
      var disposed = false;

      final container = ProviderContainer(
        overrides: [
          firebaseAuthServiceProvider.overrideWithValue(StubAuthService()),
          firestoreServiceProvider.overrideWithValue(StubFirestoreService()),
          taskRunGroupRepositoryProvider.overrideWithValue(groupRepo),
          pomodoroSessionRepositoryProvider.overrideWithValue(sessionRepo),
          appModeServiceProvider.overrideWithValue(appModeService),
          soundServiceProvider.overrideWithValue(FakeSoundService()),
          timeSyncServiceProvider.overrideWithValue(FakeTimeSyncService()),
        ],
      );
      try {
        await _pumpGroupsHubScreen(tester: tester, container: container);
        await _pumpUntilFound(tester, find.text('Start now'));

        expect(find.text('Start now'), findsOneWidget);
        expect(find.text('Open Pre-Run'), findsNothing);
        expect(find.text('Pre-Run'), findsNothing);

        await tester.tap(find.text('Test task').first);
        await _pumpUntilFound(tester, find.text('Group summary'));
        expect(find.text('Scheduled start'), findsNothing);
        expect(find.text('Pre-Run'), findsNothing);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 100));
        container.dispose();
        sessionRepo.dispose();
        groupRepo.dispose();
        disposed = true;
      } finally {
        if (!disposed) {
          container.dispose();
          sessionRepo.dispose();
          groupRepo.dispose();
        }
      }
    },
  );

  testWidgets(
    'Groups Hub summary modal shows timing totals and task breakdown',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final now = DateTime.now();
      final firstItem = _buildItem();
      const secondItem = TaskRunItem(
        sourceTaskId: 'task-2',
        name: 'Email Batch',
        presetId: null,
        pomodoroMinutes: 35,
        shortBreakMinutes: 7,
        longBreakMinutes: 20,
        totalPomodoros: 2,
        longBreakInterval: 2,
        startSound: SelectedSound.builtIn('default_chime'),
        startBreakSound: SelectedSound.builtIn('default_chime_break'),
        finishTaskSound: SelectedSound.builtIn('default_chime_finish'),
      );
      final detailedGroup = _buildScheduledGroup(
        id: 'groups-hub-summary-details-group',
        now: now,
      ).copyWith(
        tasks: [firstItem, secondItem],
        totalTasks: 2,
        totalPomodoros: 3,
        totalDurationSeconds: 5400,
        noticeMinutes: 10,
        theoreticalEndTime: now.add(const Duration(minutes: 90)),
      );
      final groupRepo = FakeTaskRunGroupRepository()..seed(detailedGroup);
      final sessionRepo = FakePomodoroSessionRepository(null);
      final appModeService = AppModeService.memory();
      var disposed = false;

      final container = ProviderContainer(
        overrides: [
          firebaseAuthServiceProvider.overrideWithValue(StubAuthService()),
          firestoreServiceProvider.overrideWithValue(StubFirestoreService()),
          taskRunGroupRepositoryProvider.overrideWithValue(groupRepo),
          pomodoroSessionRepositoryProvider.overrideWithValue(sessionRepo),
          appModeServiceProvider.overrideWithValue(appModeService),
          soundServiceProvider.overrideWithValue(FakeSoundService()),
          timeSyncServiceProvider.overrideWithValue(FakeTimeSyncService()),
        ],
      );
      try {
        await _pumpGroupsHubScreen(tester: tester, container: container);
        await _pumpUntilFound(tester, find.text('Test task'));

        await tester.tap(find.text('Test task').first);
        await _pumpUntilFound(tester, find.text('Group summary'));

        final dialog = find.byType(AlertDialog);
        expect(
          find.descendant(of: dialog, matching: find.text('Timing')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: dialog, matching: find.text('Totals')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: dialog, matching: find.text('Tasks')),
          findsNWidgets(2),
        );
        expect(
          find.descendant(of: dialog, matching: find.text('Scheduled start')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: dialog, matching: find.text('Pre-Run')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: dialog, matching: find.text('Actual start')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: dialog, matching: find.text('End')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: dialog, matching: find.text('Total time')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: dialog, matching: find.text('Pomodoros')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: dialog, matching: find.text('Email Batch')),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: dialog,
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is Text &&
                  widget.data != null &&
                  widget.data!.contains('min starts at'),
            ),
          ),
          findsOneWidget,
        );

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 100));
        container.dispose();
        sessionRepo.dispose();
        groupRepo.dispose();
        disposed = true;
      } finally {
        if (!disposed) {
          container.dispose();
          sessionRepo.dispose();
          groupRepo.dispose();
        }
      }
    },
  );

  testWidgets(
    'Integrity warning options show exact source task names for each structure',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'linux_sync_notice_seen': true,
        'web_local_notice_seen': true,
      });
      final now = DateTime.now();
      final taskRepo = InMemoryTaskRepository();
      await taskRepo.save(
        _buildTask(id: 'integrity-source-a', name: 'Deep Work', now: now),
      );
      await taskRepo.save(
        _buildTask(
          id: 'integrity-source-b',
          name: 'Email Batch',
          now: now,
        ).copyWith(
          pomodoroMinutes: 35,
          shortBreakMinutes: 7,
          longBreakMinutes: 20,
          longBreakInterval: 2,
          order: 1,
          updatedAt: now.add(const Duration(seconds: 1)),
        ),
      );
      final groupRepo = FakeTaskRunGroupRepository();
      final sessionRepo = FakePomodoroSessionRepository(null);
      final appModeService = AppModeService.memory();
      var disposed = false;

      final container = ProviderContainer(
        overrides: [
          firebaseAuthServiceProvider.overrideWithValue(StubAuthService()),
          firestoreServiceProvider.overrideWithValue(StubFirestoreService()),
          taskRepositoryProvider.overrideWithValue(taskRepo),
          taskRunGroupRepositoryProvider.overrideWithValue(groupRepo),
          pomodoroSessionRepositoryProvider.overrideWithValue(sessionRepo),
          appModeServiceProvider.overrideWithValue(appModeService),
          soundServiceProvider.overrideWithValue(FakeSoundService()),
          timeSyncServiceProvider.overrideWithValue(FakeTimeSyncService()),
        ],
      );
      try {
        await _pumpTaskListScreen(tester: tester, container: container);
        await _pumpUntilFound(tester, find.text('Deep Work'));
        await _pumpUntilFound(tester, find.text('Email Batch'));

        await tester.tap(find.text('Deep Work'));
        await tester.pump(const Duration(milliseconds: 120));
        await tester.tap(find.text('Email Batch'));
        await tester.pump(const Duration(milliseconds: 120));

        await tester.tap(find.widgetWithText(ElevatedButton, 'Next'));
        await _pumpUntilFound(tester, find.text('Pomodoro integrity warning'));

        final dialog = find.byType(AlertDialog);
        expect(
          find.descendant(of: dialog, matching: find.text('Used by:')),
          findsNWidgets(2),
        );
        expect(
          find.descendant(of: dialog, matching: find.text('Deep Work')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: dialog, matching: find.text('Email Batch')),
          findsOneWidget,
        );

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 100));
        container.dispose();
        sessionRepo.dispose();
        groupRepo.dispose();
        disposed = true;
      } finally {
        if (!disposed) {
          container.dispose();
          sessionRepo.dispose();
          groupRepo.dispose();
        }
      }
    },
  );

  testWidgets(
    'Integrity warning lists one visual option per structure and shows default preset badge',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'linux_sync_notice_seen': true,
        'web_local_notice_seen': true,
      });
      final now = DateTime.now();
      final taskRepo = InMemoryTaskRepository();
      await taskRepo.save(
        _buildTask(id: 'integrity-structure-a1', name: 'Deep Work', now: now),
      );
      await taskRepo.save(
        _buildTask(
          id: 'integrity-structure-a2',
          name: 'Planning',
          now: now,
        ).copyWith(order: 1, updatedAt: now.add(const Duration(seconds: 1))),
      );
      await taskRepo.save(
        _buildTask(
          id: 'integrity-structure-b1',
          name: 'Email Batch',
          now: now,
        ).copyWith(
          pomodoroMinutes: 35,
          shortBreakMinutes: 7,
          longBreakMinutes: 20,
          longBreakInterval: 2,
          order: 2,
          updatedAt: now.add(const Duration(seconds: 2)),
        ),
      );
      final presetRepo = InMemoryPomodoroPresetRepository();
      await presetRepo.save(
        PomodoroPreset.classicDefault(
          id: 'default-preset-rvp016',
          now: now,
          name: 'Focus Default',
        ),
      );
      final groupRepo = FakeTaskRunGroupRepository();
      final sessionRepo = FakePomodoroSessionRepository(null);
      final appModeService = AppModeService.memory();
      var disposed = false;

      final container = ProviderContainer(
        overrides: [
          firebaseAuthServiceProvider.overrideWithValue(StubAuthService()),
          firestoreServiceProvider.overrideWithValue(StubFirestoreService()),
          taskRepositoryProvider.overrideWithValue(taskRepo),
          presetRepositoryProvider.overrideWithValue(presetRepo),
          taskRunGroupRepositoryProvider.overrideWithValue(groupRepo),
          pomodoroSessionRepositoryProvider.overrideWithValue(sessionRepo),
          appModeServiceProvider.overrideWithValue(appModeService),
          soundServiceProvider.overrideWithValue(FakeSoundService()),
          timeSyncServiceProvider.overrideWithValue(FakeTimeSyncService()),
        ],
      );
      try {
        await _pumpTaskListScreen(tester: tester, container: container);
        await _pumpUntilFound(tester, find.text('Deep Work'));

        final selection = container.read(taskSelectionProvider.notifier);
        selection.toggle('integrity-structure-a1');
        selection.toggle('integrity-structure-a2');
        selection.toggle('integrity-structure-b1');
        await tester.pump(const Duration(milliseconds: 120));

        await tester.tap(find.widgetWithText(ElevatedButton, 'Next'));
        await _pumpUntilFound(tester, find.text('Pomodoro integrity warning'));

        final dialog = find.byType(AlertDialog);
        expect(
          find.descendant(of: dialog, matching: find.text('Used by:')),
          findsNWidgets(2),
        );
        expect(
          find.descendant(of: dialog, matching: find.text('Default preset')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: dialog, matching: find.text('Deep Work')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: dialog, matching: find.text('Planning')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: dialog, matching: find.text('Email Batch')),
          findsOneWidget,
        );

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 100));
        container.dispose();
        sessionRepo.dispose();
        groupRepo.dispose();
        disposed = true;
      } finally {
        if (!disposed) {
          container.dispose();
          sessionRepo.dispose();
          groupRepo.dispose();
        }
      }
    },
  );

  testWidgets(
    'Integrity warning shows clarified guidance copy and keeps default preset option below structure cards',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'linux_sync_notice_seen': true,
        'web_local_notice_seen': true,
      });
      final now = DateTime.now();
      final taskRepo = InMemoryTaskRepository();
      await taskRepo.save(
        _buildTask(id: 'integrity-copy-a1', name: 'Deep Work', now: now),
      );
      await taskRepo.save(
        _buildTask(
          id: 'integrity-copy-a2',
          name: 'Planning',
          now: now,
        ).copyWith(order: 1, updatedAt: now.add(const Duration(seconds: 1))),
      );
      await taskRepo.save(
        _buildTask(
          id: 'integrity-copy-b1',
          name: 'Email Batch',
          now: now,
        ).copyWith(
          pomodoroMinutes: 35,
          shortBreakMinutes: 7,
          longBreakMinutes: 20,
          longBreakInterval: 2,
          order: 2,
          updatedAt: now.add(const Duration(seconds: 2)),
        ),
      );
      final presetRepo = InMemoryPomodoroPresetRepository();
      await presetRepo.save(
        PomodoroPreset.classicDefault(
          id: 'default-preset-rvp018',
          now: now,
          name: 'Focus Default',
        ),
      );
      final groupRepo = FakeTaskRunGroupRepository();
      final sessionRepo = FakePomodoroSessionRepository(null);
      final appModeService = AppModeService.memory();
      var disposed = false;

      final container = ProviderContainer(
        overrides: [
          firebaseAuthServiceProvider.overrideWithValue(StubAuthService()),
          firestoreServiceProvider.overrideWithValue(StubFirestoreService()),
          taskRepositoryProvider.overrideWithValue(taskRepo),
          presetRepositoryProvider.overrideWithValue(presetRepo),
          taskRunGroupRepositoryProvider.overrideWithValue(groupRepo),
          pomodoroSessionRepositoryProvider.overrideWithValue(sessionRepo),
          appModeServiceProvider.overrideWithValue(appModeService),
          soundServiceProvider.overrideWithValue(FakeSoundService()),
          timeSyncServiceProvider.overrideWithValue(FakeTimeSyncService()),
        ],
      );
      try {
        await _pumpTaskListScreen(tester: tester, container: container);
        await _pumpUntilFound(tester, find.text('Deep Work'));

        final selection = container.read(taskSelectionProvider.notifier);
        selection.toggle('integrity-copy-a1');
        selection.toggle('integrity-copy-a2');
        selection.toggle('integrity-copy-b1');
        await tester.pump(const Duration(milliseconds: 120));

        await tester.tap(find.widgetWithText(ElevatedButton, 'Next'));
        await _pumpUntilFound(tester, find.text('Pomodoro integrity warning'));

        final dialog = find.byType(AlertDialog);
        expect(
          find.descendant(
            of: dialog,
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is Text &&
                  widget.data != null &&
                  widget.data!.contains('This group mixes Pomodoro structures.'),
            ),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: dialog,
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is Text &&
                  widget.data != null &&
                  widget.data!
                      .contains('configuration to apply to this group.'),
            ),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(of: dialog, matching: find.text('Used by:')),
          findsNWidgets(2),
        );
        final defaultPresetFinder = find.descendant(
          of: dialog,
          matching: find.text('Default preset'),
        );
        expect(defaultPresetFinder, findsOneWidget);
        final secondUsedByFinder = find
            .descendant(of: dialog, matching: find.text('Used by:'))
            .at(1);
        expect(
          tester.getTopLeft(defaultPresetFinder).dy,
          greaterThan(tester.getBottomLeft(secondUsedByFinder).dy),
        );

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 100));
        container.dispose();
        sessionRepo.dispose();
        groupRepo.dispose();
        disposed = true;
      } finally {
        if (!disposed) {
          container.dispose();
          sessionRepo.dispose();
          groupRepo.dispose();
        }
      }
    },
  );

  testWidgets('Groups Hub core sections and actions are visible', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final now = DateTime.now();
    final groupRepo = FakeTaskRunGroupRepository()
      ..seed(_buildRunningGroup(id: 'hub-running', now: now))
      ..seed(_buildScheduledGroup(id: 'hub-scheduled', now: now))
      ..seed(_buildCompletedGroup(id: 'hub-completed', now: now))
      ..seed(_buildCanceledGroup(id: 'hub-canceled', now: now));
    final sessionRepo = FakePomodoroSessionRepository(null);
    final appModeService = AppModeService.memory();
    var disposed = false;

    final container = ProviderContainer(
      overrides: [
        firebaseAuthServiceProvider.overrideWithValue(StubAuthService()),
        firestoreServiceProvider.overrideWithValue(StubFirestoreService()),
        taskRunGroupRepositoryProvider.overrideWithValue(groupRepo),
        pomodoroSessionRepositoryProvider.overrideWithValue(sessionRepo),
        appModeServiceProvider.overrideWithValue(appModeService),
        soundServiceProvider.overrideWithValue(FakeSoundService()),
        timeSyncServiceProvider.overrideWithValue(FakeTimeSyncService()),
      ],
    );
    try {
      await container.read(appModeProvider.notifier).setAccount();
      await _pumpGroupsHubScreen(tester: tester, container: container);

      expect(find.text('Groups Hub'), findsOneWidget);
      expect(find.text('Go to Task List'), findsOneWidget);
      expect(find.text('Running / Paused'), findsOneWidget);
      expect(find.text('Scheduled'), findsOneWidget);
      expect(find.text('Open Run Mode'), findsOneWidget);
      expect(find.text('Start now'), findsOneWidget);
      expect(find.text('Cancel schedule'), findsOneWidget);
      final hubList = find.byType(ListView).first;
      await _dragUntilFound(
        tester,
        scrollable: hubList,
        target: find.text('Completed'),
      );
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Run again'), findsOneWidget);
      await _dragUntilFound(
        tester,
        scrollable: hubList,
        target: find.text('Canceled'),
      );
      expect(find.text('Canceled'), findsWidgets);
      expect(find.text('Re-plan group'), findsOneWidget);

      await tester.tap(find.text('Go to Task List'));
      await _pumpUntilFound(tester, find.text('tasks-screen'));
      expect(find.text('tasks-screen'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
      container.dispose();
      sessionRepo.dispose();
      groupRepo.dispose();
      disposed = true;
    } finally {
      if (!disposed) {
        container.dispose();
        sessionRepo.dispose();
        groupRepo.dispose();
      }
    }
  });

  testWidgets('Task List clears stale active session when group is completed', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'linux_sync_notice_seen': true,
      'web_local_notice_seen': true,
    });
    final now = DateTime.now();
    final deviceInfo = DeviceInfoService.ephemeral();
    final completed = _buildCompletedGroup(
      id: 'stale-completed-group',
      now: now,
    );
    final groupRepo = FakeTaskRunGroupRepository()..seed(completed);
    final sessionRepo = FakePomodoroSessionRepository(
      _buildRunningSession(
        groupId: completed.id,
        ownerDeviceId: deviceInfo.deviceId,
        now: now,
      ),
    );
    final appModeService = AppModeService.memory();
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
        timeSyncServiceProvider.overrideWithValue(FakeTimeSyncService()),
      ],
    );
    try {
      await _pumpTaskListScreen(tester: tester, container: container);
      await tester.pump(const Duration(milliseconds: 300));

      expect(sessionRepo.clearSessionIfGroupNotRunningCalls, 1);
      expect(find.text('Group completed.'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
      container.dispose();
      sessionRepo.dispose();
      groupRepo.dispose();
      disposed = true;
    } finally {
      if (!disposed) {
        container.dispose();
        sessionRepo.dispose();
        groupRepo.dispose();
      }
    }
  });

  testWidgets('Task List clears stale active session when group is canceled', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'linux_sync_notice_seen': true,
      'web_local_notice_seen': true,
    });
    final now = DateTime.now();
    final deviceInfo = DeviceInfoService.ephemeral();
    final canceled = _buildCanceledGroup(id: 'stale-canceled-group', now: now);
    final groupRepo = FakeTaskRunGroupRepository()..seed(canceled);
    final sessionRepo = FakePomodoroSessionRepository(
      _buildRunningSession(
        groupId: canceled.id,
        ownerDeviceId: deviceInfo.deviceId,
        now: now,
      ),
    );
    final appModeService = AppModeService.memory();
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
        timeSyncServiceProvider.overrideWithValue(FakeTimeSyncService()),
      ],
    );
    try {
      await _pumpTaskListScreen(tester: tester, container: container);
      await tester.pump(const Duration(milliseconds: 300));

      expect(sessionRepo.clearSessionIfGroupNotRunningCalls, 1);
      expect(find.text('Group ended.'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
      container.dispose();
      sessionRepo.dispose();
      groupRepo.dispose();
      disposed = true;
    } finally {
      if (!disposed) {
        container.dispose();
        sessionRepo.dispose();
        groupRepo.dispose();
      }
    }
  });

  testWidgets(
    'Task List blocks scheduling when pre-run window overlaps a running group',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'linux_sync_notice_seen': true,
        'web_local_notice_seen': true,
      });
      final now = DateTime.now();
      final taskRepo = InMemoryTaskRepository();
      await taskRepo.save(
        _buildTask(
          id: 'schedule-task-running',
          name: 'Schedule Task Running',
          now: now,
        ),
      );
      final blockingRunning = _buildRunningGroup(
        id: 'blocking-running-group',
        now: now,
      ).copyWith(theoreticalEndTime: now.add(const Duration(minutes: 50)));
      final groupRepo = FakeTaskRunGroupRepository()..seed(blockingRunning);
      final sessionRepo = FakePomodoroSessionRepository(null);
      final appModeService = AppModeService.memory();
      var disposed = false;

      final container = ProviderContainer(
        overrides: [
          firebaseAuthServiceProvider.overrideWithValue(StubAuthService()),
          firestoreServiceProvider.overrideWithValue(StubFirestoreService()),
          taskRepositoryProvider.overrideWithValue(taskRepo),
          taskRunGroupRepositoryProvider.overrideWithValue(groupRepo),
          pomodoroSessionRepositoryProvider.overrideWithValue(sessionRepo),
          appModeServiceProvider.overrideWithValue(appModeService),
          soundServiceProvider.overrideWithValue(FakeSoundService()),
          timeSyncServiceProvider.overrideWithValue(FakeTimeSyncService()),
        ],
      );
      final planningResult = TaskGroupPlanningResult(
        option: TaskGroupPlanOption.scheduleStart,
        items: [_buildItem()],
        noticeMinutes: 15,
        scheduledStart: now.add(const Duration(minutes: 60)),
      );
      try {
        await _pumpTaskListScreen(
          tester: tester,
          container: container,
          planningResult: planningResult,
        );
        await _pumpUntilFound(tester, find.text('Schedule Task Running'));
        await tester.tap(find.text('Schedule Task Running'));
        await tester.pump(const Duration(milliseconds: 150));
        await tester.tap(find.widgetWithText(ElevatedButton, 'Next'));
        await tester.pump(const Duration(milliseconds: 250));

        await _pumpUntilFound(
          tester,
          find.textContaining(
            "doesn't leave enough pre-run space because another group is still running",
          ),
        );
        expect(
          find.textContaining(
            "doesn't leave enough pre-run space because another group is still running",
          ),
          findsOneWidget,
        );
        expect(await groupRepo.getAll(), hasLength(1));

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 100));
        container.dispose();
        sessionRepo.dispose();
        groupRepo.dispose();
        disposed = true;
      } finally {
        if (!disposed) {
          container.dispose();
          sessionRepo.dispose();
          groupRepo.dispose();
        }
      }
    },
  );

  testWidgets(
    'Task List blocks scheduling when pre-run window overlaps an earlier scheduled group',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'linux_sync_notice_seen': true,
        'web_local_notice_seen': true,
      });
      final now = DateTime.now();
      final taskRepo = InMemoryTaskRepository();
      await taskRepo.save(
        _buildTask(
          id: 'schedule-task-scheduled',
          name: 'Schedule Task Scheduled',
          now: now,
        ),
      );
      final blockingScheduled =
          _buildScheduledGroup(
            id: 'blocking-scheduled-group',
            now: now,
          ).copyWith(
            scheduledStartTime: now.add(const Duration(minutes: 21)),
            theoreticalEndTime: now.add(const Duration(minutes: 46)),
          );
      final groupRepo = FakeTaskRunGroupRepository()..seed(blockingScheduled);
      final sessionRepo = FakePomodoroSessionRepository(null);
      final appModeService = AppModeService.memory();
      var disposed = false;

      final container = ProviderContainer(
        overrides: [
          firebaseAuthServiceProvider.overrideWithValue(StubAuthService()),
          firestoreServiceProvider.overrideWithValue(StubFirestoreService()),
          taskRepositoryProvider.overrideWithValue(taskRepo),
          taskRunGroupRepositoryProvider.overrideWithValue(groupRepo),
          pomodoroSessionRepositoryProvider.overrideWithValue(sessionRepo),
          appModeServiceProvider.overrideWithValue(appModeService),
          soundServiceProvider.overrideWithValue(FakeSoundService()),
          timeSyncServiceProvider.overrideWithValue(FakeTimeSyncService()),
        ],
      );
      final planningResult = TaskGroupPlanningResult(
        option: TaskGroupPlanOption.scheduleStart,
        items: [_buildItem()],
        noticeMinutes: 15,
        scheduledStart: now.add(const Duration(minutes: 60)),
      );
      try {
        await _pumpTaskListScreen(
          tester: tester,
          container: container,
          planningResult: planningResult,
        );
        await _pumpUntilFound(tester, find.text('Schedule Task Scheduled'));
        await tester.tap(find.text('Schedule Task Scheduled'));
        await tester.pump(const Duration(milliseconds: 150));
        await tester.tap(find.widgetWithText(ElevatedButton, 'Next'));
        await tester.pump(const Duration(milliseconds: 250));

        await _pumpUntilFound(
          tester,
          find.textContaining(
            "doesn't leave enough pre-run space because another group is scheduled earlier",
          ),
        );
        expect(
          find.textContaining(
            "doesn't leave enough pre-run space because another group is scheduled earlier",
          ),
          findsOneWidget,
        );
        expect(await groupRepo.getAll(), hasLength(1));

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 100));
        container.dispose();
        sessionRepo.dispose();
        groupRepo.dispose();
        disposed = true;
      } finally {
        if (!disposed) {
          container.dispose();
          sessionRepo.dispose();
          groupRepo.dispose();
        }
      }
    },
  );
}
