import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/pomodoro_machine.dart';
import '../providers.dart';

/// ViewModel MVVM para Pomodoro usando Riverpod 2.x.
/// - Extiende Notifier<Estado>
/// - `state` es la fuente única de verdad.
/// - Escucha la máquina y refleja sus cambios en la UI.
class PomodoroViewModel extends Notifier<PomodoroState> {
  late PomodoroMachine _machine;
  StreamSubscription<PomodoroState>? _sub;

  @override
  PomodoroState build() {
    // 1. Inyectamos la máquina desde provider (arquitectura limpia)
    _machine = ref.read(pomodoroMachineProvider);

    // 2. Estado inicial seguro
    state = PomodoroState.idle();

    // 3. Cancelamos cualquier suscripción previa (por hot reload o rebuild)
    _sub?.cancel();

    // 4. Nos suscribimos a la máquina
    _sub = _machine.stream.listen((s) {
      state = s; // NOTIFIER → actualiza la UI automáticamente
    });

    // 5. Limpiar al destruir
    ref.onDispose(() async {
      await _sub?.cancel();
      _sub = null;
    });

    return state;
  }

  // -------------------------
  //  ACCIONES DEL VIEWMODEL
  // -------------------------

  void configureTask({
    required int pomodoroMinutes,
    required int shortBreakMinutes,
    required int longBreakMinutes,
    required int totalPomodoros,
    required int longBreakInterval,
  }) {
    _machine.configureTask(
      pomodoroMinutes: pomodoroMinutes,
      shortBreakMinutes: shortBreakMinutes,
      longBreakMinutes: longBreakMinutes,
      totalPomodoros: totalPomodoros,
      longBreakInterval: longBreakInterval,
    );

    // Forzamos que la UI reciba el estado inicial actualizado
    state = PomodoroState.idle();
  }

  void start() => _machine.startTask();
  void pause() => _machine.pause();
  void resume() => _machine.resume();
  void cancel() => _machine.cancel();
}
