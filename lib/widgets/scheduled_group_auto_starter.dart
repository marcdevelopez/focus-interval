import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/models/task_run_group.dart';
import '../presentation/providers.dart';

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
  Timer? _scheduledTimer;
  bool _autoStartInFlight = false;
  List<TaskRunGroup> _lastGroups = const [];
  int _retryAttempts = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final groups = ref.read(taskRunGroupStreamProvider).value ?? const [];
      _handleGroups(groups);
    });
  }

  @override
  void dispose() {
    _scheduledTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _handleGroups(_lastGroups);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<List<TaskRunGroup>>>(
      taskRunGroupStreamProvider,
      (previous, next) {
        final groups = next.value ?? const [];
        _handleGroups(groups);
      },
    );
    return widget.child;
  }

  void _handleGroups(List<TaskRunGroup> groups) {
    _lastGroups = groups;
    if (_autoStartInFlight) return;

    _scheduledTimer?.cancel();
    _scheduledTimer = null;

    if (groups.isEmpty) return;

    final running = groups.where((g) => g.status == TaskRunStatus.running);
    if (running.isNotEmpty) {
      debugPrint('Scheduled auto-start suppressed (running group active).');
      return;
    }

    final scheduled = groups
        .where(
          (g) =>
              g.status == TaskRunStatus.scheduled &&
              g.scheduledStartTime != null,
        )
        .toList()
      ..sort(
        (a, b) =>
            a.scheduledStartTime!.compareTo(b.scheduledStartTime!),
      );

    if (scheduled.isEmpty) return;

    final nextGroup = scheduled.first;
    final now = DateTime.now();
    final startTime = nextGroup.scheduledStartTime!;
    if (!startTime.isAfter(now)) {
      unawaited(_autoStartGroup(nextGroup.id));
      return;
    }

    final delay = startTime.difference(now);
    _scheduledTimer = Timer(delay, () {
      if (!mounted) return;
      _handleGroups(_lastGroups);
    });
  }

  Future<void> _autoStartGroup(String groupId) async {
    if (_autoStartInFlight) return;
    _autoStartInFlight = true;
    try {
      final groupRepo = ref.read(taskRunGroupRepositoryProvider);
      final latest = await groupRepo.getById(groupId);
      if (latest == null) return;
      if (latest.status != TaskRunStatus.scheduled) return;
      final scheduledStart = latest.scheduledStartTime;
      if (scheduledStart == null) return;

      final now = DateTime.now();
      if (scheduledStart.isAfter(now)) return;

      final updated = latest.copyWith(
        status: TaskRunStatus.running,
        actualStartTime: now,
        theoreticalEndTime:
            now.add(Duration(seconds: latest.totalDurationSeconds)),
        updatedAt: now,
      );
      await groupRepo.save(updated);

      ref.read(scheduledAutoStartGroupIdProvider.notifier).state = groupId;
      _navigateToTimer(groupId);
    } catch (e) {
      debugPrint('Scheduled auto-start failed: $e');
    } finally {
      _autoStartInFlight = false;
    }
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
    _scheduledTimer?.cancel();
    _scheduledTimer = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      _navigateToTimer(groupId);
    });
  }

  String _currentLocation(BuildContext context) {
    final uri = GoRouter.of(context).routerDelegate.currentConfiguration.uri;
    return uri.path;
  }
}
