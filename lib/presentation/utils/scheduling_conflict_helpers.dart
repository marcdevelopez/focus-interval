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
      return PreRunConflictType.running;
    }
    if (group.status == TaskRunStatus.scheduled) {
      return PreRunConflictType.scheduled;
    }
  }
  return null;
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
