import 'package:intl/intl.dart';

import '../../data/models/pomodoro_session.dart';
import '../../data/models/task_run_group.dart';
import 'scheduled_group_timing.dart';

enum PreRunConflictType { running, scheduled }

class GroupConflicts {
  final List<TaskRunGroup> running;
  final List<TaskRunGroup> scheduled;

  const GroupConflicts({required this.running, required this.scheduled});

  bool get isEmpty => running.isEmpty && scheduled.isEmpty;
  bool get isNotEmpty => !isEmpty;
}

class ConflictWindow {
  final String groupId;
  final String groupName;
  final TaskRunStatus status;
  final DateTime start;
  final DateTime end;
  final DateTime? preRunStart;

  const ConflictWindow({
    required this.groupId,
    required this.groupName,
    required this.status,
    required this.start,
    required this.end,
    required this.preRunStart,
  });
}

class RunningOverlapContext {
  final ConflictWindow running;
  final ConflictWindow scheduled;

  const RunningOverlapContext({required this.running, required this.scheduled});
}

class PreRunConflict {
  final PreRunConflictType type;
  final ConflictWindow blocker;

  const PreRunConflict({required this.type, required this.blocker});
}

GroupConflicts findSchedulingConflicts(
  List<TaskRunGroup> groups, {
  required DateTime newStart,
  required DateTime newEnd,
  required bool includeRunningAlways,
  required PomodoroSession? activeSession,
  required DateTime now,
  required int? fallbackNoticeMinutes,
}) {
  final running = <TaskRunGroup>[];
  final scheduled = <TaskRunGroup>[];

  for (final group in groups) {
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
                fallbackNoticeMinutes: fallbackNoticeMinutes,
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
                fallbackNoticeMinutes: fallbackNoticeMinutes,
              ) ??
              group.theoreticalEndTime)
        : (group.theoreticalEndTime.isBefore(start)
              ? start
              : group.theoreticalEndTime);
    if (!schedulingOverlaps(newStart, newEnd, start, end)) continue;
    if (group.status == TaskRunStatus.running) {
      running.add(group);
      continue;
    }
    if (group.status == TaskRunStatus.scheduled) {
      scheduled.add(group);
    }
  }

  return GroupConflicts(running: running, scheduled: scheduled);
}

PreRunConflictType? findPreRunConflict(
  List<TaskRunGroup> groups, {
  required DateTime preRunStart,
  required DateTime scheduledStart,
  required PomodoroSession? activeSession,
  required DateTime now,
  required int? fallbackNoticeMinutes,
}) {
  return findPreRunConflictDetails(
    groups,
    preRunStart: preRunStart,
    scheduledStart: scheduledStart,
    activeSession: activeSession,
    now: now,
    fallbackNoticeMinutes: fallbackNoticeMinutes,
  )?.type;
}

PreRunConflict? findPreRunConflictDetails(
  List<TaskRunGroup> groups, {
  required DateTime preRunStart,
  required DateTime scheduledStart,
  required PomodoroSession? activeSession,
  required DateTime now,
  required int? fallbackNoticeMinutes,
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
                fallbackNoticeMinutes: fallbackNoticeMinutes,
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
                fallbackNoticeMinutes: fallbackNoticeMinutes,
              ) ??
              group.theoreticalEndTime)
        : (group.theoreticalEndTime.isBefore(start)
              ? start
              : group.theoreticalEndTime);
    if (!schedulingOverlaps(preRunStart, scheduledStart, start, end)) continue;
    if (group.status == TaskRunStatus.running) {
      final blocker = resolveConflictWindow(
        group: group,
        allGroups: groups,
        activeSession: activeSession,
        now: now,
        fallbackNoticeMinutes: fallbackNoticeMinutes,
      );
      if (blocker == null) return null;
      return PreRunConflict(type: PreRunConflictType.running, blocker: blocker);
    }
    if (group.status == TaskRunStatus.scheduled) {
      final blocker = resolveConflictWindow(
        group: group,
        allGroups: groups,
        activeSession: activeSession,
        now: now,
        fallbackNoticeMinutes: fallbackNoticeMinutes,
      );
      if (blocker == null) return null;
      return PreRunConflict(
        type: PreRunConflictType.scheduled,
        blocker: blocker,
      );
    }
  }
  return null;
}

RunningOverlapContext? resolveRunningOverlapContext({
  required String runningGroupId,
  required String scheduledGroupId,
  required List<TaskRunGroup> groups,
  required PomodoroSession? activeSession,
  required DateTime now,
  required int? fallbackNoticeMinutes,
}) {
  final running = findGroupById(groups, runningGroupId);
  final scheduled = findGroupById(groups, scheduledGroupId);
  if (running == null || scheduled == null) return null;
  final runningWindow = resolveConflictWindow(
    group: running,
    allGroups: groups,
    activeSession: activeSession,
    now: now,
    fallbackNoticeMinutes: fallbackNoticeMinutes,
  );
  final scheduledWindow = resolveConflictWindow(
    group: scheduled,
    allGroups: groups,
    activeSession: activeSession,
    now: now,
    fallbackNoticeMinutes: fallbackNoticeMinutes,
  );
  if (runningWindow == null || scheduledWindow == null) return null;
  return RunningOverlapContext(
    running: runningWindow,
    scheduled: scheduledWindow,
  );
}

ConflictWindow? resolveConflictWindow({
  required TaskRunGroup group,
  required List<TaskRunGroup> allGroups,
  required PomodoroSession? activeSession,
  required DateTime now,
  required int? fallbackNoticeMinutes,
}) {
  final start = group.status == TaskRunStatus.scheduled
      ? (resolveEffectiveScheduledStart(
              group: group,
              allGroups: allGroups,
              activeSession: activeSession,
              now: now,
              fallbackNoticeMinutes: fallbackNoticeMinutes,
            ) ??
            group.scheduledStartTime ??
            group.createdAt)
      : (group.actualStartTime ?? group.scheduledStartTime ?? group.createdAt);
  final projectedRunningEnd = group.status == TaskRunStatus.running
      ? resolveProjectedRunningEnd(
          runningGroup: group,
          activeSession: activeSession,
          now: now,
        )
      : null;
  final end = group.status == TaskRunStatus.scheduled
      ? (resolveEffectiveScheduledEnd(
              group: group,
              allGroups: allGroups,
              activeSession: activeSession,
              now: now,
              fallbackNoticeMinutes: fallbackNoticeMinutes,
            ) ??
            group.theoreticalEndTime)
      : (projectedRunningEnd ??
            (group.theoreticalEndTime.isBefore(start)
                ? start
                : group.theoreticalEndTime));
  final name = group.tasks.isNotEmpty ? group.tasks.first.name : 'Task group';
  DateTime? preRunStart;
  if (group.status == TaskRunStatus.scheduled) {
    final notice = resolveNoticeMinutes(group, fallback: fallbackNoticeMinutes);
    if (notice > 0) {
      final candidate = start.subtract(Duration(minutes: notice));
      if (!candidate.isAtSameMomentAs(start)) {
        preRunStart = candidate;
      }
    }
  }
  return ConflictWindow(
    groupId: group.id,
    groupName: name,
    status: group.status,
    start: start,
    end: end,
    preRunStart: preRunStart,
  );
}

String formatConflictTime(DateTime value, {required DateTime now}) {
  final sameDay =
      value.year == now.year &&
      value.month == now.month &&
      value.day == now.day;
  if (sameDay) {
    return DateFormat('HH:mm').format(value);
  }
  return DateFormat('MMM d, HH:mm').format(value);
}

String formatConflictRange(
  DateTime start,
  DateTime end, {
  required DateTime now,
}) {
  final sameDayAsNow =
      start.year == now.year &&
      start.month == now.month &&
      start.day == now.day;
  final sameDayPair =
      start.year == end.year &&
      start.month == end.month &&
      start.day == end.day;
  if (sameDayAsNow && sameDayPair) {
    return '${DateFormat('HH:mm').format(start)}-${DateFormat('HH:mm').format(end)}';
  }
  final startLabel = DateFormat('MMM d, HH:mm').format(start);
  final endLabel = sameDayPair
      ? DateFormat('HH:mm').format(end)
      : DateFormat('MMM d, HH:mm').format(end);
  return '$startLabel-$endLabel';
}

String formatConflictSummary(
  RunningOverlapContext context, {
  required DateTime now,
}) {
  final runningRange = formatConflictRange(
    context.running.start,
    context.running.end,
    now: now,
  );
  final scheduledRange = formatConflictRange(
    context.scheduled.start,
    context.scheduled.end,
    now: now,
  );
  return 'Running ${context.running.groupName} ($runningRange) · '
      'Scheduled ${context.scheduled.groupName} ($scheduledRange)';
}

bool schedulingOverlaps(
  DateTime aStart,
  DateTime aEnd,
  DateTime bStart,
  DateTime bEnd,
) {
  final safeAEnd = aEnd.isBefore(aStart) ? aStart : aEnd;
  final safeBEnd = bEnd.isBefore(bStart) ? bStart : bEnd;
  return aStart.isBefore(safeBEnd) && safeAEnd.isAfter(bStart);
}
