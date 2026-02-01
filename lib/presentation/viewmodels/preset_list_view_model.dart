import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/pomodoro_preset.dart';
import '../../data/repositories/pomodoro_preset_repository.dart';
import '../providers.dart';

class PresetListViewModel extends AsyncNotifier<List<PomodoroPreset>> {
  StreamSubscription<List<PomodoroPreset>>? _sub;

  @override
  Future<List<PomodoroPreset>> build() async {
    final repo = ref.watch(presetRepositoryProvider);
    ref.onDispose(() => _sub?.cancel());
    return _listenToRepo(repo);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final repo = ref.read(presetRepositoryProvider);
    await _sub?.cancel();
    await _listenToRepo(repo);
  }

  Future<void> deletePreset(String id) async {
    final repo = ref.read(presetRepositoryProvider);
    await repo.delete(id);
  }

  Future<List<PomodoroPreset>> _listenToRepo(
    PomodoroPresetRepository repo,
  ) async {
    await _sub?.cancel();
    final completer = Completer<List<PomodoroPreset>>();

    _sub = repo.watchAll().listen(
      (presets) {
        final ordered = [...presets]
          ..sort((a, b) {
            if (a.isDefault != b.isDefault) {
              return a.isDefault ? -1 : 1;
            }
            final name = a.name.toLowerCase().compareTo(b.name.toLowerCase());
            if (name != 0) return name;
            return a.createdAt.compareTo(b.createdAt);
          });
        _setStateSafely(AsyncData(ordered));
        if (!completer.isCompleted) {
          completer.complete(ordered);
        }
      },
      onError: (error, stack) {
        _setStateSafely(AsyncError(error, stack));
        if (!completer.isCompleted) {
          completer.completeError(error, stack);
        }
      },
    );

    return completer.future;
  }

  void _setStateSafely(AsyncValue<List<PomodoroPreset>> value) {
    Future.microtask(() {
      if (!ref.mounted) return;
      state = value;
    });
  }
}
