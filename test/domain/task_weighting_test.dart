import 'package:flutter_test/flutter_test.dart';
import 'package:focus_interval/data/models/pomodoro_task.dart';
import 'package:focus_interval/data/models/schema_version.dart';
import 'package:focus_interval/data/models/selected_sound.dart';
import 'package:focus_interval/domain/task_weighting.dart';

PomodoroTask _task({
  required String id,
  required int pomodoroMinutes,
  required int totalPomodoros,
}) {
  final now = DateTime(2026, 2, 13, 12);
  return PomodoroTask(
    id: id,
    name: id,
    dataVersion: kCurrentDataVersion,
    pomodoroMinutes: pomodoroMinutes,
    shortBreakMinutes: 5,
    longBreakMinutes: 15,
    totalPomodoros: totalPomodoros,
    longBreakInterval: 4,
    order: 0,
    startSound: const SelectedSound.builtIn('default_chime'),
    startBreakSound: const SelectedSound.builtIn('default_chime_break'),
    finishTaskSound: const SelectedSound.builtIn('default_chime_finish'),
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('normalizeTaskWeightPercents', () {
    test('returns empty map for empty input', () {
      expect(normalizeTaskWeightPercents(const []), isEmpty);
    });

    test('returns 100% for a single task', () {
      final task = _task(id: 't1', pomodoroMinutes: 25, totalPomodoros: 4);
      expect(normalizeTaskWeightPercents([task]), {'t1': 100});
    });

    test('splits equally for equal work', () {
      final t1 = _task(id: 't1', pomodoroMinutes: 25, totalPomodoros: 2);
      final t2 = _task(id: 't2', pomodoroMinutes: 25, totalPomodoros: 2);
      expect(normalizeTaskWeightPercents([t1, t2]), {'t1': 50, 't2': 50});
    });

    test('rounds to the nearest percent', () {
      final t1 = _task(id: 't1', pomodoroMinutes: 25, totalPomodoros: 1);
      final t2 = _task(id: 't2', pomodoroMinutes: 25, totalPomodoros: 2);
      expect(normalizeTaskWeightPercents([t1, t2]), {'t1': 33, 't2': 67});
    });

    test('returns empty map when total work is zero', () {
      final t1 = _task(id: 't1', pomodoroMinutes: 25, totalPomodoros: 0);
      final t2 = _task(id: 't2', pomodoroMinutes: 25, totalPomodoros: 0);
      expect(normalizeTaskWeightPercents([t1, t2]), isEmpty);
    });
  });
}
