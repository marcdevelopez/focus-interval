import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/pomodoro_preset.dart';
import '../../widgets/mode_indicator.dart';
import '../providers.dart';

class PresetListScreen extends ConsumerWidget {
  const PresetListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presetsAsync = ref.watch(presetListProvider);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Manage presets'),
        actions: [
          const ModeIndicatorAction(compact: true),
          PopupMenuButton<String>(
            color: const Color(0xFF1A1A1A),
            onSelected: (value) async {
              if (value != 'delete_all') return;
              final confirmed = await _confirmBulkDelete(context);
              if (!confirmed) return;
              await Future<void>.delayed(Duration.zero);
              if (!context.mounted) return;
              final presets = ref.read(presetListProvider).value ?? const [];
              for (final preset in presets) {
                await ref
                    .read(presetEditorProvider.notifier)
                    .delete(preset.id);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'delete_all',
                child: Text('Delete all presets'),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ref.read(presetEditorProvider.notifier).createNew();
          context.push('/settings/presets/new');
        },
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        child: const Icon(Icons.add),
      ),
      body: presetsAsync.when(
        data: (presets) {
          if (presets.isEmpty) {
            return const Center(
              child: Text(
                'No presets yet.',
                style: TextStyle(color: Colors.white54),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: presets.length,
            itemBuilder: (context, index) {
              final preset = presets[index];
              return _PresetCard(preset: preset);
            },
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        error: (err, _) => Center(
          child: Text(
            'Failed to load presets: $err',
            style: const TextStyle(color: Colors.white54),
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmBulkDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete all presets'),
          content: const Text('This will remove every preset. Continue?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete all'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }
}

class _PresetCard extends ConsumerWidget {
  final PomodoroPreset preset;

  const _PresetCard({required this.preset});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      color: Colors.white10,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: preset.isDefault ? Colors.amberAccent : Colors.white12,
          width: preset.isDefault ? 1.2 : 1,
        ),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/settings/presets/edit/${preset.id}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      preset.name.isEmpty ? '(Untitled preset)' : preset.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Set default',
                    icon: Icon(
                      preset.isDefault ? Icons.star : Icons.star_border,
                      color: preset.isDefault
                          ? Colors.amberAccent
                          : Colors.white54,
                      size: 18,
                    ),
                    onPressed: () => ref
                        .read(presetEditorProvider.notifier)
                        .setDefault(preset.id),
                  ),
                  IconButton(
                    tooltip: 'Edit preset',
                    icon: const Icon(Icons.edit, color: Colors.white70, size: 18),
                    onPressed: () =>
                        context.push('/settings/presets/edit/${preset.id}'),
                  ),
                  IconButton(
                    tooltip: 'Delete preset',
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.redAccent, size: 18),
                    onPressed: () async {
                      final confirmed = await _confirmDelete(context, preset);
                      if (!confirmed) return;
                      await Future<void>.delayed(Duration.zero);
                      if (!context.mounted) return;
                      await ref
                          .read(presetEditorProvider.notifier)
                          .delete(preset.id);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _presetSummary(preset),
            ],
          ),
        ),
      ),
    );
  }

  Widget _presetSummary(PomodoroPreset preset) {
    return Row(
      children: [
        _summaryChip(
          color: Colors.redAccent,
          label: '${preset.pomodoroMinutes} min',
          icon: Icons.timer,
        ),
        const SizedBox(width: 8),
        _summaryChip(
          color: Colors.blueAccent,
          label: '${preset.shortBreakMinutes}/${preset.longBreakMinutes} min',
          icon: Icons.coffee,
        ),
        const SizedBox(width: 8),
        _summaryChip(
          color: Colors.white70,
          label: 'Interval ${preset.longBreakInterval}',
          icon: Icons.grid_on,
        ),
      ],
    );
  }

  Widget _summaryChip({
    required Color color,
    required String label,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDelete(
    BuildContext context,
    PomodoroPreset preset,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete preset'),
          content: Text('Delete "${preset.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }
}
