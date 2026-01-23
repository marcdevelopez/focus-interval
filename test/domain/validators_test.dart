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

    test('flags hard violations when breaks exceed pomodoro', () {
      final guidance = buildBreakDurationGuidance(
        pomodoroMinutes: 25,
        shortBreakMinutes: 30,
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
        longBreakMinutes: 25,
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
}
