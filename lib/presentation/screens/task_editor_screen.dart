import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';
import '../../data/models/pomodoro_task.dart';

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
        const SnackBar(content: Text("La tarea ya no existe.")),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = ref.watch(taskEditorProvider);

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
        title: Text(widget.isEditing ? "Editar tarea" : "Nueva tarea"),
        actions: [
          TextButton(
            onPressed: () async {
              if (!_formKey.currentState!.validate()) return;
              if (!_validateBusinessRules()) return;

              await ref.read(taskEditorProvider.notifier).save();
              if (!context.mounted) return;
              Navigator.pop(context);
            },
            child: const Text("Guardar"),
          )
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _textField(
              label: "Nombre de la tarea",
              initial: task.name,
              onChanged: (v) => _update(task.copyWith(name: v)),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? "Requerido" : null,
            ),
            const SizedBox(height: 12),

            _numberField(
              label: "Duración Pomodoro (min)",
              initial: task.pomodoroMinutes,
              onChanged: (v) =>
                  _update(task.copyWith(pomodoroMinutes: v)),
            ),
            _numberField(
              label: "Descanso corto (min)",
              initial: task.shortBreakMinutes,
              onChanged: (v) =>
                  _update(task.copyWith(shortBreakMinutes: v)),
            ),
            _numberField(
              label: "Descanso largo (min)",
              initial: task.longBreakMinutes,
              onChanged: (v) =>
                  _update(task.copyWith(longBreakMinutes: v)),
            ),
            const SizedBox(height: 12),

            _numberField(
              label: "Total Pomodoros",
              initial: task.totalPomodoros,
              onChanged: (v) =>
                  _update(task.copyWith(totalPomodoros: v)),
            ),
            _numberField(
              label: "Pomodoros por descanso largo",
              initial: task.longBreakInterval,
              onChanged: (v) =>
                  _update(task.copyWith(longBreakInterval: v)),
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
            "El intervalo de descanso largo no puede ser mayor que el total de pomodoros.",
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
        if (n == null || n <= 0) return "Debe ser > 0";
        return null;
      },
      onChanged: (v) {
        final n = int.tryParse(v);
        if (n != null) onChanged(n);
      },
    );
  }
}
