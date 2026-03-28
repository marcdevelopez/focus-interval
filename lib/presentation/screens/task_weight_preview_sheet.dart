import 'package:flutter/material.dart';

import '../../data/models/pomodoro_task.dart';
import '../../domain/task_weighting.dart';
import '../viewmodels/task_editor_view_model.dart';

enum TaskWeightField { percent, pomodoros }

typedef WeightPreviewComputer =
    Map<String, int> Function(int value, WeightEditMode mode);

class TaskWeightPreviewSheet extends StatefulWidget {
  const TaskWeightPreviewSheet({
    super.key,
    required this.editedTask,
    required this.baselineTasks,
    required this.field,
    required this.computePreview,
    required this.onApply,
  });

  final PomodoroTask editedTask;
  final List<PomodoroTask> baselineTasks;
  final TaskWeightField field;
  final WeightPreviewComputer computePreview;
  final void Function(Map<String, int> result) onApply;

  @override
  State<TaskWeightPreviewSheet> createState() => _TaskWeightPreviewSheetState();
}

class _TaskWeightPreviewSheetState extends State<TaskWeightPreviewSheet> {
  static const int _warningThreshold = 10;

  late final TextEditingController _inputCtrl;
  WeightEditMode _mode = WeightEditMode.fixed;
  Map<String, int>? _result;
  String? _precisionMessage;
  int? _requestedValue;

  bool get _singleTask => widget.baselineTasks.length <= 1;

  @override
  void initState() {
    super.initState();
    final initialValue = _initialInputValue();
    _inputCtrl = TextEditingController(text: initialValue.toString());
    _inputCtrl.addListener(_recalculate);
    _recalculate();
  }

  @override
  void dispose() {
    _inputCtrl.removeListener(_recalculate);
    _inputCtrl.dispose();
    super.dispose();
  }

  int _initialInputValue() {
    if (widget.field == TaskWeightField.pomodoros) {
      return widget.editedTask.totalPomodoros;
    }
    final percents = normalizeTaskWeightPercents(widget.baselineTasks);
    return percents[widget.editedTask.id] ?? 100;
  }

  List<PomodoroTask> _resultTasks(Map<String, int> result) {
    if (widget.baselineTasks.isEmpty) {
      return [
        widget.editedTask.copyWith(
          totalPomodoros:
              result[widget.editedTask.id] ?? widget.editedTask.totalPomodoros,
        ),
      ];
    }
    return [
      for (final task in widget.baselineTasks)
        task.copyWith(totalPomodoros: result[task.id] ?? task.totalPomodoros),
    ];
  }

  int _groupPomodoros(List<PomodoroTask> tasks) {
    return tasks.fold<int>(0, (sum, task) => sum + task.totalPomodoros);
  }

  int _groupMinutes(List<PomodoroTask> tasks) {
    return tasks.fold<int>(
      0,
      (sum, task) => sum + (task.totalPomodoros * task.pomodoroMinutes),
    );
  }

  bool _hasChange(Map<String, int> result) {
    for (final task in widget.baselineTasks) {
      final updated = result[task.id] ?? task.totalPomodoros;
      if (updated != task.totalPomodoros) return true;
    }
    return false;
  }

  String? _buildPrecisionMessage({
    required int requested,
    required Map<String, int> result,
    required List<PomodoroTask> resultTasks,
  }) {
    final changed = _hasChange(result);
    final resultPercents = normalizeTaskWeightPercents(resultTasks);
    final resultPercent = resultPercents[widget.editedTask.id] ?? 0;
    final resultPomodoros =
        result[widget.editedTask.id] ?? widget.editedTask.totalPomodoros;

    if (!changed) {
      return 'No change possible with current total pomodoros. Pomodoros are '
          'indivisible—add more pomodoros or tasks for finer weights.';
    }

    if (widget.field == TaskWeightField.percent) {
      final deviation = (resultPercent - requested).abs();
      if (deviation >= _warningThreshold) {
        return 'Exact result is not possible because pomodoros are indivisible. '
            'Closest achievable: $resultPercent%.';
      }
      if (resultPercent != requested) {
        return 'Closest achievable result: $resultPercent%.';
      }
      return null;
    }

    if (resultPomodoros != requested) {
      return 'Exact result is not possible because pomodoros are indivisible. '
          'Closest achievable: $resultPomodoros pomodoros.';
    }
    return null;
  }

  void _recalculate() {
    final parsed = int.tryParse(_inputCtrl.text.trim());
    if (parsed == null || parsed <= 0) {
      if (_requestedValue != null ||
          _result != null ||
          _precisionMessage != null) {
        setState(() {
          _requestedValue = null;
          _result = null;
          _precisionMessage = null;
        });
      }
      return;
    }
    if (widget.field == TaskWeightField.percent && parsed > 100) {
      if (_requestedValue != parsed ||
          _result != null ||
          _precisionMessage != null) {
        setState(() {
          _requestedValue = parsed;
          _result = null;
          _precisionMessage = null;
        });
      }
      return;
    }

    final mode = _singleTask ? WeightEditMode.fixed : _mode;
    try {
      final computed = widget.computePreview(parsed, mode);
      final resultTasks = _resultTasks(computed);
      final precision = _buildPrecisionMessage(
        requested: parsed,
        result: computed,
        resultTasks: resultTasks,
      );
      setState(() {
        _requestedValue = parsed;
        _result = computed;
        _precisionMessage = precision;
      });
    } catch (_) {
      setState(() {
        _requestedValue = parsed;
        _result = null;
        _precisionMessage = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final baselineTasks = widget.baselineTasks;
    final baselinePercents = normalizeTaskWeightPercents(baselineTasks);
    final result = _result;
    final resultTasks = result == null ? baselineTasks : _resultTasks(result);
    final resultPercents = normalizeTaskWeightPercents(resultTasks);
    final baselineGroupPom = _groupPomodoros(baselineTasks);
    final resultGroupPom = _groupPomodoros(resultTasks);
    final baselineGroupMin = _groupMinutes(baselineTasks);
    final resultGroupMin = _groupMinutes(resultTasks);
    final editedResultPom =
        result?[widget.editedTask.id] ?? widget.editedTask.totalPomodoros;
    final editedResultPercent = resultPercents[widget.editedTask.id] ?? 0;

    final title = widget.field == TaskWeightField.percent
        ? 'Edit Task weight'
        : 'Edit Total pomodoros';

    return AnimatedPadding(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: FractionallySizedBox(
        heightFactor: 1.0,
        child: Material(
          color: Colors.black,
          child: SafeArea(
            top: true,
            bottom: false,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextButton.icon(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back, size: 18),
                          label: const Text('Back'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 32),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            alignment: Alignment.centerLeft,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.editedTask.name,
                          style: const TextStyle(color: Colors.white54),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _inputCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: widget.field == TaskWeightField.percent
                                ? 'Task weight (%)'
                                : 'Total pomodoros',
                            suffixText: widget.field == TaskWeightField.percent
                                ? '%'
                                : null,
                            labelStyle: const TextStyle(color: Colors.white54),
                            filled: true,
                            fillColor: Colors.white10,
                            enabledBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white24),
                            ),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white54),
                            ),
                            errorText: _requestedValue == null
                                ? 'Enter a valid number'
                                : (widget.field == TaskWeightField.percent &&
                                      _requestedValue! > 100)
                                ? 'Max 100%'
                                : null,
                          ),
                        ),
                        if (!_singleTask) ...[
                          const SizedBox(height: 12),
                          SegmentedButton<WeightEditMode>(
                            segments: const [
                              ButtonSegment<WeightEditMode>(
                                value: WeightEditMode.fixed,
                                label: Text('Fixed total'),
                              ),
                              ButtonSegment<WeightEditMode>(
                                value: WeightEditMode.flexible,
                                label: Text('Flexible total'),
                              ),
                            ],
                            selected: {_mode},
                            onSelectionChanged: (selection) {
                              if (selection.isEmpty) return;
                              setState(() {
                                _mode = selection.first;
                              });
                              _recalculate();
                            },
                          ),
                        ],
                        const SizedBox(height: 16),
                        Text(
                          'Requested: ${_requestedValue ?? '—'}${widget.field == TaskWeightField.percent ? '%' : ''}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        Text(
                          'Closest achievable: '
                          '${widget.field == TaskWeightField.percent ? '$editedResultPercent%' : '$editedResultPom pomodoros'}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        Text(
                          'Result: $editedResultPom pomodoros · $editedResultPercent%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_precisionMessage != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _precisionMessage!,
                            style: const TextStyle(color: Colors.orangeAccent),
                          ),
                        ],
                        const SizedBox(height: 14),
                        Text(
                          'Group total pomodoros: $baselineGroupPom → $resultGroupPom',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        Text(
                          'Group work: $baselineGroupMin min → $resultGroupMin min',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        if (!_singleTask) ...[
                          const SizedBox(height: 14),
                          const Text(
                            'Selected tasks',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          for (final task in baselineTasks)
                            Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: task.id == widget.editedTask.id
                                    ? Colors.white12
                                    : Colors.white10,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: task.id == widget.editedTask.id
                                      ? Colors.white38
                                      : Colors.white24,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    task.name,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Pomodoros: ${task.totalPomodoros} → '
                                    '${result?[task.id] ?? task.totalPomodoros}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),
                                  Text(
                                    'Weight: ${baselinePercents[task.id] ?? 0}% → '
                                    '${resultPercents[task.id] ?? 0}%',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
                const Divider(color: Colors.white24, height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: result == null
                              ? null
                              : () {
                                  widget.onApply(result);
                                  Navigator.of(context).pop();
                                },
                          child: const Text('Apply'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
