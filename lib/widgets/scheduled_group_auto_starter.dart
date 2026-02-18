import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../presentation/viewmodels/scheduled_group_coordinator.dart';
import '../presentation/screens/late_start_overlap_queue_screen.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final action = ref.read(scheduledGroupCoordinatorProvider);
      if (action == null) return;
      _handleAction(action);
      ref.read(scheduledGroupCoordinatorProvider.notifier).clearAction();
    });
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
        _handleAction(next);
        ref.read(scheduledGroupCoordinatorProvider.notifier).clearAction();
      },
    );
    return widget.child;
  }

  void _handleAction(ScheduledGroupAction action) {
    switch (action.type) {
      case ScheduledGroupActionType.openTimer:
        final groupId = action.groupId;
        if (groupId == null) return;
        _navigateToTimer(groupId);
        break;
      case ScheduledGroupActionType.lateStartQueue:
        final groupIds = action.groupIds;
        if (groupIds == null || groupIds.isEmpty) return;
        _navigateToLateStartQueue(
          groupIds,
          action.anchor ?? DateTime.now(),
        );
        break;
    }
  }

  void _navigateToTimer(String groupId) {
    final navigatorContext = widget.navigatorKey.currentContext;
    if (navigatorContext == null) {
      _scheduleRetry(() => _navigateToTimer(groupId));
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

  void _navigateToLateStartQueue(List<String> groupIds, DateTime anchor) {
    final navigatorContext = widget.navigatorKey.currentContext;
    if (navigatorContext == null) {
      _scheduleRetry(() => _navigateToLateStartQueue(groupIds, anchor));
      return;
    }
    _retryAttempts = 0;
    final current = _currentLocation(navigatorContext);
    if (current.startsWith('/groups/late-start')) return;
    debugPrint('Opening late-start overlap queue.');
    navigatorContext.go(
      '/groups/late-start',
      extra: LateStartOverlapArgs(groupIds: groupIds, anchor: anchor),
    );
  }

  void _scheduleRetry(VoidCallback action) {
    _retryAttempts += 1;
    if (_retryAttempts > 5) {
      debugPrint('Scheduled action suppressed (navigator not ready).');
      _retryAttempts = 0;
      return;
    }
    _navRetryTimer?.cancel();
    _navRetryTimer = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      action();
    });
  }

  String _currentLocation(BuildContext context) {
    final uri = GoRouter.of(context).routerDelegate.currentConfiguration.uri;
    return uri.path;
  }
}
