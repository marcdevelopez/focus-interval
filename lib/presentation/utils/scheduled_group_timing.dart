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

int resolveNoticeMinutes(TaskRunGroup group, {int? fallback}) {
  return group.noticeMinutes ??
      fallback ??
      TaskRunNoticeService.defaultNoticeMinutes;
}

int resolveGroupDurationSeconds(TaskRunGroup group) {
  return group.totalDurationSeconds ??
      groupDurationSecondsByMode(group.tasks, group.integrityMode);
}

DateTime ceilToMinute(DateTime value) {
  if (value.second == 0 && value.millisecond == 0 && value.microsecond == 0) {
    return value;
  }
  if (value.isUtc) {
    return DateTime.utc(
      value.year,
      value.month,
      value.day,
      value.hour,
      value.minute,
    ).add(const Duration(minutes: 1));
  }
  return DateTime(
    value.year,
    value.month,
    value.day,
    value.hour,
    value.minute,
  ).add(const Duration(minutes: 1));
}

DateTime resolveAnchoredScheduledStart({
  required DateTime anchorEnd,
  required int noticeMinutes,
}) {
  var scheduledStart = ceilToMinute(
    anchorEnd.add(Duration(minutes: noticeMinutes)),
  );
  if (noticeMinutes <= 0) return scheduledStart;

  final preRunStart = scheduledStart.subtract(Duration(minutes: noticeMinutes));
  // Keep pre-run strictly after previous group end to avoid same-minute overlap.
  if (!preRunStart.isAfter(anchorEnd)) {
    scheduledStart = scheduledStart.add(const Duration(minutes: 1));
  }
  return scheduledStart;
}

DateTime resolveRunningOverlapThreshold(DateTime preRunStart) {
  // Conflict detection is exact at pre-run boundary.
  return preRunStart;
}

bool isRunningOverlapBeyondGrace({
  required DateTime runningEnd,
  required DateTime preRunStart,
}) {
  final threshold = resolveRunningOverlapThreshold(preRunStart);
  return runningEnd.isAfter(threshold) ||
      runningEnd.isAtSameMomentAs(threshold);
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
  int? fallbackNoticeMinutes,
}) {
  if (anchor.status == TaskRunStatus.running) {
    return resolveProjectedRunningEnd(
      runningGroup: anchor,
      activeSession: activeSession,
      now: now,
    );
  }
  if (anchor.status == TaskRunStatus.canceled) {
    return null;
  }
  final effectiveEnd = resolveEffectiveScheduledEnd(
    group: anchor,
    allGroups: allGroups,
    activeSession: activeSession,
    now: now,
    fallbackNoticeMinutes: fallbackNoticeMinutes,
  );
  if (effectiveEnd != null) return effectiveEnd;
  final updatedAt = anchor.updatedAt;
  if (updatedAt.isAfter(anchor.createdAt)) return updatedAt;
  return resolveGroupBaseEnd(anchor) ?? updatedAt;
}

bool isRunningOverlapStillValid({
  required String runningGroupId,
  required String scheduledGroupId,
  required List<TaskRunGroup> groups,
  required PomodoroSession? activeSession,
  required DateTime now,
  int? fallbackNoticeMinutes,
}) {
  final runningGroup = findGroupById(groups, runningGroupId);
  final scheduledGroup = findGroupById(groups, scheduledGroupId);
  if (runningGroup == null || scheduledGroup == null) return false;
  if (runningGroup.status != TaskRunStatus.running) return false;
  if (scheduledGroup.status != TaskRunStatus.scheduled) return false;
  final scheduledStart =
      resolveEffectiveScheduledStart(
        group: scheduledGroup,
        allGroups: groups,
        activeSession: activeSession,
        now: now,
        fallbackNoticeMinutes: fallbackNoticeMinutes,
      ) ??
      scheduledGroup.scheduledStartTime;
  if (scheduledStart == null) return false;
  final noticeMinutes = resolveNoticeMinutes(
    scheduledGroup,
    fallback: fallbackNoticeMinutes,
  );
  final preRunStart = noticeMinutes > 0
      ? scheduledStart.subtract(Duration(minutes: noticeMinutes))
      : scheduledStart;
  final runningEnd = resolveProjectedRunningEnd(
    runningGroup: runningGroup,
    activeSession: activeSession,
    now: now,
  );
  if (runningEnd == null) return false;
  return isRunningOverlapBeyondGrace(
    runningEnd: runningEnd,
    preRunStart: preRunStart,
  );
}

DateTime? resolveEffectiveScheduledStart({
  required TaskRunGroup group,
  required List<TaskRunGroup> allGroups,
  required PomodoroSession? activeSession,
  required DateTime now,
  int? fallbackNoticeMinutes,
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
    fallbackNoticeMinutes: fallbackNoticeMinutes,
  );
  if (anchorEnd == null) return scheduledStart;
  final noticeMinutes = resolveNoticeMinutes(
    group,
    fallback: fallbackNoticeMinutes,
  );
  return resolveAnchoredScheduledStart(
    anchorEnd: anchorEnd,
    noticeMinutes: noticeMinutes,
  );
}

DateTime? resolveEffectivePreRunStart({
  required TaskRunGroup group,
  required List<TaskRunGroup> allGroups,
  required PomodoroSession? activeSession,
  required DateTime now,
  int? fallbackNoticeMinutes,
}) {
  final scheduledStart = resolveEffectiveScheduledStart(
    group: group,
    allGroups: allGroups,
    activeSession: activeSession,
    now: now,
    fallbackNoticeMinutes: fallbackNoticeMinutes,
  );
  if (scheduledStart == null) return null;
  final noticeMinutes = resolveNoticeMinutes(
    group,
    fallback: fallbackNoticeMinutes,
  );
  if (noticeMinutes <= 0) return null;
  return scheduledStart.subtract(Duration(minutes: noticeMinutes));
}

DateTime? resolveEffectiveScheduledEnd({
  required TaskRunGroup group,
  required List<TaskRunGroup> allGroups,
  required PomodoroSession? activeSession,
  required DateTime now,
  int? fallbackNoticeMinutes,
}) {
  final scheduledStart = resolveEffectiveScheduledStart(
    group: group,
    allGroups: allGroups,
    activeSession: activeSession,
    now: now,
    fallbackNoticeMinutes: fallbackNoticeMinutes,
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
  int? fallbackNoticeMinutes,
}) {
  if (scheduled.isEmpty) return const [];
  final sorted = scheduled.toList()
    ..sort((a, b) {
      final aStart =
          resolveEffectiveScheduledStart(
            group: a,
            allGroups: allGroups,
            activeSession: activeSession,
            now: now,
            fallbackNoticeMinutes: fallbackNoticeMinutes,
          ) ??
          a.scheduledStartTime!;
      final bStart =
          resolveEffectiveScheduledStart(
            group: b,
            allGroups: allGroups,
            activeSession: activeSession,
            now: now,
            fallbackNoticeMinutes: fallbackNoticeMinutes,
          ) ??
          b.scheduledStartTime!;
      return aStart.compareTo(bStart);
    });

  final overdue = sorted.where((group) {
    // Groups anchored via postponedAfterGroupId were already repositioned by
    // the system (same mechanism used by running-overlap postpone). They
    // should follow normal scheduled -> auto-start flow, not re-enter the
    // late-start queue.
    if (group.postponedAfterGroupId != null) return false;
    final effectiveStart =
        resolveEffectiveScheduledStart(
          group: group,
          allGroups: allGroups,
          activeSession: activeSession,
          now: now,
          fallbackNoticeMinutes: fallbackNoticeMinutes,
        ) ??
        group.scheduledStartTime!;
    return !effectiveStart.isAfter(now);
  }).toList();
  if (overdue.isEmpty) return const [];

  // Cascading expansion: include any scheduled group whose window overlaps the
  // projected queue horizon, and keep expanding until stable.
  final conflictIds = overdue.map((g) => g.id).toSet();
  var changed = true;
  while (changed) {
    changed = false;
    final selected = sorted
        .where((group) => conflictIds.contains(group.id))
        .toList();
    final horizonEnd = _projectedQueueEnd(
      selected,
      now,
      fallbackNoticeMinutes: fallbackNoticeMinutes,
    );
    for (final group in sorted) {
      if (conflictIds.contains(group.id)) continue;
      final start = _scheduledWindowStart(
        group,
        allGroups: allGroups,
        activeSession: activeSession,
        now: now,
        fallbackNoticeMinutes: fallbackNoticeMinutes,
      );
      final end = _scheduledWindowEnd(
        group,
        allGroups: allGroups,
        activeSession: activeSession,
        now: now,
        fallbackNoticeMinutes: fallbackNoticeMinutes,
      );
      if (_overlaps(now, horizonEnd, start, end)) {
        conflictIds.add(group.id);
        changed = true;
      }
    }
  }

  final conflicts = sorted
      .where((group) => conflictIds.contains(group.id))
      .toList();
  return conflicts.length > 1 ? conflicts : const [];
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

DateTime _projectedQueueEnd(
  List<TaskRunGroup> overdue,
  DateTime now, {
  int? fallbackNoticeMinutes,
}) {
  var cursor = now;
  for (var index = 0; index < overdue.length; index += 1) {
    if (index > 0) {
      final notice = resolveNoticeMinutes(
        overdue[index],
        fallback: fallbackNoticeMinutes,
      );
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
  int? fallbackNoticeMinutes,
}) {
  final start =
      resolveEffectiveScheduledStart(
        group: group,
        allGroups: allGroups,
        activeSession: activeSession,
        now: now,
        fallbackNoticeMinutes: fallbackNoticeMinutes,
      ) ??
      group.scheduledStartTime!;
  final notice = resolveNoticeMinutes(group, fallback: fallbackNoticeMinutes);
  if (notice <= 0) return start;
  return start.subtract(Duration(minutes: notice));
}

DateTime _scheduledWindowEnd(
  TaskRunGroup group, {
  required List<TaskRunGroup> allGroups,
  required PomodoroSession? activeSession,
  required DateTime now,
  int? fallbackNoticeMinutes,
}) {
  final scheduledStart =
      resolveEffectiveScheduledStart(
        group: group,
        allGroups: allGroups,
        activeSession: activeSession,
        now: now,
        fallbackNoticeMinutes: fallbackNoticeMinutes,
      ) ??
      group.scheduledStartTime!;
  final duration = resolveGroupDurationSeconds(group);
  return scheduledStart.add(Duration(seconds: duration));
}

bool _overlaps(DateTime aStart, DateTime aEnd, DateTime bStart, DateTime bEnd) {
  final safeAEnd = aEnd.isBefore(aStart) ? aStart : aEnd;
  final safeBEnd = bEnd.isBefore(bStart) ? bStart : bEnd;
  return aStart.isBefore(safeBEnd) && safeAEnd.isAfter(bStart);
}
