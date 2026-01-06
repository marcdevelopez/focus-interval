import 'package:flutter/material.dart';
import '../data/models/pomodoro_task.dart';

class TaskCard extends StatelessWidget {
  final PomodoroTask task;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white10,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        title: Text(
          task.name.isEmpty ? "(Untitled)" : task.name,
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        subtitle: Text(
          "${task.totalPomodoros} pomodoros · "
          "${task.pomodoroMinutes}m / "
          "${task.shortBreakMinutes}m / "
          "${task.longBreakMinutes}m",
          style: const TextStyle(color: Colors.white54),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit, color: Colors.white70),
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete, color: Colors.redAccent),
            ),
          ],
        ),
      ),
    );
  }
}
