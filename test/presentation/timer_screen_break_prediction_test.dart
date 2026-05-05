import 'package:flutter_test/flutter_test.dart';

import 'package:focus_interval/data/models/task_run_group.dart';
import 'package:focus_interval/presentation/screens/timer_screen.dart';

void main() {
  group('usesLongBreakForNextStatus', () {
    test('uses global pomodoro index in shared mode', () {
      final isLongBreak = usesLongBreakForNextStatus(
        currentPomodoro: 4,
        longBreakInterval: 4,
        integrityMode: TaskRunIntegrityMode.shared,
        globalPomodoroOffset: 3,
      );

      expect(isLongBreak, isFalse);
    });

    test('detects long break at global shared boundary', () {
      final isLongBreak = usesLongBreakForNextStatus(
        currentPomodoro: 1,
        longBreakInterval: 4,
        integrityMode: TaskRunIntegrityMode.shared,
        globalPomodoroOffset: 3,
      );

      expect(isLongBreak, isTrue);
    });

    test('keeps per-task cadence in individual mode', () {
      final isLongBreak = usesLongBreakForNextStatus(
        currentPomodoro: 4,
        longBreakInterval: 4,
        integrityMode: TaskRunIntegrityMode.individual,
        globalPomodoroOffset: 3,
      );

      expect(isLongBreak, isTrue);
    });
  });
}
