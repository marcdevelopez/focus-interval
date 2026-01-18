import 'package:flutter/material.dart';
import '../data/models/pomodoro_task.dart';

class TaskCard extends StatelessWidget {
  final PomodoroTask task;
  final VoidCallback onTap;
  final bool selected;
  final ValueChanged<bool?> onSelected;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Widget? reorderHandle;
  final String? timeRange;

  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    required this.selected,
    required this.onSelected,
    required this.onEdit,
    required this.onDelete,
    this.reorderHandle,
    this.timeRange,
  });

  @override
  Widget build(BuildContext context) {
    final title = task.name.isEmpty ? "(Untitled)" : task.name;
    final subtitle =
        "${task.totalPomodoros} pomodoros · "
        "${task.pomodoroMinutes}m / "
        "${task.shortBreakMinutes}m / "
        "${task.longBreakMinutes}m";

    return Card(
      color: Colors.white10,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Row(
            children: [
              Checkbox(
                value: selected,
                onChanged: onSelected,
                side: const BorderSide(color: Colors.white24),
                checkColor: Colors.black,
                activeColor: Colors.white,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.white54),
                    ),
                    if (timeRange != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        timeRange!,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit, color: Colors.white70),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete, color: Colors.redAccent),
              ),
              if (reorderHandle != null) reorderHandle!,
            ],
          ),
        ),
      ),
    );
  }
}
