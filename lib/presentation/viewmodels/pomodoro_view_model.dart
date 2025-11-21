import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/pomodoro_machine.dart';
import '../providers.dart';

class PomodoroViewModel extends Notifier<PomodoroState> {
  late PomodoroMachine _machine;
  StreamSubscription<PomodoroState>? _sub;

  @override
  PomodoroState build() {
    _machine = ref.read(pomodoroMachineProvider);

    // Estado inicial
    state = PomodoroState.idle();

    // Escuchamos máquina y reflejamos en UI
    _sub = _machine.stream.listen((s) {
      state = s;
    });

    ref.onDispose(() {
      _sub?.cancel();
    });

    return state;
  }

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
  }

  void start() => _machine.startTask();
  void pause() => _machine.pause();
  void resume() => _machine.resume();
  void cancel() => _machine.cancel();
}
