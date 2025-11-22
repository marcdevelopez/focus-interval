import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/pomodoro_machine.dart';
import 'viewmodels/pomodoro_view_model.dart';

// Proveedor de la máquina (singleton)
final pomodoroMachineProvider = Provider<PomodoroMachine>((ref) {
  return PomodoroMachine();
});

// ViewModel MVVM usando NotifierProvider
final pomodoroViewModelProvider =
    NotifierProvider<PomodoroViewModel, PomodoroState>(PomodoroViewModel.new);
