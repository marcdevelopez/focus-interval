import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/pomodoro_session.dart';
import '../../data/models/task_run_group.dart';
import '../../data/services/app_mode_service.dart';
import '../../domain/pomodoro_machine.dart';
import '../providers.dart';

enum RecoveryStatus { idle, attempting, failed }

/// Sync state exposed to the VM for display and orchestration.
class SessionSyncState {
  final bool holdActive;
  final PomodoroSession? latestSession;
  final DateTime? lastActiveAt;
  final String? attachedGroupId;
  final RecoveryStatus recoveryStatus;

  const SessionSyncState({
    required this.holdActive,
    required this.latestSession,
    required this.lastActiveAt,
    required this.attachedGroupId,
    required this.recoveryStatus,
  });

  factory SessionSyncState.initial() => const SessionSyncState(
    holdActive: false,
    latestSession: null,
    lastActiveAt: null,
    attachedGroupId: null,
    recoveryStatus: RecoveryStatus.idle,
  );

  SessionSyncState copyWith({
    bool? holdActive,
    PomodoroSession? latestSession,
    bool clearLatestSession = false,
    DateTime? lastActiveAt,
    String? attachedGroupId,
    RecoveryStatus? recoveryStatus,
  }) {
    return SessionSyncState(
      holdActive: holdActive ?? this.holdActive,
      latestSession: clearLatestSession
          ? null
          : (latestSession ?? this.latestSession),
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      attachedGroupId: attachedGroupId ?? this.attachedGroupId,
      recoveryStatus: recoveryStatus ?? this.recoveryStatus,
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
  static const Duration _recoveryCooldown = Duration(seconds: 5);

  Timer? _latchTimer;
  Timer? _recoveryRetryTimer;
  ProviderSubscription<AsyncValue<PomodoroSession?>>? _sessionSub;
  DateTime? _lastRecoveryAttemptAt;
  Future<void>? _recoveryInFlight;
  Future<void>? _terminalReconcileInFlight;
  String? _terminalReconcileKey;

  @override
  SessionSyncState build() {
    ref.onDispose(() {
      _latchTimer?.cancel();
      _recoveryRetryTimer?.cancel();
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
    _recoveryRetryTimer?.cancel();
    _recoveryRetryTimer = null;
    _recoveryInFlight = null;
    _terminalReconcileInFlight = null;
    _terminalReconcileKey = null;
    _lastRecoveryAttemptAt = null;
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
    _recoveryRetryTimer?.cancel();
    _recoveryRetryTimer = null;
    _recoveryInFlight = null;
    _terminalReconcileInFlight = null;
    _terminalReconcileKey = null;
    _lastRecoveryAttemptAt = null;
    _sessionSub?.close();
    _sessionSub = null;
    state = SessionSyncState.initial();
    if (kDebugMode) {
      debugPrint('[SessionSync] detach');
    }
  }

  void _handleStreamEvent(
    AsyncValue<PomodoroSession?>? prev,
    AsyncValue<PomodoroSession?> next,
  ) {
    // AsyncLoading / AsyncError are transient and MUST NOT be treated as
    // missing-session null snapshots.
    if (next is! AsyncData<PomodoroSession?>) return;
    final session = next.value;
    if (session != null && _isSessionForGroup(session)) {
      _onSessionReceived(session);
    } else if (session == null) {
      _onSessionNull();
    }
  }

  void _onSessionReceived(PomodoroSession session) {
    _latchTimer?.cancel();
    _latchTimer = null;
    _recoveryRetryTimer?.cancel();
    _recoveryRetryTimer = null;
    final wasHold = state.holdActive;
    final timer = ref.read(timerServiceProvider);
    final shouldIgnoreNonActive =
        !session.status.isActiveExecution && timer.isTickingCandidate;
    // Ignore non-active snapshots while runtime is still active.
    // This prevents stale terminal/transitional snapshots from overriding
    // an active countdown that still has authoritative runtime continuity.
    if (shouldIgnoreNonActive) {
      _maybeReconcileTerminalSnapshot(session, wasHold: wasHold);
      if (state.recoveryStatus != RecoveryStatus.failed) {
        state = state.copyWith(recoveryStatus: RecoveryStatus.failed);
      }
      if (kDebugMode) {
        debugPrint(
          '[SessionSync] non-active snapshot ignored while runtime active '
          'hold=$wasHold '
          'groupId=${session.groupId} status=${session.status.name}',
        );
      }
      if (wasHold) {
        _scheduleRecoveryRetry(_recoveryCooldown);
      }
      return;
    }
    // Anchor TimerService to the authoritative Firestore value.
    ref.read(timerServiceProvider.notifier).applyOwnerSnapshot(session);
    state = state.copyWith(
      holdActive: false,
      latestSession: session,
      lastActiveAt: DateTime.now(),
      recoveryStatus: RecoveryStatus.idle,
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
        _recoveryRetryTimer?.cancel();
        _recoveryRetryTimer = null;
        state = state.copyWith(
          holdActive: false,
          clearLatestSession: true,
          recoveryStatus: RecoveryStatus.idle,
        );
      }
      return;
    }
    if (state.holdActive) {
      // Already in hold — extend and refresh TimerService health.
      ref.read(timerServiceProvider.notifier).notifySessionGap(_gapDuration());
      if (kDebugMode) {
        debugPrint('[SessionSync] hold extended — null stream while ticking');
      }
      unawaited(_attemptRecovery(trigger: 'null-while-hold'));
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
    state = state.copyWith(
      holdActive: true,
      recoveryStatus: RecoveryStatus.attempting,
    );
    unawaited(_attemptRecovery(trigger: 'latch-debounce'));
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

  bool _isTerminalSessionStatus(PomodoroStatus status) {
    return status == PomodoroStatus.finished || status == PomodoroStatus.idle;
  }

  void _maybeReconcileTerminalSnapshot(
    PomodoroSession session, {
    required bool wasHold,
  }) {
    if (!_isTerminalSessionStatus(session.status)) return;
    final key =
        '${session.groupId}:${session.sessionRevision}:${session.status.name}:'
        '${session.lastUpdatedAt?.microsecondsSinceEpoch ?? -1}';
    if (_terminalReconcileKey == key && _terminalReconcileInFlight != null) {
      return;
    }
    final future = _reconcileTerminalSnapshot(session, wasHold: wasHold);
    _terminalReconcileKey = key;
    _terminalReconcileInFlight = future;
    unawaited(
      future.whenComplete(() {
        if (identical(_terminalReconcileInFlight, future)) {
          _terminalReconcileInFlight = null;
          _terminalReconcileKey = null;
        }
      }),
    );
  }

  Future<void> _reconcileTerminalSnapshot(
    PomodoroSession session, {
    required bool wasHold,
  }) async {
    try {
      final groupId = session.groupId;
      if (groupId == null || groupId.isEmpty) return;
      final repo = ref.read(taskRunGroupRepositoryProvider);
      final group = await repo.getById(groupId);
      if (!_isSessionForGroup(session)) return;
      final isTerminalGroup =
          group?.status == TaskRunStatus.completed ||
          group?.status == TaskRunStatus.canceled;
      if (!isTerminalGroup) return;
      _latchTimer?.cancel();
      _latchTimer = null;
      _recoveryRetryTimer?.cancel();
      _recoveryRetryTimer = null;
      ref.read(timerServiceProvider.notifier).applyOwnerSnapshot(session);
      state = state.copyWith(
        holdActive: false,
        latestSession: session,
        lastActiveAt: DateTime.now(),
        recoveryStatus: RecoveryStatus.idle,
      );
      if (kDebugMode) {
        debugPrint(
          '[SessionSync] terminal snapshot accepted after group corroboration '
          'hold=$wasHold '
          'groupId=${session.groupId} status=${session.status.name}',
        );
      }
    } catch (_) {
      // Keep existing non-active ignore behavior when corroboration fails.
    }
  }

  Future<void> _attemptRecovery({required String trigger}) async {
    if (!state.holdActive) return;
    if (ref.read(appModeProvider) != AppMode.account) return;
    if (_recoveryInFlight != null) return;
    final lastAttempt = _lastRecoveryAttemptAt;
    final now = DateTime.now();
    if (lastAttempt != null) {
      final elapsed = now.difference(lastAttempt);
      if (elapsed < _recoveryCooldown) {
        _scheduleRecoveryRetry(_recoveryCooldown - elapsed);
        return;
      }
    }
    _lastRecoveryAttemptAt = now;
    if (state.recoveryStatus != RecoveryStatus.attempting) {
      state = state.copyWith(recoveryStatus: RecoveryStatus.attempting);
    }
    if (kDebugMode) {
      debugPrint('[SessionSync] recovery attempt trigger=$trigger');
    }

    final future = _recoverFromServer();
    _recoveryInFlight = future;
    try {
      await future;
    } finally {
      if (identical(_recoveryInFlight, future)) {
        _recoveryInFlight = null;
      }
    }
  }

  Future<void> _recoverFromServer() async {
    try {
      final repo = ref.read(pomodoroSessionRepositoryProvider);
      final serverSession = await repo.fetchSession(preferServer: true);
      if (!state.holdActive) return;
      if (serverSession != null && _isSessionForGroup(serverSession)) {
        _onSessionReceived(serverSession);
        return;
      }
      if (state.recoveryStatus != RecoveryStatus.failed) {
        state = state.copyWith(recoveryStatus: RecoveryStatus.failed);
      }
      _scheduleRecoveryRetry(_recoveryCooldown);
    } catch (_) {
      if (!state.holdActive) return;
      if (state.recoveryStatus != RecoveryStatus.failed) {
        state = state.copyWith(recoveryStatus: RecoveryStatus.failed);
      }
      _scheduleRecoveryRetry(_recoveryCooldown);
    }
  }

  void _scheduleRecoveryRetry(Duration delay) {
    _recoveryRetryTimer?.cancel();
    if (!state.holdActive) return;
    final nextDelay = delay <= Duration.zero ? Duration.zero : delay;
    _recoveryRetryTimer = Timer(nextDelay, () {
      _recoveryRetryTimer = null;
      unawaited(_attemptRecovery(trigger: 'retry'));
    });
  }
}
