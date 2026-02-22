import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/pomodoro_task.dart';
import '../../data/models/pomodoro_session.dart';
import '../../data/models/schema_version.dart';
import '../../data/models/task_run_group.dart';
import '../../data/services/task_run_notice_service.dart';
import '../../data/services/app_mode_service.dart';
import '../../domain/pomodoro_machine.dart';
import '../../widgets/task_card.dart';
import '../providers.dart';
import '../viewmodels/pre_run_notice_view_model.dart';
import '../utils/scheduled_group_timing.dart';

final DateFormat _lateStartTimeFormat = DateFormat('HH:mm');
final DateFormat _lateStartDateFormat = DateFormat('MMM d');

String _formatLateStartRange(DateTime start, DateTime end) {
  final range =
      '${_lateStartTimeFormat.format(start)}-${_lateStartTimeFormat.format(end)}';
  final now = DateTime.now();
  final isToday =
      start.year == now.year && start.month == now.month && start.day == now.day;
  if (isToday) return range;
  return '${_lateStartDateFormat.format(start)}, $range';
}

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
  static const Duration _ownerStaleThreshold = Duration(seconds: 45);

  late DateTime _anchor;
  late DateTime _anchorCapturedAt;
  DateTime _now = DateTime.now();
  Timer? _tickTimer;
  bool _claimInFlight = false;
  bool _requestInFlight = false;
  bool _showPreview = false;
  bool _showAll = false;
  bool _busy = false;
  List<String> _selectedIds = [];
  List<String> _latestConflictIds = const [];
  int? _noticeFallbackMinutes;

  @override
  void initState() {
    super.initState();
    _anchor = widget.args.anchor;
    _anchorCapturedAt = DateTime.now();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _now = DateTime.now();
      });
    });
    _selectedIds = List<String>.from(widget.args.groupIds);
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
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
    _latestConflictIds = conflictGroups.map((g) => g.id).toList();

    if (conflictGroups.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
      return const SizedBox.shrink();
    }

    final appMode = ref.watch(appModeProvider);
    final deviceId = ref.watch(deviceInfoServiceProvider).deviceId;
    final noticeFallback =
        ref
            .watch(preRunNoticeMinutesProvider)
            .maybeWhen(data: (value) => value, orElse: () => null) ??
        TaskRunNoticeService.defaultNoticeMinutes;
    _noticeFallbackMinutes = noticeFallback;
    final ownerDeviceId = resolveLateStartOwnerDeviceId(conflictGroups);
    final ownerHeartbeat = resolveLateStartOwnerHeartbeat(conflictGroups);
    final anchorFromGroups = resolveLateStartAnchor(conflictGroups);
    final requestId = resolveLateStartClaimRequestId(conflictGroups);
    final requesterDeviceId =
        resolveLateStartClaimRequesterDeviceId(conflictGroups);
    final hasPendingRequest =
        requestId != null && requesterDeviceId != null;
    final isPendingForSelf =
        hasPendingRequest && requesterDeviceId == deviceId;
    final timebase = anchorFromGroups;
    if (timebase != null && timebase != _anchor) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _anchor = timebase;
          _anchorCapturedAt = DateTime.now();
        });
      });
    }
    final ownerStale = _isOwnerStale(
      ownerDeviceId: ownerDeviceId,
      ownerHeartbeat: ownerHeartbeat,
      anchor: anchorFromGroups,
      now: _now,
    );
    final isOwner =
        appMode != AppMode.account ||
        ownerDeviceId == null ||
        ownerDeviceId == deviceId;
    final shouldAutoClaim =
        !isOwner && ownerStale && (!hasPendingRequest || isPendingForSelf);
    if (shouldAutoClaim) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _maybeAutoClaimOwnership(conflictGroups, deviceId);
      });
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
    final queueNow = _queueNow(_now);
    final projectedRanges = _buildProjectedRanges(selectedGroups, queueNow);
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
                  isOwner: isOwner,
                  ownerDeviceId: ownerDeviceId,
                  ownerStale: ownerStale,
                  hasPendingRequest: hasPendingRequest,
                  requesterDeviceId: requesterDeviceId,
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
                      onPressed: (_busy || !isOwner)
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
                      onPressed: (_busy || !isOwner)
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
                      onPressed: (_busy || !isOwner)
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: (_busy || !isOwner)
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
    required bool isOwner,
    required String? ownerDeviceId,
    required bool ownerStale,
    required bool hasPendingRequest,
    required String? requesterDeviceId,
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
        const SizedBox(height: 8),
        if (ownerDeviceId != null)
          _ownerRow(ownerDeviceId),
        if (!isOwner) ...[
          const SizedBox(height: 8),
          _mirrorOwnershipPrompt(
            ownerStale: ownerStale,
            hasPendingRequest: hasPendingRequest,
            requesterDeviceId: requesterDeviceId,
          ),
        ],
        if (isOwner && hasPendingRequest && requesterDeviceId != null) ...[
          const SizedBox(height: 8),
          _ownerRequestBanner(requesterDeviceId),
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
          onReorder: isOwner ? _reorderSelected : (_, __) {},
          itemBuilder: (context, index) {
            final group = selectedGroups[index];
            return _ConflictGroupCard(
              key: ValueKey(group.id),
              group: group,
              selected: true,
              projectedRange: projectedRanges[group.id]?.label,
              onToggle: isOwner ? () => _toggleSelection(group.id) : null,
              trailing: isOwner
                  ? ReorderableDragStartListener(
                      index: index,
                      child: const Icon(
                        Icons.drag_handle,
                        color: Colors.white38,
                      ),
                    )
                  : null,
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
              onToggle: isOwner ? () => _toggleSelection(group.id) : null,
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
      final queueNow = _queueNow(now);

      final updates = <TaskRunGroup>[];
      if (selectedGroups.isNotEmpty) {
        var cursor = queueNow;
        for (var index = 0; index < selectedGroups.length; index += 1) {
          final group = selectedGroups[index];
          final durationSeconds = _groupDurationSeconds(group);
          if (index == 0) {
            updates.add(
              group.copyWith(
                status: TaskRunStatus.running,
                scheduledStartTime: queueNow,
                actualStartTime: queueNow,
                theoreticalEndTime:
                    queueNow.add(Duration(seconds: durationSeconds)),
                scheduledByDeviceId: deviceId,
                noticeSentAt: null,
                noticeSentByDeviceId: null,
                lateStartQueueOrder: index,
                lateStartAnchorAt: null,
                lateStartOwnerDeviceId: null,
                lateStartOwnerHeartbeatAt: null,
                lateStartClaimRequestId: null,
                lateStartClaimRequestedByDeviceId: null,
                lateStartClaimRequestedAt: null,
                updatedAt: now,
              ),
            );
            cursor = queueNow.add(Duration(seconds: durationSeconds));
          } else {
            final noticeMinutes = _noticeMinutesOrDefault(group);
            final scheduledStart = ceilToMinute(
              cursor.add(Duration(minutes: noticeMinutes)),
            );
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
                lateStartQueueOrder: index,
                lateStartAnchorAt: null,
                lateStartOwnerDeviceId: null,
                lateStartOwnerHeartbeatAt: null,
                lateStartClaimRequestId: null,
                lateStartClaimRequestedByDeviceId: null,
                lateStartClaimRequestedAt: null,
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
            scheduledStart != null && !scheduledStart.isAfter(queueNow);
        updates.add(
          group.copyWith(
            status: TaskRunStatus.canceled,
            canceledReason: isMissed
                ? TaskRunCanceledReason.missedSchedule
                : TaskRunCanceledReason.conflict,
            lateStartQueueId: null,
            lateStartQueueOrder: null,
            lateStartAnchorAt: null,
            lateStartOwnerDeviceId: null,
            lateStartOwnerHeartbeatAt: null,
            lateStartClaimRequestId: null,
            lateStartClaimRequestedByDeviceId: null,
            lateStartClaimRequestedAt: null,
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
        final target = selectedGroups.first;
        await _publishInitialSession(target, queueNow: queueNow);
        ref.read(scheduledAutoStartGroupIdProvider.notifier).state =
            target.id;
        Future.delayed(const Duration(milliseconds: 350), () {
          if (!mounted) return;
          final uri = GoRouter.of(context)
              .routerDelegate
              .currentConfiguration
              .uri;
          if (uri.path.startsWith('/timer/')) return;
          context.go('/timer/${target.id}');
        });
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
    return group.noticeMinutes ??
        _noticeFallbackMinutes ??
        TaskRunNoticeService.defaultNoticeMinutes;
  }

  bool _isOwnerStale({
    required String? ownerDeviceId,
    required DateTime? ownerHeartbeat,
    required DateTime? anchor,
    required DateTime now,
  }) {
    if (ownerDeviceId == null || ownerDeviceId.isEmpty) return false;
    final lastSeen = ownerHeartbeat ?? anchor;
    if (lastSeen == null) return false;
    return now.difference(lastSeen) >= _ownerStaleThreshold;
  }

  DateTime _queueNow(DateTime now) {
    return _anchor.add(now.difference(_anchorCapturedAt));
  }

  Widget _ownerRow(String ownerDeviceId) {
    return Row(
      children: [
        const Text(
          'Owner:',
          style: TextStyle(color: Colors.white54, fontSize: 12),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            ownerDeviceId,
            style: const TextStyle(color: Colors.white, fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _mirrorOwnershipPrompt({
    required bool ownerStale,
    required bool hasPendingRequest,
    required String? requesterDeviceId,
  }) {
    final label = ownerStale ? 'Claim ownership' : 'Request ownership';
    final message = ownerStale
        ? 'Owner seems unavailable. Claim ownership to resolve this conflict.'
        : 'Owner is resolving this conflict. Request ownership if needed.';
    final isPending = hasPendingRequest &&
        requesterDeviceId == ref.read(deviceInfoServiceProvider).deviceId;
    final isBlocked = hasPendingRequest && !isPending;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          if (isPending) ...[
            const SizedBox(height: 6),
            const Text(
              'Request sent. Waiting for owner approval.',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton(
              onPressed: (_claimInFlight || _requestInFlight || isBlocked)
                  ? null
                  : () {
                      if (ownerStale) {
                        _maybeAutoClaimOwnership(
                          null,
                          ref.read(deviceInfoServiceProvider).deviceId,
                        );
                      } else {
                        _requestOwnership();
                      }
                    },
              child: Text(label),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ownerRequestBanner(String requesterDeviceId) {
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
            'Ownership request from $requesterDeviceId.',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _requestInFlight
                      ? null
                      : () => _respondOwnershipRequest(approved: false),
                  child: const Text('Reject'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _requestInFlight
                      ? null
                      : () => _respondOwnershipRequest(approved: true),
                  child: const Text('Approve'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<TaskRunGroup> _resolveConflictGroups() {
    final groups =
        ref.read(taskRunGroupStreamProvider).value ?? const [];
    if (_latestConflictIds.isEmpty) return const [];
    return groups
        .where((group) => _latestConflictIds.contains(group.id))
        .toList();
  }

  void _maybeAutoClaimOwnership(
    List<TaskRunGroup>? conflictGroups,
    String deviceId,
  ) {
    if (_claimInFlight) return;
    final groups = conflictGroups != null && conflictGroups.isNotEmpty
        ? conflictGroups
        : _resolveConflictGroups();
    if (groups.isEmpty) return;
    setState(() {
      _claimInFlight = true;
    });
    ref
        .read(taskRunGroupRepositoryProvider)
        .claimLateStartQueue(
          groups: groups,
          ownerDeviceId: deviceId,
          queueId: resolveLateStartQueueId(groups) ??
              const Uuid().v4(),
          orderedIds: groups.map((g) => g.id).toList(),
          allowOverride: true,
        )
        .whenComplete(() {
          if (!mounted) return;
          setState(() {
            _claimInFlight = false;
          });
        });
  }

  Future<void> _requestOwnership() async {
    if (_requestInFlight) return;
    final groups =
        ref.read(taskRunGroupStreamProvider).value ?? const [];
    final conflictGroups = groups
        .where((group) => widget.args.groupIds.contains(group.id))
        .toList();
    if (conflictGroups.isEmpty) return;
    final deviceId = ref.read(deviceInfoServiceProvider).deviceId;
    final requestId = const Uuid().v4();
    setState(() {
      _requestInFlight = true;
    });
    try {
      await ref
          .read(taskRunGroupRepositoryProvider)
          .requestLateStartOwnership(
            groups: conflictGroups,
            requesterDeviceId: deviceId,
            requestId: requestId,
          );
    } finally {
      if (mounted) {
        setState(() {
          _requestInFlight = false;
        });
      }
    }
  }

  Future<void> _respondOwnershipRequest({
    required bool approved,
  }) async {
    if (_requestInFlight) return;
    final groups =
        ref.read(taskRunGroupStreamProvider).value ?? const [];
    final conflictGroups = groups
        .where((group) => widget.args.groupIds.contains(group.id))
        .toList();
    if (conflictGroups.isEmpty) return;
    final ownerId = resolveLateStartOwnerDeviceId(conflictGroups);
    final requesterId =
        resolveLateStartClaimRequesterDeviceId(conflictGroups);
    final requestId = resolveLateStartClaimRequestId(conflictGroups);
    if (ownerId == null || requesterId == null || requestId == null) return;
    setState(() {
      _requestInFlight = true;
    });
    try {
      await ref
          .read(taskRunGroupRepositoryProvider)
          .respondLateStartOwnershipRequest(
            groups: conflictGroups,
            ownerDeviceId: ownerId,
            requesterDeviceId: requesterId,
            requestId: requestId,
            approved: approved,
          );
    } finally {
      if (mounted) {
        setState(() {
          _requestInFlight = false;
        });
      }
    }
  }

  Future<void> _publishInitialSession(
    TaskRunGroup group, {
    required DateTime queueNow,
  }) async {
    if (group.tasks.isEmpty) return;
    final task = group.tasks.first;
    final session = PomodoroSession(
      taskId: task.sourceTaskId,
      groupId: group.id,
      currentTaskId: task.sourceTaskId,
      currentTaskIndex: 0,
      totalTasks: group.tasks.length,
      dataVersion: kCurrentDataVersion,
      ownerDeviceId: ref.read(deviceInfoServiceProvider).deviceId,
      status: PomodoroStatus.pomodoroRunning,
      phase: PomodoroPhase.pomodoro,
      currentPomodoro: 1,
      totalPomodoros: task.totalPomodoros,
      phaseDurationSeconds: task.pomodoroMinutes * 60,
      remainingSeconds: task.pomodoroMinutes * 60,
      phaseStartedAt: queueNow,
      currentTaskStartedAt: queueNow,
      pausedAt: null,
      lastUpdatedAt: queueNow,
      finishedAt: null,
      pauseReason: null,
    );
    await ref.read(pomodoroSessionRepositoryProvider).publishSession(session);
  }

  String _scheduledRange(TaskRunGroup group) {
    final start = group.scheduledStartTime;
    if (start == null) return '--:--';
    final end = group.theoreticalEndTime;
    return _formatLateStartRange(start, end);
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
        ranges[index] = _formatLateStartRange(cursor, end);
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

  String get label => _formatLateStartRange(start, end);
}

class _ConflictGroupCard extends StatelessWidget {
  final TaskRunGroup group;
  final bool selected;
  final String? projectedRange;
  final VoidCallback? onToggle;
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
        : _formatLateStartRange(scheduledStart, scheduledEnd);
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
            onChanged: onToggle == null ? null : (_) => onToggle!(),
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
