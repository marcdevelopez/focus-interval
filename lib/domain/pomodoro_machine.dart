import 'dart:async';

/// Estados globales de la máquina Pomodoro.
/// Deben coincidir con specs.md.
enum PomodoroStatus {
  idle,
  pomodoroRunning,
  shortBreakRunning,
  longBreakRunning,
  paused,
  finished,
}

/// Tipo de ciclo actual (orientativo para UI/sonidos).
enum PomodoroPhase {
  pomodoro,
  shortBreak,
  longBreak,
}

/// Estado inmutable publicado por la máquina.
/// La UI/ViewModel debe escuchar cambios de este estado.
class PomodoroState {
  final PomodoroStatus status;
  final PomodoroPhase? phase;

  /// Pomodoro actual (1-based). Ej: 1..totalPomodoros
  final int currentPomodoro;

  /// Total de pomodoros configurados en la tarea.
  final int totalPomodoros;

  /// Duración total del ciclo actual (en segundos).
  final int totalSeconds;

  /// Segundos restantes del ciclo actual.
  final int remainingSeconds;

  /// Indica si el ciclo actual acabó (remaining == 0).
  bool get isCycleCompleted => remainingSeconds <= 0;

  /// Progreso 0..1 del ciclo actual.
  double get progress =>
      totalSeconds == 0 ? 0 : 1 - (remainingSeconds / totalSeconds);

  const PomodoroState({
    required this.status,
    required this.phase,
    required this.currentPomodoro,
    required this.totalPomodoros,
    required this.totalSeconds,
    required this.remainingSeconds,
  });

  PomodoroState copyWith({
    PomodoroStatus? status,
    PomodoroPhase? phase,
    int? currentPomodoro,
    int? totalPomodoros,
    int? totalSeconds,
    int? remainingSeconds,
  }) {
    return PomodoroState(
      status: status ?? this.status,
      phase: phase ?? this.phase,
      currentPomodoro: currentPomodoro ?? this.currentPomodoro,
      totalPomodoros: totalPomodoros ?? this.totalPomodoros,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
    );
  }

  static PomodoroState idle() => const PomodoroState(
        status: PomodoroStatus.idle,
        phase: null,
        currentPomodoro: 0,
        totalPomodoros: 0,
        totalSeconds: 0,
        remainingSeconds: 0,
      );
}

/// Callbacks de eventos para que el ViewModel dispare sonidos,
/// notificaciones o UI extra.
class PomodoroCallbacks {
  /// Se llama al iniciar un pomodoro.
  final void Function(PomodoroState state)? onPomodoroStart;

  /// Se llama al terminar un pomodoro (antes de pasar al descanso).
  final void Function(PomodoroState state)? onPomodoroEnd;

  /// Se llama al iniciar un descanso (corto o largo).
  final void Function(PomodoroState state)? onBreakStart;

  /// Se llama al terminar un descanso (antes de pasar a pomodoro).
  final void Function(PomodoroState state)? onBreakEnd;

  /// Se llama cuando se completa el ÚLTIMO pomodoro de la tarea.
  /// Aquí se debe disparar sonido final + popup + notificación.
  final void Function(PomodoroState state)? onTaskFinished;

  /// Se llama en cada tick (1s).
  final void Function(PomodoroState state)? onTick;

  const PomodoroCallbacks({
    this.onPomodoroStart,
    this.onPomodoroEnd,
    this.onBreakStart,
    this.onBreakEnd,
    this.onTaskFinished,
    this.onTick,
  });
}

/// Máquina de estados Pomodoro.
/// - Independiente de UI/Firebase.
/// - Controla transiciones, pausas, reanudación, cancelación.
/// - Finaliza estrictamente al llegar a totalPomodoros.
class PomodoroMachine {
  PomodoroState _state = PomodoroState.idle();
  PomodoroState get state => _state;

  final _controller = StreamController<PomodoroState>.broadcast();
  Stream<PomodoroState> get stream => _controller.stream;

  Timer? _timer;
  PomodoroCallbacks callbacks;

  // Configuración actual (en segundos).
  int _pomodoroSeconds = 25 * 60;
  int _shortBreakSeconds = 5 * 60;
  int _longBreakSeconds = 15 * 60;
  int _totalPomodoros = 1;
  int _longBreakInterval = 4;

  // Guardamos estado previo para pausa/reanudar.
  PomodoroStatus? _prePauseStatus;
  PomodoroPhase? _prePausePhase;

  PomodoroMachine({PomodoroCallbacks? callbacks})
      : callbacks = callbacks ?? const PomodoroCallbacks();

  /// Configura la tarea ACTUAL.
  /// Todos los valores son minutos excepto total/intervalo.
  void configureTask({
    required int pomodoroMinutes,
    required int shortBreakMinutes,
    required int longBreakMinutes,
    required int totalPomodoros,
    required int longBreakInterval,
  }) {
    if (pomodoroMinutes <= 0 ||
        shortBreakMinutes <= 0 ||
        longBreakMinutes <= 0 ||
        totalPomodoros <= 0 ||
        longBreakInterval <= 0) {
      throw ArgumentError('All configuration values must be > 0.');
    }

    _pomodoroSeconds = pomodoroMinutes * 60;
    _shortBreakSeconds = shortBreakMinutes * 60;
    _longBreakSeconds = longBreakMinutes * 60;
    _totalPomodoros = totalPomodoros;
    _longBreakInterval = longBreakInterval;

    // Reset a idle con configuración lista.
    _emit(PomodoroState(
      status: PomodoroStatus.idle,
      phase: null,
      currentPomodoro: 0,
      totalPomodoros: _totalPomodoros,
      totalSeconds: 0,
      remainingSeconds: 0,
    ));
  }

  /// Inicia la tarea desde cero.
  /// Si ya estaba corriendo, reinicia completamente.
  void startTask() {
    _cancelTimer();

    _emit(PomodoroState(
      status: PomodoroStatus.pomodoroRunning,
      phase: PomodoroPhase.pomodoro,
      currentPomodoro: 1,
      totalPomodoros: _totalPomodoros,
      totalSeconds: _pomodoroSeconds,
      remainingSeconds: _pomodoroSeconds,
    ));

    callbacks.onPomodoroStart?.call(_state);
    _startTimer();
  }

  /// Pausa el ciclo actual en cualquier momento.
  void pause() {
    if (_state.status == PomodoroStatus.paused ||
        _state.status == PomodoroStatus.idle ||
        _state.status == PomodoroStatus.finished) {
      return;
    }
    _prePauseStatus = _state.status;
    _prePausePhase = _state.phase;
    _cancelTimer();
    _emit(_state.copyWith(status: PomodoroStatus.paused));
  }

  /// Reanuda exactamente donde se pausó.
  void resume() {
    if (_state.status != PomodoroStatus.paused) return;

    final restoredStatus = _prePauseStatus ?? PomodoroStatus.pomodoroRunning;
    final restoredPhase = _prePausePhase ?? PomodoroPhase.pomodoro;

    _emit(_state.copyWith(
      status: restoredStatus,
      phase: restoredPhase,
    ));

    _startTimer();
  }

  /// Cancela la tarea y vuelve a idle.
  void cancel() {
    _cancelTimer();
    _emit(PomodoroState(
      status: PomodoroStatus.idle,
      phase: null,
      currentPomodoro: 0,
      totalPomodoros: _totalPomodoros,
      totalSeconds: 0,
      remainingSeconds: 0,
    ));
  }

  /// --- Internals ---

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_state.remainingSeconds <= 0) return;

      final nextRemaining = _state.remainingSeconds - 1;
      _emit(_state.copyWith(remainingSeconds: nextRemaining));
      callbacks.onTick?.call(_state);

      if (nextRemaining <= 0) {
        _onCycleCompleted();
      }
    });
  }

  void _onCycleCompleted() {
    _cancelTimer();

    switch (_state.phase) {
      case PomodoroPhase.pomodoro:
        callbacks.onPomodoroEnd?.call(_state);

        final isLastPomodoro =
            _state.currentPomodoro >= _state.totalPomodoros;

        if (isLastPomodoro) {
          // Finalización estricta de tarea (MVP obligatorio).
          _emit(_state.copyWith(
            status: PomodoroStatus.finished,
            phase: null,
            totalSeconds: 0,
            remainingSeconds: 0,
          ));
          callbacks.onTaskFinished?.call(_state);
          return; // No iniciar descanso.
        }

        // Decidir descanso corto o largo.
        final nextPomodoroIndex = _state.currentPomodoro;
        final shouldLongBreak =
            (nextPomodoroIndex % _longBreakInterval == 0);

        if (shouldLongBreak) {
          _startLongBreak();
        } else {
          _startShortBreak();
        }
        break;

      case PomodoroPhase.shortBreak:
        callbacks.onBreakEnd?.call(_state);
        _startNextPomodoro();
        break;

      case PomodoroPhase.longBreak:
        callbacks.onBreakEnd?.call(_state);
        _startNextPomodoro();
        break;

      default:
        break;
    }
  }

  void _startShortBreak() {
    _emit(_state.copyWith(
      status: PomodoroStatus.shortBreakRunning,
      phase: PomodoroPhase.shortBreak,
      totalSeconds: _shortBreakSeconds,
      remainingSeconds: _shortBreakSeconds,
    ));
    callbacks.onBreakStart?.call(_state);
    _startTimer();
  }

  void _startLongBreak() {
    _emit(_state.copyWith(
      status: PomodoroStatus.longBreakRunning,
      phase: PomodoroPhase.longBreak,
      totalSeconds: _longBreakSeconds,
      remainingSeconds: _longBreakSeconds,
    ));
    callbacks.onBreakStart?.call(_state);
    _startTimer();
  }

  void _startNextPomodoro() {
    final nextIndex = _state.currentPomodoro + 1;
    _emit(_state.copyWith(
      status: PomodoroStatus.pomodoroRunning,
      phase: PomodoroPhase.pomodoro,
      currentPomodoro: nextIndex,
      totalSeconds: _pomodoroSeconds,
      remainingSeconds: _pomodoroSeconds,
    ));
    callbacks.onPomodoroStart?.call(_state);
    _startTimer();
  }

  void _emit(PomodoroState newState) {
    _state = newState;
    if (!_controller.isClosed) {
      _controller.add(_state);
    }
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  /// Limpieza total (llamar en dispose del ViewModel).
  Future<void> dispose() async {
    _cancelTimer();
    await _controller.close();
  }
}
