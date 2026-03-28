import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:focus_interval/data/models/pomodoro_task.dart';
import 'package:focus_interval/data/models/selected_sound.dart';
import 'package:focus_interval/data/models/schema_version.dart';
import 'package:focus_interval/domain/validators.dart';
import 'package:focus_interval/presentation/providers.dart';
import 'package:focus_interval/presentation/viewmodels/task_editor_view_model.dart';

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

  group('TaskEditorViewModel weight redistribution', () {
    late ProviderContainer container;
    late DateTime now;

    setUp(() {
      container = ProviderContainer();
      now = DateTime(2026, 3, 28);
    });

    tearDown(() {
      container.dispose();
    });

    PomodoroTask buildTask({
      required String id,
      required int totalPomodoros,
      int pomodoroMinutes = 15,
    }) {
      return PomodoroTask(
        id: id,
        name: id,
        dataVersion: kCurrentDataVersion,
        pomodoroMinutes: pomodoroMinutes,
        shortBreakMinutes: 5,
        longBreakMinutes: 15,
        totalPomodoros: totalPomodoros,
        longBreakInterval: 4,
        order: now.millisecondsSinceEpoch,
        startSound: const SelectedSound.builtIn('default_chime'),
        startBreakSound: const SelectedSound.builtIn('default_chime_break'),
        finishTaskSound: const SelectedSound.builtIn('default_chime_finish'),
        createdAt: now,
        updatedAt: now,
      );
    }

    test('redistributeWeightPercent keeps existing fixed behavior', () {
      final viewModel = container.read(taskEditorProvider.notifier);
      final edited = buildTask(id: 'A', totalPomodoros: 5);
      final tasks = [
        edited,
        buildTask(id: 'B', totalPomodoros: 4),
        buildTask(id: 'C', totalPomodoros: 1),
        buildTask(id: 'D', totalPomodoros: 1),
      ];

      final defaultResult = viewModel.redistributeWeightPercent(
        edited: edited,
        targetPercent: 80,
        tasks: tasks,
      );
      final fixedResult = viewModel.redistributeWeightPercent(
        edited: edited,
        targetPercent: 80,
        tasks: tasks,
        mode: WeightEditMode.fixed,
      );

      expect(defaultResult, fixedResult);
    });

    test('redistributeWeightPercent flexible changes only edited task', () {
      final viewModel = container.read(taskEditorProvider.notifier);
      final edited = buildTask(id: 'A', totalPomodoros: 5);
      final tasks = [
        edited,
        buildTask(id: 'B', totalPomodoros: 4),
        buildTask(id: 'C', totalPomodoros: 1),
        buildTask(id: 'D', totalPomodoros: 1),
      ];

      final result = viewModel.redistributeWeightPercent(
        edited: edited,
        targetPercent: 80,
        tasks: tasks,
        mode: WeightEditMode.flexible,
      );

      expect(result['B'], 4);
      expect(result['C'], 1);
      expect(result['D'], 1);
      expect(result['A'], inInclusiveRange(1, 27));
    });

    test('redistributeTotalPomodoros fixed preserves group total', () {
      final viewModel = container.read(taskEditorProvider.notifier);
      final edited = buildTask(id: 'A', totalPomodoros: 5);
      final tasks = [
        edited,
        buildTask(id: 'B', totalPomodoros: 4),
        buildTask(id: 'C', totalPomodoros: 1),
        buildTask(id: 'D', totalPomodoros: 1),
      ];

      final result = viewModel.redistributeTotalPomodoros(
        edited: edited,
        targetPomodoros: 8,
        tasks: tasks,
        mode: WeightEditMode.fixed,
      );

      final total = result.values.fold<int>(0, (sum, value) => sum + value);
      expect(total, 11);
      expect(result['A'], 8);
      expect(result['B']!, greaterThanOrEqualTo(1));
      expect(result['C']!, greaterThanOrEqualTo(1));
      expect(result['D']!, greaterThanOrEqualTo(1));
    });

    test('redistributeTotalPomodoros flexible changes only edited task', () {
      final viewModel = container.read(taskEditorProvider.notifier);
      final edited = buildTask(id: 'A', totalPomodoros: 5);
      final tasks = [
        edited,
        buildTask(id: 'B', totalPomodoros: 4),
        buildTask(id: 'C', totalPomodoros: 1),
        buildTask(id: 'D', totalPomodoros: 1),
      ];

      final result = viewModel.redistributeTotalPomodoros(
        edited: edited,
        targetPomodoros: 8,
        tasks: tasks,
        mode: WeightEditMode.flexible,
      );

      expect(result['A'], 8);
      expect(result['B'], 4);
      expect(result['C'], 1);
      expect(result['D'], 1);
    });

    test('flexible tiebreak favors smallest group-total change', () {
      final viewModel = container.read(taskEditorProvider.notifier);
      final edited = buildTask(id: 'A', totalPomodoros: 90);
      final tasks = [
        edited,
        buildTask(id: 'B', totalPomodoros: 1),
        buildTask(id: 'C', totalPomodoros: 1),
        buildTask(id: 'D', totalPomodoros: 1),
      ];

      final result = viewModel.redistributeWeightPercent(
        edited: edited,
        targetPercent: 98,
        tasks: tasks,
        mode: WeightEditMode.flexible,
      );

      expect(result['A'], 90);
      expect(result['B'], 1);
      expect(result['C'], 1);
      expect(result['D'], 1);
    });
  });
}
