class IntRange {
  final int min;
  final int max;

  const IntRange({required this.min, required this.max});

  String get label => '$min-$max';

  bool contains(int value) => value >= min && value <= max;
}

enum BreakDurationStatus { optimal, suboptimal, invalid }

enum LongBreakIntervalStatus { optimal, acceptable, warning }

enum PomodoroDurationStatus { optimal, creative, general, deep, warning, invalid }

enum BreakOrderField { shortBreak, longBreak }

const int maxLongBreakInterval = 12;

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

  final shortExceedsPomodoro = shortBreakMinutes >= safePomodoro;
  final longExceedsPomodoro = longBreakMinutes >= safePomodoro;

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

bool isBreakOrderValid({
  required int shortBreakMinutes,
  required int longBreakMinutes,
}) {
  if (shortBreakMinutes <= 0 || longBreakMinutes <= 0) return true;
  return shortBreakMinutes < longBreakMinutes;
}

String? breakOrderError({
  required int shortBreakMinutes,
  required int longBreakMinutes,
  required BreakOrderField field,
}) {
  if (isBreakOrderValid(
    shortBreakMinutes: shortBreakMinutes,
    longBreakMinutes: longBreakMinutes,
  )) {
    return null;
  }
  return switch (field) {
    BreakOrderField.shortBreak =>
      'Short break must be shorter than long break.',
    BreakOrderField.longBreak =>
      'Long break must be longer than short break.',
  };
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

class LongBreakIntervalGuidance {
  final int interval;
  final int totalPomodoros;
  final LongBreakIntervalStatus status;
  final String helperText;
  final bool exceedsTotalPomodoros;

  const LongBreakIntervalGuidance({
    required this.interval,
    required this.totalPomodoros,
    required this.status,
    required this.helperText,
    required this.exceedsTotalPomodoros,
  });
}

LongBreakIntervalGuidance buildLongBreakIntervalGuidance({
  required int interval,
  required int totalPomodoros,
}) {
  final effectiveInterval = interval <= 0 ? 1 : interval;
  final status = _intervalStatus(effectiveInterval);
  var text = _intervalBaseMessage(effectiveInterval);
  final exceedsTotal = totalPomodoros > 0 && effectiveInterval > totalPomodoros;
  if (exceedsTotal) {
    text = '$text\nNote: Interval > total; only short breaks.';
  }

  return LongBreakIntervalGuidance(
    interval: effectiveInterval,
    totalPomodoros: totalPomodoros,
    status: status,
    helperText: text,
    exceedsTotalPomodoros: exceedsTotal,
  );
}

LongBreakIntervalStatus _intervalStatus(int interval) {
  if (interval == 4) return LongBreakIntervalStatus.optimal;
  if (interval >= 3 && interval <= 6) return LongBreakIntervalStatus.acceptable;
  return LongBreakIntervalStatus.warning;
}

String _intervalBaseMessage(int interval) {
  if (interval == 4) {
    return 'Recommended: Classic cadence is 4 pomodoros.';
  }
  if (interval >= 3 && interval <= 6) {
    return 'Acceptable: 3-6 works; 4 is optimal.';
  }
  if (interval <= 2) {
    return 'Warning: Too frequent can fragment focus. Consider 4.';
  }
  return 'Warning: Too long can increase fatigue. Consider 4.';
}

class PomodoroDurationGuidance {
  final int minutes;
  final PomodoroDurationStatus status;
  final String helperText;
  final bool isValid;

  const PomodoroDurationGuidance({
    required this.minutes,
    required this.status,
    required this.helperText,
    required this.isValid,
  });
}

PomodoroDurationGuidance buildPomodoroDurationGuidance({
  required int minutes,
}) {
  final safeMinutes = minutes;
  if (safeMinutes < 15) {
    return PomodoroDurationGuidance(
      minutes: safeMinutes,
      status: PomodoroDurationStatus.invalid,
      helperText:
          'Error: Under 15 min is too short for flow. Min allowed: 15.',
      isValid: false,
    );
  }
  if (safeMinutes > 60) {
    return PomodoroDurationGuidance(
      minutes: safeMinutes,
      status: PomodoroDurationStatus.invalid,
      helperText:
          'Error: Over 60 min exceeds sustained focus. Max allowed: 60.',
      isValid: false,
    );
  }
  if (safeMinutes == 25) {
    return PomodoroDurationGuidance(
      minutes: safeMinutes,
      status: PomodoroDurationStatus.optimal,
      helperText: 'Recommended: 25 min is the classic Pomodoro standard.',
      isValid: true,
    );
  }
  if (safeMinutes >= 20 && safeMinutes <= 30) {
    return PomodoroDurationGuidance(
      minutes: safeMinutes,
      status: PomodoroDurationStatus.creative,
      helperText: 'Creative range: 20-30 min fits ideation and writing.',
      isValid: true,
    );
  }
  if (safeMinutes >= 31 && safeMinutes <= 34) {
    return PomodoroDurationGuidance(
      minutes: safeMinutes,
      status: PomodoroDurationStatus.general,
      helperText: 'General work: 25-35 min is a solid range.',
      isValid: true,
    );
  }
  if (safeMinutes >= 35 && safeMinutes <= 45) {
    return PomodoroDurationGuidance(
      minutes: safeMinutes,
      status: PomodoroDurationStatus.deep,
      helperText: 'Deep work: 35-45 min can work but raises fatigue risk.',
      isValid: true,
    );
  }
  if (safeMinutes >= 15 && safeMinutes <= 19) {
    return PomodoroDurationGuidance(
      minutes: safeMinutes,
      status: PomodoroDurationStatus.warning,
      helperText: 'Warning: Too short can break flow. Try 20-25.',
      isValid: true,
    );
  }
  return PomodoroDurationGuidance(
    minutes: safeMinutes,
    status: PomodoroDurationStatus.warning,
    helperText: 'Warning: Over 45 min can fatigue. Try 35-45.',
    isValid: true,
  );
}
