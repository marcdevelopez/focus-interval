import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/pomodoro_machine.dart';
import '../data/models/pomodoro_task.dart';
import '../data/repositories/task_repository.dart';

// VIEWMODELS
import 'viewmodels/pomodoro_view_model.dart';
import 'viewmodels/task_list_view_model.dart';
import 'viewmodels/task_editor_view_model.dart';

//
// ==============================================================
//  REPO GLOBAL (MVP LOCAL)
// ==============================================================
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return InMemoryTaskRepository();
});

//
// ==============================================================
//  MÁQUINA DE ESTADOS DEL POMODORO
// ==============================================================
final pomodoroMachineProvider =
    Provider.autoDispose<PomodoroMachine>((ref) {
  final machine = PomodoroMachine();
  ref.onDispose(machine.dispose);
  return machine;
});

//
// ==============================================================
//  VIEWMODEL PRINCIPAL — POMODORO
// ==============================================================
final pomodoroViewModelProvider =
    NotifierProvider.autoDispose<PomodoroViewModel, PomodoroState>(
  PomodoroViewModel.new,
);

//
// ==============================================================
//  LISTA DE TAREAS — AsyncNotifier<List<PomodoroTask>>
// ==============================================================
final taskListProvider =
    AsyncNotifierProvider<TaskListViewModel, List<PomodoroTask>>(
      TaskListViewModel.new,
    );

//
// ==============================================================
//  EDITOR DE TAREA — Notifier<PomodoroTask?>
// ==============================================================
final taskEditorProvider = NotifierProvider<TaskEditorViewModel, PomodoroTask?>(
  TaskEditorViewModel.new,
);
