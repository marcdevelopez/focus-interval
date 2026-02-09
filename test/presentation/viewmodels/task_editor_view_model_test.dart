import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:focus_interval/data/models/pomodoro_task.dart';
import 'package:focus_interval/data/models/selected_sound.dart';
import 'package:focus_interval/data/models/schema_version.dart';
import 'package:focus_interval/domain/validators.dart';
import 'package:focus_interval/presentation/providers.dart';

void main() {
  group('TaskEditorViewModel break guidance', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    PomodoroTask buildTask({
      required int pomodoroMinutes,
      required int shortBreakMinutes,
      required int longBreakMinutes,
    }) {
      final now = DateTime(2026, 1, 23);
      return PomodoroTask(
        id: 'task-1',
        name: 'Test task',
        dataVersion: kCurrentDataVersion,
        pomodoroMinutes: pomodoroMinutes,
        shortBreakMinutes: shortBreakMinutes,
        longBreakMinutes: longBreakMinutes,
        totalPomodoros: 4,
        longBreakInterval: 4,
        order: now.millisecondsSinceEpoch,
        startSound: const SelectedSound.builtIn('default_chime'),
        startBreakSound: const SelectedSound.builtIn('default_chime_break'),
        finishTaskSound: const SelectedSound.builtIn('default_chime_finish'),
        createdAt: now,
        updatedAt: now,
      );
    }

    test('returns optimal ranges for 25 min pomodoro', () {
      final viewModel = container.read(taskEditorProvider.notifier);
      final guidance = viewModel.breakGuidanceFor(
        buildTask(
          pomodoroMinutes: 25,
          shortBreakMinutes: 5,
          longBreakMinutes: 15,
        ),
      );

      expect(guidance, isNotNull);
      expect(guidance!.shortRange.label, '4-6');
      expect(guidance.longRange.label, '10-15');
      expect(guidance.shortStatus, BreakDurationStatus.optimal);
      expect(guidance.longStatus, BreakDurationStatus.optimal);
    });

    test('flags invalid when breaks exceed pomodoro', () {
      final viewModel = container.read(taskEditorProvider.notifier);
      final guidance = viewModel.breakGuidanceFor(
        buildTask(
          pomodoroMinutes: 25,
          shortBreakMinutes: 30,
          longBreakMinutes: 26,
        ),
      );

      expect(guidance, isNotNull);
      expect(guidance!.hasHardViolation, true);
      expect(guidance.shortStatus, BreakDurationStatus.invalid);
      expect(guidance.longStatus, BreakDurationStatus.invalid);
    });

    test('flags suboptimal but valid breaks', () {
      final viewModel = container.read(taskEditorProvider.notifier);
      final guidance = viewModel.breakGuidanceFor(
        buildTask(
          pomodoroMinutes: 50,
          shortBreakMinutes: 5,
          longBreakMinutes: 15,
        ),
      );

      expect(guidance, isNotNull);
      expect(guidance!.hasHardViolation, false);
      expect(guidance.hasSoftWarning, true);
      expect(guidance.shortStatus, BreakDurationStatus.suboptimal);
      expect(guidance.longStatus, BreakDurationStatus.suboptimal);
    });
  });
}
