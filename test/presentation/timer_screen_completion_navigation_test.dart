import 'dart:async';

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
import 'package:focus_interval/data/services/firebase_auth_service.dart';
import 'package:focus_interval/data/services/firestore_service.dart';
import 'package:focus_interval/data/services/sound_service.dart';
import 'package:focus_interval/data/services/time_sync_service.dart';
import 'package:focus_interval/domain/pomodoro_machine.dart';
import 'package:focus_interval/presentation/providers.dart';
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
}
