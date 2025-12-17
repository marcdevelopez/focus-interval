import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/pomodoro_task.dart';
import '../../domain/pomodoro_machine.dart';
import '../providers.dart';
import '../../data/services/sound_service.dart';

class PomodoroViewModel extends Notifier<PomodoroState> {
  late PomodoroMachine _machine;
  StreamSubscription<PomodoroState>? _sub;
  late SoundService _soundService;
  PomodoroTask? _currentTask;

  @override
  PomodoroState build() {
    // Mantener viva la máquina mientras exista el VM
    _machine = ref.watch(pomodoroMachineProvider);
    _soundService = ref.watch(soundServiceProvider);

    // escuchamos estados
    _sub = _machine.stream.listen((s) => state = s);

    // limpiar recursos
    ref.onDispose(() {
      _sub?.cancel();
    });

    return _machine.state;
  }

  // cargar valores desde TaskRepository
  Future<bool> loadTask(String taskId) async {
    final repo = ref.read(taskRepositoryProvider);
    final PomodoroTask? task = await repo.getById(taskId);
    if (task == null) return false;

    configureFromTask(task);
    return true;
  }

  void configureFromTask(PomodoroTask task) {
    _currentTask = task;
    _machine.callbacks = PomodoroCallbacks(
      onPomodoroStart: (_) => _play(task.startSound, fallback: task.startBreakSound),
      onBreakStart: (_) => _play(task.startBreakSound, fallback: task.startSound),
      onTaskFinished: (_) => _play(task.finishTaskSound, fallback: task.startSound),
    );

    _machine.configureTask(
      pomodoroMinutes: task.pomodoroMinutes,
      shortBreakMinutes: task.shortBreakMinutes,
      longBreakMinutes: task.longBreakMinutes,
      totalPomodoros: task.totalPomodoros,
      longBreakInterval: task.longBreakInterval,
    );

    state = _machine.state;
  }

  void start() => _machine.startTask();
  void pause() => _machine.pause();
  void resume() => _machine.resume();
  void cancel() => _machine.cancel();

  Future<void> _play(String soundId, {String? fallback}) =>
      _soundService.play(soundId, fallbackId: fallback);
}
