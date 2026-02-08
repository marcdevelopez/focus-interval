import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/pomodoro_task.dart';
import '../../data/models/task_run_group.dart';
import '../../domain/task_group_planner.dart';
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
  bool _shiftNoticeSuppressed = false;
  bool _shiftNoticePrefLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowInfoDialog();
      _loadShiftNoticePreference();
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

  Future<void> _loadShiftNoticePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool(_shiftNoticeKey) ?? false;
    if (!mounted) return;
    setState(() {
      _shiftNoticeSuppressed = seen;
      _shiftNoticePrefLoaded = true;
    });
  }

  Future<void> _setShiftNoticeSuppressed(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_shiftNoticeKey, value);
  }

  Future<void> _selectScheduleStart() async {
    final picked = await _pickScheduleDateTime(
      context,
      initial: _scheduledStart ?? DateTime.now(),
      dateHelpText: 'Select start date',
      timeHelpText: 'Select start time',
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
    final start = await _pickScheduleDateTime(
      context,
      initial: initialStart,
      dateHelpText: 'Select range start date',
      timeHelpText: 'Select range start time',
    );
    if (!mounted) return;
    if (start == null) return;
    final initialEnd = _rangeEnd ?? start.add(const Duration(hours: 1));
    final end = await _pickScheduleDateTime(
      context,
      initial: initialEnd,
      dateHelpText: 'Select range end date',
      timeHelpText: 'Select range end time',
    );
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
      dateHelpText: 'Select start date',
      timeHelpText: 'Select start time',
    );
    if (!mounted) return;
    if (start == null) return;
    final duration = await _pickDuration(
      context,
      initial: _totalDuration ?? const Duration(hours: 1),
      timeHelpText: 'Select total duration',
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
    final showShiftNotice = shiftLabel != null &&
        _shiftNoticePrefLoaded &&
        !_shiftNoticeSuppressed;

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
          if (showShiftNotice) ...[
            const SizedBox(height: 6),
            _shiftNoticeBanner(shiftLabel),
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
        if (!isStartTimeInFuture(
          start: _scheduledStart!,
          now: DateTime.now(),
        )) {
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
        if (!isStartTimeInFuture(
          start: _rangeStart!,
          now: DateTime.now(),
        )) {
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
        final result = redistributeTaskGroup(
          items: items,
          integrityMode: integrityMode,
          targetDurationSeconds: targetSeconds,
        );
        if (!result.success) {
          return _PlanPreview.error(
            option: _selected,
            items: items,
            totalDurationSeconds: totalSeconds,
            message: result.message ?? 'Unable to fit the requested range.',
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
        if (!isStartTimeInFuture(
          start: _totalStart!,
          now: DateTime.now(),
        )) {
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
        final result = redistributeTaskGroup(
          items: items,
          integrityMode: integrityMode,
          targetDurationSeconds: targetSeconds,
        );
        if (!result.success) {
          return _PlanPreview.error(
            option: _selected,
            items: items,
            totalDurationSeconds: totalSeconds,
            message: result.message ?? 'Unable to fit the requested duration.',
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

  Widget _shiftNoticeBanner(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orangeAccent.withAlpha(24),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orangeAccent.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline,
                size: 16,
                color: Colors.orangeAccent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.orangeAccent,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Checkbox(
                value: false,
                onChanged: _handleShiftNoticeToggle,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              const Text(
                "Don't show again",
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleShiftNoticeToggle(bool? value) {
    if (value != true) return;
    setState(() {
      _shiftNoticeSuppressed = true;
    });
    _setShiftNoticeSuppressed(true);
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
    required String dateHelpText,
    required String timeHelpText,
  }) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: dateHelpText,
    );
    if (pickedDate == null) return null;
    if (!context.mounted) return null;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      helpText: timeHelpText,
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
    required String timeHelpText,
  }) async {
    final initialTime = TimeOfDay(
      hour: initial.inHours.clamp(0, 23),
      minute: initial.inMinutes.remainder(60),
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: timeHelpText,
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
