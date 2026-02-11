import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:focus_interval/data/models/schema_version.dart';
import 'package:focus_interval/data/models/selected_sound.dart';
import 'package:focus_interval/data/models/task_run_group.dart';
import 'package:focus_interval/data/repositories/local_task_run_group_repository.dart';
import 'package:focus_interval/data/services/task_run_retention_service.dart';

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

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('repo does NOT complete when activeSession is null', () async {
    final repo = LocalTaskRunGroupRepository(
      retentionService: TaskRunRetentionService(),
    );
    final now = DateTime.now();
    final group = _buildRunningGroup(
      id: 'group-null-session',
      start: now.subtract(const Duration(hours: 2)),
      theoreticalEnd: now.subtract(const Duration(minutes: 30)),
    );
    await repo.save(group);

    final groups = await repo.getAll();
    expect(groups.single.status, TaskRunStatus.running);
  });

  test('repo does NOT complete when activeSession is paused', () async {
    final repo = LocalTaskRunGroupRepository(
      retentionService: TaskRunRetentionService(),
    );
    final now = DateTime.now();
    final group = _buildRunningGroup(
      id: 'group-paused-session',
      start: now.subtract(const Duration(hours: 2)),
      theoreticalEnd: now.subtract(const Duration(minutes: 30)),
    );
    await repo.save(group);

    final groups = await repo.getAll();
    expect(groups.single.status, TaskRunStatus.running);
  });

  test('repo does NOT complete when activeSession is other group', () async {
    final repo = LocalTaskRunGroupRepository(
      retentionService: TaskRunRetentionService(),
    );
    final now = DateTime.now();
    final group = _buildRunningGroup(
      id: 'group-other-session',
      start: now.subtract(const Duration(hours: 2)),
      theoreticalEnd: now.subtract(const Duration(minutes: 30)),
    );
    await repo.save(group);

    final groups = await repo.getAll();
    expect(groups.single.status, TaskRunStatus.running);
  });
}
