import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:focus_interval/data/models/selected_sound.dart';
import 'package:focus_interval/data/models/task_run_group.dart';
import 'package:focus_interval/presentation/screens/task_group_planning_screen.dart';

TaskRunItem _buildPlanningItem() {
  return const TaskRunItem(
    sourceTaskId: 'task-1',
    name: 'Task 1',
    presetId: null,
    pomodoroMinutes: 25,
    shortBreakMinutes: 5,
    longBreakMinutes: 15,
    totalPomodoros: 3,
    longBreakInterval: 2,
    startSound: SelectedSound.builtIn('default_chime'),
    startBreakSound: SelectedSound.builtIn('default_chime_break'),
    finishTaskSound: SelectedSound.builtIn('default_chime_finish'),
  );
}

TaskGroupPlanningArgs _buildArgs({required TaskGroupPlanOption option}) {
  return TaskGroupPlanningArgs(
    items: [_buildPlanningItem()],
    integrityMode: TaskRunIntegrityMode.individual,
    planningAnchor: DateTime.now().add(const Duration(hours: 1)),
    initialNoticeMinutes: 0,
    initialOption: option,
    initialScheduledStart: DateTime.now().add(const Duration(hours: 2)),
  );
}

Future<void> _pumpPlanningScreen(
  WidgetTester tester, {
  required TaskGroupPlanOption option,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: TaskGroupPlanningScreen(args: _buildArgs(option: option)),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 100));
  await tester.drag(find.byType(ListView), const Offset(0, -600));
  await tester.pump();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'planning_info_seen_v1': true,
      'planning_range_shift_notice_v1': false,
      'planning_notice_clamp_notice_v1': false,
    });
  });

  testWidgets(
    'shows inline adjusted-end notice for schedule-by-range when max-fit ends earlier',
    (tester) async {
      await _pumpPlanningScreen(
        tester,
        option: TaskGroupPlanOption.scheduleRange,
      );

      expect(find.textContaining('Adjusted end:'), findsOneWidget);
    },
  );

  testWidgets(
    'shows inline adjusted-end notice for schedule-by-total when max-fit ends earlier',
    (tester) async {
      await _pumpPlanningScreen(
        tester,
        option: TaskGroupPlanOption.scheduleTotal,
      );

      expect(find.textContaining('Adjusted end:'), findsOneWidget);
    },
  );
}
