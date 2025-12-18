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
  StreamSubscription<PomodoroSession?>? _sessionSub;
  Timer? _mirrorTimer;
  String? _remoteOwnerId;

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
      _mirrorTimer?.cancel();
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
        _publishCurrentSession();
        _play(task.startSound, fallback: task.startBreakSound);
      },
      onBreakStart: (_) {
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
    if (!_controlsEnabled) return;
    _machine.startTask();
    _publishCurrentSession();
  }

  void pause() {
    if (!_controlsEnabled) return;
    _machine.pause();
    _publishCurrentSession();
  }

  void resume() {
    if (!_controlsEnabled) return;
    _machine.resume();
    _publishCurrentSession();
  }
  void cancel() {
    if (!_controlsEnabled) return;
    _machine.cancel();
    _sessionRepo.clearSession();
  }

  Future<void> _play(String soundId, {String? fallback}) =>
      _soundService.play(soundId, fallbackId: fallback);

  void _publishCurrentSession() {
    if (_currentTask == null) return;
    final current = _machine.state;
    final phaseDuration = _phaseDurationForState(current);
    final elapsed =
        (phaseDuration - current.remainingSeconds).clamp(0, phaseDuration);
    final phaseStartedAt = _isRunning(current.status)
        ? DateTime.now().subtract(Duration(seconds: elapsed))
        : null;

    final session = PomodoroSession(
      taskId: _currentTask!.id,
      ownerDeviceId: _deviceInfo.deviceId,
      status: current.status,
      phase: current.phase,
      currentPomodoro: current.currentPomodoro,
      totalPomodoros: current.totalPomodoros,
      phaseDurationSeconds: phaseDuration,
      remainingSeconds: current.remainingSeconds,
      phaseStartedAt: phaseStartedAt,
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
      if (session == null) {
        _mirrorTimer?.cancel();
        _remoteOwnerId = null;
        return;
      }
      if (session.ownerDeviceId == _deviceInfo.deviceId) {
        _mirrorTimer?.cancel();
        _remoteOwnerId = null;
        return;
      }
      if (_currentTask == null || session.taskId != _currentTask!.id) {
        // Si la sesión remota pertenece a otra tarea, no la aplicamos.
        _mirrorTimer?.cancel();
        _remoteOwnerId = null;
        return;
      }
      final isOwner = session.ownerDeviceId == _deviceInfo.deviceId;
      final allowTakeover = _shouldAllowTakeover(session);
      _remoteOwnerId = (isOwner || allowTakeover) ? null : session.ownerDeviceId;
      _setMirrorSession(session);
    });
  }

  int _remainingFromStart(int phaseDurationSeconds, DateTime startedAt) {
    final elapsed =
        DateTime.now().difference(startedAt).inSeconds.clamp(0, phaseDurationSeconds);
    final remaining = phaseDurationSeconds - elapsed;
    return remaining > 0 ? remaining : 0;
  }

  void _setMirrorSession(PomodoroSession session) {
    _mirrorTimer?.cancel();
    _updateMirrorStateFromSession(session);
    if (_isRunning(session.status) && session.phaseStartedAt != null) {
      _mirrorTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        _updateMirrorStateFromSession(session);
      });
    }
  }

  void _updateMirrorStateFromSession(PomodoroSession session) {
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
  }

  bool _isRunning(PomodoroStatus status) =>
      status == PomodoroStatus.pomodoroRunning ||
      status == PomodoroStatus.shortBreakRunning ||
      status == PomodoroStatus.longBreakRunning;

  bool _isStale(DateTime? updatedAt, {int minutes = 5}) {
    if (updatedAt == null) return true;
    return DateTime.now().difference(updatedAt).inMinutes >= minutes;
  }

  bool _shouldAllowTakeover(PomodoroSession session) {
    // Permitimos retomar si no está corriendo y la sesión es vieja.
    if (_isRunning(session.status)) return false;
    return _isStale(session.lastUpdatedAt, minutes: 5);
  }

  bool get _controlsEnabled =>
      _remoteOwnerId == null || _remoteOwnerId == _deviceInfo.deviceId;
}
