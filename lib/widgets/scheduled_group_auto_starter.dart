import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../presentation/providers.dart';
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
  Timer? _deferredActionTimer;
  int _retryAttempts = 0;
  ScheduledGroupAction? _deferredAction;

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
    _deferredActionTimer?.cancel();
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
    if (ref.read(completionDialogVisibleProvider)) {
      _deferAction(action);
      return;
    }
    switch (action.type) {
      case ScheduledGroupActionType.openTimer:
        final groupId = action.groupId;
        if (groupId == null) return;
        unawaited(_openTimerForGroup(groupId));
        break;
      case ScheduledGroupActionType.lateStartQueue:
        final groupIds = action.groupIds;
        if (groupIds == null || groupIds.isEmpty) return;
        final anchor = action.anchor;
        if (anchor == null) return;
        _navigateToLateStartQueue(
          groupIds,
          anchor,
        );
        break;
    }
  }

  void _deferAction(ScheduledGroupAction action) {
    _deferredAction = action;
    _scheduleDeferredAction();
  }

  void _scheduleDeferredAction() {
    _deferredActionTimer?.cancel();
    _deferredActionTimer = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      if (ref.read(completionDialogVisibleProvider)) {
        _scheduleDeferredAction();
        return;
      }
      final pending = _deferredAction;
      _deferredAction = null;
      if (pending != null) {
        _handleAction(pending);
      }
    });
  }

  Future<void> _openTimerForGroup(String groupId) async {
    final group =
        await ref.read(taskRunGroupRepositoryProvider).getById(groupId);
    if (!mounted) return;
    final navigatorContext = widget.navigatorKey.currentContext;
    if (navigatorContext == null) {
      _scheduleRetry(() => unawaited(_openTimerForGroup(groupId)));
      return;
    }
    if (!navigatorContext.mounted) {
      _scheduleRetry(() => unawaited(_openTimerForGroup(groupId)));
      return;
    }
    _retryAttempts = 0;
    final router = GoRouter.of(navigatorContext);
    final current = _currentLocation(navigatorContext);
    if (current.startsWith('/timer/')) {
      final active = current.substring('/timer/'.length).split('?').first;
      if (active == groupId) return;
    }
    if (group != null) {
      ref.read(pomodoroViewModelProvider.notifier).primeGroupForLoad(group);
    }
    debugPrint('Auto-start opening TimerScreen for scheduled group.');
    router.go('/timer/$groupId');
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
