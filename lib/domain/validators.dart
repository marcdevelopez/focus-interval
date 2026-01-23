class IntRange {
  final int min;
  final int max;

  const IntRange({required this.min, required this.max});

  String get label => '$min-$max';

  bool contains(int value) => value >= min && value <= max;
}

enum BreakDurationStatus { optimal, suboptimal, invalid }

class BreakDurationGuidance {
  final int pomodoroMinutes;
  final int shortBreakMinutes;
  final int longBreakMinutes;
  final IntRange shortRange;
  final IntRange longRange;
  final BreakDurationStatus shortStatus;
  final BreakDurationStatus longStatus;
  final bool shortExceedsPomodoro;
  final bool longExceedsPomodoro;

  const BreakDurationGuidance({
    required this.pomodoroMinutes,
    required this.shortBreakMinutes,
    required this.longBreakMinutes,
    required this.shortRange,
    required this.longRange,
    required this.shortStatus,
    required this.longStatus,
    required this.shortExceedsPomodoro,
    required this.longExceedsPomodoro,
  });

  bool get hasHardViolation => shortExceedsPomodoro || longExceedsPomodoro;

  bool get hasSoftWarning =>
      !hasHardViolation &&
      (shortStatus == BreakDurationStatus.suboptimal ||
          longStatus == BreakDurationStatus.suboptimal);
}

BreakDurationGuidance buildBreakDurationGuidance({
  required int pomodoroMinutes,
  required int shortBreakMinutes,
  required int longBreakMinutes,
}) {
  final safePomodoro = pomodoroMinutes <= 0 ? 1 : pomodoroMinutes;
  final shortRange = _buildRange(
    safePomodoro,
    minRatio: 0.15,
    maxRatio: 0.25,
  );
  final longRange = _buildRange(
    safePomodoro,
    minRatio: 0.40,
    maxRatio: 0.60,
  );

  final shortExceedsPomodoro = shortBreakMinutes > safePomodoro;
  final longExceedsPomodoro = longBreakMinutes > safePomodoro;

  final shortStatus = shortExceedsPomodoro
      ? BreakDurationStatus.invalid
      : shortRange.contains(shortBreakMinutes)
      ? BreakDurationStatus.optimal
      : BreakDurationStatus.suboptimal;

  final longStatus = longExceedsPomodoro
      ? BreakDurationStatus.invalid
      : longRange.contains(longBreakMinutes)
      ? BreakDurationStatus.optimal
      : BreakDurationStatus.suboptimal;

  return BreakDurationGuidance(
    pomodoroMinutes: safePomodoro,
    shortBreakMinutes: shortBreakMinutes,
    longBreakMinutes: longBreakMinutes,
    shortRange: shortRange,
    longRange: longRange,
    shortStatus: shortStatus,
    longStatus: longStatus,
    shortExceedsPomodoro: shortExceedsPomodoro,
    longExceedsPomodoro: longExceedsPomodoro,
  );
}

IntRange _buildRange(
  int pomodoroMinutes, {
  required double minRatio,
  required double maxRatio,
}) {
  final rawMin = (pomodoroMinutes * minRatio).round();
  final rawMax = (pomodoroMinutes * maxRatio).round();
  final min = rawMin < 1 ? 1 : rawMin;
  final max = rawMax < min ? min : rawMax;
  return IntRange(min: min, max: max);
}
