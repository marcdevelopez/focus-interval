import 'package:flutter_test/flutter_test.dart';

import 'package:focus_interval/data/models/pomodoro_task.dart';
import 'package:focus_interval/data/models/selected_sound.dart';
import 'package:focus_interval/data/models/schema_version.dart';
import 'package:focus_interval/domain/continuous_plan_load.dart';

void main() {
  PomodoroTask buildTask({
    required String id,
    required int pomodoros,
    required int pomodoroMinutes,
    int shortBreakMinutes = 5,
    int longBreakMinutes = 15,
    int longBreakInterval = 4,
  }) {
    final now = DateTime(2026, 3, 29);
    return PomodoroTask(
      id: id,
      name: id,
      dataVersion: kCurrentDataVersion,
      pomodoroMinutes: pomodoroMinutes,
      shortBreakMinutes: shortBreakMinutes,
      longBreakMinutes: longBreakMinutes,
      totalPomodoros: pomodoros,
      longBreakInterval: longBreakInterval,
      order: now.millisecondsSinceEpoch,
      startSound: const SelectedSound.builtIn('default_chime'),
      startBreakSound: const SelectedSound.builtIn('default_chime_break'),
      finishTaskSound: const SelectedSound.builtIn('default_chime_finish'),
      createdAt: now,
      updatedAt: now,
    );
  }

  group('continuous plan load levels', () {
    test('applies confirmed thresholds', () {
      expect(
        continuousPlanLoadLevelForSeconds(11 * 60 * 60),
        ContinuousPlanLoadLevel.unusual,
      );
      expect(
        continuousPlanLoadLevelForSeconds(24 * 60 * 60),
        ContinuousPlanLoadLevel.superhuman,
      );
      expect(
        continuousPlanLoadLevelForSeconds(72 * 60 * 60),
        ContinuousPlanLoadLevel.machineLevel,
      );
    });
  });

  group('continuous duration helpers', () {
    test('single task includes internal breaks only', () {
      final task = buildTask(id: 'T1', pomodoros: 3, pomodoroMinutes: 25);
      final seconds = continuousGroupDurationSecondsForTasks([task]);
      expect(seconds, (3 * 25 + 2 * 5) * 60);
    });

    test('shared structure uses group-global cadence', () {
      final tasks = [
        buildTask(id: 'A', pomodoros: 2, pomodoroMinutes: 25),
        buildTask(id: 'B', pomodoros: 2, pomodoroMinutes: 25),
      ];
      final seconds = continuousGroupDurationSecondsForTasks(tasks);
      expect(seconds, (4 * 25 + 3 * 5) * 60);
    });
  });
}
