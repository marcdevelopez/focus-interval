import 'dart:async';

import '../models/pomodoro_preset.dart';

abstract class PomodoroPresetRepository {
  Future<List<PomodoroPreset>> getAll();
  Future<PomodoroPreset?> getById(String id);
  Future<void> save(PomodoroPreset preset);
  Future<void> delete(String id);
  Stream<List<PomodoroPreset>> watchAll();
}

class NoopPomodoroPresetRepository implements PomodoroPresetRepository {
  @override
  Future<List<PomodoroPreset>> getAll() async => const [];

  @override
  Future<PomodoroPreset?> getById(String id) async => null;

  @override
  Future<void> save(PomodoroPreset preset) async {}

  @override
  Future<void> delete(String id) async {}

  @override
  Stream<List<PomodoroPreset>> watchAll() => const Stream.empty();
}

class InMemoryPomodoroPresetRepository implements PomodoroPresetRepository {
  final Map<String, PomodoroPreset> _store = {};
  final StreamController<List<PomodoroPreset>> _controller;

  InMemoryPomodoroPresetRepository()
    : _controller = StreamController<List<PomodoroPreset>>.broadcast(
        sync: true,
        onListen: () {},
      ) {
    _controller.onListen = _emit;
  }

  @override
  Future<List<PomodoroPreset>> getAll() async => _store.values.toList();

  @override
  Future<PomodoroPreset?> getById(String id) async => _store[id];

  @override
  Future<void> save(PomodoroPreset preset) async {
    _store[preset.id] = preset;
    _emit();
  }

  @override
  Future<void> delete(String id) async {
    _store.remove(id);
    _emit();
  }

  @override
  Stream<List<PomodoroPreset>> watchAll() => _controller.stream;

  void _emit() {
    _controller.add(_store.values.toList());
  }
}
