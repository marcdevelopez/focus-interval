import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/pomodoro_task.dart';
import '../../data/models/task_run_group.dart';
import '../../widgets/task_card.dart';

class TaskGroupPlanningArgs {
  final List<TaskRunItem> items;
  final TaskRunIntegrityMode integrityMode;
  final DateTime planningAnchor;

  const TaskGroupPlanningArgs({
    required this.items,
    required this.integrityMode,
    required this.planningAnchor,
  });
}

enum TaskGroupPlanOption {
  startNow,
  scheduleStart,
  scheduleRange,
  scheduleTotal,
}

class TaskGroupPlanningResult {
  final TaskGroupPlanOption option;
  final DateTime? scheduledStart;
  final List<TaskRunItem> items;

  const TaskGroupPlanningResult({
    required this.option,
    required this.items,
    this.scheduledStart,
  });
}

class TaskGroupPlanningScreen extends StatefulWidget {
  final TaskGroupPlanningArgs args;

  const TaskGroupPlanningScreen({
    super.key,
    required this.args,
  });

  @override
  State<TaskGroupPlanningScreen> createState() =>
      _TaskGroupPlanningScreenState();
}

class _TaskGroupPlanningScreenState extends State<TaskGroupPlanningScreen> {
  static const String _infoSeenKey = 'planning_info_seen_v1';
  static const String _shiftNoticeKey = 'planning_range_shift_notice_v1';
  static final DateFormat _timeFormat = DateFormat('HH:mm');
  static final DateFormat _dateFormat = DateFormat('MMM d');

  TaskGroupPlanOption _selected = TaskGroupPlanOption.startNow;
  DateTime? _scheduledStart;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  DateTime? _totalStart;
  Duration? _totalDuration;
  bool _infoDialogVisible = false;
  bool _shiftNoticeVisible = false;
  String? _lastShiftNoticeKey;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowInfoDialog();
    });
  }

  Future<void> _maybeShowInfoDialog() async {
    if (_infoDialogVisible) return;
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool(_infoSeenKey) ?? false;
    if (seen || !mounted) return;
    await _showInfoDialog(includeDontShowAgain: true);
  }

  Future<void> _showInfoDialog({required bool includeDontShowAgain}) async {
    if (!mounted) return;
    _infoDialogVisible = true;
    var dontShowAgain = false;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text('Planning options'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Each option controls when the group starts.',
                      style: TextStyle(color: Colors.white70, height: 1.4),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '• Start now: begin immediately using the current group snapshot.',
                      style: TextStyle(color: Colors.white70, height: 1.4),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '• Schedule by start time: pick an exact start date and time.',
                      style: TextStyle(color: Colors.white70, height: 1.4),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '• Schedule by total range time: choose a start and end time. '
                      'The group is redistributed to fit the range.',
                      style: TextStyle(color: Colors.white70, height: 1.4),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '• Schedule by total time: choose a start time and a duration. '
                      'The group is redistributed to fit the duration.',
                      style: TextStyle(color: Colors.white70, height: 1.4),
                    ),
                    if (includeDontShowAgain) ...[
                      const SizedBox(height: 12),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: dontShowAgain,
                        onChanged: (value) {
                          setModalState(() {
                            dontShowAgain = value ?? false;
                          });
                        },
                        title: const Text("Don't show again"),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    ).whenComplete(() async {
      if (includeDontShowAgain && dontShowAgain) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_infoSeenKey, true);
      }
      _infoDialogVisible = false;
    });
  }

  Future<void> _selectScheduleStart() async {
    final picked = await _pickScheduleDateTime(
      context,
      initial: _scheduledStart ?? DateTime.now(),
    );
    if (!mounted) return;
    if (picked == null) return;
    setState(() {
      _selected = TaskGroupPlanOption.scheduleStart;
      _scheduledStart = picked;
    });
  }

  Future<void> _selectRangeTimes() async {
    final initialStart = _rangeStart ?? DateTime.now();
    final start = await _pickScheduleDateTime(context, initial: initialStart);
    if (!mounted) return;
    if (start == null) return;
    final initialEnd = _rangeEnd ?? start.add(const Duration(hours: 1));
    final end = await _pickScheduleDateTime(context, initial: initialEnd);
    if (!mounted) return;
    if (end == null) return;
    if (!end.isAfter(start)) {
      _showSnackBar('End time must be after start time.');
      return;
    }
    setState(() {
      _selected = TaskGroupPlanOption.scheduleRange;
      _rangeStart = start;
      _rangeEnd = end;
    });
  }

  Future<void> _selectTotalTime() async {
    final start = await _pickScheduleDateTime(
      context,
      initial: _totalStart ?? DateTime.now(),
    );
    if (!mounted) return;
    if (start == null) return;
    final duration = await _pickDuration(
      context,
      initial: _totalDuration ?? const Duration(hours: 1),
    );
    if (!mounted) return;
    if (duration == null) return;
    if (duration.inMinutes <= 0) {
      _showSnackBar('Duration must be at least 1 minute.');
      return;
    }
    setState(() {
      _selected = TaskGroupPlanOption.scheduleTotal;
      _totalStart = start;
      _totalDuration = duration;
    });
  }

  Future<void> _selectOption(TaskGroupPlanOption option) async {
    switch (option) {
      case TaskGroupPlanOption.startNow:
        setState(() {
          _selected = TaskGroupPlanOption.startNow;
        });
        return;
      case TaskGroupPlanOption.scheduleStart:
        await _selectScheduleStart();
        return;
      case TaskGroupPlanOption.scheduleRange:
        await _selectRangeTimes();
        return;
      case TaskGroupPlanOption.scheduleTotal:
        await _selectTotalTime();
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final integrityMode = widget.args.integrityMode;
    final preview = _buildPlanPreview();
    _maybeScheduleShiftNotice(preview);

    final startTime = preview.scheduledStart;
    final groupStartLabel =
        startTime == null ? '--:--' : _timeFormat.format(startTime);
    final groupEndLabel = startTime == null
        ? '--:--'
        : _timeFormat
            .format(startTime.add(Duration(seconds: preview.totalDurationSeconds)));
    final durations = taskDurationSecondsByMode(
      preview.items,
      integrityMode,
    );
    final ranges = startTime == null
        ? <int, String>{}
        : _buildTimeRanges(durations, startTime);
    final weightTotal = _weightTotal(preview.items);
    final previewTasks = _previewTasks(preview.items);
    final shiftLabel = _formatShiftLabel(preview.shiftSeconds);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan group'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _sectionHeader('Planning options'),
          const SizedBox(height: 8),
          _infoRow(),
          const SizedBox(height: 8),
          _OptionCard(
            title: 'Start now',
            description: 'Begin immediately using the current snapshot.',
            selected: _selected == TaskGroupPlanOption.startNow,
            onTap: () => _selectOption(TaskGroupPlanOption.startNow),
          ),
          const SizedBox(height: 10),
          _OptionCard(
            title: 'Schedule by start time',
            description: 'Pick a specific start time for the group.',
            selected: _selected == TaskGroupPlanOption.scheduleStart,
            onTap: () => _selectOption(TaskGroupPlanOption.scheduleStart),
            footer: _selected == TaskGroupPlanOption.scheduleStart
                ? _SchedulePickerRow(
                    label: _scheduledStart == null
                        ? 'Select start time'
                        : _formatDateTime(_scheduledStart!),
                    onPressed: _selectScheduleStart,
                  )
                : null,
          ),
          const SizedBox(height: 10),
          _OptionCard(
            title: 'Schedule by total range time',
            description: 'Fit the group within a start and end time.',
            selected: _selected == TaskGroupPlanOption.scheduleRange,
            onTap: () => _selectOption(TaskGroupPlanOption.scheduleRange),
            footer: _selected == TaskGroupPlanOption.scheduleRange
                ? _SchedulePickerRow(
                    label: _rangeStart == null || _rangeEnd == null
                        ? 'Select time range'
                        : '${_formatDateTime(_rangeStart!)} to '
                            '${_formatDateTime(_rangeEnd!)}',
                    onPressed: _selectRangeTimes,
                  )
                : null,
          ),
          const SizedBox(height: 10),
          _OptionCard(
            title: 'Schedule by total time',
            description: 'Fit the group within a target duration.',
            selected: _selected == TaskGroupPlanOption.scheduleTotal,
            onTap: () => _selectOption(TaskGroupPlanOption.scheduleTotal),
            footer: _selected == TaskGroupPlanOption.scheduleTotal
                ? _SchedulePickerRow(
                    label: _totalStart == null || _totalDuration == null
                        ? 'Select start + duration'
                        : '${_formatDateTime(_totalStart!)} · '
                            '${_formatDuration(_totalDuration!)}',
                    onPressed: _selectTotalTime,
                  )
                : null,
          ),
          if (preview.error != null) ...[
            const SizedBox(height: 12),
            Text(
              preview.error!,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ],
          const SizedBox(height: 20),
          _sectionHeader('Group preview'),
          const SizedBox(height: 8),
          _groupTimeRow(groupStartLabel, groupEndLabel),
          if (shiftLabel != null) ...[
            const SizedBox(height: 6),
            Text(
              shiftLabel,
              style: const TextStyle(color: Colors.orangeAccent, fontSize: 12),
            ),
          ],
          const SizedBox(height: 12),
          for (var index = 0; index < previewTasks.length; index += 1)
            TaskCard(
              task: previewTasks[index],
              selected: true,
              enableInteraction: false,
              onTap: () {},
              onEdit: () {},
              onDelete: () {},
              timeRange: ranges[index],
              weightPercent: _weightPercent(
                preview.items[index],
                weightTotal: weightTotal,
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _canConfirm(preview) ? () => _handleConfirm(preview) : null,
                child: const Text('Confirm'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canConfirm(_PlanPreview preview) {
    if (!preview.isValid) return false;
    if (_selected == TaskGroupPlanOption.startNow) return true;
    return preview.scheduledStart != null;
  }

  void _handleConfirm(_PlanPreview preview) {
    final scheduledStart =
        _selected == TaskGroupPlanOption.startNow ? null : preview.scheduledStart;
    Navigator.of(context).pop(
      TaskGroupPlanningResult(
        option: _selected,
        items: preview.items,
        scheduledStart: scheduledStart,
      ),
    );
  }

  _PlanPreview _buildPlanPreview() {
    final items = widget.args.items;
    final integrityMode = widget.args.integrityMode;
    final totalSeconds = groupDurationSecondsByMode(items, integrityMode);

    switch (_selected) {
      case TaskGroupPlanOption.startNow:
        return _PlanPreview(
          option: _selected,
          items: items,
          scheduledStart: widget.args.planningAnchor,
          totalDurationSeconds: totalSeconds,
        );
      case TaskGroupPlanOption.scheduleStart:
        if (_scheduledStart == null) {
          return _PlanPreview.error(
            option: _selected,
            items: items,
            totalDurationSeconds: totalSeconds,
            message: 'Select a start time to schedule.',
          );
        }
        if (_scheduledStart!.isBefore(DateTime.now())) {
          return _PlanPreview.error(
            option: _selected,
            items: items,
            totalDurationSeconds: totalSeconds,
            message: 'Start time must be in the future.',
          );
        }
        return _PlanPreview(
          option: _selected,
          items: items,
          scheduledStart: _scheduledStart,
          totalDurationSeconds: totalSeconds,
        );
      case TaskGroupPlanOption.scheduleRange:
        if (_rangeStart == null || _rangeEnd == null) {
          return _PlanPreview.error(
            option: _selected,
            items: items,
            totalDurationSeconds: totalSeconds,
            message: 'Select a start and end time for the range.',
          );
        }
        if (_rangeStart!.isBefore(DateTime.now())) {
          return _PlanPreview.error(
            option: _selected,
            items: items,
            totalDurationSeconds: totalSeconds,
            message: 'Start time must be in the future.',
          );
        }
        if (!_rangeEnd!.isAfter(_rangeStart!)) {
          return _PlanPreview.error(
            option: _selected,
            items: items,
            totalDurationSeconds: totalSeconds,
            message: 'End time must be after start time.',
          );
        }
        final targetSeconds = _rangeEnd!.difference(_rangeStart!).inSeconds;
        final result = _redistributeForTarget(
          items: items,
          integrityMode: integrityMode,
          targetDurationSeconds: targetSeconds,
        );
        if (!result.success) {
          return _PlanPreview.error(
            option: _selected,
            items: items,
            totalDurationSeconds: totalSeconds,
            message: result.error ?? 'Unable to fit the requested range.',
          );
        }
        return _PlanPreview(
          option: _selected,
          items: result.items,
          scheduledStart: _rangeStart,
          totalDurationSeconds: result.actualDurationSeconds,
          targetDurationSeconds: targetSeconds,
        );
      case TaskGroupPlanOption.scheduleTotal:
        if (_totalStart == null || _totalDuration == null) {
          return _PlanPreview.error(
            option: _selected,
            items: items,
            totalDurationSeconds: totalSeconds,
            message: 'Select a start time and duration.',
          );
        }
        if (_totalStart!.isBefore(DateTime.now())) {
          return _PlanPreview.error(
            option: _selected,
            items: items,
            totalDurationSeconds: totalSeconds,
            message: 'Start time must be in the future.',
          );
        }
        if (_totalDuration!.inSeconds <= 0) {
          return _PlanPreview.error(
            option: _selected,
            items: items,
            totalDurationSeconds: totalSeconds,
            message: 'Duration must be at least 1 minute.',
          );
        }
        final targetSeconds = _totalDuration!.inSeconds;
        final result = _redistributeForTarget(
          items: items,
          integrityMode: integrityMode,
          targetDurationSeconds: targetSeconds,
        );
        if (!result.success) {
          return _PlanPreview.error(
            option: _selected,
            items: items,
            totalDurationSeconds: totalSeconds,
            message: result.error ?? 'Unable to fit the requested duration.',
          );
        }
        return _PlanPreview(
          option: _selected,
          items: result.items,
          scheduledStart: _totalStart,
          totalDurationSeconds: result.actualDurationSeconds,
          targetDurationSeconds: targetSeconds,
        );
    }
  }

  _RedistributionResult _redistributeForTarget({
    required List<TaskRunItem> items,
    required TaskRunIntegrityMode integrityMode,
    required int targetDurationSeconds,
  }) {
    if (items.isEmpty || targetDurationSeconds <= 0) {
      return const _RedistributionResult.failure(
        'Target duration must be greater than zero.',
      );
    }

    final minItems = [
      for (final item in items) _copyWithPomodoros(item, pomodoros: 1),
    ];
    final minDuration = groupDurationSecondsByMode(minItems, integrityMode);
    if (minDuration > targetDurationSeconds) {
      return const _RedistributionResult.failure(
        'The requested time is too short for this group.',
      );
    }

    final baselineDuration = groupDurationSecondsByMode(items, integrityMode);
    if (baselineDuration <= 0) {
      return const _RedistributionResult.failure(
        'Unable to calculate the current group duration.',
      );
    }

    final baselineWorkMinutes = _totalWorkMinutes(items);
    if (baselineWorkMinutes <= 0) {
      return const _RedistributionResult.failure(
        'Unable to calculate the current group workload.',
      );
    }

    final minWorkMinutes = _minWorkMinutes(items);
    final ratio = targetDurationSeconds / baselineDuration;
    final initialWork = (baselineWorkMinutes * ratio).clamp(
      minWorkMinutes,
      double.infinity,
    );

    final search = _searchForWorkTarget(
      items: items,
      originalItems: items,
      integrityMode: integrityMode,
      targetDurationSeconds: targetDurationSeconds,
      minWorkMinutes: minWorkMinutes,
      initialWorkMinutes: initialWork,
    );

    final best = search.bestWithinDeviation;
    if (best == null) {
      if (search.bestWithinTime != null) {
        return const _RedistributionResult.failure(
          'The requested time would skew task weights too far. '
          'Choose a larger range or fewer tasks.',
        );
      }
      return const _RedistributionResult.failure(
        'The requested time is too short for this configuration.',
      );
    }

    return _RedistributionResult.success(
      items: best.items,
      actualDurationSeconds: best.actualDurationSeconds,
    );
  }

  _RedistributionSearch _searchForWorkTarget({
    required List<TaskRunItem> items,
    required List<TaskRunItem> originalItems,
    required TaskRunIntegrityMode integrityMode,
    required int targetDurationSeconds,
    required double minWorkMinutes,
    required double initialWorkMinutes,
  }) {
    _RedistributionAttempt? bestWithinTime;
    _RedistributionAttempt? bestWithinDeviation;
    var low = minWorkMinutes;
    var high = initialWorkMinutes;

    void considerAttempt(_RedistributionAttempt attempt) {
      if (attempt.actualDurationSeconds > targetDurationSeconds) return;
      if (bestWithinTime == null ||
          attempt.actualDurationSeconds >
              bestWithinTime!.actualDurationSeconds) {
        bestWithinTime = attempt;
      }
      if (_hasExcessiveDeviation(originalItems, attempt.items)) return;
      if (bestWithinDeviation == null ||
          attempt.actualDurationSeconds >
              bestWithinDeviation!.actualDurationSeconds) {
        bestWithinDeviation = attempt;
      }
    }

    final initial = _redistributeByWorkTarget(
      items: items,
      integrityMode: integrityMode,
      targetWorkMinutes: initialWorkMinutes,
    );
    if (initial.actualDurationSeconds <= targetDurationSeconds) {
      considerAttempt(initial);
      high = initialWorkMinutes;
      var expandedHigh = high;
      for (var i = 0; i < 6; i += 1) {
        expandedHigh *= 1.2;
        final attempt = _redistributeByWorkTarget(
          items: items,
          integrityMode: integrityMode,
          targetWorkMinutes: expandedHigh,
        );
        if (attempt.actualDurationSeconds <= targetDurationSeconds) {
          considerAttempt(attempt);
          high = expandedHigh;
        } else {
          low = high;
          high = expandedHigh;
          break;
        }
      }
    }

    for (var i = 0; i < 20; i += 1) {
      final mid = (low + high) / 2;
      final attempt = _redistributeByWorkTarget(
        items: items,
        integrityMode: integrityMode,
        targetWorkMinutes: mid,
      );
      if (attempt.actualDurationSeconds <= targetDurationSeconds) {
        considerAttempt(attempt);
        low = mid;
      } else {
        high = mid;
      }
    }

    return _RedistributionSearch(
      bestWithinTime: bestWithinTime,
      bestWithinDeviation: bestWithinDeviation,
    );
  }

  _RedistributionAttempt _redistributeByWorkTarget({
    required List<TaskRunItem> items,
    required TaskRunIntegrityMode integrityMode,
    required double targetWorkMinutes,
  }) {
    final baselineWorkMinutes = _totalWorkMinutes(items);
    final allocations = <_Allocation>[];
    for (final item in items) {
      final work = item.totalPomodoros * item.pomodoroMinutes;
      final share = baselineWorkMinutes <= 0 ? 0 : work / baselineWorkMinutes;
      final targetWork = targetWorkMinutes * share;
      final targetPomodoros = targetWork / item.pomodoroMinutes;
      var rounded = _roundHalfUp(targetPomodoros);
      if (rounded < 1) rounded = 1;
      allocations.add(
        _Allocation(
          item: item,
          targetPomodoros: targetPomodoros,
          pomodoros: rounded,
        ),
      );
    }

    final redistributed = [
      for (final allocation in allocations)
        _copyWithPomodoros(
          allocation.item,
          pomodoros: allocation.pomodoros,
        ),
    ];
    final actualDurationSeconds =
        groupDurationSecondsByMode(redistributed, integrityMode);

    return _RedistributionAttempt(
      items: redistributed,
      actualDurationSeconds: actualDurationSeconds,
    );
  }

  double _minWorkMinutes(List<TaskRunItem> items) {
    var total = 0.0;
    for (final item in items) {
      total += item.pomodoroMinutes.toDouble();
    }
    return total;
  }

  bool _hasExcessiveDeviation(
    List<TaskRunItem> original,
    List<TaskRunItem> redistributed,
  ) {
    final originalTotal = _totalWorkMinutes(original);
    final redistributedTotal = _totalWorkMinutes(redistributed);
    if (originalTotal <= 0 || redistributedTotal <= 0) return false;

    for (var index = 0; index < original.length; index += 1) {
      final originalWork =
          original[index].totalPomodoros * original[index].pomodoroMinutes;
      final newWork = redistributed[index].totalPomodoros *
          redistributed[index].pomodoroMinutes;
      final originalPercent = (originalWork / originalTotal) * 100;
      final newPercent = (newWork / redistributedTotal) * 100;
      if ((newPercent - originalPercent).abs() >= 10) {
        return true;
      }
    }
    return false;
  }

  TaskRunItem _copyWithPomodoros(TaskRunItem item, {required int pomodoros}) {
    return TaskRunItem(
      sourceTaskId: item.sourceTaskId,
      name: item.name,
      presetId: item.presetId,
      pomodoroMinutes: item.pomodoroMinutes,
      shortBreakMinutes: item.shortBreakMinutes,
      longBreakMinutes: item.longBreakMinutes,
      totalPomodoros: pomodoros,
      longBreakInterval: item.longBreakInterval,
      startSound: item.startSound,
      startBreakSound: item.startBreakSound,
      finishTaskSound: item.finishTaskSound,
    );
  }

  int _roundHalfUp(double value) {
    final floor = value.floor();
    if (value - floor >= 0.5) return floor + 1;
    return floor;
  }

  void _maybeScheduleShiftNotice(_PlanPreview preview) {
    if (preview.shiftSeconds <= 0 || preview.targetDurationSeconds == null) {
      return;
    }
    final startKey = preview.scheduledStart?.millisecondsSinceEpoch ?? 0;
    final key = '${preview.option}-$startKey-${preview.shiftSeconds}';
    if (_lastShiftNoticeKey == key) return;
    _lastShiftNoticeKey = key;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showShiftNotice(preview.shiftSeconds);
    });
  }

  Future<void> _showShiftNotice(int shiftSeconds) async {
    if (_shiftNoticeVisible) return;
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool(_shiftNoticeKey) ?? false;
    if (seen || !mounted) return;
    _shiftNoticeVisible = true;
    var dontShowAgain = false;
    final shiftLabel = _formatDuration(Duration(seconds: shiftSeconds));
    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text('Adjusted end time'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'The closest valid distribution ends $shiftLabel earlier '
                    'because pomodoros are indivisible.',
                    style: const TextStyle(color: Colors.white70, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: dontShowAgain,
                    onChanged: (value) {
                      setModalState(() {
                        dontShowAgain = value ?? false;
                      });
                    },
                    title: const Text("Don't show again"),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    ).whenComplete(() async {
      if (dontShowAgain) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_shiftNoticeKey, true);
      }
      _shiftNoticeVisible = false;
    });
  }

  Widget _sectionHeader(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _infoRow() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Review the plan and confirm when ready.',
            style: TextStyle(color: Colors.white70),
          ),
        ),
        IconButton(
          onPressed: () => _showInfoDialog(includeDontShowAgain: false),
          icon: const Icon(Icons.info_outline, color: Colors.white70),
          tooltip: 'Planning options info',
        ),
      ],
    );
  }

  Widget _groupTimeRow(String start, String end) {
    return Row(
      children: [
        _timeChip('Start', start),
        const SizedBox(width: 8),
        _timeChip('End', end),
      ],
    );
  }

  Widget _timeChip(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime value) {
    return '${_dateFormat.format(value)} · ${_timeFormat.format(value)}';
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

  String? _formatShiftLabel(int shiftSeconds) {
    if (shiftSeconds <= 0) return null;
    final duration = Duration(seconds: shiftSeconds);
    return 'Adjusted end: ${_formatDuration(duration)} earlier than requested.';
  }

  Map<int, String> _buildTimeRanges(
    List<int> durations,
    DateTime start,
  ) {
    final ranges = <int, String>{};
    var cursor = start;
    for (var index = 0; index < durations.length; index += 1) {
      final end = cursor.add(Duration(seconds: durations[index]));
      ranges[index] =
          '${_timeFormat.format(cursor)}–${_timeFormat.format(end)}';
      cursor = end;
    }
    return ranges;
  }

  int? _weightTotal(List<TaskRunItem> items) {
    if (items.isEmpty) return null;
    var total = 0;
    for (final item in items) {
      total += item.totalPomodoros * item.pomodoroMinutes;
    }
    return total <= 0 ? null : total;
  }

  double _totalWorkMinutes(List<TaskRunItem> items) {
    var total = 0.0;
    for (final item in items) {
      total += item.totalPomodoros * item.pomodoroMinutes;
    }
    return total;
  }

  int? _weightPercent(TaskRunItem item, {required int? weightTotal}) {
    if (weightTotal == null || weightTotal <= 0) return null;
    final work = item.totalPomodoros * item.pomodoroMinutes;
    return ((work / weightTotal) * 100).round();
  }

  List<PomodoroTask> _previewTasks(List<TaskRunItem> items) {
    final now = DateTime.now();
    return [
      for (var index = 0; index < items.length; index += 1)
        PomodoroTask(
          id: items[index].sourceTaskId,
          name: items[index].name,
          pomodoroMinutes: items[index].pomodoroMinutes,
          shortBreakMinutes: items[index].shortBreakMinutes,
          longBreakMinutes: items[index].longBreakMinutes,
          totalPomodoros: items[index].totalPomodoros,
          longBreakInterval: items[index].longBreakInterval,
          order: index,
          presetId: items[index].presetId,
          startSound: items[index].startSound,
          startBreakSound: items[index].startBreakSound,
          finishTaskSound: items[index].finishTaskSound,
          createdAt: now,
          updatedAt: now,
        ),
    ];
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

  Future<Duration?> _pickDuration(
    BuildContext context, {
    required Duration initial,
  }) async {
    final initialTime = TimeOfDay(
      hour: initial.inHours.clamp(0, 23),
      minute: initial.inMinutes.remainder(60),
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (picked == null) return null;
    return Duration(hours: picked.hour, minutes: picked.minute);
  }

  void _showSnackBar(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }
}

class _PlanPreview {
  final TaskGroupPlanOption option;
  final List<TaskRunItem> items;
  final DateTime? scheduledStart;
  final int totalDurationSeconds;
  final int? targetDurationSeconds;
  final String? error;

  const _PlanPreview({
    required this.option,
    required this.items,
    required this.scheduledStart,
    required this.totalDurationSeconds,
    this.targetDurationSeconds,
  }) : error = null;

  const _PlanPreview.error({
    required this.option,
    required this.items,
    required this.totalDurationSeconds,
    required String message,
  })  : error = message,
        scheduledStart = null,
        targetDurationSeconds = null;

  bool get isValid => error == null;

  int get shiftSeconds {
    if (targetDurationSeconds == null) return 0;
    final diff = targetDurationSeconds! - totalDurationSeconds;
    return diff > 0 ? diff : 0;
  }
}

class _RedistributionResult {
  final bool success;
  final List<TaskRunItem> items;
  final int actualDurationSeconds;
  final String? error;

  const _RedistributionResult.success({
    required this.items,
    required this.actualDurationSeconds,
  })  : success = true,
        error = null;

  const _RedistributionResult.failure(this.error)
      : success = false,
        items = const [],
        actualDurationSeconds = 0;
}

class _Allocation {
  final TaskRunItem item;
  final double targetPomodoros;
  int pomodoros;

  _Allocation({
    required this.item,
    required this.targetPomodoros,
    required this.pomodoros,
  });

  double get fraction {
    final floor = targetPomodoros.floor();
    return targetPomodoros - floor;
  }
}

class _RedistributionAttempt {
  final List<TaskRunItem> items;
  final int actualDurationSeconds;

  const _RedistributionAttempt({
    required this.items,
    required this.actualDurationSeconds,
  });
}

class _RedistributionSearch {
  final _RedistributionAttempt? bestWithinTime;
  final _RedistributionAttempt? bestWithinDeviation;

  const _RedistributionSearch({
    required this.bestWithinTime,
    required this.bestWithinDeviation,
  });
}

class _OptionCard extends StatelessWidget {
  final String title;
  final String description;
  final bool selected;
  final VoidCallback? onTap;
  final Widget? footer;

  const _OptionCard({
    required this.title,
    required this.description,
    required this.selected,
    this.onTap,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final background = selected ? Colors.white12 : Colors.white10;
    final border = selected ? Colors.white54 : Colors.white24;
    const textColor = Colors.white;
    const subtitleColor = Colors.white70;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: TextStyle(color: subtitleColor, height: 1.35),
            ),
            if (footer != null) ...[
              const SizedBox(height: 10),
              footer!,
            ],
          ],
        ),
      ),
    );
  }
}

class _SchedulePickerRow extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _SchedulePickerRow({
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white70),
          ),
        ),
        TextButton(
          onPressed: onPressed,
          child: const Text('Edit'),
        ),
      ],
    );
  }
}
