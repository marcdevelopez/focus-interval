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
  static const Duration _ownerGrace = Duration(seconds: 10);
  Timer? _scheduledTimer;
  Timer? _preAlertTimer;
  Timer? _navRetryTimer;
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
    _preAlertTimer?.cancel();
    _navRetryTimer?.cancel();
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
    ref.listen<AsyncValue<List<TaskRunGroup>>>(taskRunGroupStreamProvider, (
      previous,
      next,
    ) {
      final groups = next.value ?? const [];
      _handleGroups(groups);
    });
    return widget.child;
  }

  void _handleGroups(List<TaskRunGroup> groups) {
    _lastGroups = groups;
    if (_autoStartInFlight) return;
    unawaited(_handleGroupsAsync(groups));
  }

  Future<void> _handleGroupsAsync(List<TaskRunGroup> groups) async {
    if (_autoStartInFlight) return;

    final deviceId = ref.read(deviceInfoServiceProvider).deviceId;

    _scheduledTimer?.cancel();
    _scheduledTimer = null;
    _preAlertTimer?.cancel();
    _preAlertTimer = null;

    if (groups.isEmpty) return;

    final running = groups.where((g) => g.status == TaskRunStatus.running);
    if (running.isNotEmpty) {
      final activeSession = ref.read(activePomodoroSessionProvider);
      if (activeSession == null) {
        final sorted = running.toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        final groupId = sorted.first.id;
        ref.read(scheduledAutoStartGroupIdProvider.notifier).state = groupId;
        _navigateToTimer(groupId);
        return;
      }
      debugPrint('Scheduled auto-start suppressed (running group active).');
      return;
    }

    final scheduled =
        groups
            .where(
              (g) =>
                  g.status == TaskRunStatus.scheduled &&
                  g.scheduledStartTime != null,
            )
            .toList()
          ..sort(
            (a, b) => a.scheduledStartTime!.compareTo(b.scheduledStartTime!),
          );

    if (scheduled.isEmpty) return;

    final nextGroup = scheduled.first;
    final now = DateTime.now();
    final startTime = nextGroup.scheduledStartTime!;
    final noticeMinutes = await _resolveNoticeMinutes(nextGroup);
    await _schedulePreAlert(nextGroup, noticeMinutes);
    if (!startTime.isAfter(now)) {
      final scheduledBy = nextGroup.scheduledByDeviceId;
      if (scheduledBy != null && scheduledBy != deviceId) {
        final graceUntil = startTime.add(_ownerGrace);
        if (now.isBefore(graceUntil)) {
          final delay = graceUntil.difference(now);
          _scheduledTimer = Timer(delay, () {
            if (!mounted) return;
            _handleGroups(_lastGroups);
          });
          return;
        }
      }
      unawaited(_autoStartGroup(nextGroup.id));
      return;
    }

    final delay = startTime.difference(now);
    _scheduledTimer = Timer(delay, () {
      if (!mounted) return;
      _handleGroups(_lastGroups);
    });
  }

  Future<int> _resolveNoticeMinutes(TaskRunGroup group) async {
    final explicit = group.noticeMinutes;
    if (explicit != null) return explicit;
    return ref.read(taskRunNoticeServiceProvider).getNoticeMinutes();
  }

  Future<void> _schedulePreAlert(TaskRunGroup group, int noticeMinutes) async {
    if (noticeMinutes <= 0) return;
    final startTime = group.scheduledStartTime;
    if (startTime == null) return;
    final now = DateTime.now();
    if (!now.isBefore(startTime)) return;

    final preAlertStart = startTime.subtract(Duration(minutes: noticeMinutes));
    if (now.isBefore(preAlertStart)) {
      final delay = preAlertStart.difference(now);
      _preAlertTimer = Timer(delay, () {
        if (!mounted) return;
        _handleGroups(_lastGroups);
      });
      return;
    }

    await _sendPreAlertIfNeeded(group, preAlertStart, noticeMinutes);
    _navigateToTimer(group.id);
  }

  Future<void> _sendPreAlertIfNeeded(
    TaskRunGroup group,
    DateTime preAlertStart,
    int noticeMinutes,
  ) async {
    final groupRepo = ref.read(taskRunGroupRepositoryProvider);
    final latest = await groupRepo.getById(group.id) ?? group;
    if (latest.status != TaskRunStatus.scheduled) return;
    final sentAt = latest.noticeSentAt;
    if (sentAt != null && sentAt.isAfter(preAlertStart)) {
      return;
    }
    final now = DateTime.now();
    final deviceId = ref.read(deviceInfoServiceProvider).deviceId;
    final updated = latest.copyWith(
      noticeSentAt: now,
      noticeSentByDeviceId: deviceId,
      updatedAt: now,
    );
    await groupRepo.save(updated);

    final name = updated.tasks.isNotEmpty
        ? updated.tasks.first.name
        : 'Task group';
    await ref
        .read(notificationServiceProvider)
        .notifyGroupPreAlert(groupName: name, minutes: noticeMinutes);
  }

  Future<void> _autoStartGroup(String groupId) async {
    if (_autoStartInFlight) return;
    _autoStartInFlight = true;
    try {
      final deviceId = ref.read(deviceInfoServiceProvider).deviceId;
      final groupRepo = ref.read(taskRunGroupRepositoryProvider);
      final latest = await groupRepo.getById(groupId);
      if (latest == null) return;
      if (latest.status != TaskRunStatus.scheduled) return;
      final scheduledStart = latest.scheduledStartTime;
      if (scheduledStart == null) return;

      final now = DateTime.now();
      if (scheduledStart.isAfter(now)) return;
      final scheduledBy = latest.scheduledByDeviceId;
      if (scheduledBy != null && scheduledBy != deviceId) {
        final graceUntil = scheduledStart.add(_ownerGrace);
        if (now.isBefore(graceUntil)) return;
      }

      final totalSeconds =
          latest.totalDurationSeconds ??
          groupDurationSecondsWithFinalBreaks(latest.tasks);

      final updated = latest.copyWith(
        status: TaskRunStatus.running,
        actualStartTime: now,
        theoreticalEndTime: now.add(Duration(seconds: totalSeconds)),
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
