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
    final auth = ref.watch(firebaseAuthServiceProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Tus tareas"),
        actions: [
          if (auth.currentUser != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Center(
                child: Text(
                  auth.currentUser!.email ?? '',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await auth.signOut();
                // Limpiamos la lista en memoria y navegamos a login
                ref.invalidate(taskListProvider);
                if (context.mounted) context.go('/login');
              },
            ),
          ] else
            IconButton(
              icon: const Icon(Icons.person),
              onPressed: () => context.go('/login'),
            ),
        ],
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
                  final ok = await ref.read(taskEditorProvider.notifier).load(t.id);
                  if (!context.mounted) return;
                  if (!ok) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("No se encontró la tarea.")),
                    );
                    return;
                  }
                  context.push("/tasks/edit/${t.id}");
                },
                onDelete: () =>
                    ref.read(taskListProvider.notifier).deleteTask(t.id),
              );
            },
          );
        },
      ),
    );
  }
}
