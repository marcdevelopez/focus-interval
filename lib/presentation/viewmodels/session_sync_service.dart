import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/pomodoro_session.dart';
import '../providers.dart';

/// Sync state exposed to the VM for display and orchestration.
class SessionSyncState {
  final bool holdActive;
  final PomodoroSession? latestSession;
  final DateTime? lastActiveAt;
  final String? attachedGroupId;

  const SessionSyncState({
    required this.holdActive,
    required this.latestSession,
    required this.lastActiveAt,
    required this.attachedGroupId,
  });

  factory SessionSyncState.initial() => const SessionSyncState(
        holdActive: false,
        latestSession: null,
        lastActiveAt: null,
        attachedGroupId: null,
      );

  SessionSyncState copyWith({
    bool? holdActive,
    PomodoroSession? latestSession,
    bool clearLatestSession = false,
    DateTime? lastActiveAt,
    String? attachedGroupId,
  }) {
    return SessionSyncState(
      holdActive: holdActive ?? this.holdActive,
      latestSession:
          clearLatestSession ? null : (latestSession ?? this.latestSession),
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      attachedGroupId: attachedGroupId ?? this.attachedGroupId,
    );
  }
}

/// Single authority for session stream subscription, hold/latch management,
/// and TimerService synchronization.
///
/// Invariants:
/// - Null stream NEVER stops TimerService. Only stops ticker when timer
///   is not running (no active session to protect).
/// - TimerService.isTickingCandidate is the gate for entering hold. If the
///   timer is not running when null arrives, there is no active session to
///   protect, so we quietly clear.
/// - applyOwnerSnapshot() is called on every valid session snapshot, keeping
///   TimerService anchored to Firestore values between ticks.
/// - detach() is only called on explicit mode switch — NOT on VM dispose.
///   This preserves stream continuity across Riverpod VM rebuilds (AP-1).
class SessionSyncService extends Notifier<SessionSyncState> {
  Timer? _latchTimer;
  ProviderSubscription<AsyncValue<PomodoroSession?>>? _sessionSub;

  @override
  SessionSyncState build() {
    ref.onDispose(() {
      _latchTimer?.cancel();
      // Do NOT close _sessionSub here — it must survive VM dispose/rebuild
      // to maintain stream continuity (AP-1 anti-pattern).
    });
    return SessionSyncState.initial();
  }

  /// Attach to a group's session stream.
  /// No-op if already attached to the same group with an active subscription.
  void attach(String groupId) {
    if (state.attachedGroupId == groupId && _sessionSub != null) return;
    _latchTimer?.cancel();
    _latchTimer = null;
    if (state.attachedGroupId != groupId) {
      // Switching groups: reset sync state for the new group.
      state = SessionSyncState.initial().copyWith(attachedGroupId: groupId);
    }
    _sessionSub?.close();
    _sessionSub = ref.listen<AsyncValue<PomodoroSession?>>(
      pomodoroSessionStreamProvider,
      (prev, next) => _handleStreamEvent(prev, next),
      fireImmediately: true,
    );
    if (kDebugMode) {
      debugPrint('[SessionSync] attach groupId=$groupId');
    }
  }

  /// Detach: close stream and reset state.
  /// Called only on mode switch away from account (never on VM dispose).
  void detach() {
    _latchTimer?.cancel();
    _latchTimer = null;
    _sessionSub?.close();
    _sessionSub = null;
    state = SessionSyncState.initial();
    if (kDebugMode) {
      debugPrint('[SessionSync] detach');
    }
  }

  /// VM calls this when a transitional snapshot should keep hold active
  /// (e.g., session is transitioning through non-active status).
  void extendHold() {
    if (!state.holdActive) {
      state = state.copyWith(holdActive: true);
    }
  }

  /// VM calls this when a valid session has been fully ingested and the
  /// hold should be cleared.
  void clearHold() {
    if (state.holdActive) {
      _latchTimer?.cancel();
      _latchTimer = null;
      state = state.copyWith(holdActive: false);
    }
  }

  void _handleStreamEvent(
    AsyncValue<PomodoroSession?>? prev,
    AsyncValue<PomodoroSession?> next,
  ) {
    final session = next is AsyncData<PomodoroSession?> ? next.value : null;
    if (session != null && _isSessionForGroup(session)) {
      _onSessionReceived(session);
    } else if (session == null) {
      _onSessionNull();
    }
  }

  void _onSessionReceived(PomodoroSession session) {
    _latchTimer?.cancel();
    _latchTimer = null;
    final wasHold = state.holdActive;
    // Anchor TimerService to the authoritative Firestore value.
    ref.read(timerServiceProvider.notifier).applyOwnerSnapshot(session);
    state = state.copyWith(
      holdActive: false,
      latestSession: session,
      lastActiveAt: DateTime.now(),
    );
    if (kDebugMode && wasHold) {
      debugPrint(
        '[SessionSync] hold cleared — valid session received '
        'groupId=${session.groupId} status=${session.status.name}',
      );
    }
  }

  void _onSessionNull() {
    final timer = ref.read(timerServiceProvider);
    if (!timer.isTickingCandidate) {
      // Timer is not running — no active session to protect. Quietly clear.
      if (state.holdActive || state.latestSession != null) {
        _latchTimer?.cancel();
        _latchTimer = null;
        state = state.copyWith(holdActive: false, clearLatestSession: true);
      }
      return;
    }
    if (state.holdActive) {
      // Already in hold — extend and refresh TimerService health.
      ref
          .read(timerServiceProvider.notifier)
          .notifySessionGap(_gapDuration());
      if (kDebugMode) {
        debugPrint('[SessionSync] hold extended — null stream while ticking');
      }
      return;
    }
    // Timer is running but no session — start 3-second debounce.
    if (kDebugMode) {
      debugPrint(
        '[SessionSync] null stream while ticking — debounce started '
        'groupId=${state.attachedGroupId}',
      );
    }
    _latchTimer ??= Timer(const Duration(seconds: 3), _onLatchDebounce);
  }

  void _onLatchDebounce() {
    _latchTimer = null;
    if (state.holdActive) return;
    final timer = ref.read(timerServiceProvider);
    // Check again — timer may have stopped during the 3s debounce window.
    if (!timer.isTickingCandidate) return;
    if (kDebugMode) {
      debugPrint(
        '[SessionSync] hold entered after debounce '
        'groupId=${state.attachedGroupId}',
      );
    }
    ref
        .read(timerServiceProvider.notifier)
        .notifySessionGap(const Duration(seconds: 3));
    state = state.copyWith(holdActive: true);
  }

  bool _isSessionForGroup(PomodoroSession session) {
    final groupId = state.attachedGroupId;
    return groupId != null && session.groupId == groupId;
  }

  Duration _gapDuration() {
    final lastAt = state.lastActiveAt;
    if (lastAt == null) return const Duration(seconds: 3);
    final gap = DateTime.now().difference(lastAt);
    return gap.isNegative ? Duration.zero : gap;
  }
}
