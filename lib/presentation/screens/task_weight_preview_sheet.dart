import 'package:flutter/material.dart';

import '../../data/models/pomodoro_task.dart';
import '../../domain/continuous_plan_load.dart';
import '../../domain/task_weighting.dart';
import '../utils/continuous_plan_load_ui.dart';
import '../viewmodels/task_editor_view_model.dart';

enum TaskWeightField { percent, pomodoros }

typedef WeightPreviewComputer =
    Map<String, int> Function(int value, WeightEditMode mode);

enum _BackDecision { apply, discard, continueEdit }

class TaskWeightPreviewSheet extends StatefulWidget {
  const TaskWeightPreviewSheet({
    super.key,
    required this.editedTask,
    required this.baselineTasks,
    required this.isGroupContext,
    required this.field,
    required this.computePreview,
    required this.onApply,
  });

  final PomodoroTask editedTask;
  final List<PomodoroTask> baselineTasks;
  final bool isGroupContext;
  final TaskWeightField field;
  final WeightPreviewComputer computePreview;
  final void Function(Map<String, int> result) onApply;

  @override
  State<TaskWeightPreviewSheet> createState() => _TaskWeightPreviewSheetState();
}

class _TaskWeightPreviewSheetState extends State<TaskWeightPreviewSheet> {
  static const int _warningThreshold = 10;
  static const double _titleTextLeftInset = 38;
  static const double _metricLabelWidth = 92;
  static const double _metricChipWidth = 84;

  late final TextEditingController _inputCtrl;
  late final int _openingInputValue;
  WeightEditMode _mode = WeightEditMode.fixed;
  Map<String, int>? _result;
  String? _warningMessage;
  int? _requestedValue;
  bool _hasUserInteracted = false;
  bool _allowPop = false;
  bool _handlingBackFlow = false;

  bool get _singleTask => widget.baselineTasks.length <= 1;
  String get _scopeLabel => widget.isGroupContext ? 'Group' : 'Task';

  String get _modeExplanation {
    if (_mode == WeightEditMode.fixed) {
      return 'Fixed total: if you apply, the closest achievable result is '
          'used. To keep selected-group totals as close as possible, other '
          'selected tasks are redistributed proportionally.';
    }
    return 'Flexible total: keeps other selected tasks unchanged and updates '
        'only this task, so selected-group total may change.';
  }

  @override
  void initState() {
    super.initState();
    _openingInputValue = _initialInputValue();
    _inputCtrl = TextEditingController(text: _openingInputValue.toString());
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

  bool _isExactResult({
    required int requested,
    required int resultPercent,
    required int resultPomodoros,
  }) {
    if (widget.field == TaskWeightField.percent) {
      return resultPercent == requested;
    }
    return resultPomodoros == requested;
  }

  bool _isAtOpeningSnapshot({
    required int requested,
    required Map<String, int> result,
  }) {
    if (requested != _openingInputValue) return false;
    return !_hasChange(result);
  }

  String _exactMessage({
    required int resultPercent,
    required int resultPomodoros,
  }) {
    if (widget.field == TaskWeightField.percent) {
      return 'Exact result: $resultPercent%';
    }
    return 'Exact result: $resultPomodoros pomodoros';
  }

  String _formatWorkMinutes(int minutes) {
    if (minutes <= 59) {
      return '$minutes min';
    }
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return '${hours}h ${remainingMinutes}m';
  }

  int _continuousDurationSecondsForTasks(List<PomodoroTask> tasks) {
    if (tasks.isEmpty) return 0;
    if (widget.isGroupContext) {
      return continuousGroupDurationSecondsForTasks(tasks);
    }
    final durations = continuousTaskDurationsSecondsForTasks(tasks);
    return durations.isEmpty ? 0 : durations.first;
  }

  String _formatDurationSeconds(int seconds) {
    final minutes = seconds <= 0 ? 0 : (seconds ~/ 60);
    return _formatWorkMinutes(minutes);
  }

  Widget _buildValueChip({
    required String value,
    required Color borderColor,
    required Color textColor,
    Color? backgroundColor,
    double borderWidth = 1.2,
  }) {
    return SizedBox(
      width: _metricChipWidth,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: borderColor, width: borderWidth),
        ),
        child: Text(
          value,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildMetricRow({
    required String label,
    required String beforeValue,
    required String afterValue,
    required bool highlightBefore,
    required bool highlightAfter,
    required bool emphasizeAfter,
    required Color resultAccent,
  }) {
    const baseBorder = Colors.white38;
    const baseText = Colors.white70;
    final beforeBorder = highlightBefore ? Colors.white60 : baseBorder;
    final beforeText = highlightBefore ? Colors.white : baseText;
    final beforeFill = highlightBefore
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.transparent;
    final beforeBorderWidth = highlightBefore ? 1.6 : 1.2;
    final afterBorder = highlightAfter ? resultAccent : baseBorder;
    final afterText = highlightAfter ? resultAccent : baseText;
    final afterFill = highlightAfter
        ? resultAccent.withValues(alpha: emphasizeAfter ? 0.16 : 0.08)
        : null;
    final afterBorderWidth = highlightAfter
        ? (emphasizeAfter ? 2.0 : 1.2)
        : 1.2;

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          SizedBox(
            width: _metricLabelWidth,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
          _buildValueChip(
            value: beforeValue,
            borderColor: beforeBorder,
            textColor: beforeText,
            backgroundColor: beforeFill,
            borderWidth: beforeBorderWidth,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Icon(Icons.arrow_forward, size: 15, color: Colors.white54),
          ),
          _buildValueChip(
            value: afterValue,
            borderColor: afterBorder,
            textColor: afterText,
            backgroundColor: afterFill,
            borderWidth: afterBorderWidth,
          ),
        ],
      ),
    );
  }

  void _recalculate() {
    final parsed = int.tryParse(_inputCtrl.text.trim());
    if (parsed == null || parsed <= 0) {
      if (_requestedValue != null ||
          _result != null ||
          _warningMessage != null) {
        setState(() {
          _requestedValue = null;
          _result = null;
          _warningMessage = null;
        });
      }
      return;
    }
    if (widget.field == TaskWeightField.percent && parsed > 100) {
      if (_requestedValue != parsed ||
          _result != null ||
          _warningMessage != null) {
        setState(() {
          _requestedValue = parsed;
          _result = null;
          _warningMessage = null;
        });
      }
      return;
    }

    final mode = _singleTask ? WeightEditMode.fixed : _mode;
    try {
      final computed = widget.computePreview(parsed, mode);
      final resultTasks = _resultTasks(computed);
      final resultPercents = normalizeTaskWeightPercents(resultTasks);
      final resultPercent = resultPercents[widget.editedTask.id] ?? 0;
      final resultPomodoros =
          computed[widget.editedTask.id] ?? widget.editedTask.totalPomodoros;
      final exact = _isExactResult(
        requested: parsed,
        resultPercent: resultPercent,
        resultPomodoros: resultPomodoros,
      );
      final warning =
          (_hasUserInteracted &&
              !_isAtOpeningSnapshot(requested: parsed, result: computed))
          ? _buildPrecisionMessage(
              requested: parsed,
              result: computed,
              resultTasks: resultTasks,
            )
          : null;
      setState(() {
        _requestedValue = parsed;
        _result = computed;
        _warningMessage = exact ? null : warning;
      });
    } catch (_) {
      setState(() {
        _requestedValue = parsed;
        _result = null;
        _warningMessage = null;
      });
    }
  }

  bool get _hasUnappliedChanges {
    final raw = _inputCtrl.text.trim();
    final parsed = int.tryParse(raw);
    final invalid =
        parsed == null ||
        parsed <= 0 ||
        (widget.field == TaskWeightField.percent && parsed > 100);
    if (invalid) {
      return _hasUserInteracted && raw != _openingInputValue.toString();
    }
    final result = _result;
    if (result == null) return false;
    return !_isAtOpeningSnapshot(requested: parsed, result: result);
  }

  void _showNoChangesMadeHint() {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      const SnackBar(
        content: Text('No changes made.'),
        duration: Duration(milliseconds: 1300),
      ),
    );
  }

  void _showChangesAppliedHint() {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      const SnackBar(
        content: Text('Changes applied.'),
        duration: Duration(milliseconds: 1300),
      ),
    );
  }

  void _closeSheet() {
    setState(() {
      _allowPop = true;
    });
    Navigator.of(context).pop();
  }

  void _applyAndClose() {
    final result = _result;
    if (result == null) return;
    final hadChanges = _hasUnappliedChanges;
    widget.onApply(result);
    _closeSheet();
    if (hadChanges) {
      _showChangesAppliedHint();
    } else {
      _showNoChangesMadeHint();
    }
  }

  String _pendingChangeSummary() {
    final result = _result;
    if (result == null) {
      return 'Current input is invalid and cannot be applied yet.';
    }
    final resultTasks = _resultTasks(result);
    final baselinePercents = normalizeTaskWeightPercents(widget.baselineTasks);
    final resultPercents = normalizeTaskWeightPercents(resultTasks);
    final beforePom = widget.editedTask.totalPomodoros;
    final afterPom = result[widget.editedTask.id] ?? beforePom;
    final beforeWeight = baselinePercents[widget.editedTask.id] ?? 0;
    final afterWeight = resultPercents[widget.editedTask.id] ?? beforeWeight;
    if (widget.field == TaskWeightField.percent) {
      return 'Task weight: $beforeWeight% → $afterWeight%\n'
          'Total pomodoros: $beforePom → $afterPom';
    }
    return 'Total pomodoros: $beforePom → $afterPom\n'
        'Task weight: $beforeWeight% → $afterWeight%';
  }

  Future<void> _confirmDiscardOrApply() async {
    final canApply = _result != null;
    final decision = await showDialog<_BackDecision>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unapplied changes'),
        content: Text('${_pendingChangeSummary()}\n\nApply before leaving?'),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(_BackDecision.continueEdit),
            child: const Text('Continue editing'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(_BackDecision.discard),
            child: const Text('Discard and close'),
          ),
          if (canApply)
            FilledButton(
              onPressed: () => Navigator.of(context).pop(_BackDecision.apply),
              child: const Text('Apply and close'),
            ),
        ],
      ),
    );
    if (!mounted) return;
    switch (decision) {
      case _BackDecision.apply:
        _applyAndClose();
        break;
      case _BackDecision.discard:
        _closeSheet();
        break;
      case _BackDecision.continueEdit:
      case null:
        break;
    }
  }

  Future<void> _handleBackPressed() async {
    if (_handlingBackFlow) return;
    _handlingBackFlow = true;
    try {
      if (_hasUnappliedChanges) {
        await _confirmDiscardOrApply();
        return;
      }
      _closeSheet();
      _showNoChangesMadeHint();
    } finally {
      _handlingBackFlow = false;
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
    final baselineContinuousSeconds = _continuousDurationSecondsForTasks(
      baselineTasks,
    );
    final resultContinuousSeconds = _continuousDurationSecondsForTasks(
      resultTasks,
    );
    final continuousSeconds = resultContinuousSeconds;
    final continuousLevel = continuousPlanLoadLevelForSeconds(
      continuousSeconds,
    );
    final continuousVisual = continuousPlanLoadVisualForLevel(continuousLevel);
    final continuousMessage = continuousPlanLoadMessage(continuousLevel);
    final showContinuousCaution =
        result != null &&
        continuousLevel != ContinuousPlanLoadLevel.none &&
        continuousVisual != null &&
        continuousMessage != null;
    final hasValidResult = result != null && _requestedValue != null;
    final isExact = hasValidResult
        ? _isExactResult(
            requested: _requestedValue!,
            resultPercent: editedResultPercent,
            resultPomodoros: editedResultPom,
          )
        : false;
    final resultAccent = isExact
        ? Colors.lightGreenAccent
        : Colors.orangeAccent;
    final highlightPomodoros = widget.field == TaskWeightField.pomodoros;
    final highlightWeight = widget.field == TaskWeightField.percent;

    final title = widget.field == TaskWeightField.percent
        ? 'Edit Task weight'
        : 'Edit Total pomodoros';
    final totalPomodorosLabel = '$_scopeLabel total pomodoros';
    final workLabel = '$_scopeLabel work';
    final totalDurationLabel = widget.isGroupContext
        ? 'Total group duration'
        : 'Total task duration';

    return AnimatedPadding(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: FractionallySizedBox(
        heightFactor: 1.0,
        child: PopScope(
          canPop: _allowPop,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            Future<void>(() async {
              if (!mounted) return;
              await _handleBackPressed();
            });
          },
          child: Material(
            color: Colors.black,
            child: SafeArea(
              top: true,
              bottom: false,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                onPressed: _handleBackPressed,
                                icon: const Icon(Icons.arrow_back),
                                color: Colors.white,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints.tightFor(
                                  width: 28,
                                  height: 28,
                                ),
                                splashRadius: 18,
                                tooltip: 'Back',
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed:
                                    (result == null || !_hasUnappliedChanges)
                                    ? null
                                    : _applyAndClose,
                                child: const Text(
                                  'Apply',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.only(
                              left: _titleTextLeftInset,
                            ),
                            child: Text(
                              widget.editedTask.name,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _inputCtrl,
                            onChanged: (_) {
                              if (_hasUserInteracted) return;
                              setState(() {
                                _hasUserInteracted = true;
                              });
                            },
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: widget.field == TaskWeightField.percent
                                  ? 'Task weight (%)'
                                  : 'Total pomodoros',
                              suffixText:
                                  widget.field == TaskWeightField.percent
                                  ? '%'
                                  : null,
                              labelStyle: const TextStyle(
                                color: Colors.white54,
                              ),
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
                                  _hasUserInteracted = true;
                                });
                                _recalculate();
                              },
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white10,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: Text(
                                _modeExplanation,
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          if (hasValidResult && isExact) ...[
                            Text(
                              _exactMessage(
                                resultPercent: editedResultPercent,
                                resultPomodoros: editedResultPom,
                              ),
                              style: const TextStyle(
                                color: Colors.lightGreenAccent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          if (_warningMessage != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              _warningMessage!,
                              style: const TextStyle(
                                color: Colors.orangeAccent,
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),
                          Text(
                            '$totalPomodorosLabel: $baselineGroupPom → $resultGroupPom',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          Text(
                            '$workLabel: ${_formatWorkMinutes(baselineGroupMin)} → ${_formatWorkMinutes(resultGroupMin)}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          Text(
                            '$totalDurationLabel: ${_formatDurationSeconds(baselineContinuousSeconds)} → ${_formatDurationSeconds(resultContinuousSeconds)}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          if (showContinuousCaution) ...[
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  continuousVisual.icon,
                                  size: 18,
                                  color: continuousVisual.color,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    continuousMessage,
                                    style: TextStyle(
                                      color: continuousVisual.color,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
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
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.fromLTRB(
                                  12,
                                  10,
                                  12,
                                  10,
                                ),
                                decoration: BoxDecoration(
                                  color: task.id == widget.editedTask.id
                                      ? Colors.white12
                                      : Colors.white10,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: task.id == widget.editedTask.id
                                        ? Colors.white54
                                        : Colors.white24,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      task.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    _buildMetricRow(
                                      label: 'Pomodoros',
                                      beforeValue: '${task.totalPomodoros}',
                                      afterValue:
                                          '${result?[task.id] ?? task.totalPomodoros}',
                                      highlightBefore:
                                          task.id == widget.editedTask.id &&
                                          highlightPomodoros,
                                      highlightAfter:
                                          highlightPomodoros && hasValidResult,
                                      emphasizeAfter:
                                          task.id == widget.editedTask.id &&
                                          highlightPomodoros &&
                                          hasValidResult,
                                      resultAccent: resultAccent,
                                    ),
                                    _buildMetricRow(
                                      label: 'Weight',
                                      beforeValue:
                                          '${baselinePercents[task.id] ?? 0}%',
                                      afterValue:
                                          '${resultPercents[task.id] ?? 0}%',
                                      highlightBefore:
                                          task.id == widget.editedTask.id &&
                                          highlightWeight,
                                      highlightAfter:
                                          highlightWeight && hasValidResult,
                                      emphasizeAfter:
                                          task.id == widget.editedTask.id &&
                                          highlightWeight &&
                                          hasValidResult,
                                      resultAccent: resultAccent,
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
