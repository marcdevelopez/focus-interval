import 'dart:async';

/// Global states of the Pomodoro machine.
/// Must match specs.md.
enum PomodoroStatus {
  idle,
  pomodoroRunning,
  shortBreakRunning,
  longBreakRunning,
  paused,
  finished,
}

extension PomodoroStatusX on PomodoroStatus {
  bool get isRunning =>
      this == PomodoroStatus.pomodoroRunning ||
      this == PomodoroStatus.shortBreakRunning ||
      this == PomodoroStatus.longBreakRunning;

  bool get isActiveExecution => isRunning || this == PomodoroStatus.paused;
}

/// Current cycle type (for UI/sounds).
enum PomodoroPhase {
  pomodoro,
  shortBreak,
  longBreak,
}

/// Immutable state emitted by the machine.
/// The UI/ViewModel should listen to changes of this state.
class PomodoroState {
  final PomodoroStatus status;
  final PomodoroPhase? phase;

  /// Current pomodoro (1-based). Example: 1..totalPomodoros
  final int currentPomodoro;

  /// Total pomodoros configured in the task.
  final int totalPomodoros;

  /// Total duration of the current cycle (in seconds).
  final int totalSeconds;

  /// Remaining seconds in the current cycle.
  final int remainingSeconds;

  /// Whether the current cycle ended (remaining == 0).
  bool get isCycleCompleted => remainingSeconds <= 0;

  /// Progress 0..1 of the current cycle.
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

/// Event callbacks so the ViewModel can trigger sounds,
/// notifications, or extra UI.
class PomodoroCallbacks {
  /// Called when a pomodoro starts.
  final void Function(PomodoroState state)? onPomodoroStart;

  /// Called when a pomodoro ends (before switching to break).
  final void Function(PomodoroState state)? onPomodoroEnd;

  /// Called when a break starts (short or long).
  final void Function(PomodoroState state)? onBreakStart;

  /// Called when a break ends (before switching to pomodoro).
  final void Function(PomodoroState state)? onBreakEnd;

  /// Called when the LAST pomodoro of the task completes.
  /// This should trigger final sound + popup + notification.
  final void Function(PomodoroState state)? onTaskFinished;

  /// Called on each tick (1s).
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

/// Pomodoro state machine.
/// - Independent from UI/Firebase.
/// - Controls transitions, pause, resume, cancel.
/// - Finishes strictly when reaching totalPomodoros.
class PomodoroMachine {
  PomodoroState _state = PomodoroState.idle();
  PomodoroState get state => _state;

  final _controller = StreamController<PomodoroState>.broadcast();
  Stream<PomodoroState> get stream => _controller.stream;

  Timer? _timer;
  PomodoroCallbacks callbacks;

  // Current configuration (in seconds).
  int _pomodoroSeconds = 25 * 60;
  int _shortBreakSeconds = 5 * 60;
  int _longBreakSeconds = 15 * 60;
  int _totalPomodoros = 1;
  int _longBreakInterval = 4;

  // Store previous state for pause/resume.
  PomodoroStatus? _prePauseStatus;
  PomodoroPhase? _prePausePhase;

  PomodoroMachine({PomodoroCallbacks? callbacks})
      : callbacks = callbacks ?? const PomodoroCallbacks();

  /// Configure the CURRENT task.
  /// All values are minutes except total/interval.
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

    // Reset to idle with configuration ready.
    _emit(PomodoroState(
      status: PomodoroStatus.idle,
      phase: null,
      currentPomodoro: 0,
      totalPomodoros: _totalPomodoros,
      totalSeconds: _pomodoroSeconds,
      remainingSeconds: _pomodoroSeconds,
    ));
  }

  /// Start the task from zero.
  /// If already running, fully restart.
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

  /// Pause the current cycle at any time.
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

  /// Resume exactly where it was paused.
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

  /// Cancel the task and return to idle.
  void cancel() {
    _cancelTimer();
    _emit(PomodoroState(
      status: PomodoroStatus.idle,
      phase: null,
      currentPomodoro: 0,
      totalPomodoros: _totalPomodoros,
      totalSeconds: _pomodoroSeconds,
      remainingSeconds: _pomodoroSeconds,
    ));
  }

  /// Restore state from a remote session (mirror/takeover).
  void restoreFromSession({
    required PomodoroStatus status,
    required PomodoroPhase? phase,
    required int currentPomodoro,
    required int totalPomodoros,
    required int totalSeconds,
    required int remainingSeconds,
  }) {
    _cancelTimer();
    _prePauseStatus = null;
    _prePausePhase = null;

    _emit(PomodoroState(
      status: status,
      phase: phase,
      currentPomodoro: currentPomodoro,
      totalPomodoros: totalPomodoros,
      totalSeconds: totalSeconds,
      remainingSeconds: remainingSeconds,
    ));

    if (status == PomodoroStatus.paused) {
      _prePausePhase = phase;
      _prePauseStatus = _runningStatusForPhase(phase);
      return;
    }

    if (_isRunningStatus(status)) {
      if (remainingSeconds <= 0) {
        _onCycleCompleted();
        return;
      }
      _startTimer();
    }
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
          // Strict task completion (mandatory MVP behavior).
          _emit(_state.copyWith(
            status: PomodoroStatus.finished,
            phase: null,
            totalSeconds: 0,
            remainingSeconds: 0,
          ));
          callbacks.onTaskFinished?.call(_state);
          return; // Do not start a break.
        }

        // Decide short or long break.
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

  bool _isRunningStatus(PomodoroStatus status) =>
      status == PomodoroStatus.pomodoroRunning ||
      status == PomodoroStatus.shortBreakRunning ||
      status == PomodoroStatus.longBreakRunning;

  PomodoroStatus _runningStatusForPhase(PomodoroPhase? phase) {
    switch (phase) {
      case PomodoroPhase.shortBreak:
        return PomodoroStatus.shortBreakRunning;
      case PomodoroPhase.longBreak:
        return PomodoroStatus.longBreakRunning;
      case PomodoroPhase.pomodoro:
      default:
        return PomodoroStatus.pomodoroRunning;
    }
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  /// Full cleanup (call in ViewModel dispose).
  Future<void> dispose() async {
    _cancelTimer();
    await _controller.close();
  }
}
