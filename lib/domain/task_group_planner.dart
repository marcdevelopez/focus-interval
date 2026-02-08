import 'package:focus_interval/data/models/task_run_group.dart';

enum TaskGroupRedistributionError {
  targetDurationInvalid,
  tooShortForGroup,
  invalidBaselineDuration,
  invalidBaselineWorkload,
  tooShortForConfiguration,
  skew,
}

extension TaskGroupRedistributionErrorMessage
    on TaskGroupRedistributionError {
  String get message {
    switch (this) {
      case TaskGroupRedistributionError.targetDurationInvalid:
        return 'Target duration must be greater than zero.';
      case TaskGroupRedistributionError.tooShortForGroup:
        return 'The requested time is too short for this group.';
      case TaskGroupRedistributionError.invalidBaselineDuration:
        return 'Unable to calculate the current group duration.';
      case TaskGroupRedistributionError.invalidBaselineWorkload:
        return 'Unable to calculate the current group workload.';
      case TaskGroupRedistributionError.tooShortForConfiguration:
        return 'The requested time is too short for this configuration.';
      case TaskGroupRedistributionError.skew:
        return 'The requested time would skew task weights too far. '
            'Choose a larger range or fewer tasks.';
    }
  }
}

class TaskGroupRedistributionResult {
  final bool success;
  final List<TaskRunItem> items;
  final int actualDurationSeconds;
  final TaskGroupRedistributionError? error;

  const TaskGroupRedistributionResult.success({
    required this.items,
    required this.actualDurationSeconds,
  })  : success = true,
        error = null;

  const TaskGroupRedistributionResult.failure(this.error)
      : success = false,
        items = const [],
        actualDurationSeconds = 0;

  String? get message => error?.message;
}

TaskGroupRedistributionResult redistributeTaskGroup({
  required List<TaskRunItem> items,
  required TaskRunIntegrityMode integrityMode,
  required int targetDurationSeconds,
}) {
  if (items.isEmpty || targetDurationSeconds <= 0) {
    return const TaskGroupRedistributionResult.failure(
      TaskGroupRedistributionError.targetDurationInvalid,
    );
  }

  final minItems = [
    for (final item in items) _copyWithPomodoros(item, pomodoros: 1),
  ];
  final minDuration = groupDurationSecondsByMode(minItems, integrityMode);
  if (minDuration > targetDurationSeconds) {
    return const TaskGroupRedistributionResult.failure(
      TaskGroupRedistributionError.tooShortForGroup,
    );
  }

  final baselineDuration = groupDurationSecondsByMode(items, integrityMode);
  if (baselineDuration <= 0) {
    return const TaskGroupRedistributionResult.failure(
      TaskGroupRedistributionError.invalidBaselineDuration,
    );
  }

  final baselineWorkMinutes = _totalWorkMinutes(items);
  if (baselineWorkMinutes <= 0) {
    return const TaskGroupRedistributionResult.failure(
      TaskGroupRedistributionError.invalidBaselineWorkload,
    );
  }

  final minWorkMinutes = _minWorkMinutes(items);
  final ratio = targetDurationSeconds / baselineDuration;
  final initialWork = (baselineWorkMinutes * ratio).clamp(
    minWorkMinutes,
    double.infinity,
  );

  final search = _searchForWorkTarget(
    items: items,
    originalItems: items,
    integrityMode: integrityMode,
    targetDurationSeconds: targetDurationSeconds,
    minWorkMinutes: minWorkMinutes,
    initialWorkMinutes: initialWork,
  );

  final best = search.bestWithinDeviation;
  if (best == null) {
    if (search.bestWithinTime != null) {
      return const TaskGroupRedistributionResult.failure(
        TaskGroupRedistributionError.skew,
      );
    }
    return const TaskGroupRedistributionResult.failure(
      TaskGroupRedistributionError.tooShortForConfiguration,
    );
  }

  final refined = _maximizeDurationWithinTarget(
    seed: best.items,
    originalItems: items,
    integrityMode: integrityMode,
    targetDurationSeconds: targetDurationSeconds,
  );

  return TaskGroupRedistributionResult.success(
    items: refined.items,
    actualDurationSeconds: refined.actualDurationSeconds,
  );
}

bool isStartTimeInFuture({
  required DateTime start,
  required DateTime now,
}) {
  return !start.isBefore(now);
}

_RedistributionAttempt _maximizeDurationWithinTarget({
  required List<TaskRunItem> seed,
  required List<TaskRunItem> originalItems,
  required TaskRunIntegrityMode integrityMode,
  required int targetDurationSeconds,
}) {
  var current = seed;
  var currentDuration = groupDurationSecondsByMode(current, integrityMode);
  if (currentDuration > targetDurationSeconds) {
    return _RedistributionAttempt(
      items: seed,
      actualDurationSeconds: currentDuration,
    );
  }

  for (var guard = 0; guard < 200; guard += 1) {
    _RedistributionAttempt? bestMove;

    for (var index = 0; index < current.length; index += 1) {
      final nextPomodoros = current[index].totalPomodoros + 1;
      final candidate = _updatePomodoros(
        current,
        updates: {index: nextPomodoros},
      );
      if (_hasExcessiveDeviation(originalItems, candidate)) continue;
      final duration = groupDurationSecondsByMode(candidate, integrityMode);
      if (duration <= targetDurationSeconds && duration > currentDuration) {
        bestMove = _bestMove(bestMove, candidate, duration);
      }
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
        if (_hasExcessiveDeviation(originalItems, candidate)) continue;
        final duration = groupDurationSecondsByMode(candidate, integrityMode);
        if (duration <= targetDurationSeconds && duration > currentDuration) {
          bestMove = _bestMove(bestMove, candidate, duration);
        }
      }
    }

    if (bestMove == null) break;
    current = bestMove.items;
    currentDuration = bestMove.actualDurationSeconds;
  }

  return _RedistributionAttempt(
    items: current,
    actualDurationSeconds: currentDuration,
  );
}

_RedistributionAttempt _bestMove(
  _RedistributionAttempt? current,
  List<TaskRunItem> candidate,
  int duration,
) {
  if (current == null || duration > current.actualDurationSeconds) {
    return _RedistributionAttempt(
      items: candidate,
      actualDurationSeconds: duration,
    );
  }
  return current;
}

List<TaskRunItem> _updatePomodoros(
  List<TaskRunItem> items, {
  required Map<int, int> updates,
}) {
  return [
    for (var index = 0; index < items.length; index += 1)
      updates.containsKey(index)
          ? _copyWithPomodoros(
              items[index],
              pomodoros: updates[index]!,
            )
          : items[index],
  ];
}

_RedistributionSearch _searchForWorkTarget({
  required List<TaskRunItem> items,
  required List<TaskRunItem> originalItems,
  required TaskRunIntegrityMode integrityMode,
  required int targetDurationSeconds,
  required double minWorkMinutes,
  required double initialWorkMinutes,
}) {
  _RedistributionAttempt? bestWithinTime;
  _RedistributionAttempt? bestWithinDeviation;
  var low = minWorkMinutes;
  var high = initialWorkMinutes;

  void considerAttempt(_RedistributionAttempt attempt) {
    if (attempt.actualDurationSeconds > targetDurationSeconds) return;
    if (bestWithinTime == null ||
        attempt.actualDurationSeconds >
            bestWithinTime!.actualDurationSeconds) {
      bestWithinTime = attempt;
    }
    if (_hasExcessiveDeviation(originalItems, attempt.items)) return;
    if (bestWithinDeviation == null ||
        attempt.actualDurationSeconds >
            bestWithinDeviation!.actualDurationSeconds) {
      bestWithinDeviation = attempt;
    }
  }

  final initial = _redistributeByWorkTarget(
    items: items,
    integrityMode: integrityMode,
    targetWorkMinutes: initialWorkMinutes,
  );
  if (initial.actualDurationSeconds <= targetDurationSeconds) {
    considerAttempt(initial);
    high = initialWorkMinutes;
    var expandedHigh = high;
    for (var i = 0; i < 6; i += 1) {
      expandedHigh *= 1.2;
      final attempt = _redistributeByWorkTarget(
        items: items,
        integrityMode: integrityMode,
        targetWorkMinutes: expandedHigh,
      );
      if (attempt.actualDurationSeconds <= targetDurationSeconds) {
        considerAttempt(attempt);
        high = expandedHigh;
      } else {
        low = high;
        high = expandedHigh;
        break;
      }
    }
  }

  for (var i = 0; i < 20; i += 1) {
    final mid = (low + high) / 2;
    final attempt = _redistributeByWorkTarget(
      items: items,
      integrityMode: integrityMode,
      targetWorkMinutes: mid,
    );
    if (attempt.actualDurationSeconds <= targetDurationSeconds) {
      considerAttempt(attempt);
      low = mid;
    } else {
      high = mid;
    }
  }

  return _RedistributionSearch(
    bestWithinTime: bestWithinTime,
    bestWithinDeviation: bestWithinDeviation,
  );
}

_RedistributionAttempt _redistributeByWorkTarget({
  required List<TaskRunItem> items,
  required TaskRunIntegrityMode integrityMode,
  required double targetWorkMinutes,
}) {
  final baselineWorkMinutes = _totalWorkMinutes(items);
  final allocations = <_Allocation>[];
  for (final item in items) {
    final work = item.totalPomodoros * item.pomodoroMinutes;
    final share = baselineWorkMinutes <= 0 ? 0 : work / baselineWorkMinutes;
    final targetWork = targetWorkMinutes * share;
    final targetPomodoros = targetWork / item.pomodoroMinutes;
    var rounded = _roundHalfUp(targetPomodoros);
    if (rounded < 1) rounded = 1;
    allocations.add(
      _Allocation(
        item: item,
        targetPomodoros: targetPomodoros,
        pomodoros: rounded,
      ),
    );
  }

  final redistributed = [
    for (final allocation in allocations)
      _copyWithPomodoros(
        allocation.item,
        pomodoros: allocation.pomodoros,
      ),
  ];
  final actualDurationSeconds =
      groupDurationSecondsByMode(redistributed, integrityMode);

  return _RedistributionAttempt(
    items: redistributed,
    actualDurationSeconds: actualDurationSeconds,
  );
}

double _minWorkMinutes(List<TaskRunItem> items) {
  var total = 0.0;
  for (final item in items) {
    total += item.pomodoroMinutes.toDouble();
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

TaskRunItem _copyWithPomodoros(TaskRunItem item, {required int pomodoros}) {
  return TaskRunItem(
    sourceTaskId: item.sourceTaskId,
    name: item.name,
    presetId: item.presetId,
    pomodoroMinutes: item.pomodoroMinutes,
    shortBreakMinutes: item.shortBreakMinutes,
    longBreakMinutes: item.longBreakMinutes,
    totalPomodoros: pomodoros,
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

int _roundHalfUp(double value) {
  final floor = value.floor();
  if (value - floor >= 0.5) return floor + 1;
  return floor;
}

class _Allocation {
  final TaskRunItem item;
  final double targetPomodoros;
  int pomodoros;

  _Allocation({
    required this.item,
    required this.targetPomodoros,
    required this.pomodoros,
  });
}

class _RedistributionAttempt {
  final List<TaskRunItem> items;
  final int actualDurationSeconds;

  const _RedistributionAttempt({
    required this.items,
    required this.actualDurationSeconds,
  });
}

class _RedistributionSearch {
  final _RedistributionAttempt? bestWithinTime;
  final _RedistributionAttempt? bestWithinDeviation;

  const _RedistributionSearch({
    required this.bestWithinTime,
    required this.bestWithinDeviation,
  });
}
