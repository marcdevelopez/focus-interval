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

  const TaskGroupPlanningResult({
    required this.option,
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
  static final DateFormat _timeFormat = DateFormat('HH:mm');

  TaskGroupPlanOption _selected = TaskGroupPlanOption.startNow;
  DateTime? _scheduledStart;
  bool _infoDialogVisible = false;

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
                      'The group is redistributed to fit the range (coming soon).',
                      style: TextStyle(color: Colors.white70, height: 1.4),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '• Schedule by total time: choose a start time and a duration. '
                      'The group is redistributed to fit the duration (coming soon).',
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

  Future<void> _selectOption(TaskGroupPlanOption option) async {
    if (option == TaskGroupPlanOption.scheduleStart) {
      await _selectScheduleStart();
      return;
    }
    if (!_isOptionEnabled(option)) return;
    setState(() {
      _selected = option;
    });
  }

  bool _isOptionEnabled(TaskGroupPlanOption option) {
    return option == TaskGroupPlanOption.startNow ||
        option == TaskGroupPlanOption.scheduleStart;
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.args.items;
    final integrityMode = widget.args.integrityMode;
    final anchor = widget.args.planningAnchor;
    final durations = _previewRunItemDurations(items, integrityMode);
    final totalSeconds = durations.fold<int>(0, (sum, value) => sum + value);
    final startTime = _selected == TaskGroupPlanOption.scheduleStart
        ? _scheduledStart
        : anchor;
    final groupStartLabel =
        startTime == null ? '--:--' : _timeFormat.format(startTime);
    final groupEndLabel = startTime == null
        ? '--:--'
        : _timeFormat
            .format(startTime.add(Duration(seconds: totalSeconds)));
    final ranges = startTime == null
        ? <int, String>{}
        : _buildTimeRanges(durations, startTime);
    final weightTotal = _weightTotal(items);
    final previewTasks = _previewTasks(items);

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
            selected: false,
            enabled: false,
            footer: const _ComingSoonLabel(),
          ),
          const SizedBox(height: 10),
          _OptionCard(
            title: 'Schedule by total time',
            description: 'Fit the group within a target duration.',
            selected: false,
            enabled: false,
            footer: const _ComingSoonLabel(),
          ),
          const SizedBox(height: 20),
          _sectionHeader('Group preview'),
          const SizedBox(height: 8),
          _groupTimeRow(groupStartLabel, groupEndLabel),
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
                items[index],
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
                onPressed: _canConfirm() ? _handleConfirm : null,
                child: const Text('Confirm'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canConfirm() {
    if (_selected == TaskGroupPlanOption.scheduleStart) {
      return _scheduledStart != null;
    }
    return _selected == TaskGroupPlanOption.startNow;
  }

  void _handleConfirm() {
    if (_selected == TaskGroupPlanOption.scheduleStart &&
        _scheduledStart == null) {
      return;
    }
    Navigator.of(context).pop(
      TaskGroupPlanningResult(
        option: _selected,
        scheduledStart: _scheduledStart,
      ),
    );
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
    return '${DateFormat('MMM d').format(value)} · ${_timeFormat.format(value)}';
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

  List<int> _previewRunItemDurations(
    List<TaskRunItem> items,
    TaskRunIntegrityMode integrityMode,
  ) {
    if (items.isEmpty) return const [];
    if (integrityMode == TaskRunIntegrityMode.individual) {
      return [
        for (var index = 0; index < items.length; index += 1)
          items[index].durationSeconds(
            includeFinalBreak: index < items.length - 1,
          ),
      ];
    }

    final master = items.first;
    final pomodoroSeconds = master.pomodoroMinutes * 60;
    final shortBreakSeconds = master.shortBreakMinutes * 60;
    final longBreakSeconds = master.longBreakMinutes * 60;
    final totalPomodoros = items.fold<int>(
      0,
      (total, item) => total + item.totalPomodoros,
    );
    if (totalPomodoros <= 0) {
      return List<int>.filled(items.length, 0);
    }

    final durations = <int>[];
    var globalIndex = 0;
    for (final item in items) {
      var taskTotal = 0;
      for (var localIndex = 0;
          localIndex < item.totalPomodoros;
          localIndex += 1) {
        globalIndex += 1;
        taskTotal += pomodoroSeconds;
        if (globalIndex >= totalPomodoros) {
          continue;
        }
        final isLongBreak = globalIndex % master.longBreakInterval == 0;
        taskTotal += isLongBreak ? longBreakSeconds : shortBreakSeconds;
      }
      durations.add(taskTotal);
    }
    return durations;
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
}

class _OptionCard extends StatelessWidget {
  final String title;
  final String description;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;
  final Widget? footer;

  const _OptionCard({
    required this.title,
    required this.description,
    required this.selected,
    this.enabled = true,
    this.onTap,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final background = selected ? Colors.white12 : Colors.white10;
    final border = selected ? Colors.white54 : Colors.white24;
    final textColor = enabled ? Colors.white : Colors.white38;
    final subtitleColor = enabled ? Colors.white70 : Colors.white30;

    return GestureDetector(
      onTap: enabled ? onTap : null,
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

class _ComingSoonLabel extends StatelessWidget {
  const _ComingSoonLabel();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white24),
        ),
        child: const Text(
          'Coming soon',
          style: TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ),
    );
  }
}
