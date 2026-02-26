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
    extends ConsumerState<ActiveSessionAutoOpener> {
  bool _autoOpenInFlight = false;
  String? _autoOpenedGroupId;
  String? _pendingGroupId;
  Timer? _retryTimer;
  int _retryAttempts = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleActiveSessionChange(ref.read(activePomodoroSessionProvider));
    });
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
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
      _pendingGroupId = null;
      _retryAttempts = 0;
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

    if (_autoOpenInFlight || _autoOpenedGroupId == groupId) {
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
        if (_isAlreadyInTimer(groupId)) {
          debugPrint('Auto-open suppressed (already in timer).');
          _autoOpenedGroupId = groupId;
          return;
        }
        debugPrint(
          '[RunModeDiag] Attempting auto-open to TimerScreen '
          'group=$groupId route=${_currentRoute()}',
        );
        _autoOpenedGroupId = groupId;
        navigatorContext.go('/timer/$groupId');
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
