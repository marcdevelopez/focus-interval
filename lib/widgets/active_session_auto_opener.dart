import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/models/pomodoro_session.dart';
import '../data/models/task_run_group.dart';
import '../data/services/app_mode_service.dart';
import '../presentation/providers.dart';

class ActiveSessionAutoOpener extends ConsumerStatefulWidget {
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;

  const ActiveSessionAutoOpener({
    super.key,
    required this.child,
    required this.navigatorKey,
  });

  @override
  ConsumerState<ActiveSessionAutoOpener> createState() =>
      _ActiveSessionAutoOpenerState();
}

class _ActiveSessionAutoOpenerState
    extends ConsumerState<ActiveSessionAutoOpener>
    with WidgetsBindingObserver {
  static const Duration _autoOpenBounceWindow = Duration(seconds: 3);
  bool _autoOpenInFlight = false;
  String? _autoOpenedGroupId;
  String? _autoOpenSuppressedGroupId;
  String? _pendingGroupId;
  DateTime? _lastAutoOpenAttemptAt;
  String? _lastAutoOpenAttemptGroupId;
  Timer? _retryTimer;
  int _retryAttempts = 0;
  bool _resumeAutoOpenPending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleActiveSessionChange(ref.read(activePomodoroSessionProvider));
    });
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _resumeAutoOpenPending = true;
      _handleActiveSessionChange(ref.read(activePomodoroSessionProvider));
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<PomodoroSession?>(
      activePomodoroSessionProvider,
      (previous, next) {
        _handleActiveSessionChange(next);
      },
    );
    return widget.child;
  }

  String _currentRoute() {
    final navigatorContext = widget.navigatorKey.currentContext;
    if (navigatorContext == null) return 'null';
    return GoRouter.of(navigatorContext).routerDelegate.currentConfiguration.uri.path;
  }

  void _handleActiveSessionChange(PomodoroSession? session) {
    if (session == null) {
      debugPrint('[RunModeDiag] Active session cleared route=${_currentRoute()}');
    } else {
      debugPrint(
        '[RunModeDiag] Active session change group=${session.groupId} '
        'status=${session.status.name} owner=${session.ownerDeviceId} '
        'route=${_currentRoute()}',
      );
    }
    if (session == null) {
      _autoOpenInFlight = false;
      _autoOpenedGroupId = null;
      _autoOpenSuppressedGroupId = null;
      _pendingGroupId = null;
      _lastAutoOpenAttemptAt = null;
      _lastAutoOpenAttemptGroupId = null;
      _retryAttempts = 0;
      _resumeAutoOpenPending = false;
      _retryTimer?.cancel();
      _retryTimer = null;
      return;
    }

    final groupId = session.groupId;
    if (groupId == null || groupId.isEmpty) {
      debugPrint('Active session missing groupId. Clearing session.');
      unawaited(_clearStaleSession());
      return;
    }

    if (_resumeAutoOpenPending) {
      debugPrint(
        '[RunModeDiag] Auto-open resume trigger. Clearing auto-open state '
        'group=$groupId route=${_currentRoute()}',
      );
      _autoOpenedGroupId = null;
      _autoOpenSuppressedGroupId = null;
      _resumeAutoOpenPending = false;
    }

    final navigatorContext = widget.navigatorKey.currentContext;
    if (navigatorContext != null) {
      final inTimer = _isAlreadyInTimer(groupId);
      final route = _currentRoute();
      if (!inTimer &&
          _autoOpenedGroupId == groupId &&
          _shouldResetAutoOpenForBounce(route, groupId)) {
        debugPrint(
          '[RunModeDiag] Auto-open reset (left timer quickly) '
          'group=$groupId route=$route',
        );
        _autoOpenedGroupId = null;
        _autoOpenSuppressedGroupId = null;
      }
      if (_autoOpenedGroupId == null && inTimer) {
        debugPrint(
          '[RunModeDiag] Auto-open state set (already in timer) '
          'group=$groupId route=${_currentRoute()}',
        );
        _autoOpenedGroupId = groupId;
        _autoOpenSuppressedGroupId = null;
      }
    }

    if (_autoOpenInFlight ||
        _autoOpenedGroupId == groupId ||
        _autoOpenSuppressedGroupId == groupId) {
      debugPrint(
        '[RunModeDiag] Auto-open suppressed (in-flight=$_autoOpenInFlight '
        'opened=$_autoOpenedGroupId route=${_currentRoute()})',
      );
      return;
    }

    if (_pendingGroupId != null && _pendingGroupId != groupId) {
      _retryTimer?.cancel();
      _retryTimer = null;
      _retryAttempts = 0;
    }

    if (_pendingGroupId == groupId && _retryTimer != null) {
      debugPrint('Auto-open retry already scheduled.');
      return;
    }

    final appMode = ref.read(appModeProvider);
    if (appMode != AppMode.account) {
      debugPrint(
        '[RunModeDiag] Auto-open suppressed (not in Account Mode) '
        'route=${_currentRoute()}',
      );
      return;
    }

    final route = _currentRoute();
    if (_isSensitiveRoute(route)) {
      debugPrint(
        '[RunModeDiag] Auto-open suppressed (sensitive route) '
        'group=$groupId route=$route',
      );
      _autoOpenSuppressedGroupId = groupId;
      return;
    }

    _autoOpenInFlight = true;
    _pendingGroupId = groupId;
    unawaited(_autoOpenSession(session));
  }

  Future<void> _autoOpenSession(PomodoroSession session) async {
    try {
      final groupId = session.groupId;
      if (groupId == null || groupId.isEmpty) {
        await _clearStaleSession();
        return;
      }

      if (_isAlreadyInTimer(groupId)) {
        debugPrint('Auto-open suppressed (already in timer).');
        _autoOpenedGroupId = groupId;
        return;
      }

      debugPrint(
        '[RunModeDiag] Active session detected. Validating auto-open '
        'group=$groupId route=${_currentRoute()}',
      );
      final shouldOpen = await _isValidActiveSession(session);
      if (!mounted || !shouldOpen) return;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final navigatorContext = widget.navigatorKey.currentContext;
        if (navigatorContext == null) {
          _scheduleRetry(groupId);
          return;
        }
        final route = _currentRoute();
        if (_isSensitiveRoute(route)) {
          debugPrint(
            '[RunModeDiag] Auto-open suppressed (sensitive route) '
            'group=$groupId route=$route',
          );
          _autoOpenSuppressedGroupId = groupId;
          return;
        }
        if (_isAlreadyInTimer(groupId)) {
          debugPrint('Auto-open suppressed (already in timer).');
          _autoOpenedGroupId = groupId;
          return;
        }
        _lastAutoOpenAttemptAt = DateTime.now();
        _lastAutoOpenAttemptGroupId = groupId;
        debugPrint(
          '[RunModeDiag] Attempting auto-open to TimerScreen '
          'group=$groupId route=${_currentRoute()}',
        );
        navigatorContext.go('/timer/$groupId');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (_isAlreadyInTimer(groupId)) {
            debugPrint(
              '[RunModeDiag] Auto-open confirmed in timer '
              'group=$groupId route=${_currentRoute()}',
            );
            _autoOpenedGroupId = groupId;
          } else {
            debugPrint(
              '[RunModeDiag] Auto-open did not reach timer '
              'group=$groupId route=${_currentRoute()}',
            );
          }
        });
      });
    } finally {
      _autoOpenInFlight = false;
    }
  }

  bool _isAlreadyInTimer(String groupId) {
    final navigatorContext = widget.navigatorKey.currentContext;
    if (navigatorContext == null) return false;
    final uri = GoRouter.of(navigatorContext)
        .routerDelegate
        .currentConfiguration
        .uri;
    final location = uri.path;
    if (!location.startsWith('/timer/')) return false;
    final current = location.substring('/timer/'.length).split('?').first;
    return current == groupId;
  }

  bool _isSensitiveRoute(String route) {
    if (route == 'null') return false;
    return route.startsWith('/tasks/plan') ||
        route.startsWith('/tasks/new') ||
        route.startsWith('/tasks/edit') ||
        route.startsWith('/settings') ||
        route.startsWith('/groups/late-start');
  }

  bool _shouldResetAutoOpenForBounce(String route, String groupId) {
    if (_isSensitiveRoute(route)) return false;
    if (_lastAutoOpenAttemptGroupId != groupId) return false;
    final lastAttempt = _lastAutoOpenAttemptAt;
    if (lastAttempt == null) return false;
    return DateTime.now().difference(lastAttempt) <= _autoOpenBounceWindow;
  }

  Future<bool> _isValidActiveSession(PomodoroSession session) async {
    final groupId = session.groupId;
    if (groupId == null || groupId.isEmpty) return false;
    final groupRepo = ref.read(taskRunGroupRepositoryProvider);
    final group = await groupRepo.getById(groupId);
    if (group == null || group.status != TaskRunStatus.running) {
      debugPrint('Active session invalid or not running. Clearing session.');
      await _clearStaleSession();
      return false;
    }
    return true;
  }

  Future<void> _clearStaleSession() async {
    final sessionRepo = ref.read(pomodoroSessionRepositoryProvider);
    await sessionRepo.clearSessionIfGroupNotRunning();
  }

  void _scheduleRetry(String groupId) {
    _retryAttempts += 1;
    if (_retryAttempts > 5) {
      debugPrint(
        '[RunModeDiag] Auto-open suppressed (navigator not ready after retries) '
        'group=$groupId route=${_currentRoute()}',
      );
      _retryAttempts = 0;
      _pendingGroupId = null;
      return;
    }
    debugPrint(
      '[RunModeDiag] Navigator not ready. Retrying auto-open '
      'group=$groupId attempt=$_retryAttempts route=${_currentRoute()}',
    );
    _retryTimer?.cancel();
    _retryTimer = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      final session = ref.read(activePomodoroSessionProvider);
      if (session == null || session.groupId != groupId) return;
      _autoOpenInFlight = true;
      unawaited(_autoOpenSession(session));
    });
  }
}
