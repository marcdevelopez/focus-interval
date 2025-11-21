import 'package:flutter/material.dart';

class TaskEditorScreen extends StatelessWidget {
  final bool isEditing;
  final String? taskId;

  const TaskEditorScreen({super.key, required this.isEditing, this.taskId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? "Editar tarea" : "Nueva tarea")),
      body: const Center(child: Text("Editor de tareas (placeholder)")),
    );
  }
}
