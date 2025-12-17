import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/pomodoro_task.dart';
import '../../data/models/pomodoro_session.dart';
import '../../domain/pomodoro_machine.dart';
import '../../data/services/sound_service.dart';
import '../providers.dart';
import '../../data/repositories/pomodoro_session_repository.dart';
import '../../data/services/device_info_service.dart';

class PomodoroViewModel extends Notifier<PomodoroState> {
  late PomodoroMachine _machine;
  StreamSubscription<PomodoroState>? _sub;
  late SoundService _soundService;
  late PomodoroSessionRepository _sessionRepo;
  late DeviceInfoService _deviceInfo;
  PomodoroTask? _currentTask;
  DateTime? _phaseStartedAt;
  StreamSubscription<PomodoroSession?>? _sessionSub;

  @override
  PomodoroState build() {
    // Mantener viva la máquina mientras exista el VM
    _machine = ref.watch(pomodoroMachineProvider);
    _soundService = ref.watch(soundServiceProvider);
    _sessionRepo = ref.watch(pomodoroSessionRepositoryProvider);
    _deviceInfo = ref.watch(deviceInfoServiceProvider);

    // escuchamos estados
    _sub = _machine.stream.listen((s) => state = s);

    // limpiar recursos
    ref.onDispose(() {
      _sub?.cancel();
      _sessionSub?.cancel();
    });

    return _machine.state;
  }

  // cargar valores desde TaskRepository
  Future<bool> loadTask(String taskId) async {
    final repo = ref.read(taskRepositoryProvider);
    final PomodoroTask? task = await repo.getById(taskId);
    if (task == null) return false;

    _currentTask = task;
    configureFromTask(task);
    _subscribeToRemoteSession();
    return true;
  }

  void configureFromTask(PomodoroTask task) {
    _machine.callbacks = PomodoroCallbacks(
      onPomodoroStart: (_) {
        _phaseStartedAt = DateTime.now();
        _publishCurrentSession();
        _play(task.startSound, fallback: task.startBreakSound);
      },
      onBreakStart: (_) {
        _phaseStartedAt = DateTime.now();
        _publishCurrentSession();
        _play(task.startBreakSound, fallback: task.startSound);
      },
      onTaskFinished: (_) {
        _publishCurrentSession();
        _play(task.finishTaskSound, fallback: task.startSound);
        _sessionRepo.clearSession();
      },
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

  void start() {
    _phaseStartedAt = DateTime.now();
    _machine.startTask();
  }

  void pause() {
    _machine.pause();
    _publishCurrentSession();
  }

  void resume() {
    _phaseStartedAt = DateTime.now();
    _machine.resume();
    _publishCurrentSession();
  }
  void cancel() {
    _machine.cancel();
    _sessionRepo.clearSession();
  }

  Future<void> _play(String soundId, {String? fallback}) =>
      _soundService.play(soundId, fallbackId: fallback);

  void _publishCurrentSession() {
    if (_currentTask == null) return;
    final current = _machine.state;
    final session = PomodoroSession(
      taskId: _currentTask!.id,
      ownerDeviceId: _deviceInfo.deviceId,
      status: current.status,
      phase: current.phase,
      currentPomodoro: current.currentPomodoro,
      totalPomodoros: current.totalPomodoros,
      phaseDurationSeconds: _phaseDurationForState(current),
      remainingSeconds: current.remainingSeconds,
      phaseStartedAt: _phaseStartedAt,
      lastUpdatedAt: DateTime.now(),
    );
    _sessionRepo.publishSession(session);
  }

  int _phaseDurationForState(PomodoroState state) {
    if (_currentTask == null) return state.totalSeconds;
    switch (state.phase) {
      case PomodoroPhase.pomodoro:
        return _currentTask!.pomodoroMinutes * 60;
      case PomodoroPhase.shortBreak:
        return _currentTask!.shortBreakMinutes * 60;
      case PomodoroPhase.longBreak:
        return _currentTask!.longBreakMinutes * 60;
      default:
        return state.totalSeconds;
    }
  }

  void _subscribeToRemoteSession() {
    _sessionSub?.cancel();
    _sessionSub = _sessionRepo.watchSession().listen((session) {
      if (session == null) return;
      if (session.ownerDeviceId == _deviceInfo.deviceId) return;
      // Modo espejo básico: reflejar estado remoto.
      final remaining = session.phaseStartedAt != null
          ? _remainingFromStart(
              session.phaseDurationSeconds, session.phaseStartedAt!)
          : session.remainingSeconds;
      state = PomodoroState(
        status: session.status,
        phase: session.phase,
        currentPomodoro: session.currentPomodoro,
        totalPomodoros: session.totalPomodoros,
        totalSeconds: session.phaseDurationSeconds,
        remainingSeconds: remaining,
      );
    });
  }

  int _remainingFromStart(int phaseDurationSeconds, DateTime startedAt) {
    final elapsed =
        DateTime.now().difference(startedAt).inSeconds.clamp(0, phaseDurationSeconds);
    final remaining = phaseDurationSeconds - elapsed;
    return remaining > 0 ? remaining : 0;
  }
}
