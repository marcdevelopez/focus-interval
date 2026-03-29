import 'package:flutter_test/flutter_test.dart';

import 'package:focus_interval/data/models/selected_sound.dart';
import 'package:focus_interval/data/models/task_run_group.dart';

TaskRunItem _item({
  required String id,
  required int totalPomodoros,
  required int longBreakInterval,
}) {
  return TaskRunItem(
    sourceTaskId: id,
    name: id,
    pomodoroMinutes: 25,
    shortBreakMinutes: 5,
    longBreakMinutes: 15,
    totalPomodoros: totalPomodoros,
    longBreakInterval: longBreakInterval,
    startSound: const SelectedSound.builtIn('default_chime'),
    startBreakSound: const SelectedSound.builtIn('default_chime_break'),
    finishTaskSound: const SelectedSound.builtIn('default_chime_finish'),
  );
}

void main() {
  group('Mode A global long-break sequencing', () {
    test('applies long break using global pomodoro index across tasks', () {
      final tasks = <TaskRunItem>[
        _item(id: 'task-a', totalPomodoros: 2, longBreakInterval: 3),
        _item(id: 'task-b', totalPomodoros: 2, longBreakInterval: 3),
      ];

      final sharedTaskDurations = taskDurationSecondsByMode(
        tasks,
        TaskRunIntegrityMode.shared,
      );
      final individualTaskDurations = taskDurationSecondsByMode(
        tasks,
        TaskRunIntegrityMode.individual,
      );

      // Shared mode: global pomodoro #3 is first pomodoro of task-b, so
      // task-b starts with a long-break boundary.
      expect(sharedTaskDurations, <int>[60 * 60, 65 * 60]);
      // Individual mode: task-b resets its own counter, so it stays short-break.
      expect(individualTaskDurations, <int>[60 * 60, 55 * 60]);

      expect(
        groupDurationSecondsByMode(tasks, TaskRunIntegrityMode.shared),
        125 * 60,
      );
      expect(
        groupDurationSecondsByMode(tasks, TaskRunIntegrityMode.individual),
        115 * 60,
      );
    });

    test('does not reset shared long-break cadence at task boundaries', () {
      final tasks = <TaskRunItem>[
        _item(id: 'task-a', totalPomodoros: 3, longBreakInterval: 4),
        _item(id: 'task-b', totalPomodoros: 2, longBreakInterval: 4),
      ];

      final sharedTaskDurations = taskDurationSecondsByMode(
        tasks,
        TaskRunIntegrityMode.shared,
      );

      // Long break happens after global pomodoro #4 (inside task-b).
      expect(sharedTaskDurations, <int>[90 * 60, 65 * 60]);
      expect(
        groupDurationSecondsByMode(tasks, TaskRunIntegrityMode.shared),
        155 * 60,
      );
    });
  });
}
