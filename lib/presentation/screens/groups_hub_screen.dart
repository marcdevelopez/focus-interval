import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/pomodoro_session.dart';
import '../../data/models/task_run_group.dart';
import '../../data/models/schema_version.dart';
import '../../data/repositories/task_run_group_repository.dart';
import '../../data/services/app_mode_service.dart';
import '../../domain/pomodoro_machine.dart';
import '../../widgets/mode_indicator.dart';
import '../providers.dart';
import '../viewmodels/pre_run_notice_view_model.dart';
import 'task_group_planning_screen.dart';
import '../utils/scheduled_group_timing.dart';
import 'late_start_overlap_queue_screen.dart';

final DateFormat _groupsHubTimeFormat = DateFormat('HH:mm');
final DateFormat _groupsHubDateTimeFormat = DateFormat('MMM d, HH:mm');

String _formatGroupDateTime(DateTime? value, DateTime now) {
  if (value == null) return '--:--';
  final isToday =
      value.year == now.year && value.month == now.month && value.day == now.day;
  return isToday
      ? _groupsHubTimeFormat.format(value)
      : _groupsHubDateTimeFormat.format(value);
}

class GroupsHubScreen extends ConsumerStatefulWidget {
  const GroupsHubScreen({super.key});

  @override
  ConsumerState<GroupsHubScreen> createState() => _GroupsHubScreenState();
}

class _GroupsHubScreenState extends ConsumerState<GroupsHubScreen> {
  static const Duration _ownerStaleThreshold = Duration(seconds: 45);
  int? _noticeFallbackMinutes;
  String? _dismissedOwnershipRequestKey;
  String? _dismissedOwnershipRequesterId;
  static const int _completedHistoryLimit = 7;
  static const int _canceledHistoryLimit = 7;
  Timer? _nowTickTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _nowTickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _now = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _nowTickTimer?.cancel();
    super.dispose();
  }

  RunningOverlapDecision? _resolveMirrorConflictDecision({
    required AppMode appMode,
    required PomodoroSession? activeSession,
    required RunningOverlapDecision? decision,
    required String deviceId,
    required List<TaskRunGroup> groups,
    required DateTime now,
    int? noticeFallbackMinutes,
  }) {
    if (appMode != AppMode.account) return null;
    if (activeSession == null || decision == null) return null;
    if (activeSession.ownerDeviceId == deviceId) return null;
    if (activeSession.groupId != decision.runningGroupId) return null;
    final isValid = isRunningOverlapStillValid(
      runningGroupId: decision.runningGroupId,
      scheduledGroupId: decision.scheduledGroupId,
      groups: groups,
      activeSession: activeSession,
      now: now,
      fallbackNoticeMinutes: noticeFallbackMinutes,
    );
    if (!isValid) return null;
    return decision;
  }

  String _ownershipRequestKey(OwnershipRequest? request) {
    if (request == null) return '';
    return request.requestId ?? request.requesterDeviceId;
  }

  bool _isDismissedOwnershipRequest(OwnershipRequest? request) {
    if (request == null) return false;
    if (request.requestId != null) {
      return request.requestId == _dismissedOwnershipRequestKey;
    }
    final requestKey = _ownershipRequestKey(request);
    return (requestKey.isNotEmpty &&
            requestKey == _dismissedOwnershipRequestKey) ||
        (_dismissedOwnershipRequesterId != null &&
            request.requesterDeviceId == _dismissedOwnershipRequesterId);
  }

  void _clearDismissedOwnershipRequest() {
    if (mounted) {
      setState(() {
        _dismissedOwnershipRequestKey = null;
        _dismissedOwnershipRequesterId = null;
      });
    } else {
      _dismissedOwnershipRequestKey = null;
      _dismissedOwnershipRequesterId = null;
    }
  }

  bool _isOwnerStale(PomodoroSession? session, DateTime now) {
    if (session == null) return false;
    final updatedAt = session.lastUpdatedAt;
    if (updatedAt == null) return false;
    return now.difference(updatedAt) >= _ownerStaleThreshold;
  }

  Widget _buildMirrorConflictBanner(
    BuildContext context, {
    required RunningOverlapDecision decision,
    required bool ownerStale,
  }) {
    final message = ownerStale
        ? 'Owner seems unavailable. Claim ownership to resolve this conflict.'
        : 'Owner is resolving this conflict. Request ownership if needed.';
    final actionLabel = ownerStale ? 'Claim ownership' : 'Request ownership';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton(
              onPressed: () => _handleConflictOwnershipAction(
                decision.runningGroupId,
                ownerStale: ownerStale,
              ),
              child: Text(actionLabel),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleConflictOwnershipAction(
    String groupId, {
    required bool ownerStale,
  }) async {
    final vm = ref.read(pomodoroViewModelProvider.notifier);
    if (ownerStale) {
      await vm.claimOwnershipForActiveSession(groupId: groupId);
      return;
    }
    await vm.requestOwnershipForActiveSession(groupId: groupId);
  }

  String _platformFromDeviceId(String deviceId) {
    final dash = deviceId.indexOf('-');
    if (dash <= 0) return deviceId;
    return deviceId.substring(0, dash);
  }

  Widget _buildOwnershipRequestBanner(OwnershipRequest request) {
    final requesterLabel = _platformFromDeviceId(request.requesterDeviceId);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ownership request from $requesterLabel.',
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _dismissedOwnershipRequestKey =
                          request.requestId ?? request.requesterDeviceId;
                      _dismissedOwnershipRequesterId =
                          request.requestId == null
                              ? request.requesterDeviceId
                              : null;
                    });
                    unawaited(
                      ref.read(pomodoroViewModelProvider.notifier)
                          .rejectOwnershipRequest(),
                    );
                  },
                  child: const Text('Reject'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _dismissedOwnershipRequestKey =
                          request.requestId ?? request.requesterDeviceId;
                      _dismissedOwnershipRequesterId =
                          request.requestId == null
                              ? request.requesterDeviceId
                              : null;
                    });
                    unawaited(
                      ref.read(pomodoroViewModelProvider.notifier)
                          .approveOwnershipRequest(),
                    );
                  },
                  child: const Text('Approve'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(taskRunGroupStreamProvider);
    final activeSession = ref.watch(activePomodoroSessionProvider);
    final overlapDecision = ref.watch(runningOverlapDecisionProvider);
    final appMode = ref.watch(appModeProvider);
    final deviceId = ref.watch(deviceInfoServiceProvider).deviceId;
    final now = _now;
    _noticeFallbackMinutes = ref
        .watch(preRunNoticeMinutesProvider)
        .maybeWhen(data: (value) => value, orElse: () => null);
    final groups = groupsAsync.value ?? const [];
    final mirrorConflictDecision = _resolveMirrorConflictDecision(
      appMode: appMode,
      activeSession: activeSession,
      decision: overlapDecision,
      deviceId: deviceId,
      groups: groups,
      now: now,
      noticeFallbackMinutes: _noticeFallbackMinutes,
    );
    if (overlapDecision != null && mirrorConflictDecision == null) {
      final stillValid = isRunningOverlapStillValid(
        runningGroupId: overlapDecision.runningGroupId,
        scheduledGroupId: overlapDecision.scheduledGroupId,
        groups: groups,
        activeSession: activeSession,
        now: now,
        fallbackNoticeMinutes: _noticeFallbackMinutes,
      );
      if (!stillValid) {
        ref.read(runningOverlapDecisionProvider.notifier).state = null;
      }
    }

    final ownershipRequest = activeSession?.ownershipRequest;
    final isOwnerDevice =
        activeSession != null && activeSession.ownerDeviceId == deviceId;
    final hasPendingOwnerRequest =
        ownershipRequest?.status == OwnershipRequestStatus.pending &&
        ownershipRequest?.requesterDeviceId != deviceId;
    final isDismissedOwnerRequest =
        _isDismissedOwnershipRequest(ownershipRequest);
    if ((_dismissedOwnershipRequestKey != null ||
            _dismissedOwnershipRequesterId != null) &&
        (ownershipRequest == null ||
            ownershipRequest.status != OwnershipRequestStatus.pending ||
            !_isDismissedOwnershipRequest(ownershipRequest))) {
      _clearDismissedOwnershipRequest();
    }
    final showOwnerRequestBanner =
        isOwnerDevice && hasPendingOwnerRequest && !isDismissedOwnerRequest;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Groups Hub'),
        actions: [
          const ModeIndicatorAction(compact: true),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: OutlinedButton.icon(
              onPressed: () => context.go('/tasks'),
              icon: const Icon(Icons.library_books),
              label: const Text('Go to Task List'),
            ),
          ),
          Expanded(
            child: groupsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text(
                  "Error: $e",
                  style: const TextStyle(color: Colors.red),
                ),
              ),
              data: (groups) {
                final runningGroups = groups
                    .where((g) => g.status == TaskRunStatus.running)
                    .toList()
                  ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
                final scheduledGroups = groups
                    .where((g) => g.status == TaskRunStatus.scheduled)
                    .toList()
                  ..sort((a, b) {
                    final aStart =
                        resolveEffectiveScheduledStart(
                          group: a,
                          allGroups: groups,
                          activeSession: activeSession,
                          now: now,
                          fallbackNoticeMinutes: _noticeFallbackMinutes,
                        ) ??
                        a.scheduledStartTime ??
                        a.createdAt;
                    final bStart =
                        resolveEffectiveScheduledStart(
                          group: b,
                          allGroups: groups,
                          activeSession: activeSession,
                          now: now,
                          fallbackNoticeMinutes: _noticeFallbackMinutes,
                        ) ??
                        b.scheduledStartTime ??
                        b.createdAt;
                    return aStart.compareTo(bStart);
                  });
                final completedGroups = groups
                    .where((g) => g.status == TaskRunStatus.completed)
                    .toList()
                  ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
                final completedSlice = completedGroups
                    .take(_completedHistoryLimit)
                    .toList(growable: false);
                final canceledGroups = groups
                    .where((g) => g.status == TaskRunStatus.canceled)
                    .toList()
                  ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
                final canceledSlice = canceledGroups
                    .take(_canceledHistoryLimit)
                    .toList(growable: false);

                final hasGroups =
                    runningGroups.isNotEmpty ||
                    scheduledGroups.isNotEmpty ||
                    completedSlice.isNotEmpty ||
                    canceledSlice.isNotEmpty;

                final children = <Widget>[];
                if (showOwnerRequestBanner && ownershipRequest != null) {
                  children.add(_buildOwnershipRequestBanner(ownershipRequest));
                  children.add(const SizedBox(height: 16));
                }
                if (mirrorConflictDecision != null) {
                  final ownerStale = _isOwnerStale(activeSession, now);
                  children.add(
                    _buildMirrorConflictBanner(
                      context,
                      decision: mirrorConflictDecision,
                      ownerStale: ownerStale,
                    ),
                  );
                  children.add(const SizedBox(height: 16));
                }

                if (!hasGroups) {
                  children
                    ..add(const SizedBox(height: 48))
                    ..add(
                      const Center(
                        child: Text(
                          'No groups yet.',
                          style: TextStyle(color: Colors.white54),
                        ),
                      ),
                    );
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: children,
                  );
                }

                children.addAll([
            _SectionHeader(title: 'Running / Paused'),
            if (runningGroups.isEmpty)
              const _EmptySection(label: 'No running groups'),
            for (final group in runningGroups)
              _GroupCard(
                group: group,
                activeSession: activeSession,
                preRunStartOverride: null,
                onTap: () => _showSummaryDialog(context, group),
                actions: [
                  _GroupAction(
                    label: 'Open Run Mode',
                    onPressed: () => context.go('/timer/${group.id}'),
                  ),
                ],
                now: now,
              ),
            const SizedBox(height: 20),
            _SectionHeader(title: 'Scheduled'),
            if (scheduledGroups.isEmpty)
              const _EmptySection(label: 'No scheduled groups'),
            for (final group in scheduledGroups)
              Builder(
                builder: (context) {
                  final effectiveStart = resolveEffectiveScheduledStart(
                    group: group,
                    allGroups: groups,
                    activeSession: activeSession,
                    now: now,
                    fallbackNoticeMinutes: _noticeFallbackMinutes,
                  );
                  final effectivePreRunStart = resolveEffectivePreRunStart(
                    group: group,
                    allGroups: groups,
                    activeSession: activeSession,
                    now: now,
                    fallbackNoticeMinutes: _noticeFallbackMinutes,
                  );
                  final isPreRunActive = _isPreRunActive(
                    group,
                    now,
                    scheduledStartOverride: effectiveStart,
                  );
                  return _GroupCard(
                    group: group,
                    activeSession: activeSession,
                    scheduledStartOverride: effectiveStart,
                    scheduledEndOverride: resolveEffectiveScheduledEnd(
                      group: group,
                      allGroups: groups,
                      activeSession: activeSession,
                      now: now,
                      fallbackNoticeMinutes: _noticeFallbackMinutes,
                    ),
                    preRunStartOverride: effectivePreRunStart,
                    onTap: () => _showSummaryDialog(context, group),
                    actions: [
                      if (isPreRunActive)
                        _GroupAction(
                          label: 'Open Pre-Run',
                          onPressed: () => context.go('/timer/${group.id}'),
                        )
                      else
                        _GroupAction(
                          label: 'Start now',
                          onPressed: () => _handleStartNow(
                            context,
                            ref,
                            group,
                          ),
                        ),
                      _GroupAction(
                        label: 'Cancel schedule',
                        outlined: true,
                        onPressed: () => _handleCancelSchedule(
                          context,
                          ref,
                          group,
                        ),
                      ),
                    ],
                    now: now,
                  );
                },
              ),
            const SizedBox(height: 20),
            _SectionHeader(title: 'Completed'),
            if (completedSlice.isEmpty)
              const _EmptySection(label: 'No completed groups yet'),
            for (final group in completedSlice)
              _GroupCard(
                group: group,
                activeSession: activeSession,
                preRunStartOverride: null,
                onTap: () => _showSummaryDialog(context, group),
                actions: [
                  _GroupAction(
                    label: 'Run again',
                    onPressed: () => _handleRunAgain(
                      context,
                      ref,
                      group,
                    ),
                  ),
                ],
                now: now,
              ),
            const SizedBox(height: 20),
            _SectionHeader(title: 'Canceled'),
            if (canceledSlice.isEmpty)
              const _EmptySection(label: 'No canceled groups yet'),
            for (final group in canceledSlice)
              _GroupCard(
                group: group,
                activeSession: activeSession,
                preRunStartOverride: null,
                onTap: () => _showSummaryDialog(context, group),
                actions: [
                  _GroupAction(
                    label: 'Re-plan group',
                    onPressed: () => _handleRunAgain(
                      context,
                      ref,
                      group,
                    ),
                  ),
                ],
                now: now,
              ),
                ]);

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: children,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCancelSchedule(
    BuildContext context,
    WidgetRef ref,
    TaskRunGroup group,
  ) async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel scheduled group?'),
        content: const Text(
          'This will cancel the schedule and move the group to Canceled.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cancel schedule'),
          ),
        ],
      ),
    );
    if (shouldCancel != true) return;

    final repo = ref.read(taskRunGroupRepositoryProvider);
    final now = DateTime.now();
    final updated = group.copyWith(
      status: TaskRunStatus.canceled,
      canceledReason: TaskRunCanceledReason.user,
      postponedAfterGroupId: null,
      updatedAt: now,
    );
    await repo.save(updated);
    await ref.read(notificationServiceProvider).cancelGroupPreAlert(group.id);
    if (!context.mounted) return;
    _showSnackBar(context, 'Schedule canceled. You can re-plan it from Canceled.');
  }

  Future<void> _handleStartNow(
    BuildContext context,
    WidgetRef ref,
    TaskRunGroup group,
  ) async {
    final repo = ref.read(taskRunGroupRepositoryProvider);
    final now = DateTime.now();
    final activeSession = ref.read(activePomodoroSessionProvider);
    final totalSeconds =
        group.totalDurationSeconds ??
        groupDurationSecondsByMode(group.tasks, group.integrityMode);
    final conflictStart = now;
    final conflictEnd = now.add(Duration(seconds: totalSeconds));

    List<TaskRunGroup> existing = const [];
    try {
      existing = await repo.getAll();
      if (!context.mounted) return;
    } catch (e) {
      if (!context.mounted) return;
      _showSnackBar(context, "Failed to check conflicts: $e");
      return;
    }

    final hasRunning =
        existing.any((candidate) => candidate.status == TaskRunStatus.running);
    if (!hasRunning) {
      final scheduled =
          existing
              .where(
                (candidate) =>
                    candidate.status == TaskRunStatus.scheduled &&
                    candidate.scheduledStartTime != null,
              )
              .toList()
            ..sort((a, b) {
              final aStart =
                  resolveEffectiveScheduledStart(
                    group: a,
                    allGroups: existing,
                    activeSession: activeSession,
                    now: now,
                    fallbackNoticeMinutes: _noticeFallbackMinutes,
                  ) ??
                  a.scheduledStartTime!;
              final bStart =
                  resolveEffectiveScheduledStart(
                    group: b,
                    allGroups: existing,
                    activeSession: activeSession,
                    now: now,
                    fallbackNoticeMinutes: _noticeFallbackMinutes,
                  ) ??
                  b.scheduledStartTime!;
              return aStart.compareTo(bStart);
            });
      final lateStartConflicts = resolveLateStartConflictSet(
        scheduled: scheduled,
        allGroups: existing,
        activeSession: activeSession,
        now: now,
        fallbackNoticeMinutes: _noticeFallbackMinutes,
      );
      if (lateStartConflicts.isNotEmpty) {
        final anchor =
            resolveLateStartAnchor(lateStartConflicts) ?? now;
        if (!context.mounted) return;
        context.go(
          '/groups/late-start',
          extra: LateStartOverlapArgs(
            groupIds: lateStartConflicts.map((g) => g.id).toList(),
            anchor: anchor,
          ),
        );
        return;
      }
    }

    final conflicts = _findConflicts(
      existing,
      newStart: conflictStart,
      newEnd: conflictEnd,
      includeRunningAlways: true,
      activeSession: activeSession,
      now: now,
      excludeGroupId: group.id,
    );

    try {
      if (conflicts.running.isNotEmpty) {
        final resolved = await _resolveRunningConflict(
          context,
          conflicts.running,
          repo,
        );
        if (!context.mounted) return;
        if (!resolved) return;
      }

      if (conflicts.scheduled.isNotEmpty) {
        final resolved = await _resolveScheduledConflict(
          context,
          conflicts.scheduled,
          repo,
        );
        if (!context.mounted) return;
        if (!resolved) return;
      }
    } catch (e) {
      if (!context.mounted) return;
      _showSnackBar(context, "Failed to resolve conflicts: $e");
      return;
    }

    final deviceId = ref.read(deviceInfoServiceProvider).deviceId;
    final updated = group.copyWith(
      status: TaskRunStatus.running,
      actualStartTime: now,
      theoreticalEndTime: now.add(Duration(seconds: totalSeconds)),
      scheduledByDeviceId: deviceId,
      updatedAt: now,
    );
    await repo.save(updated);
    await ref.read(notificationServiceProvider).cancelGroupPreAlert(group.id);
    if (!context.mounted) return;
    context.go('/timer/${group.id}');
  }

  Future<TaskGroupPlanningResult?> _showPlanningScreen(
    BuildContext context, {
    required List<TaskRunItem> items,
    required TaskRunIntegrityMode integrityMode,
  }) {
    return context.push<TaskGroupPlanningResult>(
      '/tasks/plan',
      extra: TaskGroupPlanningArgs(
        items: items,
        integrityMode: integrityMode,
        planningAnchor: DateTime.now(),
      ),
    );
  }

  Future<void> _handleRunAgain(
    BuildContext context,
    WidgetRef ref,
    TaskRunGroup source,
  ) async {
    var items = _cloneRunItems(source.tasks);
    final planningResult = await _showPlanningScreen(
      context,
      items: items,
      integrityMode: source.integrityMode,
    );
    if (!context.mounted) return;
    if (planningResult == null) return;

    items = planningResult.items;
    final planOption = planningResult.option;
    final isStartNow = planOption == TaskGroupPlanOption.startNow;
    final isSchedule = !isStartNow;

    final planCapturedAt = DateTime.now();
    DateTime? scheduledStart;
    if (isSchedule) {
      scheduledStart = planningResult.scheduledStart;
      if (scheduledStart == null) {
        _showSnackBar(context, 'Select a start time for scheduling.');
        return;
      }
      if (scheduledStart.isBefore(planCapturedAt)) {
        _showSnackBar(context, 'Scheduled time must be in the future.');
        return;
      }
    }

    final totalDurationSeconds = groupDurationSecondsByMode(
      items,
      source.integrityMode,
    );
    final noticeMinutes = source.noticeMinutes ??
        await ref.read(taskRunNoticeServiceProvider).getNoticeMinutes();
    if (!context.mounted) return;
    final conflictStart = scheduledStart ?? planCapturedAt;
    final conflictEnd = conflictStart.add(
      Duration(seconds: totalDurationSeconds),
    );

    final repo = ref.read(taskRunGroupRepositoryProvider);
    List<TaskRunGroup> existing = const [];
    try {
      existing = await repo.getAll();
      if (!context.mounted) return;
    } catch (e) {
      if (!context.mounted) return;
      _showSnackBar(context, "Failed to check conflicts: $e");
      return;
    }
    final now = DateTime.now();
    final activeSession = ref.read(activePomodoroSessionProvider);
    if (isSchedule && scheduledStart != null && noticeMinutes > 0) {
      final preRunStart = scheduledStart.subtract(
        Duration(minutes: noticeMinutes),
      );
      if (preRunStart.isBefore(now)) {
        _showSnackBar(
          context,
          "That start time is too soon to show the full pre-run countdown. "
          "Choose a later start or reduce the pre-run notice.",
        );
        return;
      }
      final preRunConflict = _findPreRunConflict(
        existing,
        preRunStart: preRunStart,
        scheduledStart: scheduledStart,
        activeSession: activeSession,
        now: now,
      );
      if (preRunConflict != null) {
        final message = preRunConflict == _PreRunConflictType.running
            ? "That time doesn't leave enough pre-run space because another "
                'group is still running. Choose a later start or reduce the '
                'pre-run notice.'
            : "That time doesn't leave enough pre-run space because another "
                'group is scheduled earlier. Choose a later start or reduce '
                'the pre-run notice.';
        _showSnackBar(context, message);
        return;
      }
    }

    final conflicts = _findConflicts(
      existing,
      newStart: conflictStart,
      newEnd: conflictEnd,
      includeRunningAlways: isStartNow,
      activeSession: activeSession,
      now: now,
    );

    try {
      if (conflicts.running.isNotEmpty) {
        final resolved = await _resolveRunningConflict(
          context,
          conflicts.running,
          repo,
        );
        if (!context.mounted) return;
        if (!resolved) return;
      }

      if (conflicts.scheduled.isNotEmpty) {
        final resolved = await _resolveScheduledConflict(
          context,
          conflicts.scheduled,
          repo,
        );
        if (!context.mounted) return;
        if (!resolved) return;
      }
    } catch (e) {
      if (!context.mounted) return;
      _showSnackBar(context, "Failed to resolve conflicts: $e");
      return;
    }

    final auth = ref.read(firebaseAuthServiceProvider);
    final ownerUid = auth.currentUser?.uid ?? 'local';
    final status =
        isStartNow ? TaskRunStatus.running : TaskRunStatus.scheduled;
    final deviceId = ref.read(deviceInfoServiceProvider).deviceId;
    final scheduledByDeviceId = deviceId;
    final recalculatedStart = scheduledStart ?? DateTime.now();
    final recalculatedEnd = recalculatedStart.add(
      Duration(seconds: totalDurationSeconds),
    );

    final newGroup = TaskRunGroup(
      id: const Uuid().v4(),
      ownerUid: ownerUid,
      dataVersion: kCurrentDataVersion,
      integrityMode: source.integrityMode,
      tasks: items,
      createdAt: planCapturedAt,
      scheduledStartTime: scheduledStart,
      scheduledByDeviceId: scheduledByDeviceId,
      actualStartTime: status == TaskRunStatus.running ? recalculatedStart : null,
      theoreticalEndTime: recalculatedEnd,
      status: status,
      noticeMinutes: noticeMinutes,
      totalTasks: items.length,
      totalPomodoros: items.fold<int>(
        0,
        (total, item) => total + item.totalPomodoros,
      ),
      totalDurationSeconds: totalDurationSeconds,
      updatedAt: DateTime.now(),
    );

    try {
      await repo.save(newGroup);
      if (!context.mounted) return;
      if (status == TaskRunStatus.scheduled) {
        await _schedulePreAlertIfNeeded(ref, newGroup);
      } else {
        context.go('/timer/${newGroup.id}');
      }
    } catch (e) {
      if (!context.mounted) return;
      _showSnackBar(context, "Failed to re-plan group: $e");
    }
  }

  Future<void> _schedulePreAlertIfNeeded(
    WidgetRef ref,
    TaskRunGroup group,
  ) async {
    final scheduledStart = group.scheduledStartTime;
    if (scheduledStart == null) return;
    final scheduledBy = group.scheduledByDeviceId;
    if (scheduledBy != null) {
      final deviceId = ref.read(deviceInfoServiceProvider).deviceId;
      if (scheduledBy != deviceId) return;
    }
    final noticeMinutes = resolveNoticeMinutes(
      group,
      fallback: _noticeFallbackMinutes,
    );
    if (noticeMinutes <= 0) return;
    final preAlertStart =
        scheduledStart.subtract(Duration(minutes: noticeMinutes));
    final now = DateTime.now();
    if (!preAlertStart.isAfter(now)) return;
    final name = group.tasks.isNotEmpty ? group.tasks.first.name : 'Task group';
    await ref.read(notificationServiceProvider).scheduleGroupPreAlert(
          groupId: group.id,
          groupName: name,
          scheduledFor: preAlertStart,
          remainingSeconds: noticeMinutes * 60,
        );
  }

  _GroupConflicts _findConflicts(
    List<TaskRunGroup> groups, {
    required DateTime newStart,
    required DateTime newEnd,
    required bool includeRunningAlways,
    required PomodoroSession? activeSession,
    required DateTime now,
    String? excludeGroupId,
  }) {
    final running = <TaskRunGroup>[];
    final scheduled = <TaskRunGroup>[];

    for (final group in groups) {
      if (excludeGroupId != null && group.id == excludeGroupId) continue;
      if (group.status == TaskRunStatus.canceled ||
          group.status == TaskRunStatus.completed) {
        continue;
      }
      if (group.status == TaskRunStatus.running && includeRunningAlways) {
        running.add(group);
        continue;
      }
      final start = group.status == TaskRunStatus.scheduled
          ? (resolveEffectiveScheduledStart(
                group: group,
                allGroups: groups,
                activeSession: activeSession,
                now: now,
                fallbackNoticeMinutes: _noticeFallbackMinutes,
              ) ??
              group.scheduledStartTime ??
              group.createdAt)
          : (group.actualStartTime ??
              group.scheduledStartTime ??
              group.createdAt);
      final end = group.status == TaskRunStatus.scheduled
          ? (resolveEffectiveScheduledEnd(
                group: group,
                allGroups: groups,
                activeSession: activeSession,
                now: now,
                fallbackNoticeMinutes: _noticeFallbackMinutes,
              ) ??
              group.theoreticalEndTime)
          : (group.theoreticalEndTime.isBefore(start)
              ? start
              : group.theoreticalEndTime);
      if (!_overlaps(newStart, newEnd, start, end)) continue;
      if (group.status == TaskRunStatus.running) {
        running.add(group);
        continue;
      }
      if (group.status == TaskRunStatus.scheduled) {
        scheduled.add(group);
      }
    }

    return _GroupConflicts(running: running, scheduled: scheduled);
  }

  _PreRunConflictType? _findPreRunConflict(
    List<TaskRunGroup> groups, {
    required DateTime preRunStart,
    required DateTime scheduledStart,
    required PomodoroSession? activeSession,
    required DateTime now,
  }) {
    for (final group in groups) {
      if (group.status == TaskRunStatus.canceled ||
          group.status == TaskRunStatus.completed) {
        continue;
      }
      final start = group.status == TaskRunStatus.scheduled
          ? (resolveEffectiveScheduledStart(
                group: group,
                allGroups: groups,
                activeSession: activeSession,
                now: now,
                fallbackNoticeMinutes: _noticeFallbackMinutes,
              ) ??
              group.scheduledStartTime ??
              group.createdAt)
          : (group.actualStartTime ??
              group.scheduledStartTime ??
              group.createdAt);
      final end = group.status == TaskRunStatus.scheduled
          ? (resolveEffectiveScheduledEnd(
                group: group,
                allGroups: groups,
                activeSession: activeSession,
                now: now,
                fallbackNoticeMinutes: _noticeFallbackMinutes,
              ) ??
              group.theoreticalEndTime)
          : (group.theoreticalEndTime.isBefore(start)
              ? start
              : group.theoreticalEndTime);
      if (!_overlaps(preRunStart, scheduledStart, start, end)) continue;
      if (group.status == TaskRunStatus.running) {
        return _PreRunConflictType.running;
      }
      if (group.status == TaskRunStatus.scheduled) {
        return _PreRunConflictType.scheduled;
      }
    }
    return null;
  }

  bool _overlaps(
    DateTime aStart,
    DateTime aEnd,
    DateTime bStart,
    DateTime bEnd,
  ) {
    final safeAEnd = aEnd.isBefore(aStart) ? aStart : aEnd;
    final safeBEnd = bEnd.isBefore(bStart) ? bStart : bEnd;
    return aStart.isBefore(safeBEnd) && safeAEnd.isAfter(bStart);
  }

  Future<bool> _resolveRunningConflict(
    BuildContext context,
    List<TaskRunGroup> runningGroups,
    TaskRunGroupRepository repo,
  ) async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conflict with running group'),
        content: const Text(
          'A group is already running. Cancel it to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cancel running group'),
          ),
        ],
      ),
    );
    if (shouldCancel != true) return false;
    final now = DateTime.now();
    for (final group in runningGroups) {
      await repo.save(
        group.copyWith(
          status: TaskRunStatus.canceled,
          canceledReason: TaskRunCanceledReason.user,
          updatedAt: now,
        ),
      );
    }
    return true;
  }

  Future<bool> _resolveScheduledConflict(
    BuildContext context,
    List<TaskRunGroup> scheduledGroups,
    TaskRunGroupRepository repo,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conflict with scheduled group'),
        content: const Text(
          'A group is already scheduled in that time range. Delete it to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete scheduled group'),
          ),
        ],
      ),
    );
    if (shouldDelete != true) return false;
    for (final group in scheduledGroups) {
      await repo.delete(group.id);
    }
    return true;
  }

  List<TaskRunItem> _cloneRunItems(List<TaskRunItem> items) {
    return items
        .map(
          (item) => TaskRunItem(
            sourceTaskId: item.sourceTaskId,
            name: item.name,
            presetId: item.presetId,
            pomodoroMinutes: item.pomodoroMinutes,
            shortBreakMinutes: item.shortBreakMinutes,
            longBreakMinutes: item.longBreakMinutes,
            totalPomodoros: item.totalPomodoros,
            longBreakInterval: item.longBreakInterval,
            startSound: item.startSound,
            startBreakSound: item.startBreakSound,
            finishTaskSound: item.finishTaskSound,
          ),
        )
        .toList();
  }

  void _showSummaryDialog(BuildContext context, TaskRunGroup group) {
    final title = group.tasks.isNotEmpty ? group.tasks.first.name : 'Task group';
    final now = DateTime.now();
    final allGroups = ref.read(taskRunGroupStreamProvider).value ?? const [];
    final activeSession = ref.read(activePomodoroSessionProvider);
    final effectiveScheduledStart = resolveEffectiveScheduledStart(
      group: group,
      allGroups: allGroups,
      activeSession: activeSession,
      now: now,
      fallbackNoticeMinutes: _noticeFallbackMinutes,
    );
    final effectiveScheduledEnd = resolveEffectiveScheduledEnd(
      group: group,
      allGroups: allGroups,
      activeSession: activeSession,
      now: now,
      fallbackNoticeMinutes: _noticeFallbackMinutes,
    );
    final scheduledLabel = _formatGroupDateTime(
      effectiveScheduledStart ?? group.scheduledStartTime,
      now,
    );
    final scheduledStart =
        effectiveScheduledStart ?? group.scheduledStartTime;
    final actualLabel = _formatGroupDateTime(group.actualStartTime, now);
    final endLabel = _formatGroupDateTime(
      effectiveScheduledEnd ?? group.theoreticalEndTime,
      now,
    );
    final totalTasks = group.totalTasks ?? group.tasks.length;
    final totalDuration = _formatDuration(group.totalDurationSeconds ?? 0);
    final totalPomodoros = group.totalPomodoros ??
        group.tasks.fold<int>(0, (total, item) => total + item.totalPomodoros);
    final preRunStart = resolveEffectivePreRunStart(
      group: group,
      allGroups: allGroups,
      activeSession: activeSession,
      now: now,
      fallbackNoticeMinutes: _noticeFallbackMinutes,
    );
    final preRunMinutes =
        (preRunStart != null && scheduledStart != null)
            ? scheduledStart.difference(preRunStart).inMinutes
            : null;
    final showScheduled =
        (effectiveScheduledStart ?? group.scheduledStartTime) != null;
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.white12, width: 1),
        ),
        title: const Text(
          'Group summary',
          style: TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: 360,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                _SummaryStatusChip(status: group.status),
                const SizedBox(height: 16),
                _summarySectionTitle('Timing'),
                if (showScheduled)
                  _summaryRow('Scheduled start', scheduledLabel),
                if (preRunStart != null &&
                    preRunMinutes != null &&
                    preRunMinutes > 0)
                  _summaryRow(
                    'Pre-Run',
                    '$preRunMinutes min starts at ${_formatGroupDateTime(preRunStart, now)}',
                  ),
                _summaryRow('Actual start', actualLabel),
                _summaryRow('End', endLabel),
                _summaryRow('Total time', totalDuration),
                const SizedBox(height: 12),
                _summarySectionTitle('Totals'),
                _summaryRow('Tasks', totalTasks.toString()),
                _summaryRow('Pomodoros', totalPomodoros.toString()),
                const SizedBox(height: 12),
                _summarySectionTitle('Tasks'),
                const SizedBox(height: 8),
                for (final item in group.tasks)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _SummaryTaskCard(item: item),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  bool _isPreRunActive(
    TaskRunGroup group,
    DateTime now, {
    DateTime? scheduledStartOverride,
  }) {
    if (group.status != TaskRunStatus.scheduled) return false;
    final scheduledStart = scheduledStartOverride ??
        resolveEffectiveScheduledStart(
          group: group,
          allGroups: ref.read(taskRunGroupStreamProvider).value ?? const [],
          activeSession: ref.read(activePomodoroSessionProvider),
          now: now,
          fallbackNoticeMinutes: _noticeFallbackMinutes,
        );
    if (scheduledStart == null) return false;
    final preRunStart = resolveEffectivePreRunStart(
      group: group,
      allGroups: ref.read(taskRunGroupStreamProvider).value ?? const [],
      activeSession: ref.read(activePomodoroSessionProvider),
      now: now,
      fallbackNoticeMinutes: _noticeFallbackMinutes,
    );
    if (preRunStart == null) return false;
    return !now.isBefore(preRunStart) && now.isBefore(scheduledStart);
  }

  String _formatDuration(int seconds) {
    if (seconds <= 0) return '0m';
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
    return '${minutes}m';
  }

  void _showSnackBar(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }
}

Widget _summarySectionTitle(String label) {
  return Text(
    label,
    style: const TextStyle(
      color: Colors.white70,
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.4,
    ),
  );
}

Widget _summaryRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _SummaryStatusChip extends StatelessWidget {
  final TaskRunStatus status;

  const _SummaryStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      TaskRunStatus.running => Colors.greenAccent,
      TaskRunStatus.scheduled => Colors.orangeAccent,
      TaskRunStatus.completed => Colors.blueAccent,
      TaskRunStatus.canceled => Colors.redAccent,
    };
    final label = status.name[0].toUpperCase() + status.name.substring(1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SummaryTaskCard extends StatelessWidget {
  final TaskRunItem item;

  const _SummaryTaskCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final title = item.name.isEmpty ? '(Untitled)' : item.name;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _summaryStatCard(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${item.totalPomodoros}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      _summaryMetricCircle(
                        value: '${item.pomodoroMinutes}',
                        size: 26,
                        stroke: 2,
                        color: Colors.redAccent,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _summaryStatCard(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _summaryMetricCircle(
                        value: '${item.shortBreakMinutes}',
                        size: 24,
                        stroke: 1,
                        color: Colors.blueAccent,
                      ),
                      const SizedBox(width: 6),
                      _summaryMetricCircle(
                        value: '${item.longBreakMinutes}',
                        size: 24,
                        stroke: 3,
                        color: Colors.blueAccent,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _summaryStatCard(
                  child: _summaryBreakDots(item.longBreakInterval),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Widget _summaryMetricCircle({
  required String value,
  required double size,
  required double stroke,
  required Color color,
}) {
  return Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: color, width: stroke),
    ),
    child: Padding(
      padding: const EdgeInsets.all(3),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.42,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ),
  );
}

Widget _summaryStatCard({required Widget child}) {
  return Container(
    height: 36,
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Colors.white10,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white12, width: 1),
    ),
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: child,
    ),
  );
}

Widget _summaryBreakDots(int interval) {
  final safeInterval = interval <= 0 ? 1 : interval;
  final redDots = safeInterval > 12 ? 12 : safeInterval;
  final totalDots = redDots + 1;
  return LayoutBuilder(
    builder: (context, constraints) {
      final maxWidth = constraints.maxWidth.isFinite
          ? constraints.maxWidth
          : 90.0;
      const maxHeight = 24.0;
      var dotSize = 5.0;
      var spacing = 3.0;
      const minDot = 3.0;

      while (dotSize >= minDot) {
        final rows = _summaryRowsFor(
          maxHeight,
          dotSize,
          spacing,
          totalDots,
          maxRows: 3,
        );
        final maxCols = _summaryMaxColsFor(maxWidth, dotSize, spacing);
        if (rows * maxCols >= totalDots) break;
        dotSize -= 0.5;
        spacing = dotSize <= 4 ? 2 : 3;
      }

      if (redDots == 1) {
        return SizedBox(
          height: maxHeight,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SummaryDot(color: Colors.redAccent, size: dotSize),
                SizedBox(width: spacing),
                _SummaryDot(color: Colors.blueAccent, size: dotSize),
              ],
            ),
          ),
        );
      }

      final rows = _summaryRowsFor(
        maxHeight,
        dotSize,
        spacing,
        totalDots,
        maxRows: 3,
      );
      final maxCols = _summaryMaxColsFor(maxWidth, dotSize, spacing);
      final redColsNeeded = (redDots / rows).ceil();
      final blueSeparate = redColsNeeded < maxCols;
      final columns = <Widget>[];
      var remainingRed = redDots;
      final redColumnsCount = blueSeparate ? redColsNeeded : maxCols;

      for (var col = 0; col < redColumnsCount; col += 1) {
        final isLast = col == redColumnsCount - 1;
        final capacity = (!blueSeparate && isLast) ? rows - 1 : rows;
        final take = remainingRed > capacity ? capacity : remainingRed;
        remainingRed -= take;
        columns.add(
          _summaryDotColumn(
            redCount: take,
            includeBlue: !blueSeparate && isLast,
            dotSize: dotSize,
            spacing: spacing,
            height: maxHeight,
          ),
        );
      }

      if (blueSeparate) {
        columns.add(
          _summaryDotColumn(
            redCount: 0,
            includeBlue: true,
            dotSize: dotSize,
            spacing: spacing,
            height: maxHeight,
          ),
        );
      }

      return SizedBox(
        height: maxHeight,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: _summaryWithColumnSpacing(columns, spacing + 2),
        ),
      );
    },
  );
}

int _summaryRowsFor(
  double maxHeight,
  double dotSize,
  double spacing,
  int totalDots, {
  int? maxRows,
}) {
  final rows = ((maxHeight + spacing) / (dotSize + spacing)).floor();
  if (rows < 1) return 1;
  final clampedRows = maxRows != null && rows > maxRows ? maxRows : rows;
  return clampedRows > totalDots ? totalDots : clampedRows;
}

int _summaryMaxColsFor(double maxWidth, double dotSize, double spacing) {
  final cols = ((maxWidth + spacing) / (dotSize + spacing)).floor();
  return cols < 1 ? 1 : cols;
}

List<Widget> _summaryWithColumnSpacing(List<Widget> columns, double spacing) {
  final spaced = <Widget>[];
  for (var i = 0; i < columns.length; i += 1) {
    spaced.add(columns[i]);
    if (i < columns.length - 1) {
      spaced.add(SizedBox(width: spacing));
    }
  }
  return spaced;
}

Widget _summaryDotColumn({
  required int redCount,
  required bool includeBlue,
  required double dotSize,
  required double spacing,
  required double height,
}) {
  return SizedBox(
    width: dotSize,
    height: height,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        for (var i = 0; i < redCount; i += 1) ...[
          _SummaryDot(color: Colors.redAccent, size: dotSize),
          if (i < redCount - 1) SizedBox(height: spacing),
        ],
        if (includeBlue) ...[
          if (redCount > 0) SizedBox(height: spacing),
          _SummaryDot(color: Colors.blueAccent, size: dotSize),
        ],
      ],
    ),
  );
}

class _SummaryDot extends StatelessWidget {
  final Color color;
  final double size;

  const _SummaryDot({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.7,
        ),
      ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  final String label;

  const _EmptySection({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white38),
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final TaskRunGroup group;
  final PomodoroSession? activeSession;
  final DateTime? scheduledStartOverride;
  final DateTime? scheduledEndOverride;
  final DateTime? preRunStartOverride;
  final VoidCallback onTap;
  final List<_GroupAction> actions;
  final DateTime now;

  const _GroupCard({
    required this.group,
    required this.activeSession,
    this.scheduledStartOverride,
    this.scheduledEndOverride,
    required this.preRunStartOverride,
    required this.onTap,
    required this.actions,
    required this.now,
  });

  @override
  Widget build(BuildContext context) {
    final name = group.tasks.isNotEmpty ? group.tasks.first.name : 'Task group';
    final totalTasks = group.totalTasks ?? group.tasks.length;
    final totalDuration =
        _formatDuration(group.totalDurationSeconds ?? 0);
    final scheduledStart = scheduledStartOverride ?? group.scheduledStartTime;
    final endTime = scheduledEndOverride ?? group.theoreticalEndTime;
    final showScheduled =
        group.status == TaskRunStatus.scheduled && scheduledStart != null;
    final preRunStart = preRunStartOverride;
    final showPreRun =
        showScheduled &&
        preRunStart != null &&
        preRunStart.isBefore(scheduledStart!);
    final preRunMinutes = showPreRun
        ? scheduledStart!.difference(preRunStart).inMinutes
        : 0;
    final sessionPaused =
        activeSession?.groupId == group.id &&
        activeSession?.status == PomodoroStatus.paused;
    final statusLabel = group.status == TaskRunStatus.running && sessionPaused
        ? 'Paused'
        : group.status.name;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Status: $statusLabel',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            if (group.status == TaskRunStatus.canceled)
              _ReasonRow(
                label: 'Reason',
                value: _canceledReasonLabel(group),
                onTap: () => _showCanceledReasonDialog(context, group),
              ),
            const SizedBox(height: 8),
            if (showScheduled)
              _MetaRow(
                label: 'Scheduled',
                value: _formatGroupDateTime(scheduledStart, now),
              ),
            if (showPreRun && preRunMinutes > 0)
              _MetaRow(
                label: 'Pre-Run',
                value:
                    '$preRunMinutes min starts at ${_formatGroupDateTime(preRunStart, now)}',
              ),
            _MetaRow(
              label: 'Ends',
              value: _formatGroupDateTime(endTime, now),
            ),
            _MetaRow(
              label: 'Tasks',
              value: totalTasks.toString(),
            ),
            _MetaRow(
              label: 'Total time',
              value: totalDuration,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final action in actions) action,
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    if (seconds <= 0) return '0m';
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
    return '${minutes}m';
  }

  String _canceledReasonLabel(TaskRunGroup group) {
    switch (group.canceledReason) {
      case TaskRunCanceledReason.interrupted:
        return 'Interrupted';
      case TaskRunCanceledReason.conflict:
        return 'Conflict';
      case TaskRunCanceledReason.missedSchedule:
        return 'Missed schedule';
      case TaskRunCanceledReason.user:
        return 'Canceled';
      default:
        return 'Canceled';
    }
  }

  String _canceledReasonDescription(TaskRunGroup group) {
    switch (group.canceledReason) {
      case TaskRunCanceledReason.interrupted:
        return 'This group was canceled because a running session was ended '
            'early (for example, choosing "End current group" during a '
            'conflict).';
      case TaskRunCanceledReason.conflict:
        return 'This group was canceled because it would overlap another '
            'group. This can happen during running overlap decisions or when '
            'late-start overdue groups push later groups out of their planned '
            'time.';
      case TaskRunCanceledReason.missedSchedule:
        return 'This group was canceled because its scheduled start time had '
            'already passed when conflicts were resolved.';
      case TaskRunCanceledReason.user:
        return 'This group was canceled manually by you (for example from '
            'Groups Hub or when canceling a running group).';
      default:
        return 'This group was canceled.';
    }
  }

  void _showCanceledReasonDialog(
    BuildContext context,
    TaskRunGroup group,
  ) {
    final description = _canceledReasonDescription(group);
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancellation reason'),
        content: Text(
          '$description\n\nYou can re-plan canceled groups from Groups Hub.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetaRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ReasonRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _ReasonRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Row(
          children: [
            Text(
              '$label: ',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              'Details',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupAction extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool outlined;

  const _GroupAction({
    required this.label,
    required this.onPressed,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    if (outlined) {
      return OutlinedButton(
        onPressed: onPressed,
        child: Text(label),
      );
    }
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(label),
    );
  }
}

enum _PreRunConflictType { running, scheduled }

class _GroupConflicts {
  final List<TaskRunGroup> running;
  final List<TaskRunGroup> scheduled;

  const _GroupConflicts({required this.running, required this.scheduled});
}
