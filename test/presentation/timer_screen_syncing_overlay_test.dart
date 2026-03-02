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
import 'package:focus_interval/data/services/sound_service.dart';
import 'package:focus_interval/data/services/task_run_notice_service.dart';
import 'package:focus_interval/data/services/time_sync_service.dart';
import 'package:focus_interval/data/services/firebase_auth_service.dart';
import 'package:focus_interval/data/services/firestore_service.dart';
import 'package:focus_interval/presentation/providers.dart';
import 'package:focus_interval/presentation/screens/timer_screen.dart';
import 'package:focus_interval/widgets/timer_display.dart';

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

void main() {
  testWidgets(
    'Pending intent without snapshot shows full loader',
    (tester) async {
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
    },
  );
}
