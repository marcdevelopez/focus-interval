import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:focus_interval/data/models/pomodoro_session.dart';
import 'package:focus_interval/data/models/schema_version.dart';
import 'package:focus_interval/data/models/selected_sound.dart';
import 'package:focus_interval/data/models/task_run_group.dart';
import 'package:focus_interval/data/repositories/pomodoro_session_repository.dart';
import 'package:focus_interval/data/repositories/task_run_group_repository.dart';
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
  Future<void> delete(String id) async {
    _store.remove(id);
    _emit();
  }

  @override
  Future<void> prune({int? keepCompleted}) async {}

  void dispose() {
    _controller.close();
  }
}

class FakePomodoroSessionRepository implements PomodoroSessionRepository {
  final StreamController<PomodoroSession?> _controller =
      StreamController<PomodoroSession?>.broadcast();

  void emit(PomodoroSession? session) {
    _controller.add(session);
  }

  @override
  Stream<PomodoroSession?> watchSession() => _controller.stream;

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
  await Future<void>.delayed(const Duration(milliseconds: 20));
  await Future<void>.delayed(const Duration(milliseconds: 20));
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
}
