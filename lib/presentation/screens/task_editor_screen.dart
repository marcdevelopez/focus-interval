import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';
import '../../data/models/pomodoro_task.dart';
import '../../widgets/sound_selector.dart';

class TaskEditorScreen extends ConsumerStatefulWidget {
  final bool isEditing;
  final String? taskId;

  const TaskEditorScreen({
    super.key,
    required this.isEditing,
    this.taskId,
  });

  @override
  ConsumerState<TaskEditorScreen> createState() => _TaskEditorScreenState();
}

class _TaskEditorScreenState extends ConsumerState<TaskEditorScreen> {
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    if (widget.isEditing && widget.taskId != null) {
      Future.microtask(() {
        _loadExisting();
      });
    }
  }

  Future<void> _loadExisting() async {
    final ok = await ref.read(taskEditorProvider.notifier).load(widget.taskId!);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("The task no longer exists.")),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = ref.watch(taskEditorProvider);
    const pomodoroSounds = [
      SoundOption('default_chime', 'Chime (pomodoro start)'),
      SoundOption('bell_soft', 'Soft bell'),
      SoundOption('digital_beep', 'Digital beep'),
    ];

    const breakSounds = [
      SoundOption('default_chime_break', 'Chime (break start)'),
      SoundOption('bell_soft_break', 'Soft bell (break)'),
      SoundOption('digital_beep_break', 'Digital beep (break)'),
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

              await ref.read(taskEditorProvider.notifier).save();
              if (!context.mounted) return;
              Navigator.pop(context);
            },
            child: const Text("Save"),
          )
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _textField(
              label: "Task name",
              initial: task.name,
              onChanged: (v) => _update(task.copyWith(name: v)),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? "Required" : null,
            ),
            const SizedBox(height: 12),

            _numberField(
              label: "Pomodoro duration (min)",
              initial: task.pomodoroMinutes,
              onChanged: (v) =>
                  _update(task.copyWith(pomodoroMinutes: v)),
            ),
            _numberField(
              label: "Short break (min)",
              initial: task.shortBreakMinutes,
              onChanged: (v) =>
                  _update(task.copyWith(shortBreakMinutes: v)),
            ),
            _numberField(
              label: "Long break (min)",
              initial: task.longBreakMinutes,
              onChanged: (v) =>
                  _update(task.copyWith(longBreakMinutes: v)),
            ),
            const SizedBox(height: 12),

            _numberField(
              label: "Total pomodoros",
              initial: task.totalPomodoros,
              onChanged: (v) =>
                  _update(task.copyWith(totalPomodoros: v)),
            ),
            _numberField(
              label: "Pomodoros per long break",
              initial: task.longBreakInterval,
              onChanged: (v) =>
                  _update(task.copyWith(longBreakInterval: v)),
            ),
            const SizedBox(height: 24),
            const Text(
              "Sounds",
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 8),
            SoundSelector(
              label: "Pomodoro start",
              value: task.startSound,
              options: pomodoroSounds,
              onChanged: (v) => _update(task.copyWith(startSound: v)),
            ),
            const SizedBox(height: 12),
            SoundSelector(
              label: "Break start",
              value: task.startBreakSound,
              options: breakSounds,
              onChanged: (v) => _update(task.copyWith(startBreakSound: v)),
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

  bool _validateBusinessRules() {
    final task = ref.read(taskEditorProvider);
    if (task == null) return false;

    if (task.longBreakInterval > task.totalPomodoros) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Long break interval cannot be greater than total pomodoros.",
          ),
        ),
      );
      return false;
    }
    return true;
  }

  Widget _textField({
    required String label,
    required String initial,
    required Function(String) onChanged,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      initialValue: initial,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white24),
        ),
      ),
      validator: validator,
      onChanged: onChanged,
    );
  }

  Widget _numberField({
    required String label,
    required int initial,
    required Function(int) onChanged,
  }) {
    return TextFormField(
      initialValue: initial.toString(),
      keyboardType: TextInputType.number,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white24),
        ),
      ),
      validator: (v) {
        final n = int.tryParse(v ?? "");
        if (n == null || n <= 0) return "Must be > 0";
        return null;
      },
      onChanged: (v) {
        final n = int.tryParse(v);
        if (n != null) onChanged(n);
      },
    );
  }
}
