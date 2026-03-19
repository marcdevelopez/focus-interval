import 'package:flutter_test/flutter_test.dart';

import 'package:focus_interval/data/models/schema_version.dart';
import 'package:focus_interval/data/models/selected_sound.dart';
import 'package:focus_interval/data/models/task_run_group.dart';
import 'package:focus_interval/presentation/utils/scheduled_group_timing.dart';

TaskRunItem _buildItem() {
  return const TaskRunItem(
    sourceTaskId: 'task-1',
    name: 'Test task',
    presetId: null,
    pomodoroMinutes: 25,
    shortBreakMinutes: 5,
    longBreakMinutes: 15,
    totalPomodoros: 1,
    longBreakInterval: 1,
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
    actualStartTime: start,
    theoreticalEndTime: theoreticalEnd,
    status: TaskRunStatus.running,
    noticeMinutes: null,
    totalTasks: 1,
    totalPomodoros: 1,
    totalDurationSeconds: item.durationSeconds(includeFinalBreak: true),
    updatedAt: start,
  );
}

TaskRunGroup _buildScheduledGroup({
  required String id,
  required DateTime scheduledStart,
  required int noticeMinutes,
  required String anchorId,
}) {
  final item = _buildItem();
  final createdAt = scheduledStart.subtract(const Duration(minutes: 1));
  return TaskRunGroup(
    id: id,
    ownerUid: 'user-1',
    dataVersion: kCurrentDataVersion,
    integrityMode: TaskRunIntegrityMode.shared,
    tasks: [item],
    createdAt: createdAt,
    scheduledStartTime: scheduledStart,
    scheduledByDeviceId: 'device-1',
    postponedAfterGroupId: anchorId,
    actualStartTime: null,
    theoreticalEndTime: scheduledStart.add(const Duration(minutes: 15)),
    status: TaskRunStatus.scheduled,
    noticeMinutes: noticeMinutes,
    totalTasks: 1,
    totalPomodoros: 1,
    totalDurationSeconds: 15 * 60,
    updatedAt: createdAt,
  );
}

void main() {
  group('resolveEffectiveScheduledStart', () {
    test(
      'rounds effective postponed start up to the next minute when anchor end has seconds',
      () {
        final now = DateTime(2026, 3, 19, 20, 10, 0);
        final running = _buildRunningGroup(
          id: 'running-1',
          start: DateTime(2026, 3, 19, 19, 40, 0),
          theoreticalEnd: DateTime(2026, 3, 19, 20, 9, 32),
        );
        final postponed = _buildScheduledGroup(
          id: 'scheduled-1',
          scheduledStart: DateTime(2026, 3, 19, 20, 20, 0),
          noticeMinutes: 1,
          anchorId: running.id,
        );

        final effectiveStart = resolveEffectiveScheduledStart(
          group: postponed,
          allGroups: [running, postponed],
          activeSession: null,
          now: now,
          fallbackNoticeMinutes: null,
        );

        expect(effectiveStart, DateTime(2026, 3, 19, 20, 11, 0));
      },
    );

    test(
      'keeps exact-minute anchor when noticeMinutes is zero (known strict-inequality edge)',
      () {
        final now = DateTime(2026, 3, 19, 20, 10, 0);
        final running = _buildRunningGroup(
          id: 'running-2',
          start: DateTime(2026, 3, 19, 19, 45, 0),
          theoreticalEnd: DateTime(2026, 3, 19, 20, 10, 0),
        );
        final postponed = _buildScheduledGroup(
          id: 'scheduled-2',
          scheduledStart: DateTime(2026, 3, 19, 20, 30, 0),
          noticeMinutes: 0,
          anchorId: running.id,
        );

        final effectiveStart = resolveEffectiveScheduledStart(
          group: postponed,
          allGroups: [running, postponed],
          activeSession: null,
          now: now,
          fallbackNoticeMinutes: null,
        );

        // Known edge: equals anchorEnd when noticeMinutes=0 + exact minute.
        expect(effectiveStart, DateTime(2026, 3, 19, 20, 10, 0));
      },
    );
  });
}
