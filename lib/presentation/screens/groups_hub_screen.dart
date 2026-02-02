import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/pomodoro_session.dart';
import '../../data/models/task_run_group.dart';
import '../../data/repositories/task_run_group_repository.dart';
import '../../data/services/task_run_notice_service.dart';
import '../../domain/pomodoro_machine.dart';
import '../providers.dart';

class GroupsHubScreen extends ConsumerWidget {
  const GroupsHubScreen({super.key});

  static const int _completedHistoryLimit = 7;
  static final DateFormat _timeFormat = DateFormat('HH:mm');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(taskRunGroupStreamProvider);
    final activeSession = ref.watch(activePomodoroSessionProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Groups Hub'),
        actions: [
          IconButton(
            tooltip: 'Task List',
            icon: const Icon(Icons.list_alt),
            onPressed: () => context.go('/tasks'),
          ),
        ],
      ),
      body: groupsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text("Error: $e", style: const TextStyle(color: Colors.red)),
        ),
        data: (groups) {
          final now = DateTime.now();
          final runningGroups = groups
              .where((g) => g.status == TaskRunStatus.running)
              .toList()
            ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          final scheduledGroups = groups
              .where((g) => g.status == TaskRunStatus.scheduled)
              .toList()
            ..sort((a, b) {
              final aStart = a.scheduledStartTime ?? a.createdAt;
              final bStart = b.scheduledStartTime ?? b.createdAt;
              return aStart.compareTo(bStart);
            });
          final completedGroups = groups
              .where((g) => g.status == TaskRunStatus.completed)
              .toList()
            ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          final completedSlice = completedGroups
              .take(_completedHistoryLimit)
              .toList(growable: false);

          if (runningGroups.isEmpty &&
              scheduledGroups.isEmpty &&
              completedSlice.isEmpty) {
            return const Center(
              child: Text(
                'No groups yet.',
                style: TextStyle(color: Colors.white54),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              _SectionHeader(title: 'Running / Paused'),
              if (runningGroups.isEmpty)
                const _EmptySection(label: 'No running groups'),
              for (final group in runningGroups)
                _GroupCard(
                  group: group,
                  activeSession: activeSession,
                  onTap: () => _showSummaryDialog(context, group),
                  actions: [
                    _GroupAction(
                      label: 'Open Run Mode',
                      onPressed: () => context.go('/timer/${group.id}'),
                    ),
                  ],
                ),
              const SizedBox(height: 20),
              _SectionHeader(title: 'Scheduled'),
              if (scheduledGroups.isEmpty)
                const _EmptySection(label: 'No scheduled groups'),
              for (final group in scheduledGroups)
                Builder(
                  builder: (context) {
                    final isPreRunActive = _isPreRunActive(group, now);
                    return _GroupCard(
                      group: group,
                      activeSession: activeSession,
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
                ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => context.go('/tasks'),
                icon: const Icon(Icons.library_books),
                label: const Text('Go to Task List'),
              ),
            ],
          );
        },
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
          'This will cancel the schedule and remove it from upcoming groups.',
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
      updatedAt: now,
    );
    await repo.save(updated);
    await ref.read(notificationServiceProvider).cancelGroupPreAlert(group.id);
    if (!context.mounted) return;
    _showSnackBar(context, 'Schedule canceled.');
  }

  Future<void> _handleStartNow(
    BuildContext context,
    WidgetRef ref,
    TaskRunGroup group,
  ) async {
    final repo = ref.read(taskRunGroupRepositoryProvider);
    final now = DateTime.now();
    final totalSeconds =
        group.totalDurationSeconds ?? groupDurationSecondsWithFinalBreaks(group.tasks);
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

    final conflicts = _findConflicts(
      existing,
      newStart: conflictStart,
      newEnd: conflictEnd,
      includeRunningAlways: true,
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

  Future<void> _handleRunAgain(
    BuildContext context,
    WidgetRef ref,
    TaskRunGroup source,
  ) async {
    final planAction = await _showPlanActionDialog(context);
    if (!context.mounted) return;
    if (planAction == null) return;

    final planCapturedAt = DateTime.now();
    DateTime? scheduledStart;
    if (planAction == _PlanAction.schedule) {
      scheduledStart = await _pickScheduleDateTime(
        context,
        initial: planCapturedAt,
      );
      if (!context.mounted) return;
      if (scheduledStart == null) return;
      if (scheduledStart.isBefore(planCapturedAt)) {
        _showSnackBar(context, 'Scheduled time must be in the future.');
        return;
      }
    }

    final items = _cloneRunItems(source.tasks);
    final totalDurationSeconds = groupDurationSecondsWithFinalBreaks(items);
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
    if (planAction == _PlanAction.schedule &&
        scheduledStart != null &&
        noticeMinutes > 0) {
      final preRunStart = scheduledStart.subtract(
        Duration(minutes: noticeMinutes),
      );
      final now = DateTime.now();
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
      includeRunningAlways: planAction == _PlanAction.startNow,
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
    final status = planAction == _PlanAction.startNow
        ? TaskRunStatus.running
        : TaskRunStatus.scheduled;
    final deviceId = ref.read(deviceInfoServiceProvider).deviceId;
    final scheduledByDeviceId =
        status == TaskRunStatus.scheduled ? deviceId : null;
    final recalculatedStart = scheduledStart ?? DateTime.now();
    final recalculatedEnd = recalculatedStart.add(
      Duration(seconds: totalDurationSeconds),
    );

    final newGroup = TaskRunGroup(
      id: const Uuid().v4(),
      ownerUid: ownerUid,
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
      _showSnackBar(context, "Failed to run group again: $e");
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
    final noticeMinutes = group.noticeMinutes ?? 0;
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

  Future<_PlanAction?> _showPlanActionDialog(BuildContext context) {
    return showDialog<_PlanAction>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Plan start'),
        content: const Text(
          'Choose whether to start now or schedule the group.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(_PlanAction.schedule),
            child: const Text('Schedule start'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(_PlanAction.startNow),
            child: const Text('Start now'),
          ),
        ],
      ),
    );
  }

  Future<DateTime?> _pickScheduleDateTime(
    BuildContext context, {
    required DateTime initial,
  }) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (pickedDate == null) return null;
    if (!context.mounted) return null;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (pickedTime == null) return null;
    return DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
  }

  _GroupConflicts _findConflicts(
    List<TaskRunGroup> groups, {
    required DateTime newStart,
    required DateTime newEnd,
    required bool includeRunningAlways,
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
      final start =
          group.actualStartTime ?? group.scheduledStartTime ?? group.createdAt;
      final end = group.theoreticalEndTime.isBefore(start)
          ? start
          : group.theoreticalEndTime;
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
  }) {
    for (final group in groups) {
      if (group.status == TaskRunStatus.canceled ||
          group.status == TaskRunStatus.completed) {
        continue;
      }
      final start =
          group.actualStartTime ?? group.scheduledStartTime ?? group.createdAt;
      final end = group.theoreticalEndTime.isBefore(start)
          ? start
          : group.theoreticalEndTime;
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
        group.copyWith(status: TaskRunStatus.canceled, updatedAt: now),
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
    final startLabel = _formatStartLabel(group);
    final endLabel = _formatTime(group.theoreticalEndTime);
    final totalTasks = group.totalTasks ?? group.tasks.length;
    final totalDuration =
        _formatDuration(group.totalDurationSeconds ?? 0);
    final notice = group.noticeMinutes;
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(
          'Status: ${group.status.name}\n'
          'Start: $startLabel\n'
          'End: $endLabel\n'
          'Tasks: $totalTasks\n'
          'Total time: $totalDuration\n'
          'Notice: ${notice ?? 0} min',
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

  String _formatStartLabel(TaskRunGroup group) {
    final scheduled = group.scheduledStartTime;
    if (group.status == TaskRunStatus.scheduled && scheduled != null) {
      return _formatTime(scheduled);
    }
    final actual = group.actualStartTime;
    if (actual != null) return _formatTime(actual);
    return _formatTime(group.createdAt);
  }

  bool _isPreRunActive(TaskRunGroup group, DateTime now) {
    if (group.status != TaskRunStatus.scheduled) return false;
    final scheduledStart = group.scheduledStartTime;
    if (scheduledStart == null) return false;
    final noticeMinutes =
        group.noticeMinutes ?? TaskRunNoticeService.defaultNoticeMinutes;
    if (noticeMinutes <= 0) return false;
    final preRunStart = scheduledStart.subtract(
      Duration(minutes: noticeMinutes),
    );
    return !now.isBefore(preRunStart) && now.isBefore(scheduledStart);
  }

  String _formatTime(DateTime? value) {
    if (value == null) return '--:--';
    return _timeFormat.format(value);
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
  final VoidCallback onTap;
  final List<_GroupAction> actions;

  const _GroupCard({
    required this.group,
    required this.activeSession,
    required this.onTap,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final name = group.tasks.isNotEmpty ? group.tasks.first.name : 'Task group';
    final totalTasks = group.totalTasks ?? group.tasks.length;
    final totalDuration =
        _formatDuration(group.totalDurationSeconds ?? 0);
    final scheduledStart = group.scheduledStartTime;
    final endTime = group.theoreticalEndTime;
    final notice =
        group.noticeMinutes ?? TaskRunNoticeService.defaultNoticeMinutes;
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
            const SizedBox(height: 8),
            _MetaRow(
              label: 'Scheduled',
              value: _formatTime(scheduledStart),
            ),
            _MetaRow(
              label: 'Ends',
              value: _formatTime(endTime),
            ),
            _MetaRow(
              label: 'Tasks',
              value: totalTasks.toString(),
            ),
            _MetaRow(
              label: 'Total time',
              value: totalDuration,
            ),
            _MetaRow(
              label: 'Notice',
              value: '$notice min',
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

  String _formatTime(DateTime? value) {
    if (value == null) return '--:--';
    return GroupsHubScreen._timeFormat.format(value);
  }

  String _formatDuration(int seconds) {
    if (seconds <= 0) return '0m';
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
    return '${minutes}m';
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

enum _PlanAction { startNow, schedule }

enum _PreRunConflictType { running, scheduled }

class _GroupConflicts {
  final List<TaskRunGroup> running;
  final List<TaskRunGroup> scheduled;

  const _GroupConflicts({required this.running, required this.scheduled});
}
