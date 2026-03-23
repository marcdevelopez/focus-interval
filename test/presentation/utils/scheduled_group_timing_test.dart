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

TaskRunGroup _buildLateStartQueueGroup({
  required String id,
  required DateTime scheduledStart,
  required int noticeMinutes,
  required int durationMinutes,
}) {
  const item = TaskRunItem(
    sourceTaskId: 'late-start-task',
    name: 'Late start task',
    presetId: null,
    pomodoroMinutes: 15,
    shortBreakMinutes: 5,
    longBreakMinutes: 15,
    totalPomodoros: 1,
    longBreakInterval: 1,
    startSound: SelectedSound.builtIn('default_chime'),
    startBreakSound: SelectedSound.builtIn('default_chime_break'),
    finishTaskSound: SelectedSound.builtIn('default_chime_finish'),
  );
  final createdAt = scheduledStart.subtract(const Duration(minutes: 1));
  return TaskRunGroup(
    id: id,
    ownerUid: 'user-1',
    dataVersion: kCurrentDataVersion,
    integrityMode: TaskRunIntegrityMode.shared,
    tasks: const [item],
    createdAt: createdAt,
    scheduledStartTime: scheduledStart,
    scheduledByDeviceId: 'device-1',
    actualStartTime: null,
    theoreticalEndTime: scheduledStart.add(Duration(minutes: durationMinutes)),
    status: TaskRunStatus.scheduled,
    noticeMinutes: noticeMinutes,
    totalTasks: 1,
    totalPomodoros: 1,
    totalDurationSeconds: durationMinutes * 60,
    updatedAt: createdAt,
  );
}

void main() {
  group('resolvePostponedAnchorEnd', () {
    test('returns null when anchor is canceled', () {
      final now = DateTime(2026, 3, 19, 22, 21, 0);
      final anchor = _buildRunningGroup(
        id: 'anchor-canceled',
        start: DateTime(2026, 3, 19, 22, 0, 0),
        theoreticalEnd: DateTime(2026, 3, 19, 22, 30, 0),
      ).copyWith(status: TaskRunStatus.canceled, updatedAt: now);

      final anchorEnd = resolvePostponedAnchorEnd(
        anchor: anchor,
        allGroups: [anchor],
        activeSession: null,
        now: now,
        fallbackNoticeMinutes: null,
      );

      expect(anchorEnd, isNull);
    });
  });

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

    test('returns stored scheduledStart when anchor is canceled', () {
      final now = DateTime(2026, 3, 19, 22, 21, 0);
      final anchor = _buildRunningGroup(
        id: 'running-canceled',
        start: DateTime(2026, 3, 19, 22, 0, 0),
        theoreticalEnd: DateTime(2026, 3, 19, 22, 30, 0),
      ).copyWith(status: TaskRunStatus.canceled, updatedAt: now);
      final storedStart = DateTime(2026, 3, 19, 22, 35, 0);
      final postponed = _buildScheduledGroup(
        id: 'scheduled-canceled-anchor',
        scheduledStart: storedStart,
        noticeMinutes: 0,
        anchorId: anchor.id,
      );

      final effectiveStart = resolveEffectiveScheduledStart(
        group: postponed,
        allGroups: [anchor, postponed],
        activeSession: null,
        now: now,
        fallbackNoticeMinutes: null,
      );

      expect(effectiveStart, storedStart);
    });
  });

  group('resolveLateStartConflictSet', () {
    test('cascades conflict set to later groups after horizon expansion', () {
      final now = DateTime(2026, 3, 23, 8, 57, 0);
      final first = _buildLateStartQueueGroup(
        id: 'g1',
        scheduledStart: DateTime(2026, 3, 23, 8, 51, 0),
        noticeMinutes: 1,
        durationMinutes: 15,
      );
      final second = _buildLateStartQueueGroup(
        id: 'g2',
        scheduledStart: DateTime(2026, 3, 23, 9, 7, 0),
        noticeMinutes: 1,
        durationMinutes: 15,
      );
      final third = _buildLateStartQueueGroup(
        id: 'g3',
        scheduledStart: DateTime(2026, 3, 23, 9, 23, 0),
        noticeMinutes: 1,
        durationMinutes: 15,
      );

      final conflicts = resolveLateStartConflictSet(
        scheduled: [first, second, third],
        allGroups: [first, second, third],
        activeSession: null,
        now: now,
      );

      expect(conflicts.map((group) => group.id).toList(), ['g1', 'g2', 'g3']);
    });

    test('keeps non-overlapping later groups outside the queue set', () {
      final now = DateTime(2026, 3, 23, 8, 57, 0);
      final first = _buildLateStartQueueGroup(
        id: 'g1',
        scheduledStart: DateTime(2026, 3, 23, 8, 51, 0),
        noticeMinutes: 1,
        durationMinutes: 15,
      );
      final second = _buildLateStartQueueGroup(
        id: 'g2',
        scheduledStart: DateTime(2026, 3, 23, 9, 7, 0),
        noticeMinutes: 1,
        durationMinutes: 15,
      );
      final third = _buildLateStartQueueGroup(
        id: 'g3',
        scheduledStart: DateTime(2026, 3, 23, 9, 31, 0),
        noticeMinutes: 1,
        durationMinutes: 15,
      );

      final conflicts = resolveLateStartConflictSet(
        scheduled: [first, second, third],
        allGroups: [first, second, third],
        activeSession: null,
        now: now,
      );

      expect(conflicts.map((group) => group.id).toList(), ['g1', 'g2']);
    });

    test(
      'excludes queue-confirmed anchored groups from overdue detection',
      () {
        final now = DateTime(2026, 3, 23, 11, 57, 0, 70);
        final running = _buildRunningGroup(
          id: 'g1',
          start: DateTime(2026, 3, 23, 11, 40, 0),
          theoreticalEnd: DateTime(2026, 3, 23, 11, 55, 46),
        );
        final second = _buildLateStartQueueGroup(
          id: 'g2',
          scheduledStart: DateTime(2026, 3, 23, 11, 57, 0),
          noticeMinutes: 1,
          durationMinutes: 15,
        ).copyWith(postponedAfterGroupId: running.id);
        final third = _buildLateStartQueueGroup(
          id: 'g3',
          scheduledStart: DateTime(2026, 3, 23, 12, 13, 0),
          noticeMinutes: 1,
          durationMinutes: 15,
        ).copyWith(postponedAfterGroupId: second.id);

        final conflicts = resolveLateStartConflictSet(
          scheduled: [second, third],
          allGroups: [running, second, third],
          activeSession: null,
          now: now,
        );

        expect(
          conflicts,
          isEmpty,
          reason:
              'Groups anchored with postponedAfterGroupId are system-managed '
              'and must not re-trigger the late-start queue.',
        );
      },
    );
  });
}
