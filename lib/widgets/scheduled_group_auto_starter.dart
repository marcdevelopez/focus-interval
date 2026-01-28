import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../presentation/viewmodels/scheduled_group_coordinator.dart';

class ScheduledGroupAutoStarter extends ConsumerStatefulWidget {
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;

  const ScheduledGroupAutoStarter({
    super.key,
    required this.child,
    required this.navigatorKey,
  });

  @override
  ConsumerState<ScheduledGroupAutoStarter> createState() =>
      _ScheduledGroupAutoStarterState();
}

class _ScheduledGroupAutoStarterState
    extends ConsumerState<ScheduledGroupAutoStarter>
    with WidgetsBindingObserver {
  Timer? _navRetryTimer;
  int _retryAttempts = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _navRetryTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(scheduledGroupCoordinatorProvider.notifier).onAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ScheduledGroupAction?>(
      scheduledGroupCoordinatorProvider,
      (previous, next) {
        if (next == null) return;
        _navigateToTimer(next.groupId);
        ref.read(scheduledGroupCoordinatorProvider.notifier).clearAction();
      },
      fireImmediately: true,
    );
    return widget.child;
  }

  void _navigateToTimer(String groupId) {
    final navigatorContext = widget.navigatorKey.currentContext;
    if (navigatorContext == null) {
      _scheduleRetry(groupId);
      return;
    }
    _retryAttempts = 0;
    final current = _currentLocation(navigatorContext);
    if (current.startsWith('/timer/')) {
      final active = current.substring('/timer/'.length).split('?').first;
      if (active == groupId) return;
    }
    debugPrint('Auto-start opening TimerScreen for scheduled group.');
    navigatorContext.go('/timer/$groupId');
  }

  void _scheduleRetry(String groupId) {
    _retryAttempts += 1;
    if (_retryAttempts > 5) {
      debugPrint('Scheduled auto-start suppressed (navigator not ready).');
      _retryAttempts = 0;
      return;
    }
    _navRetryTimer?.cancel();
    _navRetryTimer = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      _navigateToTimer(groupId);
    });
  }

  String _currentLocation(BuildContext context) {
    final uri = GoRouter.of(context).routerDelegate.currentConfiguration.uri;
    return uri.path;
  }
}
