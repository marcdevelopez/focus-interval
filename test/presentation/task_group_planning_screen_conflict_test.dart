import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:focus_interval/data/models/schema_version.dart';
import 'package:focus_interval/data/models/selected_sound.dart';
import 'package:focus_interval/data/models/task_run_group.dart';
import 'package:focus_interval/presentation/providers.dart';
import 'package:focus_interval/presentation/screens/task_group_planning_screen.dart';
import 'package:focus_interval/presentation/viewmodels/pre_run_notice_view_model.dart';

class _FixedPreRunNoticeViewModel extends PreRunNoticeViewModel {
  _FixedPreRunNoticeViewModel(this.value);

  final int value;

  @override
  Future<int> build() async => value;
}

class _PlanningLauncher extends StatefulWidget {
  const _PlanningLauncher({required this.args});

  final TaskGroupPlanningArgs args;

  @override
  State<_PlanningLauncher> createState() => _PlanningLauncherState();
}

class _PlanningLauncherState extends State<_PlanningLauncher> {
  TaskGroupPlanningResult? _result;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    Future<void>(() async {
      final result = await Navigator.of(context).push<TaskGroupPlanningResult>(
        PageRouteBuilder<TaskGroupPlanningResult>(
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          pageBuilder: (_, __, ___) =>
              TaskGroupPlanningScreen(args: widget.args),
        ),
      );
      if (!mounted) return;
      setState(() {
        _result = result;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final label = result == null
        ? 'result:pending'
        : 'result:cancel=${result.pendingCancelIds.length},delete=${result.pendingDeleteIds.length}';
    return Scaffold(body: Center(child: Text(label)));
  }
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
  required Widget home,
}) {
  return ProviderScope(
    overrides: [
      taskRunGroupStreamProvider.overrideWith((_) => groupsStream),
      activePomodoroSessionProvider.overrideWith((_) => null),
      preRunNoticeMinutesProvider.overrideWith(
        () => _FixedPreRunNoticeViewModel(0),
      ),
    ],
    child: MaterialApp(home: home),
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
    'race guard opens modal and returns pendingDeleteIds for scheduled conflicts',
    (tester) async {
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
          home: _PlanningLauncher(
            args: _buildArgs(scheduledStart: scheduledStart),
          ),
        ),
      );

      final confirmFinder = find.widgetWithText(ElevatedButton, 'Confirm');
      await tester.pumpAndSettle();
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

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Scheduling conflict'), findsAtLeastNWidgets(1));

      await tester.tap(find.widgetWithText(ElevatedButton, 'Delete (1)'));
      await tester.pumpAndSettle();

      expect(find.text('result:cancel=0,delete=1'), findsOneWidget);
    },
  );

  testWidgets('race guard returns pendingCancelIds for running conflicts', (
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
        home: _PlanningLauncher(
          args: _buildArgs(scheduledStart: scheduledStart),
        ),
      ),
    );

    final confirmFinder = find.widgetWithText(ElevatedButton, 'Confirm');
    await tester.pumpAndSettle();
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

    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Delete (1)'));
    await tester.pumpAndSettle();

    expect(find.text('result:cancel=1,delete=0'), findsOneWidget);
  });
}
