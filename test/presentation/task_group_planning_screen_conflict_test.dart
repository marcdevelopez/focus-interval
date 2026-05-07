import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:focus_interval/data/models/pomodoro_session.dart';
import 'package:focus_interval/data/models/schema_version.dart';
import 'package:focus_interval/data/models/selected_sound.dart';
import 'package:focus_interval/data/models/task_run_group.dart';
import 'package:focus_interval/domain/pomodoro_machine.dart';
import 'package:focus_interval/presentation/providers.dart';
import 'package:focus_interval/presentation/screens/task_group_planning_screen.dart';
import 'package:focus_interval/presentation/viewmodels/pre_run_notice_view_model.dart';

class _FixedPreRunNoticeViewModel extends PreRunNoticeViewModel {
  _FixedPreRunNoticeViewModel(this.value);

  final int value;

  @override
  Future<int> build() async => value;
}

TaskRunItem _buildItem() {
  return const TaskRunItem(
    sourceTaskId: 'task-1',
    name: 'Planning task',
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

TaskRunGroup _buildGroup({
  required String id,
  required TaskRunStatus status,
  required DateTime start,
  required DateTime end,
}) {
  final task = _buildItem();
  return TaskRunGroup(
    id: id,
    ownerUid: 'owner',
    dataVersion: kCurrentDataVersion,
    integrityMode: TaskRunIntegrityMode.shared,
    tasks: [task],
    createdAt: start.subtract(const Duration(minutes: 1)),
    scheduledStartTime: status == TaskRunStatus.scheduled ? start : null,
    scheduledByDeviceId: 'device-a',
    actualStartTime: status == TaskRunStatus.running ? start : null,
    theoreticalEndTime: end,
    status: status,
    noticeMinutes: 0,
    totalTasks: 1,
    totalPomodoros: 1,
    totalDurationSeconds: end.difference(start).inSeconds,
    updatedAt: start,
  );
}

DateTime _futureMinute(int minutesFromNow) {
  final now = DateTime.now();
  final floored = DateTime(now.year, now.month, now.day, now.hour, now.minute);
  return floored.add(Duration(minutes: minutesFromNow));
}

TaskGroupPlanningArgs _buildArgs({required DateTime scheduledStart}) {
  return TaskGroupPlanningArgs(
    items: [_buildItem()],
    integrityMode: TaskRunIntegrityMode.shared,
    planningAnchor: DateTime.now(),
    initialNoticeMinutes: 0,
    initialOption: TaskGroupPlanOption.scheduleStart,
    initialScheduledStart: scheduledStart,
  );
}

Widget _buildApp({
  required TaskGroupPlanningArgs args,
  required Stream<List<TaskRunGroup>> groupsStream,
  PomodoroSession? activeSession,
  required Widget home,
}) {
  return ProviderScope(
    overrides: [
      taskRunGroupStreamProvider.overrideWith((_) => groupsStream),
      activePomodoroSessionProvider.overrideWith((_) => activeSession),
      preRunNoticeMinutesProvider.overrideWith(
        () => _FixedPreRunNoticeViewModel(0),
      ),
    ],
    child: MaterialApp(home: home),
  );
}

PomodoroSession _buildPausedSession({
  required String groupId,
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
    ownerDeviceId: 'device-a',
    status: PomodoroStatus.paused,
    phase: PomodoroPhase.pomodoro,
    currentPomodoro: 1,
    totalPomodoros: 1,
    phaseDurationSeconds: 25 * 60,
    remainingSeconds: 10 * 60,
    accumulatedPausedSeconds: 0,
    phaseStartedAt: now.subtract(const Duration(minutes: 20)),
    currentTaskStartedAt: now.subtract(const Duration(minutes: 20)),
    pausedAt: now.subtract(const Duration(minutes: 30)),
    lastUpdatedAt: now,
    finishedAt: null,
    pauseReason: null,
    ownershipRequest: null,
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(const {
      'planning_info_seen_v1': true,
      'planning_range_shift_notice_v1': true,
      'planning_notice_clamp_notice_v1': true,
    });
  });

  testWidgets(
    'shows inline scheduling conflict and disables confirm after sync',
    (tester) async {
      final scheduledStart = _futureMinute(90);
      final conflict = _buildGroup(
        id: 'scheduled-conflict',
        status: TaskRunStatus.scheduled,
        start: scheduledStart.add(const Duration(minutes: 10)),
        end: scheduledStart.add(const Duration(minutes: 20)),
      );

      await tester.pumpWidget(
        _buildApp(
          args: _buildArgs(scheduledStart: scheduledStart),
          groupsStream: Stream.value([conflict]),
          home: TaskGroupPlanningScreen(
            args: _buildArgs(scheduledStart: scheduledStart),
          ),
        ),
      );

      await tester.pump();
      await tester.pump();

      expect(find.text('Scheduling conflict'), findsOneWidget);
      final confirm = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Confirm'),
      );
      expect(confirm.onPressed, isNull);
    },
  );

  testWidgets(
    'inline conflict chip uses effective postponed range instead of raw range',
    (tester) async {
      final now = DateTime.now();
      final scheduledStart = _futureMinute(45);
      final anchorStart = scheduledStart.subtract(const Duration(minutes: 50));
      final anchorBaseEnd = scheduledStart.subtract(
        const Duration(minutes: 10),
      );
      final anchorRunning = _buildGroup(
        id: 'anchor-running',
        status: TaskRunStatus.running,
        start: anchorStart,
        end: anchorBaseEnd,
      );

      final rawStart = scheduledStart.subtract(const Duration(minutes: 40));
      final rawEnd = rawStart.add(const Duration(minutes: 25));
      final postponedScheduled = _buildGroup(
        id: 'postponed-scheduled',
        status: TaskRunStatus.scheduled,
        start: rawStart,
        end: rawEnd,
      ).copyWith(postponedAfterGroupId: anchorRunning.id);

      final pausedSession = _buildPausedSession(
        groupId: anchorRunning.id,
        now: now,
      );

      await tester.pumpWidget(
        _buildApp(
          args: _buildArgs(scheduledStart: scheduledStart),
          groupsStream: Stream.value([anchorRunning, postponedScheduled]),
          activeSession: pausedSession,
          home: TaskGroupPlanningScreen(
            args: _buildArgs(scheduledStart: scheduledStart),
          ),
        ),
      );

      await tester.pump();
      await tester.pump();

      expect(find.text('Scheduling conflict'), findsOneWidget);
      expect(find.textContaining('Scheduled'), findsWidgets);

      final rawRange =
          '${DateFormat('HH:mm').format(rawStart)}–${DateFormat('HH:mm').format(rawEnd)}';
      expect(
        find.textContaining(rawRange),
        findsNothing,
        reason:
            'Conflict chip must use effective postponed window, not raw stored range.',
      );
    },
  );

  testWidgets('race guard blocks confirm without modal for scheduled conflicts', (
    tester,
  ) async {
    final scheduledStart = _futureMinute(120);
    final conflict = _buildGroup(
      id: 'scheduled-conflict',
      status: TaskRunStatus.scheduled,
      start: scheduledStart.add(const Duration(minutes: 5)),
      end: scheduledStart.add(const Duration(minutes: 18)),
    );
    final groupsController = StreamController<List<TaskRunGroup>>.broadcast();
    addTearDown(groupsController.close);

    await tester.pumpWidget(
      _buildApp(
        args: _buildArgs(scheduledStart: scheduledStart),
        groupsStream: groupsController.stream,
        home: TaskGroupPlanningScreen(
          args: _buildArgs(scheduledStart: scheduledStart),
        ),
      ),
    );

    final confirmFinder = find.widgetWithText(ElevatedButton, 'Confirm');
    await tester.pump();
    await tester.pump();
    expect(confirmFinder, findsOneWidget);

    groupsController.add(const []);
    await tester.pump();

    final raceTapCallback = tester
        .widget<ElevatedButton>(confirmFinder)
        .onPressed;
    expect(raceTapCallback, isNotNull);

    groupsController.add([conflict]);
    await tester.pump();

    raceTapCallback!.call();
    await tester.pump();

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Scheduling conflict'), findsOneWidget);
    expect(
      find.text(
        'Selected execution window overlaps an existing group. Choose another time.',
      ),
      findsOneWidget,
    );

    final updatedConfirm = tester.widget<ElevatedButton>(confirmFinder);
    expect(updatedConfirm.onPressed, isNull);
  });

  testWidgets('race guard blocks confirm without modal for running conflicts', (
    tester,
  ) async {
    final scheduledStart = _futureMinute(150);
    final conflict = _buildGroup(
      id: 'running-conflict',
      status: TaskRunStatus.running,
      start: scheduledStart.subtract(const Duration(minutes: 2)),
      end: scheduledStart.add(const Duration(minutes: 10)),
    );
    final groupsController = StreamController<List<TaskRunGroup>>.broadcast();
    addTearDown(groupsController.close);

    await tester.pumpWidget(
      _buildApp(
        args: _buildArgs(scheduledStart: scheduledStart),
        groupsStream: groupsController.stream,
        home: TaskGroupPlanningScreen(
          args: _buildArgs(scheduledStart: scheduledStart),
        ),
      ),
    );

    final confirmFinder = find.widgetWithText(ElevatedButton, 'Confirm');
    await tester.pump();
    await tester.pump();
    expect(confirmFinder, findsOneWidget);

    groupsController.add(const []);
    await tester.pump();

    final raceTapCallback = tester
        .widget<ElevatedButton>(confirmFinder)
        .onPressed;
    expect(raceTapCallback, isNotNull);

    groupsController.add([conflict]);
    await tester.pump();

    raceTapCallback!.call();
    await tester.pump();

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Scheduling conflict'), findsOneWidget);
    expect(
      find.text(
        'Selected execution window overlaps an existing group. Choose another time.',
      ),
      findsOneWidget,
    );

    final updatedConfirm = tester.widget<ElevatedButton>(confirmFinder);
    expect(updatedConfirm.onPressed, isNull);
  });
}
