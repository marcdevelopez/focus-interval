import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers.dart';
import '../../data/services/firebase_auth_service.dart';
import '../../widgets/task_card.dart';

class TaskListScreen extends ConsumerStatefulWidget {
  const TaskListScreen({super.key});

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen> {
  static const String _linuxSyncNoticeKey = 'linux_sync_notice_seen';
  bool _syncNoticeChecked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowLinuxSyncNotice();
    });
  }

  Future<void> _maybeShowLinuxSyncNotice() async {
    if (_syncNoticeChecked) return;
    _syncNoticeChecked = true;
    final auth = ref.read(firebaseAuthServiceProvider);
    if (auth is! StubAuthService) return;
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool(_linuxSyncNoticeKey) ?? false;
    if (seen) return;
    if (!mounted) return;
    await _showLinuxSyncInfoDialog();
    await prefs.setBool(_linuxSyncNoticeKey, true);
  }

  Future<void> _handleSyncInfoTap() async {
    await _showLinuxSyncInfoDialog();
    await _setSyncNoticeSeen();
  }

  Future<void> _setSyncNoticeSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_linuxSyncNoticeKey, true);
  }

  Future<void> _showLinuxSyncInfoDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Sync across devices'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: [
                Text(
                  'Linux desktop does not support sign-in yet, so tasks stay on '
                  'this machine.',
                ),
                SizedBox(height: 8),
                Text(
                  'Use the web app in Chrome to sign in and sync in real time '
                  'with other devices.',
                ),
              ],
            ),
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

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(taskListProvider);
    final auth = ref.watch(firebaseAuthServiceProvider);
    final authSupported = auth is! StubAuthService;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Your tasks"),
        actions: [
          if (authSupported && auth.currentUser != null) ...[
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
                // Clear the in-memory list and navigate to login
                ref.invalidate(taskListProvider);
                if (context.mounted) context.go('/login');
              },
            ),
          ] else if (authSupported)
            IconButton(
              icon: const Icon(Icons.person),
              onPressed: () => context.go('/login'),
            ),
          if (!authSupported)
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: _handleSyncInfoTap,
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
                "Your tasks will appear here",
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
                      const SnackBar(content: Text("Task not found.")),
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
