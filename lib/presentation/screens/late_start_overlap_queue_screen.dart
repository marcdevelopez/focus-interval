import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../data/models/pomodoro_task.dart';
import '../../data/models/schema_version.dart';
import '../../data/models/task_run_group.dart';
import '../../data/services/task_run_notice_service.dart';
import '../../widgets/task_card.dart';
import '../providers.dart';

class LateStartOverlapArgs {
  final List<String> groupIds;
  final DateTime anchor;

  const LateStartOverlapArgs({
    required this.groupIds,
    required this.anchor,
  });
}

class LateStartOverlapQueueScreen extends ConsumerStatefulWidget {
  final LateStartOverlapArgs args;

  const LateStartOverlapQueueScreen({super.key, required this.args});

  @override
  ConsumerState<LateStartOverlapQueueScreen> createState() =>
      _LateStartOverlapQueueScreenState();
}

class _LateStartOverlapQueueScreenState
    extends ConsumerState<LateStartOverlapQueueScreen> {
  static const int _maxVisibleGroups = 5;
  static const Duration _warningThreshold = Duration(hours: 8);
  static final DateFormat _timeFormat = DateFormat('HH:mm');

  late DateTime _anchor;
  bool _showPreview = false;
  bool _showAll = false;
  bool _busy = false;
  List<String> _selectedIds = [];

  @override
  void initState() {
    super.initState();
    _anchor = widget.args.anchor;
    _selectedIds = List<String>.from(widget.args.groupIds);
  }

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(taskRunGroupStreamProvider);
    if (groupsAsync.isLoading && groupsAsync.value == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (groupsAsync.hasError) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'Unable to load scheduled groups.',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    final groups = groupsAsync.value ?? const [];
    final conflictGroups = groups
        .where((group) => widget.args.groupIds.contains(group.id))
        .toList()
      ..sort(
        (a, b) => a.scheduledStartTime!.compareTo(b.scheduledStartTime!),
      );

    if (conflictGroups.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
      return const SizedBox.shrink();
    }

    final availableIds = conflictGroups.map((group) => group.id).toSet();
    _syncSelection(availableIds);

    final selectedSet = _selectedIds.toSet();
    final groupsById = {
      for (final group in conflictGroups) group.id: group,
    };
    final selectedGroups = _selectedIds
        .where(groupsById.containsKey)
        .map((id) => groupsById[id]!)
        .toList();
    final unselectedGroups =
        conflictGroups.where((g) => !selectedSet.contains(g.id)).toList();
    final projectedRanges = _buildProjectedRanges(selectedGroups, _anchor);
    final totalSeconds = _totalQueueSeconds(selectedGroups);
    final totalDuration = Duration(seconds: totalSeconds);
    final totalLabel = _formatDuration(totalDuration);
    final showWarning = totalDuration > _warningThreshold;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(_showPreview ? 'Confirm queue' : 'Resolve overlaps'),
      ),
      body: Stack(
        children: [
          _showPreview
              ? _buildPreview(
                  context,
                  selectedGroups: selectedGroups,
                  projectedRanges: projectedRanges,
                )
              : _buildSelection(
                  context,
                  selectedGroups: selectedGroups,
                  unselectedGroups: unselectedGroups,
                  projectedRanges: projectedRanges,
                  totalLabel: totalLabel,
                  showWarning: showWarning,
                ),
          if (_busy)
            const Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: LinearProgressIndicator(minHeight: 2),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          children: _showPreview
              ? [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() {
                                _showPreview = false;
                              }),
                      child: const Text('Back'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _busy
                          ? null
                          : () => _applySelection(
                                conflictGroups: conflictGroups,
                                selectedGroups: selectedGroups,
                              ),
                      child: const Text('Confirm'),
                    ),
                  ),
                ]
              : [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _busy ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _busy
                          ? null
                          : () =>
                              _handleContinue(conflictGroups, selectedGroups),
                      child: const Text('Continue'),
                    ),
                  ),
                ],
        ),
      ),
    );
  }

  Widget _buildSelection(
    BuildContext context, {
    required List<TaskRunGroup> selectedGroups,
    required List<TaskRunGroup> unselectedGroups,
    required Map<String, _ProjectedRange> projectedRanges,
    required String totalLabel,
    required bool showWarning,
  }) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        const Text(
          'One or more scheduled groups overlap because the start time passed.',
          style: TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 12),
        _summaryRow('Total time (with pre-run)', totalLabel),
        if (showWarning) ...[
          const SizedBox(height: 6),
          const Text(
            'Warning: total exceeds 8 hours.',
            style: TextStyle(color: Colors.orangeAccent, fontSize: 12),
          ),
        ],
        const SizedBox(height: 16),
        _sectionHeader('Selected groups'),
        if (selectedGroups.isEmpty) ...[
          const SizedBox(height: 6),
          const Text(
            'No groups selected. Continue will cancel all listed groups.',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
        const SizedBox(height: 8),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          itemCount: selectedGroups.length,
          onReorder: _reorderSelected,
          itemBuilder: (context, index) {
            final group = selectedGroups[index];
            return _ConflictGroupCard(
              key: ValueKey(group.id),
              group: group,
              selected: true,
              projectedRange: projectedRanges[group.id]?.label,
              onToggle: () => _toggleSelection(group.id),
              trailing: ReorderableDragStartListener(
                index: index,
                child: const Icon(Icons.drag_handle, color: Colors.white38),
              ),
            );
          },
        ),
        if (unselectedGroups.isNotEmpty) ...[
          const SizedBox(height: 16),
          _sectionHeader('Other groups'),
          const SizedBox(height: 8),
          for (final group in _visibleUnselected(unselectedGroups))
            _ConflictGroupCard(
              key: ValueKey(group.id),
              group: group,
              selected: false,
              projectedRange: null,
              onToggle: () => _toggleSelection(group.id),
            ),
          if (unselectedGroups.length > _maxVisibleGroups)
            TextButton(
              onPressed: () => setState(() {
                _showAll = !_showAll;
              }),
              child: Text(_showAll ? 'Show less' : 'Show more'),
            ),
        ],
      ],
    );
  }

  Widget _buildPreview(
    BuildContext context, {
    required List<TaskRunGroup> selectedGroups,
    required Map<String, _ProjectedRange> projectedRanges,
  }) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        const Text(
          'Review the queue before applying changes.',
          style: TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 16),
        for (final group in selectedGroups) ...[
          _previewHeader(
            group: group,
            projectedRange: projectedRanges[group.id]?.label,
          ),
          const SizedBox(height: 8),
          for (final entry in _previewTasksWithRanges(group, projectedRanges))
            TaskCard(
              task: entry.task,
              selected: true,
              enableInteraction: false,
              onTap: () {},
              onEdit: () {},
              onDelete: () {},
              timeRange: entry.range,
              weightPercent: entry.weightPercent,
            ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
      ],
    );
  }

  Widget _sectionHeader(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _previewHeader({
    required TaskRunGroup group,
    required String? projectedRange,
  }) {
    final name = _groupLabel(group);
    final range = projectedRange ?? _scheduledRange(group);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            range,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _syncSelection(Set<String> availableIds) {
    final next = _selectedIds.where(availableIds.contains).toList();
    if (_listEquals(next, _selectedIds)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _selectedIds = next;
      });
    });
  }

  void _reorderSelected(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    setState(() {
      final id = _selectedIds.removeAt(oldIndex);
      _selectedIds.insert(newIndex, id);
    });
  }

  void _toggleSelection(String groupId) {
    setState(() {
      if (_selectedIds.contains(groupId)) {
        _selectedIds.remove(groupId);
      } else {
        _selectedIds.add(groupId);
      }
    });
  }

  List<TaskRunGroup> _visibleUnselected(List<TaskRunGroup> groups) {
    if (_showAll || groups.length <= _maxVisibleGroups) return groups;
    return groups.take(_maxVisibleGroups).toList();
  }

  Future<void> _handleContinue(
    List<TaskRunGroup> conflictGroups,
    List<TaskRunGroup> selectedGroups,
  ) async {
    if (selectedGroups.isNotEmpty) {
      setState(() {
        _showPreview = true;
      });
      return;
    }

    final shouldCancelAll = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel all groups?'),
        content: const Text(
          'No groups are selected. Continue will cancel all listed groups.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cancel all'),
          ),
        ],
      ),
    );
    if (shouldCancelAll != true) return;
    await _applySelection(
      conflictGroups: conflictGroups,
      selectedGroups: const [],
    );
  }

  Future<void> _applySelection({
    required List<TaskRunGroup> conflictGroups,
    required List<TaskRunGroup> selectedGroups,
  }) async {
    if (_busy) return;
    setState(() {
      _busy = true;
    });
    try {
      final repo = ref.read(taskRunGroupRepositoryProvider);
      final deviceId = ref.read(deviceInfoServiceProvider).deviceId;
      final notifier = ref.read(notificationServiceProvider);
      final now = DateTime.now();

      final updates = <TaskRunGroup>[];
      if (selectedGroups.isNotEmpty) {
        var cursor = now;
        for (var index = 0; index < selectedGroups.length; index += 1) {
          final group = selectedGroups[index];
          final durationSeconds = _groupDurationSeconds(group);
          if (index == 0) {
            updates.add(
              group.copyWith(
                status: TaskRunStatus.running,
                actualStartTime: now,
                theoreticalEndTime:
                    now.add(Duration(seconds: durationSeconds)),
                scheduledByDeviceId: deviceId,
                noticeSentAt: null,
                noticeSentByDeviceId: null,
                updatedAt: now,
              ),
            );
            cursor = now.add(Duration(seconds: durationSeconds));
          } else {
            final noticeMinutes = _noticeMinutesOrDefault(group);
            final scheduledStart =
                cursor.add(Duration(minutes: noticeMinutes));
            updates.add(
              group.copyWith(
                status: TaskRunStatus.scheduled,
                scheduledStartTime: scheduledStart,
                scheduledByDeviceId: deviceId,
                actualStartTime: null,
                theoreticalEndTime:
                    scheduledStart.add(Duration(seconds: durationSeconds)),
                noticeSentAt: null,
                noticeSentByDeviceId: null,
                updatedAt: now,
              ),
            );
            cursor = scheduledStart.add(Duration(seconds: durationSeconds));
          }
        }
      }

      final selectedIds = selectedGroups.map((g) => g.id).toSet();
      for (final group in conflictGroups) {
        if (selectedIds.contains(group.id)) continue;
        final scheduledStart = group.scheduledStartTime;
        final isMissed =
            scheduledStart != null && !scheduledStart.isAfter(now);
        updates.add(
          group.copyWith(
            status: TaskRunStatus.canceled,
            canceledReason: isMissed
                ? TaskRunCanceledReason.missedSchedule
                : TaskRunCanceledReason.conflict,
            updatedAt: now,
          ),
        );
      }

      await repo.saveAll(updates);
      for (final group in updates) {
        await notifier.cancelGroupPreAlert(group.id);
      }

      if (!mounted) return;
      if (selectedGroups.isNotEmpty) {
        context.go('/timer/${selectedGroups.first.id}');
      } else {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Update failed'),
          content: Text('Unable to apply changes. Please retry.\n$e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Map<String, _ProjectedRange> _buildProjectedRanges(
    List<TaskRunGroup> groups,
    DateTime anchor,
  ) {
    final ranges = <String, _ProjectedRange>{};
    var cursor = anchor;
    for (var index = 0; index < groups.length; index += 1) {
      if (index > 0) {
        final notice = _noticeMinutesOrDefault(groups[index]);
        cursor = cursor.add(Duration(minutes: notice));
      }
      final durationSeconds = _groupDurationSeconds(groups[index]);
      final end = cursor.add(Duration(seconds: durationSeconds));
      ranges[groups[index].id] = _ProjectedRange(start: cursor, end: end);
      cursor = end;
    }
    return ranges;
  }

  int _totalQueueSeconds(List<TaskRunGroup> groups) {
    var total = 0;
    for (var index = 0; index < groups.length; index += 1) {
      total += _groupDurationSeconds(groups[index]);
      if (index > 0) {
        total += _noticeMinutesOrDefault(groups[index]) * 60;
      }
    }
    return total;
  }

  int _groupDurationSeconds(TaskRunGroup group) {
    return group.totalDurationSeconds ??
        groupDurationSecondsByMode(group.tasks, group.integrityMode);
  }

  int _noticeMinutesOrDefault(TaskRunGroup group) {
    return group.noticeMinutes ?? TaskRunNoticeService.defaultNoticeMinutes;
  }

  String _formatRange(DateTime start, DateTime end) {
    return '${_timeFormat.format(start)}-${_timeFormat.format(end)}';
  }

  String _scheduledRange(TaskRunGroup group) {
    final start = group.scheduledStartTime;
    if (start == null) return '--:--';
    final end = group.theoreticalEndTime;
    return _formatRange(start, end);
  }

  String _formatDuration(Duration value) {
    final totalMinutes = value.inMinutes;
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours > 0 && minutes > 0) {
      return '${hours}h ${minutes}m';
    }
    if (hours > 0) return '${hours}h';
    return '${minutes}m';
  }

  String _groupLabel(TaskRunGroup group) {
    if (group.tasks.isNotEmpty) {
      final name = group.tasks.first.name;
      if (name.isNotEmpty) return name;
    }
    return 'Task group';
  }

  List<_PreviewEntry> _previewTasksWithRanges(
    TaskRunGroup group,
    Map<String, _ProjectedRange> projectedRanges,
  ) {
    final projected = projectedRanges[group.id];
    final start = projected?.start;
    final durations = taskDurationSecondsByMode(
      group.tasks,
      group.integrityMode,
    );
    final ranges = <int, String>{};
    if (start != null) {
      var cursor = start;
      for (var index = 0; index < durations.length; index += 1) {
        final end = cursor.add(Duration(seconds: durations[index]));
        ranges[index] = _formatRange(cursor, end);
        cursor = end;
      }
    }
    final totalWeight = _weightTotal(group.tasks);
    return [
      for (var index = 0; index < group.tasks.length; index += 1)
        _PreviewEntry(
          task: _buildPreviewTask(group.tasks[index], index),
          range: ranges[index],
          weightPercent:
              _weightPercent(group.tasks[index], weightTotal: totalWeight),
        ),
    ];
  }

  PomodoroTask _buildPreviewTask(TaskRunItem item, int order) {
    final now = DateTime.now();
    return PomodoroTask(
      id: item.sourceTaskId,
      name: item.name,
      dataVersion: kCurrentDataVersion,
      pomodoroMinutes: item.pomodoroMinutes,
      shortBreakMinutes: item.shortBreakMinutes,
      longBreakMinutes: item.longBreakMinutes,
      totalPomodoros: item.totalPomodoros,
      longBreakInterval: item.longBreakInterval,
      order: order,
      presetId: item.presetId,
      startSound: item.startSound,
      startBreakSound: item.startBreakSound,
      finishTaskSound: item.finishTaskSound,
      createdAt: now,
      updatedAt: now,
    );
  }

  int? _weightTotal(List<TaskRunItem> items) {
    if (items.isEmpty) return null;
    var total = 0;
    for (final item in items) {
      total += item.totalPomodoros * item.pomodoroMinutes;
    }
    return total <= 0 ? null : total;
  }

  int? _weightPercent(TaskRunItem item, {required int? weightTotal}) {
    if (weightTotal == null || weightTotal <= 0) return null;
    final work = item.totalPomodoros * item.pomodoroMinutes;
    return ((work / weightTotal) * 100).round();
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i += 1) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

class _PreviewEntry {
  final PomodoroTask task;
  final String? range;
  final int? weightPercent;

  const _PreviewEntry({
    required this.task,
    required this.range,
    required this.weightPercent,
  });
}

class _ProjectedRange {
  final DateTime start;
  final DateTime end;

  const _ProjectedRange({required this.start, required this.end});

  String get label =>
      '${DateFormat('HH:mm').format(start)}-${DateFormat('HH:mm').format(end)}';
}

class _ConflictGroupCard extends StatelessWidget {
  final TaskRunGroup group;
  final bool selected;
  final String? projectedRange;
  final VoidCallback onToggle;
  final Widget? trailing;

  const _ConflictGroupCard({
    super.key,
    required this.group,
    required this.selected,
    required this.projectedRange,
    required this.onToggle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final title = group.tasks.isNotEmpty && group.tasks.first.name.isNotEmpty
        ? group.tasks.first.name
        : 'Task group';
    final scheduledStart = group.scheduledStartTime;
    final scheduledEnd = group.theoreticalEndTime;
    final scheduledLabel = scheduledStart == null
        ? '--:--'
        : '${DateFormat('HH:mm').format(scheduledStart)}-'
            '${DateFormat('HH:mm').format(scheduledEnd)}';
    final projectedLabel = projectedRange;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: selected ? Colors.white12 : Colors.white10,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? Colors.white38 : Colors.white24,
        ),
      ),
      child: Row(
        children: [
          Checkbox(
            value: selected,
            onChanged: (_) => onToggle(),
          ),
          const SizedBox(width: 6),
          Expanded(
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
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Scheduled: $scheduledLabel',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                if (projectedLabel != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Projected: $projectedLabel',
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
