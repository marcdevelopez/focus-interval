import 'package:flutter_test/flutter_test.dart';
import 'package:focus_interval/data/models/selected_sound.dart';
import 'package:focus_interval/data/models/task_run_group.dart';
import 'package:focus_interval/domain/task_group_planner.dart';

TaskRunItem _item({
  required String id,
  required int pomodoroMinutes,
  required int shortBreakMinutes,
  required int longBreakMinutes,
  required int longBreakInterval,
  required int totalPomodoros,
}) {
  return TaskRunItem(
    sourceTaskId: id,
    name: id,
    presetId: null,
    pomodoroMinutes: pomodoroMinutes,
    shortBreakMinutes: shortBreakMinutes,
    longBreakMinutes: longBreakMinutes,
    totalPomodoros: totalPomodoros,
    longBreakInterval: longBreakInterval,
    startSound: const SelectedSound.builtIn('default_chime'),
    startBreakSound: const SelectedSound.builtIn('default_chime_break'),
    finishTaskSound: const SelectedSound.builtIn('default_chime_finish'),
  );
}

TaskRunItem _copyWithPomodoros(TaskRunItem item, int totalPomodoros) {
  return TaskRunItem(
    sourceTaskId: item.sourceTaskId,
    name: item.name,
    presetId: item.presetId,
    pomodoroMinutes: item.pomodoroMinutes,
    shortBreakMinutes: item.shortBreakMinutes,
    longBreakMinutes: item.longBreakMinutes,
    totalPomodoros: totalPomodoros,
    longBreakInterval: item.longBreakInterval,
    startSound: item.startSound,
    startBreakSound: item.startBreakSound,
    finishTaskSound: item.finishTaskSound,
  );
}

double _totalWorkMinutes(List<TaskRunItem> items) {
  var total = 0.0;
  for (final item in items) {
    total += item.totalPomodoros * item.pomodoroMinutes;
  }
  return total;
}

bool _hasExcessiveDeviation(
  List<TaskRunItem> original,
  List<TaskRunItem> redistributed,
) {
  final originalTotal = _totalWorkMinutes(original);
  final redistributedTotal = _totalWorkMinutes(redistributed);
  if (originalTotal <= 0 || redistributedTotal <= 0) return false;

  for (var index = 0; index < original.length; index += 1) {
    final originalWork =
        original[index].totalPomodoros * original[index].pomodoroMinutes;
    final newWork =
        redistributed[index].totalPomodoros * redistributed[index].pomodoroMinutes;
    final originalPercent = (originalWork / originalTotal) * 100;
    final newPercent = (newWork / redistributedTotal) * 100;
    if ((newPercent - originalPercent).abs() >= 10) {
      return true;
    }
  }
  return false;
}

List<TaskRunItem> _updatePomodoros(
  List<TaskRunItem> items, {
  required Map<int, int> updates,
}) {
  return [
    for (var index = 0; index < items.length; index += 1)
      updates.containsKey(index)
          ? _copyWithPomodoros(items[index], updates[index]!)
          : items[index],
  ];
}

void _expectNoBetterCandidate({
  required List<TaskRunItem> original,
  required List<TaskRunItem> current,
  required TaskRunIntegrityMode integrityMode,
  required int targetDurationSeconds,
}) {
  final currentDuration = groupDurationSecondsByMode(current, integrityMode);

  for (var index = 0; index < current.length; index += 1) {
    final candidate = _updatePomodoros(
      current,
      updates: {index: current[index].totalPomodoros + 1},
    );
    if (_hasExcessiveDeviation(original, candidate)) continue;
    final duration = groupDurationSecondsByMode(candidate, integrityMode);
    expect(duration <= targetDurationSeconds && duration > currentDuration, false);
  }

  for (var addIndex = 0; addIndex < current.length; addIndex += 1) {
    for (var removeIndex = 0;
        removeIndex < current.length;
        removeIndex += 1) {
      if (addIndex == removeIndex) continue;
      if (current[removeIndex].totalPomodoros <= 1) continue;
      final candidate = _updatePomodoros(
        current,
        updates: {
          addIndex: current[addIndex].totalPomodoros + 1,
          removeIndex: current[removeIndex].totalPomodoros - 1,
        },
      );
      if (_hasExcessiveDeviation(original, candidate)) continue;
      final duration = groupDurationSecondsByMode(candidate, integrityMode);
      expect(duration <= targetDurationSeconds && duration > currentDuration, false);
    }
  }
}

void main() {
  group('Schedule start validation', () {
    test('accepts now or future timestamps', () {
      final now = DateTime(2026, 2, 8, 5, 30);
      expect(isStartTimeInFuture(start: now, now: now), true);
      expect(
        isStartTimeInFuture(
          start: now.add(const Duration(minutes: 1)),
          now: now,
        ),
        true,
      );
    });

    test('rejects past timestamps', () {
      final now = DateTime(2026, 2, 8, 5, 30);
      expect(
        isStartTimeInFuture(
          start: now.subtract(const Duration(minutes: 1)),
          now: now,
        ),
        false,
      );
    });
  });

  group('TaskGroupRedistribution (individual)', () {
    late List<TaskRunItem> items;

    setUp(() {
      items = [
        _item(
          id: 't3',
          pomodoroMinutes: 25,
          shortBreakMinutes: 5,
          longBreakMinutes: 15,
          longBreakInterval: 4,
          totalPomodoros: 4,
        ),
        _item(
          id: 't2',
          pomodoroMinutes: 15,
          shortBreakMinutes: 5,
          longBreakMinutes: 14,
          longBreakInterval: 2,
          totalPomodoros: 2,
        ),
      ];
    });

    test('blocks when target is shorter than minimum', () {
      final result = redistributeTaskGroup(
        items: items,
        integrityMode: TaskRunIntegrityMode.individual,
        targetDurationSeconds: 40 * 60,
      );

      expect(result.success, false);
      expect(result.error, TaskGroupRedistributionError.tooShortForGroup);
    });

    test('blocks when redistribution would skew weights too far', () {
      final result = redistributeTaskGroup(
        items: items,
        integrityMode: TaskRunIntegrityMode.individual,
        targetDurationSeconds: 70 * 60,
      );

      expect(result.success, false);
      expect(result.error, TaskGroupRedistributionError.skew);
    });

    test('fits the minimal valid window at 75 minutes', () {
      final result = redistributeTaskGroup(
        items: items,
        integrityMode: TaskRunIntegrityMode.individual,
        targetDurationSeconds: 75 * 60,
      );

      expect(result.success, true);
      expect(result.actualDurationSeconds, 75 * 60);
      expect(
        result.items.map((item) => item.totalPomodoros).toList(),
        [2, 1],
      );
    });

    test('maximizes within a 6 hour window', () {
      final result = redistributeTaskGroup(
        items: items,
        integrityMode: TaskRunIntegrityMode.individual,
        targetDurationSeconds: 360 * 60,
      );

      expect(result.success, true);
      expect(result.actualDurationSeconds, 354 * 60);
      expect(result.actualDurationSeconds <= 360 * 60, true);
      _expectNoBetterCandidate(
        original: items,
        current: result.items,
        integrityMode: TaskRunIntegrityMode.individual,
        targetDurationSeconds: 360 * 60,
      );
    });

    test('handles a long duration target', () {
      final result = redistributeTaskGroup(
        items: items,
        integrityMode: TaskRunIntegrityMode.individual,
        targetDurationSeconds: 480 * 60,
      );

      expect(result.success, true);
      expect(result.actualDurationSeconds, 474 * 60);
      expect(result.actualDurationSeconds <= 480 * 60, true);
    });

    test('supports three-task redistribution', () {
      final threeTasks = [
        _item(
          id: 'a',
          pomodoroMinutes: 25,
          shortBreakMinutes: 5,
          longBreakMinutes: 15,
          longBreakInterval: 4,
          totalPomodoros: 4,
        ),
        _item(
          id: 'b',
          pomodoroMinutes: 20,
          shortBreakMinutes: 5,
          longBreakMinutes: 10,
          longBreakInterval: 3,
          totalPomodoros: 3,
        ),
        _item(
          id: 'c',
          pomodoroMinutes: 15,
          shortBreakMinutes: 5,
          longBreakMinutes: 10,
          longBreakInterval: 2,
          totalPomodoros: 2,
        ),
      ];
      final result = redistributeTaskGroup(
        items: threeTasks,
        integrityMode: TaskRunIntegrityMode.individual,
        targetDurationSeconds: 360 * 60,
      );

      expect(result.success, true);
      expect(result.actualDurationSeconds <= 360 * 60, true);
      _expectNoBetterCandidate(
        original: threeTasks,
        current: result.items,
        integrityMode: TaskRunIntegrityMode.individual,
        targetDurationSeconds: 360 * 60,
      );
    });
  });

  group('TaskGroupRedistribution (shared)', () {
    late List<TaskRunItem> items;

    setUp(() {
      items = [
        _item(
          id: 'a',
          pomodoroMinutes: 25,
          shortBreakMinutes: 5,
          longBreakMinutes: 15,
          longBreakInterval: 4,
          totalPomodoros: 4,
        ),
        _item(
          id: 'b',
          pomodoroMinutes: 25,
          shortBreakMinutes: 5,
          longBreakMinutes: 15,
          longBreakInterval: 4,
          totalPomodoros: 2,
        ),
      ];
    });

    test('blocks when target is below the minimum shared duration', () {
      final result = redistributeTaskGroup(
        items: items,
        integrityMode: TaskRunIntegrityMode.shared,
        targetDurationSeconds: 50 * 60,
      );

      expect(result.success, false);
      expect(result.error, TaskGroupRedistributionError.tooShortForGroup);
    });

    test('keeps baseline distribution when target equals baseline', () {
      final result = redistributeTaskGroup(
        items: items,
        integrityMode: TaskRunIntegrityMode.shared,
        targetDurationSeconds: 185 * 60,
      );

      expect(result.success, true);
      expect(result.actualDurationSeconds, 185 * 60);
      expect(
        result.items.map((item) => item.totalPomodoros).toList(),
        [4, 2],
      );
    });

    test('maximizes duration for shared configuration', () {
      final result = redistributeTaskGroup(
        items: items,
        integrityMode: TaskRunIntegrityMode.shared,
        targetDurationSeconds: 240 * 60,
      );

      expect(result.success, true);
      expect(result.actualDurationSeconds <= 240 * 60, true);
      _expectNoBetterCandidate(
        original: items,
        current: result.items,
        integrityMode: TaskRunIntegrityMode.shared,
        targetDurationSeconds: 240 * 60,
      );
    });
  });
}
