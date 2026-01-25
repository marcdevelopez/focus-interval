import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers.dart';
import '../viewmodels/task_editor_view_model.dart';
import '../../data/models/pomodoro_task.dart';
import '../../domain/validators.dart';
import '../../widgets/sound_selector.dart';
import '../../widgets/mode_indicator.dart';

class TaskEditorScreen extends ConsumerStatefulWidget {
  final bool isEditing;
  final String? taskId;

  const TaskEditorScreen({super.key, required this.isEditing, this.taskId});

  @override
  ConsumerState<TaskEditorScreen> createState() => _TaskEditorScreenState();
}

class _Dot extends StatelessWidget {
  final Color color;
  final double size;

  const _Dot({required this.color, this.size = 4});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _TaskEditorScreenState extends ConsumerState<TaskEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _shortBreakFieldKey = GlobalKey<FormFieldState<String>>();
  final _longBreakFieldKey = GlobalKey<FormFieldState<String>>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _pomodoroCtrl;
  late final TextEditingController _shortBreakCtrl;
  late final TextEditingController _longBreakCtrl;
  late final TextEditingController _totalPomodorosCtrl;
  late final TextEditingController _longBreakIntervalCtrl;
  String? _loadedTaskId;
  bool _intervalTouched = false;
  bool _breaksTouched = false;

  @override
  void initState() {
    super.initState();

    _nameCtrl = TextEditingController();
    _pomodoroCtrl = TextEditingController();
    _shortBreakCtrl = TextEditingController();
    _longBreakCtrl = TextEditingController();
    _totalPomodorosCtrl = TextEditingController();
    _longBreakIntervalCtrl = TextEditingController();

    final initial = ref.read(taskEditorProvider);
    if (initial != null) {
      _syncControllers(initial);
    }

    if (widget.isEditing && widget.taskId != null) {
      Future.microtask(() {
        _loadExisting();
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _pomodoroCtrl.dispose();
    _shortBreakCtrl.dispose();
    _longBreakCtrl.dispose();
    _totalPomodorosCtrl.dispose();
    _longBreakIntervalCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadExisting() async {
    final result = await ref
        .read(taskEditorProvider.notifier)
        .load(widget.taskId!);
    if (!mounted) return;

    if (result == TaskEditorLoadResult.notFound) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("The task no longer exists.")),
      );
      _exitEditor();
      return;
    }
    if (result == TaskEditorLoadResult.blockedByActiveSession) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Stop the running task before editing it."),
        ),
      );
      _exitEditor();
    }
  }

  void _exitEditor() {
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/tasks');
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = ref.watch(taskEditorProvider);
    final editor = ref.read(taskEditorProvider.notifier);
    final pomodoroDisplayName =
        editor.customDisplayName(SoundPickTarget.pomodoroStart);
    final breakDisplayName =
        editor.customDisplayName(SoundPickTarget.breakStart);
    final guidance = editor.breakGuidanceFor(task);
    final breakOrderInvalid = task != null &&
        !isBreakOrderValid(
          shortBreakMinutes: task.shortBreakMinutes,
          longBreakMinutes: task.longBreakMinutes,
        );
    final shortBlocking =
        breakOrderInvalid || (guidance?.shortExceedsPomodoro ?? false);
    final longBlocking =
        breakOrderInvalid || (guidance?.longExceedsPomodoro ?? false);
    final shortStatus = shortBlocking
        ? BreakDurationStatus.invalid
        : (guidance?.shortStatus ?? BreakDurationStatus.optimal);
    final longStatus = longBlocking
        ? BreakDurationStatus.invalid
        : (guidance?.longStatus ?? BreakDurationStatus.optimal);
    final breakAutovalidateMode =
        (_breaksTouched || shortBlocking || longBlocking)
            ? AutovalidateMode.always
            : AutovalidateMode.onUserInteraction;
    final pomodoroGuidance = task == null
        ? null
        : buildPomodoroDurationGuidance(minutes: task.pomodoroMinutes);
    final intervalInput = _parseIntervalInput();
    final intervalValue = task == null
        ? null
        : intervalInput ?? task.longBreakInterval;
    final intervalGuidance = task == null || intervalValue == null
        ? null
        : buildLongBreakIntervalGuidance(
            interval: intervalValue,
            totalPomodoros: task.totalPomodoros,
          );
    final intervalInvalid = _intervalTouched &&
        (intervalInput == null ||
            intervalInput < 1 ||
            intervalInput > maxLongBreakInterval);
    final shortHelper = guidance == null || shortBlocking
        ? null
        : 'Optimal range: ${guidance.shortRange.label} min';
    final longHelper = guidance == null || longBlocking
        ? null
        : 'Optimal range: ${guidance.longRange.label} min';
    final pomodoroHelper = pomodoroGuidance?.helperText;
    final pomodoroStatus =
        pomodoroGuidance?.status ?? PomodoroDurationStatus.optimal;
    final intervalHelper =
        intervalInvalid ? null : intervalGuidance?.helperText;
    final intervalStatus =
        intervalGuidance?.status ?? LongBreakIntervalStatus.optimal;
    _maybeSyncControllers(task);
    const pomodoroSounds = [
      SoundOption('default_chime', 'Chime (pomodoro start)'),
      SoundOption('default_chime_break', 'Chime (break start)'),
      SoundOption('default_chime_finish', 'Finish chime'),
    ];

    const breakSounds = [
      SoundOption('default_chime_break', 'Chime (break start)'),
      SoundOption('default_chime', 'Chime (pomodoro start)'),
      SoundOption('default_chime_finish', 'Finish chime'),
    ];

    if (task == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(widget.isEditing ? "Edit task" : "New task"),
        actions: [
          const ModeIndicatorAction(compact: true),
          TextButton(
            onPressed: () async {
              if (!_formKey.currentState!.validate()) return;
              if (!await _validateBusinessRules()) return;

              final saved = await ref.read(taskEditorProvider.notifier).save();
              if (!context.mounted) return;
              if (!saved) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Stop the running task before saving changes.",
                    ),
                  ),
                );
                return;
              }
              _exitEditor();
            },
            child: const Text("Save"),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _textField(
              label: "Task name",
              controller: _nameCtrl,
              onChanged: (v) => _update(task.copyWith(name: v)),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? "Required" : null,
            ),
            const SizedBox(height: 12),
            _numberField(
              label: "Total pomodoros",
              controller: _totalPomodorosCtrl,
              onChanged: (v) => _update(task.copyWith(totalPomodoros: v)),
              suffix: _totalPomodorosSuffix(),
              suffixMaxWidth: 32,
            ),
            _numberField(
              label: "Pomodoro duration (min)",
              controller: _pomodoroCtrl,
              onChanged: (v) {
                _update(task.copyWith(pomodoroMinutes: v));
                _revalidateBreakFields();
              },
              suffix: _pomodoroSuffix(task.pomodoroMinutes),
              suffixMaxWidth: 140,
              helperText: pomodoroHelper,
              helperColor: _pomodoroHelperColor(pomodoroStatus),
              borderColor: _pomodoroBorderColor(
                pomodoroStatus,
                focused: false,
              ),
              focusedBorderColor: _pomodoroBorderColor(
                pomodoroStatus,
                focused: true,
              ),
              helperMaxLines: 2,
              additionalValidator: (value) =>
                  _pomodoroRangeValidator(value),
              autovalidateMode: AutovalidateMode.onUserInteraction,
            ),
            _numberField(
              label: "Short break (min)",
              fieldKey: _shortBreakFieldKey,
              controller: _shortBreakCtrl,
              onChanged: (v) {
                if (!_breaksTouched) {
                  setState(() {
                    _breaksTouched = true;
                  });
                }
                _update(task.copyWith(shortBreakMinutes: v));
                _revalidateBreakFields();
              },
              suffix: _shortBreakSuffix(task.shortBreakMinutes),
              helperText: shortHelper,
              helperColor: _statusHelperColor(shortStatus),
              borderColor: _statusBorderColor(shortStatus, focused: false),
              focusedBorderColor: _statusBorderColor(shortStatus, focused: true),
              additionalValidator: (value) => _breakFieldValidator(
                value: value,
                label: 'Short break',
                orderField: BreakOrderField.shortBreak,
                otherController: _longBreakCtrl,
              ),
              autovalidateMode: breakAutovalidateMode,
            ),
            _numberField(
              label: "Long break (min)",
              fieldKey: _longBreakFieldKey,
              controller: _longBreakCtrl,
              onChanged: (v) {
                if (!_breaksTouched) {
                  setState(() {
                    _breaksTouched = true;
                  });
                }
                _update(task.copyWith(longBreakMinutes: v));
                _revalidateBreakFields();
              },
              suffix: _longBreakSuffix(task.longBreakMinutes),
              helperText: longHelper,
              helperColor: _statusHelperColor(longStatus),
              borderColor: _statusBorderColor(longStatus, focused: false),
              focusedBorderColor: _statusBorderColor(longStatus, focused: true),
              additionalValidator: (value) => _breakFieldValidator(
                value: value,
                label: 'Long break',
                orderField: BreakOrderField.longBreak,
                otherController: _shortBreakCtrl,
              ),
              autovalidateMode: breakAutovalidateMode,
            ),
            const SizedBox(height: 12),
            _numberField(
              label: "Pomodoros per long break",
              controller: _longBreakIntervalCtrl,
              onChanged: (v) => _update(task.copyWith(longBreakInterval: v)),
              onTextChanged: (raw) {
                if (!_intervalTouched) {
                  _intervalTouched = true;
                }
                if (int.tryParse(raw.trim()) == null) {
                  setState(() {});
                }
              },
              suffix: _intervalSuffix(intervalValue ?? task.longBreakInterval),
              suffixMaxWidth: 140,
              helperText: intervalHelper,
              helperColor: _intervalHelperColor(
                intervalStatus,
                isInvalid: intervalInvalid,
              ),
              borderColor: _intervalBorderColor(
                intervalStatus,
                focused: false,
                isInvalid: intervalInvalid,
              ),
              focusedBorderColor: _intervalBorderColor(
                intervalStatus,
                focused: true,
                isInvalid: intervalInvalid,
              ),
              helperMaxLines: 2,
              additionalValidator: _longBreakIntervalValidator,
              autovalidateMode: AutovalidateMode.onUserInteraction,
            ),
            const SizedBox(height: 24),
            const Text(
              "Sounds",
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 4),
            const Text(
              "Custom sounds are stored on this device only.",
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 8),
            SoundSelector(
              label: "Pomodoro start",
              value: task.startSound,
              options: pomodoroSounds,
              customDisplayName: pomodoroDisplayName,
              leading: const Icon(
                Icons.volume_up_rounded,
                color: Colors.redAccent,
                size: 16,
              ),
              onPickLocal: () async {
                final result = await ref
                    .read(taskEditorProvider.notifier)
                    .pickLocalSound(SoundPickTarget.pomodoroStart);
                if (!context.mounted) return;
                if (result.error != null) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(result.error!)));
                  return;
                }
                if (result.sound != null) {
                  _update(task.copyWith(startSound: result.sound));
                }
              },
              onChanged: (v) async {
                await ref
                    .read(taskEditorProvider.notifier)
                    .clearLocalSoundOverride(SoundPickTarget.pomodoroStart);
                _update(task.copyWith(startSound: v));
              },
            ),
            const SizedBox(height: 12),
            SoundSelector(
              label: "Break start",
              value: task.startBreakSound,
              options: breakSounds,
              customDisplayName: breakDisplayName,
              leading: const Icon(
                Icons.volume_up_rounded,
                color: Colors.blueAccent,
                size: 16,
              ),
              onPickLocal: () async {
                final result = await ref
                    .read(taskEditorProvider.notifier)
                    .pickLocalSound(SoundPickTarget.breakStart);
                if (!context.mounted) return;
                if (result.error != null) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(result.error!)));
                  return;
                }
                if (result.sound != null) {
                  _update(task.copyWith(startBreakSound: result.sound));
                }
              },
              onChanged: (v) async {
                await ref
                    .read(taskEditorProvider.notifier)
                    .clearLocalSoundOverride(SoundPickTarget.breakStart);
                _update(task.copyWith(startBreakSound: v));
              },
            ),
            const SizedBox(height: 12),
            Text(
              "End of all pomodoros",
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 4),
            const Text(
              "A default final sound will be used to avoid confusion.",
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  void _update(PomodoroTask updated) {
    ref.read(taskEditorProvider.notifier).update(updated);
  }

  void _revalidateBreakFields() {
    _shortBreakFieldKey.currentState?.validate();
    _longBreakFieldKey.currentState?.validate();
  }

  void _syncControllers(PomodoroTask task) {
    _loadedTaskId = task.id;
    _nameCtrl.text = task.name;
    _pomodoroCtrl.text = task.pomodoroMinutes.toString();
    _shortBreakCtrl.text = task.shortBreakMinutes.toString();
    _longBreakCtrl.text = task.longBreakMinutes.toString();
    _totalPomodorosCtrl.text = task.totalPomodoros.toString();
    _longBreakIntervalCtrl.text = task.longBreakInterval.toString();
    _intervalTouched = false;
    _breaksTouched = false;
  }

  void _maybeSyncControllers(PomodoroTask? task) {
    if (task == null) return;
    if (_loadedTaskId == task.id) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_loadedTaskId == task.id) return;
      _syncControllers(task);
    });
  }

  int? _parseIntervalInput() {
    final raw = _longBreakIntervalCtrl.text.trim();
    if (raw.isEmpty) return null;
    return int.tryParse(raw);
  }

  Future<bool> _validateBusinessRules() async {
    final task = ref.read(taskEditorProvider);
    if (task == null) return false;
    final guidance =
        ref.read(taskEditorProvider.notifier).breakGuidanceFor(task);
    if (guidance == null) return true;
    if (guidance.hasHardViolation) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Breaks must be shorter than the pomodoro duration "
            "(${task.pomodoroMinutes} min).",
          ),
        ),
      );
      return false;
    }
    if (!guidance.hasSoftWarning) return true;
    final shouldContinue = await _showBreakWarningDialog(task, guidance);
    return shouldContinue;
  }

  Future<bool> _showBreakWarningDialog(
    PomodoroTask task,
    BreakDurationGuidance guidance,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Break durations are outside the optimal range'),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                Text(
                  'For a ${task.pomodoroMinutes} min pomodoro, recommended '
                  'ranges are:',
                ),
                const SizedBox(height: 8),
                Text(
                  'Short break: ${guidance.shortRange.label} min '
                  '(current: ${task.shortBreakMinutes} min)',
                ),
                Text(
                  'Long break: ${guidance.longRange.label} min '
                  '(current: ${task.longBreakMinutes} min)',
                ),
                const SizedBox(height: 8),
                const Text('Do you want to save anyway?'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Adjust'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Save anyway'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  String? _breakMaxValidator({
    required int value,
    required int pomodoroMinutes,
    required String label,
  }) {
    if (pomodoroMinutes <= 0) return null;
    if (value >= pomodoroMinutes) {
      return '$label must be shorter than the pomodoro duration '
          '($pomodoroMinutes min).';
    }
    return null;
  }

  String? _breakFieldValidator({
    required int value,
    required String label,
    required BreakOrderField orderField,
    required TextEditingController otherController,
  }) {
    final pomodoroMinutes = _currentPomodoroMinutes();
    if (pomodoroMinutes == null) return null;
    final maxError = _breakMaxValidator(
      value: value,
      pomodoroMinutes: pomodoroMinutes,
      label: label,
    );
    if (maxError != null) return maxError;

    final otherValue = int.tryParse(otherController.text.trim());
    if (otherValue == null || otherValue <= 0) return null;

    final shortBreakMinutes = orderField == BreakOrderField.shortBreak
        ? value
        : otherValue;
    final longBreakMinutes = orderField == BreakOrderField.longBreak
        ? value
        : otherValue;

    return breakOrderError(
      shortBreakMinutes: shortBreakMinutes,
      longBreakMinutes: longBreakMinutes,
      field: orderField,
    );
  }

  int? _currentPomodoroMinutes() {
    final raw = _pomodoroCtrl.text.trim();
    final value = int.tryParse(raw);
    if (value == null || value <= 0) return null;
    return value;
  }

  String? _longBreakIntervalValidator(int value) {
    if (value > maxLongBreakInterval) {
      return 'Max $maxLongBreakInterval pomodoros. Longer cycles '
          'increase fatigue and reduce focus.';
    }
    return null;
  }

  Color _statusHelperColor(BreakDurationStatus status) {
    return switch (status) {
      BreakDurationStatus.optimal => Colors.greenAccent,
      BreakDurationStatus.suboptimal => Colors.orangeAccent,
      BreakDurationStatus.invalid => Colors.redAccent,
    };
  }

  Color _statusBorderColor(
    BreakDurationStatus status, {
    required bool focused,
  }) {
    if (status == BreakDurationStatus.optimal) {
      return focused ? Colors.white54 : Colors.white24;
    }
    final base = _statusHelperColor(status);
    return focused ? base : base.withValues(alpha: 0.6);
  }

  Future<void> _showLongBreakInfoDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Long break interval'),
          content: const Text(
            'The long break interval defines how many pomodoros you complete '
            'before taking a long break (15-30 min). If it is greater than the '
            'total pomodoros for the task, you will only take short breaks '
            '(5 min).',
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
  }

  Future<void> _showShortBreakInfoDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Short break duration'),
          content: const Text(
            'Short breaks are brief recovery pauses between pomodoros. '
            'Common practice is 3-7 minutes for a 25-minute pomodoro, '
            'roughly 15-25% of the work interval.',
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
  }

  Future<void> _showLongBreakDurationInfoDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Long break duration'),
          content: const Text(
            'Long breaks are longer recovery periods after several pomodoros. '
            'Common practice is 15-30 minutes for a 25-minute pomodoro, '
            'roughly 40-60% of the work interval.',
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
  }

  Future<void> _showTotalPomodorosInfoDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Total pomodoros'),
          content: const Text(
            'Total pomodoros is the number of work intervals in this task. '
            'It determines total duration and how many breaks you will take. '
            'Many workflows use 2-6 pomodoros per task; 4 is a classic cadence.',
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
  }

  Future<void> _showPomodoroInfoDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pomodoro duration'),
          content: const Text(
            'Pomodoro duration is the uninterrupted work time. Research '
            'suggests optimal focus in 20-45 minute blocks. Shorter durations '
            '(20-25) fit creative work; mid ranges (25-35) suit general tasks; '
            'longer ranges (35-45) support deep analytical work but require '
            'more mental effort.',
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
  }

  String? _pomodoroRangeValidator(int value) {
    if (value < 15) {
      return 'Pomodoro must be at least 15 minutes.';
    }
    if (value > 60) {
      return 'Pomodoro must be 60 minutes or less.';
    }
    return null;
  }

  Color _pomodoroHelperColor(PomodoroDurationStatus status) {
    return switch (status) {
      PomodoroDurationStatus.optimal => Colors.greenAccent,
      PomodoroDurationStatus.creative => Colors.lightGreenAccent,
      PomodoroDurationStatus.general => Colors.lightGreenAccent,
      PomodoroDurationStatus.deep => Colors.amberAccent,
      PomodoroDurationStatus.warning => Colors.orangeAccent,
      PomodoroDurationStatus.invalid => Colors.redAccent,
    };
  }

  Color _pomodoroBorderColor(
    PomodoroDurationStatus status, {
    required bool focused,
  }) {
    final base = _pomodoroHelperColor(status);
    return focused ? base : base.withValues(alpha: 0.6);
  }

  Color _intervalHelperColor(
    LongBreakIntervalStatus status, {
    required bool isInvalid,
  }) {
    if (isInvalid) return Colors.redAccent;
    return switch (status) {
      LongBreakIntervalStatus.optimal => Colors.greenAccent,
      LongBreakIntervalStatus.acceptable => Colors.amberAccent,
      LongBreakIntervalStatus.warning => Colors.orangeAccent,
    };
  }

  Color _intervalBorderColor(
    LongBreakIntervalStatus status, {
    required bool focused,
    required bool isInvalid,
  }) {
    final base = _intervalHelperColor(status, isInvalid: isInvalid);
    return focused ? base : base.withValues(alpha: 0.6);
  }

  Widget _textField({
    required String label,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      cursorColor: Colors.white,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: Colors.white10,
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white24),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white54),
        ),
      ),
    );
  }

  Widget _numberField({
    required String label,
    Key? fieldKey,
    required TextEditingController controller,
    required ValueChanged<int> onChanged,
    ValueChanged<String>? onTextChanged,
    Widget? suffix,
    String? helperText,
    Color? helperColor,
    Color? borderColor,
    Color? focusedBorderColor,
    String? Function(int value)? additionalValidator,
    double suffixMaxWidth = 84,
    int? helperMaxLines,
    int errorMaxLines = 2,
    AutovalidateMode? autovalidateMode,
  }) {
    return TextFormField(
      key: fieldKey,
      controller: controller,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: Colors.white),
      cursorColor: Colors.white,
      autovalidateMode: autovalidateMode,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: Colors.white10,
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: borderColor ?? Colors.white24),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: focusedBorderColor ?? Colors.white54),
        ),
        helperText: helperText,
        helperStyle: TextStyle(
          color: helperColor ?? Colors.white38,
          fontSize: 11,
        ),
        helperMaxLines: helperMaxLines,
        errorMaxLines: errorMaxLines,
        suffixIcon: suffix == null
            ? null
            : Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: suffixMaxWidth),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: suffix,
                  ),
                ),
              ),
        suffixIconConstraints: const BoxConstraints(
          minHeight: 42,
          minWidth: 28,
          maxWidth: 140,
        ),
      ),
      validator: (v) {
        final value = int.tryParse(v ?? '');
        if (value == null || value <= 0) {
          return "Enter a valid number";
        }
        final extraError = additionalValidator?.call(value);
        if (extraError != null) return extraError;
        return null;
      },
      onChanged: (v) {
        onTextChanged?.call(v);
        final value = int.tryParse(v);
        if (value == null) return;
        onChanged(value);
      },
    );
  }

  Widget _metricCircle({
    required String value,
    required Color color,
    required double stroke,
  }) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: stroke),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _intervalDotsCard(int interval) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12, width: 1),
      ),
      child: _intervalDots(interval),
    );
  }

  Widget _intervalSuffix(int interval) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _infoButton(
          tooltip: 'Long break interval info',
          onPressed: _showLongBreakInfoDialog,
        ),
        const SizedBox(width: 6),
        _intervalDotsCard(interval),
      ],
    );
  }

  Widget _totalPomodorosSuffix() {
    return _infoButton(
      tooltip: 'Total pomodoros info',
      onPressed: _showTotalPomodorosInfoDialog,
    );
  }

  Widget _shortBreakSuffix(int minutes) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _infoButton(
          tooltip: 'Short break info',
          onPressed: _showShortBreakInfoDialog,
        ),
        const SizedBox(width: 6),
        _metricCircle(
          value: minutes.toString(),
          color: Colors.blueAccent,
          stroke: 1,
        ),
      ],
    );
  }

  Widget _longBreakSuffix(int minutes) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _infoButton(
          tooltip: 'Long break info',
          onPressed: _showLongBreakDurationInfoDialog,
        ),
        const SizedBox(width: 6),
        _metricCircle(
          value: minutes.toString(),
          color: Colors.blueAccent,
          stroke: 3,
        ),
      ],
    );
  }

  Widget _pomodoroSuffix(int minutes) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _infoButton(
          tooltip: 'Pomodoro duration info',
          onPressed: _showPomodoroInfoDialog,
        ),
        const SizedBox(width: 6),
        _metricCircle(
          value: minutes.toString(),
          color: Colors.redAccent,
          stroke: 2,
        ),
      ],
    );
  }

  Widget _infoButton({
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      icon: const Icon(Icons.info_outline, size: 18),
      color: Colors.white54,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 28, height: 28),
      tooltip: tooltip,
      onPressed: onPressed,
    );
  }

  Widget _intervalDots(int interval) {
    final safeInterval = interval <= 0 ? 1 : interval;
    final redDots = safeInterval > maxLongBreakInterval
        ? maxLongBreakInterval
        : safeInterval;
    final totalDots = redDots + 1;
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 48.0;
        const maxHeight = 30.0;
        var dotSize = 5.0;
        var spacing = 3.0;
        const minDot = 3.0;

        while (dotSize >= minDot) {
          final rows = _rowsFor(
            maxHeight,
            dotSize,
            spacing,
            totalDots,
            maxRows: 3,
          );
          final maxCols = _maxColsFor(maxWidth, dotSize, spacing);
          if (rows * maxCols >= totalDots) break;
          dotSize -= 0.5;
          spacing = dotSize <= 4 ? 2 : 3;
        }

        if (redDots == 1) {
          return Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Dot(color: Colors.redAccent, size: dotSize),
                SizedBox(width: spacing),
                _Dot(color: Colors.blueAccent, size: dotSize),
              ],
            ),
          );
        }

        final rows = _rowsFor(
          maxHeight,
          dotSize,
          spacing,
          totalDots,
          maxRows: 3,
        );
        final maxCols = _maxColsFor(maxWidth, dotSize, spacing);
        final redColsNeeded = (redDots / rows).ceil();
        final blueSeparate = redColsNeeded < maxCols;
        final columns = <Widget>[];
        var remainingRed = redDots;
        final redColumnsCount = blueSeparate ? redColsNeeded : maxCols;

        for (var col = 0; col < redColumnsCount; col += 1) {
          final isLast = col == redColumnsCount - 1;
          final capacity = (!blueSeparate && isLast) ? rows - 1 : rows;
          final take = remainingRed > capacity ? capacity : remainingRed;
          remainingRed -= take;
          columns.add(
            _dotColumn(
              redCount: take,
              includeBlue: !blueSeparate && isLast,
              dotSize: dotSize,
              spacing: spacing,
              height: maxHeight,
            ),
          );
        }

        if (blueSeparate) {
          columns.add(
            _dotColumn(
              redCount: 0,
              includeBlue: true,
              dotSize: dotSize,
              spacing: spacing,
              height: maxHeight,
            ),
          );
        }

        return SizedBox(
          height: maxHeight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: _withColumnSpacing(columns, spacing + 1),
          ),
        );
      },
    );
  }

  int _rowsFor(
    double maxHeight,
    double dotSize,
    double spacing,
    int totalDots, {
    int? maxRows,
  }
  ) {
    final rows = ((maxHeight + spacing) / (dotSize + spacing)).floor();
    if (rows < 1) return 1;
    final clampedRows = maxRows != null && rows > maxRows ? maxRows : rows;
    return clampedRows > totalDots ? totalDots : clampedRows;
  }

  int _maxColsFor(double maxWidth, double dotSize, double spacing) {
    final cols = ((maxWidth + spacing) / (dotSize + spacing)).floor();
    return cols < 1 ? 1 : cols;
  }

  List<Widget> _withColumnSpacing(List<Widget> columns, double spacing) {
    final spaced = <Widget>[];
    for (var i = 0; i < columns.length; i += 1) {
      spaced.add(columns[i]);
      if (i < columns.length - 1) {
        spaced.add(SizedBox(width: spacing));
      }
    }
    return spaced;
  }

  Widget _dotColumn({
    required int redCount,
    required bool includeBlue,
    required double dotSize,
    required double spacing,
    required double height,
  }) {
    return SizedBox(
      width: dotSize,
      height: height,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          for (var i = 0; i < redCount; i += 1) ...[
            _Dot(color: Colors.redAccent, size: dotSize),
            if (i < redCount - 1) SizedBox(height: spacing),
          ],
          if (includeBlue) ...[
            if (redCount > 0) SizedBox(height: spacing),
            _Dot(color: Colors.blueAccent, size: dotSize),
          ],
        ],
      ),
    );
  }
}
