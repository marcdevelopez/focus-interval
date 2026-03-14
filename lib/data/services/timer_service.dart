import 'dart:async';

import '../../data/models/pomodoro_session.dart';
import '../../domain/pomodoro_machine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SyncHealth { healthy, degraded, recovery }

class TimerRuntimeState {
  final String? groupId;
  final String? currentTaskId;
  final PomodoroStatus status;
  final PomodoroPhase phase;
  final int remainingSeconds;
  final int totalSeconds;
  final int currentPomodoro;
  final int totalPomodoros;
  final DateTime? phaseStartedAt;
  final String? ownerDeviceId;
  final SyncHealth syncHealth;

  const TimerRuntimeState({
    required this.groupId,
    required this.currentTaskId,
    required this.status,
    required this.phase,
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.currentPomodoro,
    required this.totalPomodoros,
    required this.phaseStartedAt,
    required this.ownerDeviceId,
    required this.syncHealth,
  });

  factory TimerRuntimeState.idle() {
    return const TimerRuntimeState(
      groupId: null,
      currentTaskId: null,
      status: PomodoroStatus.idle,
      phase: PomodoroPhase.pomodoro,
      remainingSeconds: 0,
      totalSeconds: 0,
      currentPomodoro: 0,
      totalPomodoros: 0,
      phaseStartedAt: null,
      ownerDeviceId: null,
      syncHealth: SyncHealth.healthy,
    );
  }

  bool get isTickingCandidate =>
      status == PomodoroStatus.pomodoroRunning ||
      status == PomodoroStatus.shortBreakRunning ||
      status == PomodoroStatus.longBreakRunning;

  TimerRuntimeState copyWith({
    String? groupId,
    String? currentTaskId,
    PomodoroStatus? status,
    PomodoroPhase? phase,
    int? remainingSeconds,
    int? totalSeconds,
    int? currentPomodoro,
    int? totalPomodoros,
    DateTime? phaseStartedAt,
    String? ownerDeviceId,
    SyncHealth? syncHealth,
  }) {
    return TimerRuntimeState(
      groupId: groupId ?? this.groupId,
      currentTaskId: currentTaskId ?? this.currentTaskId,
      status: status ?? this.status,
      phase: phase ?? this.phase,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      currentPomodoro: currentPomodoro ?? this.currentPomodoro,
      totalPomodoros: totalPomodoros ?? this.totalPomodoros,
      phaseStartedAt: phaseStartedAt ?? this.phaseStartedAt,
      ownerDeviceId: ownerDeviceId ?? this.ownerDeviceId,
      syncHealth: syncHealth ?? this.syncHealth,
    );
  }
}

class TimerService extends Notifier<TimerRuntimeState> {
  Timer? _tickTimer;

  @override
  TimerRuntimeState build() {
    ref.onDispose(() {
      _tickTimer?.cancel();
      _tickTimer = null;
    });
    return TimerRuntimeState.idle();
  }

  void startTick({
    required int remainingSeconds,
    required PomodoroPhase phase,
    required String groupId,
    int? totalSeconds,
    PomodoroStatus? status,
    int? currentPomodoro,
    int? totalPomodoros,
    DateTime? phaseStartedAt,
    String? ownerDeviceId,
  }) {
    final boundedRemaining = remainingSeconds < 0 ? 0 : remainingSeconds;
    final resolvedTotal = (totalSeconds ?? boundedRemaining) < 0
        ? 0
        : (totalSeconds ?? boundedRemaining);
    state = state.copyWith(
      groupId: groupId,
      status: status ?? _statusForPhase(phase),
      phase: phase,
      remainingSeconds: boundedRemaining,
      totalSeconds: resolvedTotal,
      currentPomodoro: currentPomodoro ?? state.currentPomodoro,
      totalPomodoros: totalPomodoros ?? state.totalPomodoros,
      phaseStartedAt: phaseStartedAt ?? state.phaseStartedAt,
      ownerDeviceId: ownerDeviceId ?? state.ownerDeviceId,
    );
    _ensureTickRunning();
  }

  void pauseTick() {
    state = state.copyWith(status: PomodoroStatus.paused);
    _tickTimer?.cancel();
    _tickTimer = null;
  }

  void resumeTick() {
    final status = _statusForPhase(state.phase);
    state = state.copyWith(status: status);
    _ensureTickRunning();
  }

  void stopTick() {
    _tickTimer?.cancel();
    _tickTimer = null;
    state = TimerRuntimeState.idle().copyWith(syncHealth: state.syncHealth);
  }

  void applyOwnerSnapshot(PomodoroSession snapshot) {
    final phase = snapshot.phase ?? state.phase;
    final total = snapshot.phaseDurationSeconds < 0
        ? 0
        : snapshot.phaseDurationSeconds;
    final remaining = snapshot.remainingSeconds.clamp(
      0,
      total > 0 ? total : snapshot.remainingSeconds,
    );
    state = state.copyWith(
      groupId: snapshot.groupId,
      currentTaskId: snapshot.currentTaskId,
      status: snapshot.status,
      phase: phase,
      remainingSeconds: remaining,
      totalSeconds: total,
      currentPomodoro: snapshot.currentPomodoro,
      totalPomodoros: snapshot.totalPomodoros,
      phaseStartedAt: snapshot.phaseStartedAt,
      ownerDeviceId: snapshot.ownerDeviceId,
      syncHealth: SyncHealth.healthy,
    );
    // Reset ticker so it restarts from the authoritative remaining value.
    _tickTimer?.cancel();
    _tickTimer = null;
    _ensureTickRunning();
  }

  void notifySessionGap(Duration gap) {
    final health = gap >= const Duration(seconds: 45)
        ? SyncHealth.recovery
        : SyncHealth.degraded;
    notifySyncHealth(health);
  }

  void notifySyncHealth(SyncHealth health) {
    if (state.syncHealth != health) {
      state = state.copyWith(syncHealth: health);
    }
    // Ticker runs whenever isTickingCandidate, independent of health state.
    _ensureTickRunning();
  }

  void applyDriftCorrection(Duration delta) {
    if (delta.inSeconds == 0) return;
    final total = state.totalSeconds;
    if (total <= 0) return;
    final corrected = (state.remainingSeconds - delta.inSeconds).clamp(
      0,
      total,
    );
    state = state.copyWith(remainingSeconds: corrected);
  }

  void _ensureTickRunning() {
    if (!state.isTickingCandidate) return;
    if (state.remainingSeconds <= 0) return;
    if (_tickTimer != null) return;
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final current = state;
      if (!current.isTickingCandidate) {
        _tickTimer?.cancel();
        _tickTimer = null;
        return;
      }
      if (current.remainingSeconds <= 0) {
        _tickTimer?.cancel();
        _tickTimer = null;
        return;
      }
      final next = current.remainingSeconds - 1;
      state = current.copyWith(remainingSeconds: next < 0 ? 0 : next);
    });
  }

  PomodoroStatus _statusForPhase(PomodoroPhase phase) {
    switch (phase) {
      case PomodoroPhase.pomodoro:
        return PomodoroStatus.pomodoroRunning;
      case PomodoroPhase.shortBreak:
        return PomodoroStatus.shortBreakRunning;
      case PomodoroPhase.longBreak:
        return PomodoroStatus.longBreakRunning;
    }
  }
}
