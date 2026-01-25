import 'package:flutter_test/flutter_test.dart';
import 'package:focus_interval/domain/validators.dart';

void main() {
  group('BreakDurationGuidance', () {
    test('computes short/long ranges for 25 min pomodoro', () {
      final guidance = buildBreakDurationGuidance(
        pomodoroMinutes: 25,
        shortBreakMinutes: 5,
        longBreakMinutes: 15,
      );

      expect(guidance.shortRange.min, 4);
      expect(guidance.shortRange.max, 6);
      expect(guidance.longRange.min, 10);
      expect(guidance.longRange.max, 15);
    });

    test('computes short/long ranges for 50 min pomodoro', () {
      final guidance = buildBreakDurationGuidance(
        pomodoroMinutes: 50,
        shortBreakMinutes: 10,
        longBreakMinutes: 25,
      );

      expect(guidance.shortRange.min, 8);
      expect(guidance.shortRange.max, 13);
      expect(guidance.longRange.min, 20);
      expect(guidance.longRange.max, 30);
    });

    test('flags hard violations when breaks meet or exceed pomodoro', () {
      final guidance = buildBreakDurationGuidance(
        pomodoroMinutes: 25,
        shortBreakMinutes: 25,
        longBreakMinutes: 26,
      );

      expect(guidance.shortExceedsPomodoro, true);
      expect(guidance.longExceedsPomodoro, true);
      expect(guidance.hasHardViolation, true);
      expect(guidance.shortStatus, BreakDurationStatus.invalid);
      expect(guidance.longStatus, BreakDurationStatus.invalid);
    });

    test('flags soft warnings when breaks are valid but suboptimal', () {
      final guidance = buildBreakDurationGuidance(
        pomodoroMinutes: 25,
        shortBreakMinutes: 2,
        longBreakMinutes: 20,
      );

      expect(guidance.hasHardViolation, false);
      expect(guidance.shortStatus, BreakDurationStatus.suboptimal);
      expect(guidance.longStatus, BreakDurationStatus.suboptimal);
      expect(guidance.hasSoftWarning, true);
    });

    test('marks optimal ranges when within evidence-based ratios', () {
      final guidance = buildBreakDurationGuidance(
        pomodoroMinutes: 35,
        shortBreakMinutes: 6,
        longBreakMinutes: 18,
      );

      expect(guidance.shortStatus, BreakDurationStatus.optimal);
      expect(guidance.longStatus, BreakDurationStatus.optimal);
      expect(guidance.hasSoftWarning, false);
      expect(guidance.hasHardViolation, false);
    });
  });

  group('BreakDurationOrder', () {
    test('requires long break to be strictly longer than short break', () {
      expect(
        isBreakOrderValid(shortBreakMinutes: 5, longBreakMinutes: 15),
        true,
      );
      expect(
        isBreakOrderValid(shortBreakMinutes: 10, longBreakMinutes: 10),
        false,
      );
      expect(
        isBreakOrderValid(shortBreakMinutes: 12, longBreakMinutes: 10),
        false,
      );
    });

    test('provides field-specific errors when order is invalid', () {
      final shortError = breakOrderError(
        shortBreakMinutes: 10,
        longBreakMinutes: 10,
        field: BreakOrderField.shortBreak,
      );
      final longError = breakOrderError(
        shortBreakMinutes: 10,
        longBreakMinutes: 10,
        field: BreakOrderField.longBreak,
      );

      expect(shortError, contains('Short break'));
      expect(longError, contains('Long break'));
    });
  });

  group('LongBreakIntervalGuidance', () {
    test('marks 4 pomodoros as optimal', () {
      final guidance = buildLongBreakIntervalGuidance(
        interval: 4,
        totalPomodoros: 4,
      );

      expect(guidance.status, LongBreakIntervalStatus.optimal);
      expect(
        guidance.helperText,
        contains('Recommended: Classic cadence'),
      );
      expect(guidance.exceedsTotalPomodoros, false);
    });

    test('marks 3-6 pomodoros as acceptable (excluding 4)', () {
      final guidance = buildLongBreakIntervalGuidance(
        interval: 5,
        totalPomodoros: 8,
      );

      expect(guidance.status, LongBreakIntervalStatus.acceptable);
      expect(guidance.helperText, contains('Acceptable: 3-6 works'));
    });

    test('marks 1-2 pomodoros as warning', () {
      final guidance = buildLongBreakIntervalGuidance(
        interval: 2,
        totalPomodoros: 6,
      );

      expect(guidance.status, LongBreakIntervalStatus.warning);
      expect(guidance.helperText, contains('Too frequent'));
    });

    test('marks 7+ pomodoros as warning', () {
      final guidance = buildLongBreakIntervalGuidance(
        interval: 7,
        totalPomodoros: 10,
      );

      expect(guidance.status, LongBreakIntervalStatus.warning);
      expect(guidance.helperText, contains('Too long'));
    });

    test('adds note when interval exceeds total pomodoros', () {
      final guidance = buildLongBreakIntervalGuidance(
        interval: 6,
        totalPomodoros: 4,
      );

      expect(guidance.exceedsTotalPomodoros, true);
      expect(
        guidance.helperText,
        contains('only short breaks'),
      );
    });
  });

  group('PomodoroDurationGuidance', () {
    test('flags invalid when below 15 minutes', () {
      final guidance = buildPomodoroDurationGuidance(minutes: 10);
      expect(guidance.isValid, false);
      expect(guidance.status, PomodoroDurationStatus.invalid);
      expect(guidance.helperText, contains('Min allowed'));
    });

    test('flags invalid when above 60 minutes', () {
      final guidance = buildPomodoroDurationGuidance(minutes: 70);
      expect(guidance.isValid, false);
      expect(guidance.status, PomodoroDurationStatus.invalid);
      expect(guidance.helperText, contains('Max allowed'));
    });

    test('marks 25 minutes as optimal', () {
      final guidance = buildPomodoroDurationGuidance(minutes: 25);
      expect(guidance.isValid, true);
      expect(guidance.status, PomodoroDurationStatus.optimal);
      expect(guidance.helperText, contains('25 min'));
    });

    test('marks 20-30 minutes as creative (excluding 25)', () {
      final guidance = buildPomodoroDurationGuidance(minutes: 20);
      expect(guidance.status, PomodoroDurationStatus.creative);
      expect(guidance.helperText, contains('Creative range'));
    });

    test('marks 31-34 minutes as general', () {
      final guidance = buildPomodoroDurationGuidance(minutes: 32);
      expect(guidance.status, PomodoroDurationStatus.general);
      expect(guidance.helperText, contains('General work'));
    });

    test('marks 35-45 minutes as deep', () {
      final guidance = buildPomodoroDurationGuidance(minutes: 40);
      expect(guidance.status, PomodoroDurationStatus.deep);
      expect(guidance.helperText, contains('Deep work'));
    });

    test('marks 15-19 minutes as warning', () {
      final guidance = buildPomodoroDurationGuidance(minutes: 18);
      expect(guidance.status, PomodoroDurationStatus.warning);
      expect(guidance.helperText, contains('Too short'));
    });

    test('marks 46-60 minutes as warning', () {
      final guidance = buildPomodoroDurationGuidance(minutes: 50);
      expect(guidance.status, PomodoroDurationStatus.warning);
      expect(guidance.helperText, contains('Over 45'));
    });
  });
}
