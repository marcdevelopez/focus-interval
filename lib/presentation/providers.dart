import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/task_repository.dart';
import '../domain/pomodoro_machine.dart';
import 'viewmodels/pomodoro_view_model.dart';

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return InMemoryTaskRepository();
});

final pomodoroMachineProvider = Provider<PomodoroMachine>((ref) {
  final machine = PomodoroMachine();
  ref.onDispose(machine.dispose);
  return machine;
});

final pomodoroViewModelProvider =
    NotifierProvider<PomodoroViewModel, PomodoroState>(PomodoroViewModel.new);
