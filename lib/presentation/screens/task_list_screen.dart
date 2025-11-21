import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TaskListScreen extends StatelessWidget {
  const TaskListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tus tareas")),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/timer/demo'),
        child: const Icon(Icons.add),
      ),

      body: const Center(
        child: Text(
          "Aquí aparecerán tus tareas\n(placeholder)",
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
