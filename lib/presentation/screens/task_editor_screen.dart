import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';
import '../viewmodels/task_editor_view_model.dart';
import '../../data/models/pomodoro_task.dart';
import '../../widgets/sound_selector.dart';

class TaskEditorScreen extends ConsumerStatefulWidget {
  final bool isEditing;
  final String? taskId;

  const TaskEditorScreen({super.key, required this.isEditing, this.taskId});

  @override
  ConsumerState<TaskEditorScreen> createState() => _TaskEditorScreenState();
}

class _TaskEditorScreenState extends ConsumerState<TaskEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _pomodoroCtrl;
  late final TextEditingController _shortBreakCtrl;
  late final TextEditingController _longBreakCtrl;
  late final TextEditingController _totalPomodorosCtrl;
  late final TextEditingController _longBreakIntervalCtrl;
  String? _loadedTaskId;

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
      Navigator.pop(context);
      return;
    }
    if (result == TaskEditorLoadResult.blockedByActiveSession) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Stop the running task before editing it."),
        ),
      );
      Navigator.pop(context);
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
          TextButton(
            onPressed: () async {
              if (!_formKey.currentState!.validate()) return;
              if (!_validateBusinessRules()) return;

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
              Navigator.pop(context);
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
              label: "Pomodoro duration (min)",
              controller: _pomodoroCtrl,
              onChanged: (v) => _update(task.copyWith(pomodoroMinutes: v)),
            ),
            _numberField(
              label: "Short break (min)",
              controller: _shortBreakCtrl,
              onChanged: (v) => _update(task.copyWith(shortBreakMinutes: v)),
            ),
            _numberField(
              label: "Long break (min)",
              controller: _longBreakCtrl,
              onChanged: (v) => _update(task.copyWith(longBreakMinutes: v)),
            ),
            const SizedBox(height: 12),

            _numberField(
              label: "Total pomodoros",
              controller: _totalPomodorosCtrl,
              onChanged: (v) => _update(task.copyWith(totalPomodoros: v)),
            ),
            _numberField(
              label: "Pomodoros per long break",
              controller: _longBreakIntervalCtrl,
              onChanged: (v) => _update(task.copyWith(longBreakInterval: v)),
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

  void _syncControllers(PomodoroTask task) {
    _loadedTaskId = task.id;
    _nameCtrl.text = task.name;
    _pomodoroCtrl.text = task.pomodoroMinutes.toString();
    _shortBreakCtrl.text = task.shortBreakMinutes.toString();
    _longBreakCtrl.text = task.longBreakMinutes.toString();
    _totalPomodorosCtrl.text = task.totalPomodoros.toString();
    _longBreakIntervalCtrl.text = task.longBreakInterval.toString();
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

  bool _validateBusinessRules() {
    final task = ref.read(taskEditorProvider);
    if (task == null) return false;
    if (task.longBreakInterval > task.totalPomodoros) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Long break interval cannot exceed total pomodoros."),
        ),
      );
      return false;
    }
    return true;
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
    required TextEditingController controller,
    required ValueChanged<int> onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
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
      validator: (v) {
        final value = int.tryParse(v ?? '');
        if (value == null || value <= 0) {
          return "Enter a valid number";
        }
        return null;
      },
      onChanged: (v) {
        final value = int.tryParse(v);
        if (value == null) return;
        onChanged(value);
      },
    );
  }
}
