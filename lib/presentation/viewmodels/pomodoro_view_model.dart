import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/pomodoro_task.dart';
import '../../data/models/pomodoro_session.dart';
import '../../data/models/task_run_group.dart';
import '../../data/models/selected_sound.dart';
import '../../domain/pomodoro_machine.dart';
import '../../data/services/sound_service.dart';
import '../providers.dart';
import '../../data/repositories/pomodoro_session_repository.dart';
import '../../data/repositories/task_run_group_repository.dart';
import '../../data/services/device_info_service.dart';
import '../../data/services/notification_service.dart';
import '../../data/services/foreground_service.dart';
import '../../data/services/app_mode_service.dart';

enum PomodoroGroupLoadResult { loaded, notFound, blockedByActiveSession }

class TaskTimeRange {
  final DateTime start;
  final DateTime end;

  const TaskTimeRange(this.start, this.end);
}

class _GroupResumeProjection {
  final int taskIndex;
  final PomodoroState state;
  final DateTime taskStartedAt;

  const _GroupResumeProjection({
    required this.taskIndex,
    required this.state,
    required this.taskStartedAt,
  });
}

class PomodoroViewModel extends Notifier<PomodoroState> {
  static const int _heartbeatIntervalSeconds = 30;
  late PomodoroMachine _machine;
  StreamSubscription<PomodoroState>? _sub;
  late SoundService _soundService;
  late NotificationService _notificationService;
  late PomodoroSessionRepository _sessionRepo;
  late TaskRunGroupRepository _groupRepo;
  late DeviceInfoService _deviceInfo;
  PomodoroTask? _currentTask;
  TaskRunGroup? _currentGroup;
  TaskRunItem? _currentItem;
  int _currentTaskIndex = 0;
  DateTime? _currentTaskStartedAt;
  final Map<int, TaskTimeRange> _completedTaskRanges = {};
  DateTime? _timelinePhaseStartedAt;
  StreamSubscription<PomodoroSession?>? _sessionSub;
  Timer? _mirrorTimer;
  String? _remoteOwnerId;
  PomodoroSession? _remoteSession;
  PomodoroSession? _latestSession;
  DateTime? _localPhaseStartedAt;
  DateTime? _lastHeartbeatAt;
  DateTime? _finishedAt;
  String? _pauseReason;
  bool _groupCompleted = false;
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
    _groupRepo = ref.watch(taskRunGroupRepositoryProvider);
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

  // Load values from TaskRunGroup.
  Future<PomodoroGroupLoadResult> loadGroup(String groupId) async {
    final session = await _readCurrentSession();
    _latestSession = session;
    if (_hasActiveGroupConflict(session, groupId)) {
      return PomodoroGroupLoadResult.blockedByActiveSession;
    }

    final group = await _groupRepo.getById(groupId);
    if (group == null) return PomodoroGroupLoadResult.notFound;

    _currentGroup = group;
    _currentTask = null;
    _finishedAt = null;
    _lastHeartbeatAt = null;
    _pauseReason = null;
    _groupCompleted = false;
    _completedTaskRanges.clear();
    _timelinePhaseStartedAt = null;
    final now = DateTime.now();
    final projection = _projectFromGroupTimelineIfNeeded(
      group,
      session,
      now,
    );
    if (projection != null) {
      _currentTaskIndex = projection.taskIndex;
      _currentItem = _resolveTaskItem(group, _currentTaskIndex);
      _currentTaskStartedAt = projection.taskStartedAt;
    } else {
      _currentTaskIndex = _resolveTaskIndex(group, session);
      _currentItem = _resolveTaskItem(group, _currentTaskIndex);
      _currentTaskStartedAt = _resolveTaskStart(group, session);
    }

    if (_currentItem == null) {
      return PomodoroGroupLoadResult.notFound;
    }

    configureFromItem(_currentItem!);
    _subscribeToRemoteSession();
    if (projection != null) {
      _applyProjectedState(projection.state, now: now);
    }
    unawaited(_notificationService.requestPermissions());
    return PomodoroGroupLoadResult.loaded;
  }

  void configureFromItem(TaskRunItem item) {
    final group = _currentGroup;
    final allowFinalBreak =
        group != null && _currentTaskIndex < (group.tasks.length - 1);
    final globalPomodoroOffset =
        group != null && group.integrityMode == TaskRunIntegrityMode.shared
        ? _globalPomodoroOffsetForTask(group, _currentTaskIndex)
        : 0;
    _machine.callbacks = PomodoroCallbacks(
      onPomodoroStart: (_) {
        _markPhaseStartedFromState(_machine.state);
        _markTimelinePhaseStarted();
        _publishCurrentSession();
        _play(item.startSound, fallback: item.startBreakSound);
      },
      onPomodoroEnd: (s) {
        if (s.currentPomodoro >= s.totalPomodoros) return;
        _notifyPomodoroEnd(s);
      },
      onBreakStart: (_) {
        _markPhaseStartedFromState(_machine.state);
        _markTimelinePhaseStarted();
        _publishCurrentSession();
        _play(item.startBreakSound, fallback: item.startSound);
      },
      onTaskFinished: (_) => _handleTaskFinished(),
      onTick: _maybeHeartbeat,
    );

    _machine.configureTask(
      pomodoroMinutes: item.pomodoroMinutes,
      shortBreakMinutes: item.shortBreakMinutes,
      longBreakMinutes: item.longBreakMinutes,
      totalPomodoros: item.totalPomodoros,
      longBreakInterval: item.longBreakInterval,
      allowFinalBreak: allowFinalBreak,
      globalPomodoroOffset: globalPomodoroOffset,
    );

    state = _machine.state;
  }

  int _groupTotalSeconds(TaskRunGroup group) {
    return groupDurationSecondsByMode(group.tasks, group.integrityMode);
  }

  List<int> _taskDurationsForGroup(TaskRunGroup group) {
    return taskDurationSecondsByMode(group.tasks, group.integrityMode);
  }

  int _taskDurationForIndex(TaskRunGroup group, int index) {
    final durations = _taskDurationsForGroup(group);
    if (index < 0 || index >= durations.length) return 0;
    return durations[index];
  }

  int _globalPomodoroOffsetForTask(TaskRunGroup group, int taskIndex) {
    if (group.integrityMode != TaskRunIntegrityMode.shared) return 0;
    if (taskIndex <= 0) return 0;
    var total = 0;
    for (var index = 0; index < taskIndex && index < group.tasks.length; index += 1) {
      total += group.tasks[index].totalPomodoros;
    }
    return total;
  }

  int _totalGroupPomodoros(TaskRunGroup group) {
    return group.tasks.fold<int>(
      0,
      (total, item) => total + item.totalPomodoros,
    );
  }

  int _resolveTaskIndex(TaskRunGroup group, PomodoroSession? session) {
    if (session != null && session.groupId == group.id) {
      final index = session.currentTaskIndex;
      if (index != null && index >= 0 && index < group.tasks.length) {
        return index;
      }
      final currentId = session.currentTaskId;
      if (currentId != null) {
        final found = group.tasks.indexWhere(
          (task) => task.sourceTaskId == currentId,
        );
        if (found >= 0) return found;
      }
    }
    return 0;
  }

  TaskRunItem? _resolveTaskItem(TaskRunGroup group, int index) {
    if (index < 0 || index >= group.tasks.length) return null;
    return group.tasks[index];
  }

  DateTime? _resolveTaskStart(TaskRunGroup group, PomodoroSession? session) {
    if (session != null && session.groupId == group.id) {
      return session.phaseStartedAt ?? group.actualStartTime;
    }
    return group.actualStartTime ?? group.createdAt;
  }

  _GroupResumeProjection? _projectFromGroupTimelineIfNeeded(
    TaskRunGroup group,
    PomodoroSession? session,
    DateTime now,
  ) {
    if (session != null) return null;
    if (ref.read(appModeProvider) != AppMode.local) return null;
    if (group.status != TaskRunStatus.running) return null;
    return _projectFromGroupTimeline(group, now);
  }

  _GroupResumeProjection? _projectFromGroupTimeline(
    TaskRunGroup group,
    DateTime now,
  ) {
    final actualStart = group.actualStartTime;
    if (actualStart == null) return null;
    if (group.tasks.isEmpty) return null;

    var elapsed = now.difference(actualStart).inSeconds;
    if (elapsed < 0) return null;

    var offset = 0;
    var globalPomodoroOffset = 0;
    final lastIndex = group.tasks.length - 1;
    final taskDurations = _taskDurationsForGroup(group);
    final totalGroupPomodoros = _totalGroupPomodoros(group);
    for (var index = 0; index < group.tasks.length; index += 1) {
      final item = group.tasks[index];
      final taskDuration = taskDurations[index];
      if (elapsed < offset + taskDuration) {
        final elapsedInTask = elapsed - offset;
        final includeFinalBreak =
            group.integrityMode == TaskRunIntegrityMode.shared
            ? globalPomodoroOffset + item.totalPomodoros < totalGroupPomodoros
            : index < lastIndex;
        final projected = _projectStateWithinTask(
          item: item,
          elapsedSeconds: elapsedInTask,
          includeFinalBreak: includeFinalBreak,
          integrityMode: group.integrityMode,
          globalPomodoroOffset: globalPomodoroOffset,
          totalGroupPomodoros: totalGroupPomodoros,
        );
        if (projected == null) return null;
        return _GroupResumeProjection(
          taskIndex: index,
          state: projected,
          taskStartedAt: actualStart.add(Duration(seconds: offset)),
        );
      }
      offset += taskDuration;
      globalPomodoroOffset += item.totalPomodoros;
    }
    return null;
  }

  PomodoroState? _projectStateWithinTask({
    required TaskRunItem item,
    required int elapsedSeconds,
    required bool includeFinalBreak,
    required TaskRunIntegrityMode integrityMode,
    required int globalPomodoroOffset,
    required int totalGroupPomodoros,
  }) {
    var elapsed = elapsedSeconds;
    if (elapsed < 0) elapsed = 0;
    final pomodoroSeconds = item.pomodoroMinutes * 60;
    final shortBreakSeconds = item.shortBreakMinutes * 60;
    final longBreakSeconds = item.longBreakMinutes * 60;

    if (integrityMode == TaskRunIntegrityMode.shared) {
      for (var pomodoroIndex = 1;
          pomodoroIndex <= item.totalPomodoros;
          pomodoroIndex += 1) {
        if (elapsed < pomodoroSeconds) {
          return PomodoroState(
            status: PomodoroStatus.pomodoroRunning,
            phase: PomodoroPhase.pomodoro,
            currentPomodoro: pomodoroIndex,
            totalPomodoros: item.totalPomodoros,
            totalSeconds: pomodoroSeconds,
            remainingSeconds: pomodoroSeconds - elapsed,
          );
        }
        elapsed -= pomodoroSeconds;

        final globalIndex = globalPomodoroOffset + pomodoroIndex;
        final hasBreak = globalIndex < totalGroupPomodoros;
        if (!hasBreak) {
          return PomodoroState(
            status: PomodoroStatus.finished,
            phase: null,
            currentPomodoro: item.totalPomodoros,
            totalPomodoros: item.totalPomodoros,
            totalSeconds: 0,
            remainingSeconds: 0,
          );
        }

        final isLongBreak = globalIndex % item.longBreakInterval == 0;
        final breakSeconds = isLongBreak ? longBreakSeconds : shortBreakSeconds;
        if (elapsed < breakSeconds) {
          return PomodoroState(
            status: isLongBreak
                ? PomodoroStatus.longBreakRunning
                : PomodoroStatus.shortBreakRunning,
            phase: isLongBreak
                ? PomodoroPhase.longBreak
                : PomodoroPhase.shortBreak,
            currentPomodoro: pomodoroIndex,
            totalPomodoros: item.totalPomodoros,
            totalSeconds: breakSeconds,
            remainingSeconds: breakSeconds - elapsed,
          );
        }
        elapsed -= breakSeconds;
      }

      return PomodoroState(
        status: PomodoroStatus.finished,
        phase: null,
        currentPomodoro: item.totalPomodoros,
        totalPomodoros: item.totalPomodoros,
        totalSeconds: 0,
        remainingSeconds: 0,
      );
    }

    for (var pomodoroIndex = 1;
        pomodoroIndex <= item.totalPomodoros;
        pomodoroIndex += 1) {
      if (elapsed < pomodoroSeconds) {
        return PomodoroState(
          status: PomodoroStatus.pomodoroRunning,
          phase: PomodoroPhase.pomodoro,
          currentPomodoro: pomodoroIndex,
          totalPomodoros: item.totalPomodoros,
          totalSeconds: pomodoroSeconds,
          remainingSeconds: pomodoroSeconds - elapsed,
        );
      }
      elapsed -= pomodoroSeconds;

      final isLastPomodoro = pomodoroIndex == item.totalPomodoros;
      final hasBreak = !isLastPomodoro || includeFinalBreak;
      if (!hasBreak) {
        return PomodoroState(
          status: PomodoroStatus.finished,
          phase: null,
          currentPomodoro: item.totalPomodoros,
          totalPomodoros: item.totalPomodoros,
          totalSeconds: 0,
          remainingSeconds: 0,
        );
      }

      final isLongBreak = pomodoroIndex % item.longBreakInterval == 0;
      final breakSeconds = isLongBreak ? longBreakSeconds : shortBreakSeconds;
      if (elapsed < breakSeconds) {
        return PomodoroState(
          status: isLongBreak
              ? PomodoroStatus.longBreakRunning
              : PomodoroStatus.shortBreakRunning,
          phase: isLongBreak
              ? PomodoroPhase.longBreak
              : PomodoroPhase.shortBreak,
          currentPomodoro: pomodoroIndex,
          totalPomodoros: item.totalPomodoros,
          totalSeconds: breakSeconds,
          remainingSeconds: breakSeconds - elapsed,
        );
      }
      elapsed -= breakSeconds;
    }

    return PomodoroState(
      status: PomodoroStatus.finished,
      phase: null,
      currentPomodoro: item.totalPomodoros,
      totalPomodoros: item.totalPomodoros,
      totalSeconds: 0,
      remainingSeconds: 0,
    );
  }

  void _handleTaskFinished() {
    final item = _currentItem;
    if (item == null) return;

    _recordCompletedTaskRange();
    _notifyTaskFinished();
    _play(item.finishTaskSound, fallback: item.startSound);

    final group = _currentGroup;
    if (group == null) return;

    final isLastTask = _currentTaskIndex >= group.tasks.length - 1;
    if (isLastTask) {
      _groupCompleted = true;
      _markGroupCompleted();
      _publishCurrentSession();
      return;
    }

    _currentTaskIndex += 1;
    _currentItem = _resolveTaskItem(group, _currentTaskIndex);
    _currentTaskStartedAt = DateTime.now();
    if (_currentItem == null) return;
    configureFromItem(_currentItem!);
    _machine.startTask();
    _markPhaseStartedFromState(_machine.state);
    _publishCurrentSession();
  }

  void start() {
    if (!_controlsEnabled) return;
    _finishedAt = null;
    _lastHeartbeatAt = null;
    _pauseReason = null;
    _groupCompleted = false;
    _completedTaskRanges.clear();
    _timelinePhaseStartedAt = null;
    _currentTaskStartedAt = DateTime.now();
    unawaited(_markGroupRunningIfNeeded(startOverride: DateTime.now()));
    _machine.startTask();
    _markPhaseStartedFromState(_machine.state);
    _publishCurrentSession();
  }

  void pause() {
    if (!_controlsEnabled) return;
    _pauseReason = 'user';
    _machine.pause();
    _publishCurrentSession();
  }

  void resume() {
    if (!_controlsEnabled) return;
    _pauseReason = null;
    _machine.resume();
    _markPhaseStartedFromState(_machine.state);
    _publishCurrentSession();
  }

  Future<void> cancel() async {
    if (!_controlsEnabled) return;
    _resetLocalSessionState();
    await _markGroupCanceled();
    await _sessionRepo.clearSession();
  }

  void applyRemoteCancellation() {
    _resetLocalSessionState();
    _sessionRepo.clearSession();
  }

  void _resetLocalSessionState() {
    _finishedAt = null;
    _lastHeartbeatAt = null;
    _pauseReason = null;
    _groupCompleted = false;
    _completedTaskRanges.clear();
    _timelinePhaseStartedAt = null;
    _machine.cancel();
    _localPhaseStartedAt = null;
    _groupCompleted = false;
  }

  Future<void> _markGroupRunningIfNeeded({DateTime? startOverride}) async {
    final group = _currentGroup;
    if (group == null) return;
    final now = DateTime.now();
    final start = startOverride ?? group.actualStartTime ?? now;
    final totalSeconds = _groupTotalSeconds(group);
    final end = start.add(Duration(seconds: totalSeconds));
    final shouldUpdate =
        group.status != TaskRunStatus.running ||
        group.actualStartTime != start ||
        group.totalDurationSeconds != totalSeconds ||
        group.theoreticalEndTime != end;
    if (!shouldUpdate) return;
    final updated = group.copyWith(
      status: TaskRunStatus.running,
      actualStartTime: start,
      theoreticalEndTime: end,
      totalDurationSeconds: totalSeconds,
      updatedAt: now,
    );
    _currentGroup = updated;
    await _groupRepo.save(updated);
  }

  Future<void> _markGroupCompleted() async {
    final group = _currentGroup;
    if (group == null) return;
    final now = DateTime.now();
    final updated = group.copyWith(
      status: TaskRunStatus.completed,
      updatedAt: now,
    );
    _currentGroup = updated;
    await _groupRepo.save(updated);
  }

  Future<void> _markGroupCanceled() async {
    final group = _currentGroup;
    if (group == null) return;
    if (group.status == TaskRunStatus.canceled) return;
    final now = DateTime.now();
    final updated = group.copyWith(
      status: TaskRunStatus.canceled,
      updatedAt: now,
    );
    _currentGroup = updated;
    await _groupRepo.save(updated);
  }

  Future<void> takeOver() async {
    final session = _remoteSession;
    if (session == null || !_shouldAllowTakeover(session)) return;
    if (_currentGroup != null) {
      if (session.groupId != _currentGroup!.id) return;
      _currentTaskIndex = session.currentTaskIndex ?? _currentTaskIndex;
      _currentItem = _resolveTaskItem(_currentGroup!, _currentTaskIndex);
    } else if (_currentTask != null && session.taskId != _currentTask!.id) {
      return;
    }

    _mirrorTimer?.cancel();

    final now = DateTime.now();
    final projected = _projectStateFromSession(session, now: now);
    final totalSeconds = projected.totalSeconds;
    final normalizedRemaining = totalSeconds <= 0
        ? 0
        : projected.remainingSeconds.clamp(0, totalSeconds).toInt();
    final phaseStartedAt = _isRunning(projected.status)
        ? now.subtract(Duration(seconds: totalSeconds - normalizedRemaining))
        : null;
    final finishedAt = projected.status == PomodoroStatus.finished
        ? (session.finishedAt ?? now)
        : null;
    final pauseReason = projected.status == PomodoroStatus.paused
        ? session.pauseReason
        : null;

    final takeover = PomodoroSession(
      taskId: session.taskId,
      groupId: session.groupId,
      currentTaskId: session.currentTaskId ?? session.taskId,
      currentTaskIndex: session.currentTaskIndex ?? 0,
      totalTasks: session.totalTasks ?? 1,
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

  Future<void> _play(SelectedSound sound, {SelectedSound? fallback}) =>
      _soundService.play(sound, fallback: fallback);

  void _notifyPomodoroEnd(PomodoroState state) {
    final name = _currentItem?.name ?? _currentTask?.name;
    if (name == null || name.isEmpty) return; // Ensure name is valid
    _notificationService.notifyPomodoroEnd(
      taskName: name,
      currentPomodoro: state.currentPomodoro,
      totalPomodoros: state.totalPomodoros,
    );
  }

  void _notifyTaskFinished() {
    final name = _currentItem?.name ?? _currentTask?.name;
    if (name == null || name.isEmpty) return; // Ensure name is valid
    _notificationService.notifyTaskFinished(taskName: name);
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
    final taskId = _currentItem?.sourceTaskId ?? _currentTask?.id;
    if (taskId == null || taskId.isEmpty) return;
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
    final pauseReason = current.status == PomodoroStatus.paused
        ? _pauseReason
        : null;
    final phaseDuration = _phaseDurationForState(current);
    final phaseStartedAt =
        _isRunning(current.status) || current.status == PomodoroStatus.paused
        ? _localPhaseStartedAt
        : null;

    final session = PomodoroSession(
      taskId: taskId,
      groupId: _currentGroup?.id,
      currentTaskId: taskId,
      currentTaskIndex: _currentGroup != null ? _currentTaskIndex : 0,
      totalTasks: _currentGroup?.tasks.length ?? 1,
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
    final item = _currentItem;
    final task = _currentTask;
    if (item == null && task == null) return state.totalSeconds;
    switch (state.phase) {
      case PomodoroPhase.pomodoro:
        return item != null
            ? item.pomodoroMinutes * 60
            : task!.pomodoroMinutes * 60;
      case PomodoroPhase.shortBreak:
        return item != null
            ? item.shortBreakMinutes * 60
            : task!.shortBreakMinutes * 60;
      case PomodoroPhase.longBreak:
        return item != null
            ? item.longBreakMinutes * 60
            : task!.longBreakMinutes * 60;
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
        if (_currentItem != null || _currentTask != null) {
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
        if (_currentGroup != null && session.groupId == _currentGroup!.id) {
          _applySessionTaskContext(session);
          final shouldHydrate =
              _machine.state.status == PomodoroStatus.idle &&
              session.status != PomodoroStatus.idle;
          if (shouldHydrate) {
            unawaited(_hydrateOwnerSession(session));
          }
        } else if (_currentTask != null && session.taskId == _currentTask!.id) {
          final shouldHydrate =
              _machine.state.status == PomodoroStatus.idle &&
              session.status != PomodoroStatus.idle;
          if (shouldHydrate) {
            unawaited(_hydrateOwnerSession(session));
          }
        }
        return;
      }
      if (_currentGroup != null) {
        if (session.groupId != _currentGroup!.id) {
          _mirrorTimer?.cancel();
          _remoteOwnerId = null;
          _remoteSession = null;
          _stopForegroundService();
          return;
        }
        _applySessionTaskContext(session);
      } else if (_currentTask == null || session.taskId != _currentTask!.id) {
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
    if (_currentGroup != null) {
      if (session.groupId != _currentGroup!.id) return;
      _applySessionTaskContext(session);
    } else if (_currentTask == null || session.taskId != _currentTask!.id) {
      return;
    }
    if (session.status == PomodoroStatus.idle) return;
    final now = DateTime.now();
    final pauseReason = session.status == PomodoroStatus.paused
        ? session.pauseReason
        : null;
    if (_currentGroup != null) {
      if (session.groupId != _currentGroup!.id) return;
    } else if (_currentTask == null || session.taskId != _currentTask!.id) {
      return;
    }
    if (session.status == PomodoroStatus.finished) {
      _finishedAt = session.finishedAt;
    }
    _pauseReason = pauseReason;
    if (session.status != PomodoroStatus.paused &&
        _applyGroupTimelineProjection(now)) {
      _publishCurrentSession();
      return;
    }
    final projected = _projectStateFromSession(session, now: now);
    _applyProjectedState(projected, now: now);
    _publishCurrentSession();
  }

  void _applySessionTaskContext(PomodoroSession session) {
    final group = _currentGroup;
    if (group == null || session.groupId != group.id) return;
    final index = session.currentTaskIndex ?? _resolveTaskIndex(group, session);
    if (index < 0 || index >= group.tasks.length) return;
    if (_currentTaskIndex == index && _currentItem != null) return;
    _currentTaskIndex = index;
    _currentItem = _resolveTaskItem(group, index);
    if (session.phaseStartedAt != null &&
        session.phase == PomodoroPhase.pomodoro &&
        session.currentPomodoro <= 1) {
      _currentTaskStartedAt = session.phaseStartedAt;
    }
    if (_currentItem != null) {
      configureFromItem(_currentItem!);
    }
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
    final phaseEnd = session.phaseStartedAt!.add(
      Duration(seconds: session.phaseDurationSeconds),
    );
    return DateTime.now().isAfter(phaseEnd.add(const Duration(seconds: 10)));
  }

  bool get isMirrorMode => _remoteOwnerId != null;

  bool get isGroupCompleted => _groupCompleted;

  TaskRunGroup? get currentGroup => _currentGroup;

  TaskRunItem? get currentItem => _currentItem;

  void updateGroup(TaskRunGroup group) {
    if (_currentGroup?.id != group.id) return;
    _currentGroup = group;
    _groupCompleted = group.status == TaskRunStatus.completed;
  }

  TaskRunItem? get previousItem {
    final group = _currentGroup;
    if (group == null || _currentTaskIndex <= 0) return null;
    return group.tasks[_currentTaskIndex - 1];
  }

  TaskRunItem? get nextItem {
    final group = _currentGroup;
    if (group == null) return null;
    final nextIndex = _currentTaskIndex + 1;
    if (nextIndex >= group.tasks.length) return null;
    return group.tasks[nextIndex];
  }

  int get currentTaskIndex => _currentTaskIndex;

  int get totalTasks => _currentGroup?.tasks.length ?? 0;

  int get totalGroupPomodoros =>
      _currentGroup?.tasks.fold<int>(
        0,
        (total, item) => total + item.totalPomodoros,
      ) ??
      0;

  int get totalGroupDurationSeconds => _currentGroup == null
      ? 0
      : _groupTotalSeconds(_currentGroup!);

  DateTime? get phaseStartedAt {
    if (_remoteOwnerId != null && _remoteOwnerId != _deviceInfo.deviceId) {
      return _remoteSession?.phaseStartedAt;
    }
    return _localPhaseStartedAt ?? _remoteSession?.phaseStartedAt;
  }

  DateTime? get currentTaskStartedAt => _currentTaskStartedAt;

  DateTime? get groupTimelineStart => _resolveGroupTimelineStart();

  TaskTimeRange? taskRangeForIndex(int index) {
    final group = _currentGroup;
    if (group == null) return null;
    if (index < 0 || index >= group.tasks.length) return null;
    final baseStart = group.actualStartTime;
    if (baseStart == null) return null;

    final durations = _taskDurationsForGroup(group);
    if (index < _currentTaskIndex) {
      final cached = _completedTaskRanges[index];
      if (cached != null) return cached;
      final start = _expectedTaskStart(group, index);
      if (start == null) return null;
      final duration = _taskDurationForIndex(group, index);
      return TaskTimeRange(start, start.add(Duration(seconds: duration)));
    }

    if (index == _currentTaskIndex) {
      final start = _currentTaskStartedAt ?? _expectedTaskStart(group, index);
      if (start == null) return null;
      final duration = _taskDurationForIndex(group, index);
      final pauseSeconds = _pauseSecondsSinceCurrentTaskStart();
      return TaskTimeRange(
        start,
        start.add(Duration(seconds: duration + pauseSeconds)),
      );
    }

    final currentRange = taskRangeForIndex(_currentTaskIndex);
    if (currentRange == null) return null;
    var start = currentRange.end;
    for (var i = _currentTaskIndex + 1; i <= index; i += 1) {
      final duration = durations[i];
      final end = start.add(Duration(seconds: duration));
      if (i == index) {
        return TaskTimeRange(start, end);
      }
      start = end;
    }
    return null;
  }

  DateTime? get currentPhaseStartFromGroup {
    if (_timelinePhaseStartedAt != null) {
      return _timelinePhaseStartedAt;
    }
    final timelineStart = _resolveGroupTimelineStart();
    if (timelineStart == null) return null;
    final offsetSeconds = _activeSecondsBeforeCurrentPhase();
    return timelineStart.add(Duration(seconds: offsetSeconds));
  }

  bool get canTakeOver {
    final session = _remoteSession;
    if (session == null) return false;
    return _shouldAllowTakeover(session);
  }

  bool get hasActiveConflict =>
      _hasActiveGroupConflict(_latestSession, _currentGroup?.id);

  bool get canControlSession => _controlsEnabled;

  bool get _controlsEnabled {
    if (hasActiveConflict) return false;
    return _remoteOwnerId == null || _remoteOwnerId == _deviceInfo.deviceId;
  }

  DateTime? _resolveGroupTimelineStart() {
    final group = _currentGroup;
    if (group == null) return null;
    final actualStart = group.actualStartTime;
    if (actualStart == null) return null;
    final phaseStart = phaseStartedAt;
    if (phaseStart == null) return actualStart;
    final activeOffsetSeconds = _activeSecondsBeforeCurrentPhase();
    final expectedPhaseStart = actualStart.add(
      Duration(seconds: activeOffsetSeconds),
    );
    final pauseOffset = phaseStart.difference(expectedPhaseStart).inSeconds;
    return actualStart.add(Duration(seconds: pauseOffset));
  }

  int _activeSecondsBeforeCurrentPhase() {
    final group = _currentGroup;
    final item = _currentItem;
    if (group == null || item == null) return 0;
    var total = 0;
    final durations = _taskDurationsForGroup(group);
    for (var index = 0; index < _currentTaskIndex; index += 1) {
      total += durations[index];
    }
    total += _activeSecondsBeforePhaseInTask(
      item,
      state,
      integrityMode: group.integrityMode,
      globalPomodoroOffset:
          _globalPomodoroOffsetForTask(group, _currentTaskIndex),
    );
    return total;
  }

  int _activeSecondsBeforePhaseInTask(
    TaskRunItem item,
    PomodoroState state, {
    required TaskRunIntegrityMode integrityMode,
    required int globalPomodoroOffset,
  }) {
    if (state.phase == null || state.currentPomodoro <= 0) return 0;
    final pomodoroSeconds = item.pomodoroMinutes * 60;
    final shortBreakSeconds = item.shortBreakMinutes * 60;
    final longBreakSeconds = item.longBreakMinutes * 60;
    final currentPomodoro = state.currentPomodoro;
    var total = 0;
    for (var index = 1; index < currentPomodoro; index += 1) {
      total += pomodoroSeconds;
      final globalIndex = integrityMode == TaskRunIntegrityMode.shared
          ? globalPomodoroOffset + index
          : index;
      final isLongBreak = globalIndex % item.longBreakInterval == 0;
      total += isLongBreak ? longBreakSeconds : shortBreakSeconds;
    }
    if (state.phase == PomodoroPhase.shortBreak ||
        state.phase == PomodoroPhase.longBreak) {
      total += pomodoroSeconds;
    }
    return total;
  }

  DateTime? _expectedTaskStart(TaskRunGroup group, int index) {
    final baseStart = group.actualStartTime;
    if (baseStart == null) return null;
    var cursor = baseStart;
    final durations = _taskDurationsForGroup(group);
    for (var i = 0; i < index && i < group.tasks.length; i += 1) {
      cursor = cursor.add(
        Duration(
          seconds: durations[i],
        ),
      );
    }
    return cursor;
  }

  int _totalPausedSecondsSoFar() {
    final group = _currentGroup;
    final actualStart = group?.actualStartTime;
    final phaseStart = phaseStartedAt;
    if (group == null || actualStart == null || phaseStart == null) return 0;
    final expectedPhaseStart = actualStart.add(
      Duration(seconds: _activeSecondsBeforeCurrentPhase()),
    );
    final offset = phaseStart.difference(expectedPhaseStart).inSeconds;
    return offset < 0 ? 0 : offset;
  }

  int _pauseSecondsSinceCurrentTaskStart() {
    if (_currentGroup == null) return 0;
    final taskStart = _currentTaskStartedAt;
    if (taskStart == null) return 0;
    final expectedTaskStart = _expectedTaskStart(
      _currentGroup!,
      _currentTaskIndex,
    );
    if (expectedTaskStart == null) return 0;
    final pauseBeforeTask = taskStart.difference(expectedTaskStart).inSeconds;
    final totalPause = _totalPausedSecondsSoFar();
    final pauseSinceTask =
        totalPause - (pauseBeforeTask < 0 ? 0 : pauseBeforeTask);
    return pauseSinceTask < 0 ? 0 : pauseSinceTask;
  }

  void _recordCompletedTaskRange() {
    final group = _currentGroup;
    if (group == null) return;
    final index = _currentTaskIndex;
    if (_completedTaskRanges.containsKey(index)) return;
    final start = _currentTaskStartedAt ?? _expectedTaskStart(group, index);
    if (start == null) return;
    _completedTaskRanges[index] = TaskTimeRange(start, DateTime.now());
  }

  void _markTimelinePhaseStarted({DateTime? now}) {
    _timelinePhaseStartedAt = now ?? DateTime.now();
  }

  void _syncForegroundService(PomodoroState state) {
    if (!ForegroundService.isSupported) return;
    if (_currentItem == null && _currentTask == null) {
      _stopForegroundService();
      return;
    }
    if (_remoteOwnerId != null && _remoteOwnerId != _deviceInfo.deviceId) {
      _stopForegroundService();
      return;
    }
    final shouldRun =
        _isRunning(state.status) ||
        (state.status == PomodoroStatus.finished && !_groupCompleted);
    if (!shouldRun) {
      _stopForegroundService();
      return;
    }
    final taskName = _currentItem?.name ?? _currentTask?.name ?? '';
    final title = taskName.isNotEmpty ? taskName : 'Pomodoro running';
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

  bool _applyGroupTimelineProjection(DateTime now) {
    final group = _currentGroup;
    if (group == null) return false;
    if (group.status != TaskRunStatus.running) return false;
    if (_remoteOwnerId != null && _remoteOwnerId != _deviceInfo.deviceId) {
      return false;
    }
    if (!_controlsEnabled) return false;
    if (state.status == PomodoroStatus.paused) return false;

    final projection = _projectFromGroupTimeline(group, now);
    if (projection == null) return false;

    final sameTask = projection.taskIndex == _currentTaskIndex;
    final sameState = _isSameState(state, projection.state);
    if (sameTask && sameState) return false;

    _currentTaskIndex = projection.taskIndex;
    _currentItem = _resolveTaskItem(group, projection.taskIndex);
    _currentTaskStartedAt = projection.taskStartedAt;
    if (_currentItem == null) return false;
    configureFromItem(_currentItem!);
    _applyProjectedState(projection.state, now: now);
    return true;
  }

  void handleAppPaused() {
    if (_currentItem == null && _currentTask == null) return;
    if (_remoteOwnerId != null) return;
    // Keep running in background; no auto-pause or prompt.
  }

  void handleAppResumed() {
    if (_currentItem == null && _currentTask == null) return;
    if (_remoteOwnerId != null) {
      final session = _remoteSession;
      if (session != null) {
        _setMirrorSession(session);
      }
      return;
    }
    final now = DateTime.now();
    if (_applyGroupTimelineProjection(now)) {
      _publishCurrentSession();
      return;
    }
    final current = _machine.state;
    if (!_isRunning(current.status)) return;
    final phaseStartedAt = _localPhaseStartedAt;
    if (phaseStartedAt == null) {
      _markPhaseStartedFromState(current);
      return;
    }
    final taskId = _currentItem?.sourceTaskId ?? _currentTask?.id;
    if (taskId == null) return;
    final baseSession = PomodoroSession(
      taskId: taskId,
      groupId: _currentGroup?.id,
      currentTaskId: taskId,
      currentTaskIndex: _currentGroup != null ? _currentTaskIndex : 0,
      totalTasks: _currentGroup?.tasks.length ?? 1,
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
      if (state.status != PomodoroStatus.paused) {
        _localPhaseStartedAt = null;
        _timelinePhaseStartedAt = null;
      }
      return;
    }
    final total = state.totalSeconds;
    if (total <= 0) {
      _localPhaseStartedAt = now ?? DateTime.now();
      return;
    }
    final elapsed = (total - state.remainingSeconds).clamp(0, total).toInt();
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

  bool _hasActiveGroupConflict(PomodoroSession? session, String? groupId) {
    if (session == null) return false;
    if (!session.status.isActiveExecution) return false;
    if (groupId == null) return true;
    if (session.groupId == null) return true;
    return session.groupId != groupId;
  }

  PomodoroState _idlePreviewState() {
    final item = _currentItem;
    final task = _currentTask;
    if (item == null && task == null) return PomodoroState.idle();
    final total = item != null
        ? item.pomodoroMinutes * 60
        : task!.pomodoroMinutes * 60;
    return PomodoroState(
      status: PomodoroStatus.idle,
      phase: PomodoroPhase.pomodoro,
      currentPomodoro: 0,
      totalPomodoros: item?.totalPomodoros ?? task!.totalPomodoros,
      totalSeconds: total,
      remainingSeconds: total,
    );
  }

  PomodoroState _projectStateFromSession(
    PomodoroSession session, {
    DateTime? now,
  }) {
    if (_currentItem == null && _currentTask == null) {
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
    final group = _currentGroup;
    final sharedMode =
        group != null && group.integrityMode == TaskRunIntegrityMode.shared;
    final globalPomodoroOffset = sharedMode
        ? _globalPomodoroOffsetForTask(group, _currentTaskIndex)
        : 0;
    var phaseDuration = _phaseDurationForPhase(
      phase,
      fallback: session.phaseDurationSeconds,
    );
    if (phaseDuration <= 0) {
      phaseDuration = session.phaseDurationSeconds;
    }
    if (phaseDuration <= 0) {
      // Defensive fallback to avoid infinite projection loops.
      return _stateFromSession(session, remaining: session.remainingSeconds);
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
        final interval =
            _currentItem?.longBreakInterval ??
            _currentTask?.longBreakInterval ??
            1;
        final globalIndex = sharedMode
            ? globalPomodoroOffset + currentPomodoro
            : currentPomodoro;
        final isLongBreak = globalIndex % interval == 0;
        phase = isLongBreak
            ? PomodoroPhase.longBreak
            : PomodoroPhase.shortBreak;
        phaseDuration = _phaseDurationForPhase(phase);
        if (phaseDuration <= 0) {
          return _stateFromSession(
            session,
            remaining: session.remainingSeconds,
          );
        }
        continue;
      }

      currentPomodoro += 1;
      phase = PomodoroPhase.pomodoro;
      phaseDuration = _phaseDurationForPhase(phase);
      if (phaseDuration <= 0) {
        return _stateFromSession(session, remaining: session.remainingSeconds);
      }
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

  int _phaseDurationForPhase(PomodoroPhase phase, {int? fallback}) {
    final item = _currentItem;
    final task = _currentTask;
    if (item == null && task == null) return fallback ?? 0;
    switch (phase) {
      case PomodoroPhase.pomodoro:
        return item != null
            ? item.pomodoroMinutes * 60
            : task!.pomodoroMinutes * 60;
      case PomodoroPhase.shortBreak:
        return item != null
            ? item.shortBreakMinutes * 60
            : task!.shortBreakMinutes * 60;
      case PomodoroPhase.longBreak:
        return item != null
            ? item.longBreakMinutes * 60
            : task!.longBreakMinutes * 60;
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
