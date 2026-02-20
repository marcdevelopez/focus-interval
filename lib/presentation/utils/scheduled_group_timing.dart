import '../../data/models/pomodoro_session.dart';
import '../../data/models/task_run_group.dart';
import '../../data/services/task_run_notice_service.dart';
import '../../domain/pomodoro_machine.dart';

TaskRunGroup? findGroupById(List<TaskRunGroup> groups, String id) {
  for (final group in groups) {
    if (group.id == id) return group;
  }
  return null;
}

int resolveNoticeMinutes(TaskRunGroup group) {
  return group.noticeMinutes ?? TaskRunNoticeService.defaultNoticeMinutes;
}

int resolveGroupDurationSeconds(TaskRunGroup group) {
  return group.totalDurationSeconds ??
      groupDurationSecondsByMode(group.tasks, group.integrityMode);
}

DateTime? resolveGroupBaseEnd(TaskRunGroup group) {
  final start = group.actualStartTime;
  if (start == null) return null;
  final end = group.theoreticalEndTime;
  if (end.isBefore(start)) {
    final totalSeconds = resolveGroupDurationSeconds(group);
    if (totalSeconds > 0) {
      return start.add(Duration(seconds: totalSeconds));
    }
  }
  return end;
}

DateTime? resolveProjectedRunningEnd({
  required TaskRunGroup runningGroup,
  required PomodoroSession? activeSession,
  required DateTime now,
}) {
  final baseEnd = resolveGroupBaseEnd(runningGroup);
  if (baseEnd == null) return null;
  if (activeSession == null) return baseEnd;
  if (activeSession.groupId != runningGroup.id) return baseEnd;
  if (activeSession.status != PomodoroStatus.paused) return baseEnd;
  final pausedAt = activeSession.pausedAt;
  if (pausedAt == null) return baseEnd;
  final extra = now.difference(pausedAt);
  if (extra.inSeconds <= 0) return baseEnd;
  return baseEnd.add(extra);
}

DateTime? resolvePostponedAnchorEnd({
  required TaskRunGroup anchor,
  required List<TaskRunGroup> allGroups,
  required PomodoroSession? activeSession,
  required DateTime now,
}) {
  if (anchor.status == TaskRunStatus.running) {
    return resolveProjectedRunningEnd(
      runningGroup: anchor,
      activeSession: activeSession,
      now: now,
    );
  }
  final effectiveEnd = resolveEffectiveScheduledEnd(
    group: anchor,
    allGroups: allGroups,
    activeSession: activeSession,
    now: now,
  );
  if (effectiveEnd != null) return effectiveEnd;
  final updatedAt = anchor.updatedAt;
  if (updatedAt.isAfter(anchor.createdAt)) return updatedAt;
  return resolveGroupBaseEnd(anchor) ?? updatedAt;
}

DateTime? resolveEffectiveScheduledStart({
  required TaskRunGroup group,
  required List<TaskRunGroup> allGroups,
  required PomodoroSession? activeSession,
  required DateTime now,
}) {
  final scheduledStart = group.scheduledStartTime;
  if (scheduledStart == null) return null;
  final anchorId = group.postponedAfterGroupId;
  if (anchorId == null) return scheduledStart;
  final anchor = findGroupById(allGroups, anchorId);
  if (anchor == null) return scheduledStart;
  final anchorEnd = resolvePostponedAnchorEnd(
    anchor: anchor,
    allGroups: allGroups,
    activeSession: activeSession,
    now: now,
  );
  if (anchorEnd == null) return scheduledStart;
  final noticeMinutes = resolveNoticeMinutes(group);
  return anchorEnd.add(Duration(minutes: noticeMinutes));
}

DateTime? resolveEffectivePreRunStart({
  required TaskRunGroup group,
  required List<TaskRunGroup> allGroups,
  required PomodoroSession? activeSession,
  required DateTime now,
}) {
  final scheduledStart = resolveEffectiveScheduledStart(
    group: group,
    allGroups: allGroups,
    activeSession: activeSession,
    now: now,
  );
  if (scheduledStart == null) return null;
  final noticeMinutes = resolveNoticeMinutes(group);
  if (noticeMinutes <= 0) return scheduledStart;
  return scheduledStart.subtract(Duration(minutes: noticeMinutes));
}

DateTime? resolveEffectiveScheduledEnd({
  required TaskRunGroup group,
  required List<TaskRunGroup> allGroups,
  required PomodoroSession? activeSession,
  required DateTime now,
}) {
  final scheduledStart = resolveEffectiveScheduledStart(
    group: group,
    allGroups: allGroups,
    activeSession: activeSession,
    now: now,
  );
  if (scheduledStart == null) return null;
  final durationSeconds = resolveGroupDurationSeconds(group);
  return scheduledStart.add(Duration(seconds: durationSeconds));
}

bool isPostponedAfterGroup(TaskRunGroup group, String anchorId) {
  return group.postponedAfterGroupId == anchorId;
}

List<TaskRunGroup> resolveLateStartConflictSet({
  required List<TaskRunGroup> scheduled,
  required List<TaskRunGroup> allGroups,
  required PomodoroSession? activeSession,
  required DateTime now,
}) {
  if (scheduled.isEmpty) return const [];
  final overdue = scheduled
      .where((group) {
        final effectiveStart =
            resolveEffectiveScheduledStart(
              group: group,
              allGroups: allGroups,
              activeSession: activeSession,
              now: now,
            ) ??
            group.scheduledStartTime!;
        return !effectiveStart.isAfter(now);
      })
      .toList()
    ..sort((a, b) {
      final aStart =
          resolveEffectiveScheduledStart(
            group: a,
            allGroups: allGroups,
            activeSession: activeSession,
            now: now,
          ) ??
          a.scheduledStartTime!;
      final bStart =
          resolveEffectiveScheduledStart(
            group: b,
            allGroups: allGroups,
            activeSession: activeSession,
            now: now,
          ) ??
          b.scheduledStartTime!;
      return aStart.compareTo(bStart);
    });
  if (overdue.isEmpty) return const [];

  if (overdue.length == 1) {
    final horizonEnd = now.add(
      Duration(seconds: resolveGroupDurationSeconds(overdue.first)),
    );
    final conflict = _collectLateStartConflicts(
      scheduled: scheduled,
      overdueIds: {overdue.first.id},
      windowStart: now,
      windowEnd: horizonEnd,
      allGroups: allGroups,
      activeSession: activeSession,
      now: now,
    );
    return conflict.length > 1 ? conflict : const [];
  }

  final horizonEnd = _projectedQueueEnd(overdue, now);
  return _collectLateStartConflicts(
    scheduled: scheduled,
    overdueIds: overdue.map((g) => g.id).toSet(),
    windowStart: now,
    windowEnd: horizonEnd,
    allGroups: allGroups,
    activeSession: activeSession,
    now: now,
  );
}

DateTime? resolveLateStartAnchor(List<TaskRunGroup> groups) {
  DateTime? anchor;
  for (final group in groups) {
    final candidate = group.lateStartAnchorAt;
    if (candidate == null) continue;
    if (anchor == null || candidate.isBefore(anchor)) {
      anchor = candidate;
    }
  }
  return anchor;
}

String? resolveLateStartQueueId(List<TaskRunGroup> groups) {
  String? queueId;
  for (final group in groups) {
    final candidate = group.lateStartQueueId;
    if (candidate == null || candidate.isEmpty) continue;
    if (queueId == null || queueId == candidate) {
      queueId = candidate;
      continue;
    }
    return queueId;
  }
  return queueId;
}

String? resolveLateStartOwnerDeviceId(List<TaskRunGroup> groups) {
  String? ownerId;
  for (final group in groups) {
    final candidate = group.lateStartOwnerDeviceId;
    if (candidate == null || candidate.isEmpty) continue;
    if (ownerId == null || ownerId == candidate) {
      ownerId = candidate;
      continue;
    }
    return ownerId;
  }
  return ownerId;
}

DateTime? resolveLateStartOwnerHeartbeat(List<TaskRunGroup> groups) {
  DateTime? heartbeat;
  for (final group in groups) {
    final candidate = group.lateStartOwnerHeartbeatAt;
    if (candidate == null) continue;
    if (heartbeat == null || candidate.isAfter(heartbeat)) {
      heartbeat = candidate;
    }
  }
  return heartbeat;
}

String? resolveLateStartClaimRequestId(List<TaskRunGroup> groups) {
  String? requestId;
  for (final group in groups) {
    final candidate = group.lateStartClaimRequestId;
    if (candidate == null || candidate.isEmpty) continue;
    if (requestId == null || requestId == candidate) {
      requestId = candidate;
      continue;
    }
    return requestId;
  }
  return requestId;
}

String? resolveLateStartClaimRequesterDeviceId(List<TaskRunGroup> groups) {
  String? requesterId;
  for (final group in groups) {
    final candidate = group.lateStartClaimRequestedByDeviceId;
    if (candidate == null || candidate.isEmpty) continue;
    if (requesterId == null || requesterId == candidate) {
      requesterId = candidate;
      continue;
    }
    return requesterId;
  }
  return requesterId;
}

List<TaskRunGroup> _collectLateStartConflicts({
  required List<TaskRunGroup> scheduled,
  required Set<String> overdueIds,
  required DateTime windowStart,
  required DateTime windowEnd,
  required List<TaskRunGroup> allGroups,
  required PomodoroSession? activeSession,
  required DateTime now,
}) {
  final conflicts = <TaskRunGroup>{};
  for (final group in scheduled) {
    if (overdueIds.contains(group.id)) {
      conflicts.add(group);
      continue;
    }
    final start = _scheduledWindowStart(
      group,
      allGroups: allGroups,
      activeSession: activeSession,
      now: now,
    );
    final end = _scheduledWindowEnd(
      group,
      allGroups: allGroups,
      activeSession: activeSession,
      now: now,
    );
    if (_overlaps(windowStart, windowEnd, start, end)) {
      conflicts.add(group);
    }
  }
  final list = conflicts.toList()
    ..sort((a, b) => a.scheduledStartTime!.compareTo(b.scheduledStartTime!));
  return list;
}

DateTime _projectedQueueEnd(List<TaskRunGroup> overdue, DateTime now) {
  var cursor = now;
  for (var index = 0; index < overdue.length; index += 1) {
    if (index > 0) {
      final notice = resolveNoticeMinutes(overdue[index]);
      cursor = cursor.add(Duration(minutes: notice));
    }
    cursor = cursor.add(
      Duration(seconds: resolveGroupDurationSeconds(overdue[index])),
    );
  }
  return cursor;
}

DateTime _scheduledWindowStart(
  TaskRunGroup group, {
  required List<TaskRunGroup> allGroups,
  required PomodoroSession? activeSession,
  required DateTime now,
}) {
  final start =
      resolveEffectiveScheduledStart(
        group: group,
        allGroups: allGroups,
        activeSession: activeSession,
        now: now,
      ) ??
      group.scheduledStartTime!;
  final notice = resolveNoticeMinutes(group);
  if (notice <= 0) return start;
  return start.subtract(Duration(minutes: notice));
}

DateTime _scheduledWindowEnd(
  TaskRunGroup group, {
  required List<TaskRunGroup> allGroups,
  required PomodoroSession? activeSession,
  required DateTime now,
}) {
  final scheduledStart =
      resolveEffectiveScheduledStart(
        group: group,
        allGroups: allGroups,
        activeSession: activeSession,
        now: now,
      ) ??
      group.scheduledStartTime!;
  final duration = resolveGroupDurationSeconds(group);
  return scheduledStart.add(Duration(seconds: duration));
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
