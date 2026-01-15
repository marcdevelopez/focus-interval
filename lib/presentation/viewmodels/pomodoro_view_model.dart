import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/pomodoro_task.dart';
import '../../data/models/pomodoro_session.dart';
import '../../domain/pomodoro_machine.dart';
import '../../data/services/sound_service.dart';
import '../providers.dart';
import '../../data/repositories/pomodoro_session_repository.dart';
import '../../data/services/device_info_service.dart';
import '../../data/services/notification_service.dart';
import '../../data/services/foreground_service.dart';

enum PomodoroTaskLoadResult {
  loaded,
  notFound,
  blockedByActiveSession,
}

class PomodoroViewModel extends Notifier<PomodoroState> {
  static const int _heartbeatIntervalSeconds = 30;
  late PomodoroMachine _machine;
  StreamSubscription<PomodoroState>? _sub;
  late SoundService _soundService;
  late NotificationService _notificationService;
  late PomodoroSessionRepository _sessionRepo;
  late DeviceInfoService _deviceInfo;
  PomodoroTask? _currentTask;
  StreamSubscription<PomodoroSession?>? _sessionSub;
  Timer? _mirrorTimer;
  String? _remoteOwnerId;
  PomodoroSession? _remoteSession;
  PomodoroSession? _latestSession;
  DateTime? _localPhaseStartedAt;
  DateTime? _lastHeartbeatAt;
  DateTime? _finishedAt;
  String? _pauseReason;
  bool _foregroundActive = false;
  String? _foregroundTitle;
  String? _foregroundText;

  @override
  PomodoroState build() {
    // Keep the machine alive while the VM exists.
    _machine = ref.watch(pomodoroMachineProvider);
    _soundService = ref.watch(soundServiceProvider);
    _notificationService = ref.watch(notificationServiceProvider);
    _sessionRepo = ref.watch(pomodoroSessionRepositoryProvider);
    _deviceInfo = ref.watch(deviceInfoServiceProvider);

    // Listen to states.
    _sub = _machine.stream.listen((s) {
      state = s;
      _syncForegroundService(s);
    });

    // Clean up resources.
    ref.onDispose(() {
      _sub?.cancel();
      _sessionSub?.cancel();
      _mirrorTimer?.cancel();
      _stopForegroundService();
    });

    return _machine.state;
  }

  // Load values from TaskRepository.
  Future<PomodoroTaskLoadResult> loadTask(String taskId) async {
    final session = await _readCurrentSession();
    _latestSession = session;
    if (_hasActiveConflict(session, taskId)) {
      return PomodoroTaskLoadResult.blockedByActiveSession;
    }
    final repo = ref.read(taskRepositoryProvider);
    final PomodoroTask? task = await repo.getById(taskId);
    if (task == null) return PomodoroTaskLoadResult.notFound;

    _currentTask = task;
    _finishedAt = null;
    _lastHeartbeatAt = null;
    _pauseReason = null;
    configureFromTask(task);
    _subscribeToRemoteSession();
    unawaited(_notificationService.requestPermissions());
    return PomodoroTaskLoadResult.loaded;
  }

  void configureFromTask(PomodoroTask task) {
    _machine.callbacks = PomodoroCallbacks(
      onPomodoroStart: (_) {
        _markPhaseStartedFromState(_machine.state);
        _publishCurrentSession();
        _play(task.startSound, fallback: task.startBreakSound);
      },
      onPomodoroEnd: (s) {
        if (s.currentPomodoro >= s.totalPomodoros) return;
        _notifyPomodoroEnd(s);
      },
      onBreakStart: (_) {
        _markPhaseStartedFromState(_machine.state);
        _publishCurrentSession();
        _play(task.startBreakSound, fallback: task.startSound);
      },
      onTaskFinished: (_) {
        _publishCurrentSession();
        _notifyTaskFinished();
        _play(task.finishTaskSound, fallback: task.startSound);
      },
      onTick: _maybeHeartbeat,
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
    _finishedAt = null;
    _lastHeartbeatAt = null;
    _pauseReason = null;
    _machine.startTask();
    _markPhaseStartedFromState(_machine.state);
    _publishCurrentSession();
  }

  void pause() {
    if (!_controlsEnabled) return;
    _pauseReason = 'user';
    _machine.pause();
    _localPhaseStartedAt = null;
    _publishCurrentSession();
  }

  void resume() {
    if (!_controlsEnabled) return;
    _pauseReason = null;
    _machine.resume();
    _markPhaseStartedFromState(_machine.state);
    _publishCurrentSession();
  }

  void cancel() {
    if (!_controlsEnabled) return;
    _finishedAt = null;
    _lastHeartbeatAt = null;
    _pauseReason = null;
    _machine.cancel();
    _localPhaseStartedAt = null;
    _sessionRepo.clearSession();
  }

  Future<void> takeOver() async {
    final session = _remoteSession;
    if (session == null || !_shouldAllowTakeover(session)) return;
    if (_currentTask == null || session.taskId != _currentTask!.id) return;

    _mirrorTimer?.cancel();

    final now = DateTime.now();
    final projected = _projectStateFromSession(session, now: now);
    final totalSeconds = projected.totalSeconds;
    final normalizedRemaining = totalSeconds <= 0
        ? 0
        : projected.remainingSeconds.clamp(0, totalSeconds).toInt();
    final phaseStartedAt = _isRunning(projected.status)
        ? now.subtract(
            Duration(seconds: totalSeconds - normalizedRemaining),
          )
        : null;
    final finishedAt = projected.status == PomodoroStatus.finished
        ? (session.finishedAt ?? now)
        : null;
    final pauseReason = projected.status == PomodoroStatus.paused
        ? session.pauseReason
        : null;

    final takeover = PomodoroSession(
      taskId: session.taskId,
      ownerDeviceId: _deviceInfo.deviceId,
      status: projected.status,
      phase: projected.phase,
      currentPomodoro: projected.currentPomodoro,
      totalPomodoros: projected.totalPomodoros,
      phaseDurationSeconds: totalSeconds,
      remainingSeconds: normalizedRemaining,
      phaseStartedAt: phaseStartedAt,
      lastUpdatedAt: now,
      finishedAt: finishedAt,
      pauseReason: pauseReason,
    );

    _remoteOwnerId = null;
    _remoteSession = null;
    _finishedAt = finishedAt;
    _pauseReason = pauseReason;
    _applyProjectedState(projected, now: now);

    await _sessionRepo.publishSession(takeover);
  }

  Future<void> _play(String soundId, {String? fallback}) =>
      _soundService.play(soundId, fallbackId: fallback);

  void _notifyPomodoroEnd(PomodoroState state) {
    if (_currentTask == null) return;
    _notificationService.notifyPomodoroEnd(
      taskName: _currentTask!.name,
      currentPomodoro: state.currentPomodoro,
      totalPomodoros: state.totalPomodoros,
    );
  }

  void _notifyTaskFinished() {
    if (_currentTask == null) return;
    _notificationService.notifyTaskFinished(taskName: _currentTask!.name);
  }

  void _maybeHeartbeat(PomodoroState state) {
    if (!_controlsEnabled) return;
    if (!_isRunning(state.status)) return;
    final now = DateTime.now();
    final last = _lastHeartbeatAt;
    if (last != null &&
        now.difference(last).inSeconds < _heartbeatIntervalSeconds) {
      return;
    }
    _lastHeartbeatAt = now;
    _publishCurrentSession();
  }

  void _publishCurrentSession() {
    if (_currentTask == null) return;
    final current = _machine.state;
    if (current.status != PomodoroStatus.finished) {
      _finishedAt = null;
    }
    if (current.status != PomodoroStatus.paused) {
      _pauseReason = null;
    }
    final finishedAt = current.status == PomodoroStatus.finished
        ? (_finishedAt ??= DateTime.now())
        : null;
    final pauseReason =
        current.status == PomodoroStatus.paused ? _pauseReason : null;
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
      finishedAt: finishedAt,
      pauseReason: pauseReason,
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
      _latestSession = session;
      if (session == null) {
        _mirrorTimer?.cancel();
        _remoteOwnerId = null;
        _remoteSession = null;
        _localPhaseStartedAt = null;
        _stopForegroundService();
        // If the owner cancels and clears the session, mirror idle.
        if (_currentTask != null) {
          final base = _machine.state;
          state = base.status == PomodoroStatus.idle && base.totalSeconds > 0
              ? base
              : _idlePreviewState();
        }
        return;
      }
      if (session.ownerDeviceId == _deviceInfo.deviceId) {
        _mirrorTimer?.cancel();
        _remoteOwnerId = null;
        _remoteSession = null;
        if (_currentTask != null && session.taskId == _currentTask!.id) {
          final shouldHydrate =
              _machine.state.status == PomodoroStatus.idle &&
              session.status != PomodoroStatus.idle;
          if (shouldHydrate) {
            unawaited(_hydrateOwnerSession(session));
          }
        }
        return;
      }
      if (_currentTask == null || session.taskId != _currentTask!.id) {
        // If the remote session belongs to another task, do not apply it.
        _mirrorTimer?.cancel();
        _remoteOwnerId = null;
        _remoteSession = null;
        _stopForegroundService();
        return;
      }
      _remoteOwnerId = session.ownerDeviceId;
      _remoteSession = session;
      _stopForegroundService();
      _setMirrorSession(session);
    });
  }

  Future<void> _hydrateOwnerSession(PomodoroSession session) async {
    if (_currentTask == null || session.taskId != _currentTask!.id) return;
    if (session.status == PomodoroStatus.idle) return;
    final now = DateTime.now();
    final projected = _projectStateFromSession(session, now: now);
    final pauseReason =
        session.status == PomodoroStatus.paused ? session.pauseReason : null;
    if (_currentTask == null || session.taskId != _currentTask!.id) return;
    if (session.status == PomodoroStatus.finished) {
      _finishedAt = session.finishedAt;
    }
    _pauseReason = pauseReason;
    _applyProjectedState(projected, now: now);
    _publishCurrentSession();
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
    state = _projectStateFromSession(session);
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
    if (session.status == PomodoroStatus.finished) return true;
    if (!_isRunning(session.status)) {
      return _isStale(session.lastUpdatedAt, minutes: 5);
    }
    if (session.phaseStartedAt == null) return true;
    final phaseEnd = session.phaseStartedAt!
        .add(Duration(seconds: session.phaseDurationSeconds));
    return DateTime.now().isAfter(
      phaseEnd.add(const Duration(seconds: 10)),
    );
  }

  bool get isMirrorMode => _remoteOwnerId != null;

  bool get canTakeOver {
    final session = _remoteSession;
    if (session == null) return false;
    return _shouldAllowTakeover(session);
  }

  bool get hasActiveConflict =>
      _hasActiveConflict(_latestSession, _currentTask?.id);

  bool get canControlSession => _controlsEnabled;

  bool get _controlsEnabled {
    if (hasActiveConflict) return false;
    return _remoteOwnerId == null || _remoteOwnerId == _deviceInfo.deviceId;
  }

  void _syncForegroundService(PomodoroState state) {
    if (!ForegroundService.isSupported) return;
    if (_currentTask == null) {
      _stopForegroundService();
      return;
    }
    if (_remoteOwnerId != null && _remoteOwnerId != _deviceInfo.deviceId) {
      _stopForegroundService();
      return;
    }
    final shouldRun = _isRunning(state.status);
    if (!shouldRun) {
      _stopForegroundService();
      return;
    }
    final title = _currentTask!.name.isNotEmpty
        ? _currentTask!.name
        : 'Pomodoro running';
    final text = _foregroundTextForState(state);
    if (!_foregroundActive) {
      _foregroundActive = true;
      _foregroundTitle = title;
      _foregroundText = text;
      unawaited(ForegroundService.start(title: title, text: text));
      return;
    }
    if (_foregroundTitle != title || _foregroundText != text) {
      _foregroundTitle = title;
      _foregroundText = text;
      unawaited(ForegroundService.update(title: title, text: text));
    }
  }

  void _stopForegroundService() {
    if (!_foregroundActive) return;
    _foregroundActive = false;
    _foregroundTitle = null;
    _foregroundText = null;
    unawaited(ForegroundService.stop());
  }

  String _foregroundTextForState(PomodoroState state) {
    switch (state.phase) {
      case PomodoroPhase.shortBreak:
        return 'Short break running';
      case PomodoroPhase.longBreak:
        return 'Long break running';
      case PomodoroPhase.pomodoro:
        return 'Pomodoro running';
      default:
        return 'Focus Interval is active';
    }
  }

  void handleAppPaused() {
    if (_currentTask == null) return;
    if (_remoteOwnerId != null) return;
    // Keep running in background; no auto-pause or prompt.
  }

  void handleAppResumed() {
    if (_currentTask == null) return;
    if (_remoteOwnerId != null) {
      final session = _remoteSession;
      if (session != null) {
        _setMirrorSession(session);
      }
      return;
    }
    final current = _machine.state;
    if (!_isRunning(current.status)) return;
    final phaseStartedAt = _localPhaseStartedAt;
    if (phaseStartedAt == null) {
      _markPhaseStartedFromState(current);
      return;
    }
    final now = DateTime.now();
    final baseSession = PomodoroSession(
      taskId: _currentTask!.id,
      ownerDeviceId: _deviceInfo.deviceId,
      status: current.status,
      phase: current.phase,
      currentPomodoro: current.currentPomodoro,
      totalPomodoros: current.totalPomodoros,
      phaseDurationSeconds: current.totalSeconds,
      remainingSeconds: current.remainingSeconds,
      phaseStartedAt: phaseStartedAt,
      lastUpdatedAt: now,
      finishedAt: null,
      pauseReason: null,
    );
    final projected = _projectStateFromSession(baseSession, now: now);
    if (_isSameState(current, projected)) return;
    _applyProjectedState(projected, now: now);
    _publishCurrentSession();
  }

  void _applyProjectedState(PomodoroState projected, {DateTime? now}) {
    _machine.restoreFromSession(
      status: projected.status,
      phase: projected.phase,
      currentPomodoro: projected.currentPomodoro,
      totalPomodoros: projected.totalPomodoros,
      totalSeconds: projected.totalSeconds,
      remainingSeconds: projected.remainingSeconds,
    );
    _markPhaseStartedFromState(projected, now: now);
  }

  void _markPhaseStartedFromState(PomodoroState state, {DateTime? now}) {
    if (!_isRunning(state.status)) {
      _localPhaseStartedAt = null;
      return;
    }
    final total = state.totalSeconds;
    if (total <= 0) {
      _localPhaseStartedAt = now ?? DateTime.now();
      return;
    }
    final elapsed =
        (total - state.remainingSeconds).clamp(0, total).toInt();
    final anchor = now ?? DateTime.now();
    _localPhaseStartedAt = anchor.subtract(Duration(seconds: elapsed));
  }

  Future<PomodoroSession?> _readCurrentSession() async {
    try {
      return await _sessionRepo.watchSession().first;
    } on StateError {
      return null;
    }
  }

  bool _hasActiveConflict(PomodoroSession? session, String? taskId) {
    if (session == null) return false;
    if (!session.status.isActiveExecution) return false;
    if (taskId == null) return true;
    return session.taskId != taskId;
  }

  PomodoroState _idlePreviewState() {
    if (_currentTask == null) return PomodoroState.idle();
    final total = _currentTask!.pomodoroMinutes * 60;
    return PomodoroState(
      status: PomodoroStatus.idle,
      phase: PomodoroPhase.pomodoro,
      currentPomodoro: 0,
      totalPomodoros: _currentTask!.totalPomodoros,
      totalSeconds: total,
      remainingSeconds: total,
    );
  }


  PomodoroState _projectStateFromSession(
    PomodoroSession session, {
    DateTime? now,
  }) {
    if (_currentTask == null) {
      return _stateFromSession(session, remaining: session.remainingSeconds);
    }
    if (!_isRunning(session.status) || session.phaseStartedAt == null) {
      return _stateFromSession(session, remaining: session.remainingSeconds);
    }
    final anchor = now ?? DateTime.now();
    var elapsed = anchor.difference(session.phaseStartedAt!).inSeconds;
    if (elapsed < 0) elapsed = 0;
    final initialPhase = session.phase;
    if (initialPhase == null) {
      return _stateFromSession(session, remaining: session.remainingSeconds);
    }
    PomodoroPhase phase = initialPhase;
    var currentPomodoro = session.currentPomodoro;
    final totalPomodoros = session.totalPomodoros;
    var phaseDuration =
        _phaseDurationForPhase(phase, fallback: session.phaseDurationSeconds);
    if (phaseDuration <= 0) {
      phaseDuration = session.phaseDurationSeconds;
    }

    while (true) {
      if (elapsed < phaseDuration) {
        final remaining = (phaseDuration - elapsed).clamp(0, phaseDuration);
        return PomodoroState(
          status: _statusForPhase(phase),
          phase: phase,
          currentPomodoro: currentPomodoro,
          totalPomodoros: totalPomodoros,
          totalSeconds: phaseDuration,
          remainingSeconds: remaining,
        );
      }

      elapsed -= phaseDuration;

      if (phase == PomodoroPhase.pomodoro) {
        if (currentPomodoro >= totalPomodoros) {
          return PomodoroState(
            status: PomodoroStatus.finished,
            phase: null,
            currentPomodoro: currentPomodoro,
            totalPomodoros: totalPomodoros,
            totalSeconds: 0,
            remainingSeconds: 0,
          );
        }
        final isLongBreak =
            currentPomodoro % _currentTask!.longBreakInterval == 0;
        phase = isLongBreak ? PomodoroPhase.longBreak : PomodoroPhase.shortBreak;
        phaseDuration = _phaseDurationForPhase(phase);
        continue;
      }

      currentPomodoro += 1;
      phase = PomodoroPhase.pomodoro;
      phaseDuration = _phaseDurationForPhase(phase);
    }
  }

  PomodoroState _stateFromSession(
    PomodoroSession session, {
    required int remaining,
  }) {
    return PomodoroState(
      status: session.status,
      phase: session.phase,
      currentPomodoro: session.currentPomodoro,
      totalPomodoros: session.totalPomodoros,
      totalSeconds: session.phaseDurationSeconds,
      remainingSeconds: remaining,
    );
  }

  int _phaseDurationForPhase(
    PomodoroPhase phase, {
    int? fallback,
  }) {
    if (_currentTask == null) return fallback ?? 0;
    switch (phase) {
      case PomodoroPhase.pomodoro:
        return _currentTask!.pomodoroMinutes * 60;
      case PomodoroPhase.shortBreak:
        return _currentTask!.shortBreakMinutes * 60;
      case PomodoroPhase.longBreak:
        return _currentTask!.longBreakMinutes * 60;
    }
  }

  PomodoroStatus _statusForPhase(PomodoroPhase phase) {
    switch (phase) {
      case PomodoroPhase.shortBreak:
        return PomodoroStatus.shortBreakRunning;
      case PomodoroPhase.longBreak:
        return PomodoroStatus.longBreakRunning;
      case PomodoroPhase.pomodoro:
        return PomodoroStatus.pomodoroRunning;
    }
  }

  bool _isSameState(PomodoroState a, PomodoroState b) {
    return a.status == b.status &&
        a.phase == b.phase &&
        a.currentPomodoro == b.currentPomodoro &&
        a.totalPomodoros == b.totalPomodoros &&
        a.totalSeconds == b.totalSeconds &&
        a.remainingSeconds == b.remainingSeconds;
  }
}
