import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers.dart';
import '../../widgets/task_card.dart';

class TaskListScreen extends ConsumerWidget {
  const TaskListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(taskListProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Tus tareas"),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ref.read(taskEditorProvider.notifier).createNew();
          context.push("/tasks/new");
        },
        child: const Icon(Icons.add),
      ),
      body: tasksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text("Error: $e", style: const TextStyle(color: Colors.red)),
        ),
        data: (tasks) {
          if (tasks.isEmpty) {
            return const Center(
              child: Text(
                "Aquí aparecerán tus tareas",
                style: TextStyle(color: Colors.white54),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: tasks.length,
            itemBuilder: (_, i) {
              final t = tasks[i];
              return TaskCard(
                task: t,
                onTap: () => context.push("/timer/${t.id}"),
                onEdit: () async {
                  await ref.read(taskEditorProvider.notifier).load(t.id);
                  context.push("/tasks/edit/${t.id}");
                },
                onDelete: () => ref
                    .read(taskListProvider.notifier)
                    .deleteTask(t.id),
              );
            },
          );
        },
      ),
    );
  }
}
