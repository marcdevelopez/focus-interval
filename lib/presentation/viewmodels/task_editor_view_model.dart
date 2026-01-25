import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:just_audio/just_audio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/pomodoro_task.dart';
import '../../data/models/pomodoro_session.dart';
import '../../data/models/selected_sound.dart';
import '../../domain/pomodoro_machine.dart';
import '../../domain/validators.dart';
import '../providers.dart';
import '../../data/services/local_sound_overrides.dart';

enum TaskEditorLoadResult { loaded, notFound, blockedByActiveSession }

enum SoundPickTarget { pomodoroStart, breakStart }

class SoundPickResult {
  final SelectedSound? sound;
  final String? error;

  const SoundPickResult({this.sound, this.error});
}

class TaskEditorViewModel extends Notifier<PomodoroTask?> {
  static const int _maxSoundBytes = 2 * 1024 * 1024;
  static const int _maxSoundDurationSeconds = 10;

  final _uuid = const Uuid();

  late LocalSoundOverrides _soundOverrides;
  final Map<SoundSlot, String?> _customDisplayNames = {};

  @override
  PomodoroTask? build() {
    _soundOverrides = ref.watch(localSoundOverridesProvider);
    return null;
  }

  // Create a new task with defaults.
  void createNew() {
    final now = DateTime.now();
    state = PomodoroTask(
      id: _uuid.v4(),
      name: "",
      pomodoroMinutes: 25,
      shortBreakMinutes: 5,
      longBreakMinutes: 15,
      totalPomodoros: 4,
      longBreakInterval: 4,
      order: now.millisecondsSinceEpoch,
      startSound: const SelectedSound.builtIn('default_chime'),
      startBreakSound: const SelectedSound.builtIn('default_chime_break'),
      finishTaskSound: const SelectedSound.builtIn('default_chime_finish'),
      createdAt: now,
      updatedAt: now,
    );
  }

  // Load existing by id. Returns a result to handle active-session guards.
  Future<TaskEditorLoadResult> load(String taskId) async {
    final repo = ref.read(taskRepositoryProvider);
    final task = await repo.getById(taskId);
    if (task == null) return TaskEditorLoadResult.notFound;
    state = await _applyLocalOverrides(task);
    return TaskEditorLoadResult.loaded;
  }

  void update(PomodoroTask task) {
    state = task;
  }

  BreakDurationGuidance? breakGuidanceFor(PomodoroTask? task) {
    if (task == null) return null;
    return buildBreakDurationGuidance(
      pomodoroMinutes: task.pomodoroMinutes,
      shortBreakMinutes: task.shortBreakMinutes,
      longBreakMinutes: task.longBreakMinutes,
    );
  }

  Future<bool> save() async {
    if (state == null) return false;
    final session = await _readCurrentSession();
    if (session != null &&
        session.status.isActiveExecution &&
        session.taskId == state!.id) {
      return false;
    }
    final now = DateTime.now();
    final base = state!;
    final withTimestamps = base.copyWith(
      updatedAt: now,
      createdAt: base.createdAt,
    );
    final sanitized = await _sanitizeForSync(withTimestamps);
    final repo = ref.read(taskRepositoryProvider);
    await repo.save(sanitized);
    return true;
  }

  Future<int> applySettingsToRemainingTasks({
    List<PomodoroTask>? orderedTasks,
  }) async {
    final source = state;
    if (source == null) return 0;
    final tasks = orderedTasks == null
        ? await _fetchOrderedTasks()
        : _orderTasks(orderedTasks);
    if (tasks.isEmpty) return 0;
    final sourceIndex = tasks.indexWhere((task) => task.id == source.id);
    if (sourceIndex == -1 || sourceIndex >= tasks.length - 1) return 0;

    final remaining = tasks.sublist(sourceIndex + 1);
    if (remaining.isEmpty) return 0;

    final now = DateTime.now();
    final repo = ref.read(taskRepositoryProvider);
    final startOverride =
        await _soundOverrides.getOverride(source.id, SoundSlot.pomodoroStart);
    final breakOverride =
        await _soundOverrides.getOverride(source.id, SoundSlot.breakStart);

    for (final target in remaining) {
      final updated = target.copyWith(
        pomodoroMinutes: source.pomodoroMinutes,
        shortBreakMinutes: source.shortBreakMinutes,
        longBreakMinutes: source.longBreakMinutes,
        totalPomodoros: source.totalPomodoros,
        longBreakInterval: source.longBreakInterval,
        startSound: source.startSound,
        startBreakSound: source.startBreakSound,
        finishTaskSound: source.finishTaskSound,
        updatedAt: now,
      );
      final sanitized = await _sanitizeForSync(updated);
      await repo.save(sanitized);
      await _applySoundOverrideToTarget(
        targetId: target.id,
        slot: SoundSlot.pomodoroStart,
        sourceSound: source.startSound,
        sourceOverride: startOverride,
        fallbackBuiltInId: _fallbackBuiltInFromTask(
          source,
          SoundSlot.pomodoroStart,
        ),
      );
      await _applySoundOverrideToTarget(
        targetId: target.id,
        slot: SoundSlot.breakStart,
        sourceSound: source.startBreakSound,
        sourceOverride: breakOverride,
        fallbackBuiltInId: _fallbackBuiltInFromTask(
          source,
          SoundSlot.breakStart,
        ),
      );
    }

    return remaining.length;
  }

  Future<void> _applySoundOverrideToTarget({
    required String targetId,
    required SoundSlot slot,
    required SelectedSound sourceSound,
    required LocalSoundOverride? sourceOverride,
    required String fallbackBuiltInId,
  }) async {
    if (sourceSound.type == SoundType.custom) {
      await _soundOverrides.setOverride(
        taskId: targetId,
        slot: slot,
        sound: sourceSound,
        fallbackBuiltInId:
            sourceOverride?.fallbackBuiltInId ?? fallbackBuiltInId,
        displayName: sourceOverride?.displayName,
      );
      return;
    }
    await _soundOverrides.clearOverride(targetId, slot);
  }

  Future<List<PomodoroTask>> _fetchOrderedTasks() async {
    final asyncTasks = ref.read(taskListProvider);
    final cached = asyncTasks.asData?.value;
    if (cached != null) {
      return _orderTasks(cached);
    }
    final repo = ref.read(taskRepositoryProvider);
    final tasks = await repo.getAll();
    return _orderTasks(tasks);
  }

  List<PomodoroTask> _orderTasks(List<PomodoroTask> tasks) {
    final ordered = [...tasks];
    ordered.sort((a, b) {
      final order = a.order.compareTo(b.order);
      if (order != 0) return order;
      return a.createdAt.compareTo(b.createdAt);
    });
    return ordered;
  }

  Future<PomodoroTask> _applyLocalOverrides(PomodoroTask task) async {
    final startOverride = await _soundOverrides.getOverride(
      task.id,
      SoundSlot.pomodoroStart,
    );
    final breakOverride = await _soundOverrides.getOverride(
      task.id,
      SoundSlot.breakStart,
    );
    _syncDisplayName(SoundSlot.pomodoroStart, startOverride);
    _syncDisplayName(SoundSlot.breakStart, breakOverride);
    return task.copyWith(
      startSound: startOverride?.sound ?? task.startSound,
      startBreakSound: breakOverride?.sound ?? task.startBreakSound,
    );
  }

  Future<PomodoroTask> _sanitizeForSync(PomodoroTask task) async {
    final startFallback = await _fallbackBuiltInId(
      taskId: task.id,
      slot: SoundSlot.pomodoroStart,
      current: task.startSound,
      defaultId: 'default_chime',
    );
    final breakFallback = await _fallbackBuiltInId(
      taskId: task.id,
      slot: SoundSlot.breakStart,
      current: task.startBreakSound,
      defaultId: 'default_chime_break',
    );

    return task.copyWith(
      startSound: task.startSound.type == SoundType.custom
          ? SelectedSound.builtIn(startFallback)
          : task.startSound,
      startBreakSound: task.startBreakSound.type == SoundType.custom
          ? SelectedSound.builtIn(breakFallback)
          : task.startBreakSound,
      finishTaskSound: task.finishTaskSound.type == SoundType.custom
          ? const SelectedSound.builtIn('default_chime_finish')
          : task.finishTaskSound,
    );
  }

  Future<String> _fallbackBuiltInId({
    required String taskId,
    required SoundSlot slot,
    required SelectedSound current,
    required String defaultId,
  }) async {
    if (current.type == SoundType.builtIn && current.value.isNotEmpty) {
      return current.value;
    }
    final override = await _soundOverrides.getOverride(taskId, slot);
    return override?.fallbackBuiltInId ?? defaultId;
  }

  Future<void> clearLocalSoundOverride(SoundPickTarget target) async {
    final task = state;
    if (task == null) return;
    final slot = _slotForTarget(target);
    await _soundOverrides.clearOverride(task.id, slot);
    _customDisplayNames.remove(slot);
  }

  SoundSlot _slotForTarget(SoundPickTarget target) {
    return switch (target) {
      SoundPickTarget.pomodoroStart => SoundSlot.pomodoroStart,
      SoundPickTarget.breakStart => SoundSlot.breakStart,
    };
  }

  String? customDisplayName(SoundPickTarget target) {
    return _customDisplayNames[_slotForTarget(target)];
  }

  void _syncDisplayName(SoundSlot slot, LocalSoundOverride? override) {
    if (override?.sound.type == SoundType.custom) {
      final name = override?.displayName;
      if (name == null || name.trim().isEmpty) {
        _customDisplayNames.remove(slot);
      } else {
        _customDisplayNames[slot] = name;
      }
    } else {
      _customDisplayNames.remove(slot);
    }
  }

  Future<SoundPickResult> pickLocalSound(SoundPickTarget target) async {
    if (kIsWeb) {
      return const SoundPickResult(
        error: 'Custom sounds are not supported on web.',
      );
    }

    final storage = ref.read(localSoundStorageProvider);
    if (!storage.isSupported) {
      return const SoundPickResult(
        error: 'Custom sounds are not supported on this platform.',
      );
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['mp3', 'wav', 'm4a'],
      withData: false,
    );

    if (result == null || result.files.isEmpty) {
      return const SoundPickResult();
    }

    final file = result.files.first;
    final path = file.path;
    if (path == null || path.isEmpty) {
      return const SoundPickResult(
        error: 'The selected file is not accessible.',
      );
    }

    final displayName = file.name.trim().isNotEmpty ? file.name.trim() : null;
    final extension = (file.extension ?? '').toLowerCase();
    const allowed = ['mp3', 'wav', 'm4a'];
    if (!allowed.contains(extension)) {
      return const SoundPickResult(
        error: 'Unsupported format. Use mp3, wav, or m4a.',
      );
    }

    final size = await storage.fileSize(path);
    if (size != null && size > _maxSoundBytes) {
      return const SoundPickResult(
        error: 'File is too large. Max size is 2 MB.',
      );
    }

    final okDuration = await _isDurationAcceptable(path);
    if (!okDuration) {
      return const SoundPickResult(
        error: 'Sound is too long. Keep it under 10 seconds.',
      );
    }

    final copyOnImport =
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;

    final targetFileName = _buildTargetFileName(target, extension: extension);

    final imported = await storage.importSound(
      sourcePath: path,
      targetFileName: targetFileName,
      copyOnImport: copyOnImport,
    );

    if (imported.error != null) {
      return SoundPickResult(error: imported.error);
    }

    final storedPath = imported.path ?? path;
    final custom = SelectedSound.custom(storedPath);

    final task = state;
    if (task != null) {
      final slot = _slotForTarget(target);
      final fallbackBuiltInId = _fallbackBuiltInFromTask(task, slot);
      await _soundOverrides.setOverride(
        taskId: task.id,
        slot: slot,
        sound: custom,
        fallbackBuiltInId: fallbackBuiltInId,
        displayName: displayName,
      );
      if (displayName != null && displayName.trim().isNotEmpty) {
        _customDisplayNames[slot] = displayName;
      } else {
        _customDisplayNames.remove(slot);
      }
    }

    return SoundPickResult(sound: custom);
  }

  String _fallbackBuiltInFromTask(PomodoroTask task, SoundSlot slot) {
    final current = switch (slot) {
      SoundSlot.pomodoroStart => task.startSound,
      SoundSlot.breakStart => task.startBreakSound,
    };
    if (current.type == SoundType.builtIn && current.value.isNotEmpty) {
      return current.value;
    }
    return slot == SoundSlot.pomodoroStart
        ? 'default_chime'
        : 'default_chime_break';
  }

  Future<bool> _isDurationAcceptable(String path) async {
    // just_audio is not available on all desktop targets (e.g., Windows), so
    // skip the duration check there to avoid MissingPluginException.
    if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux) {
      return true;
    }

    AudioPlayer? player;
    try {
      player = AudioPlayer();
      final duration = await player.setFilePath(path);
      if (duration == null) return true;
      return duration.inSeconds <= _maxSoundDurationSeconds;
    } catch (_) {
      return true;
    } finally {
      await player?.dispose();
    }
  }

  String _buildTargetFileName(
    SoundPickTarget target, {
    required String extension,
  }) {
    final base = switch (target) {
      SoundPickTarget.pomodoroStart => 'pomodoro_start_custom',
      SoundPickTarget.breakStart => 'break_start_custom',
    };
    return '$base.$extension';
  }

  Future<PomodoroSession?> _readCurrentSession() async {
    final repo = ref.read(pomodoroSessionRepositoryProvider);
    try {
      return await repo.watchSession().first;
    } on StateError {
      return null;
    }
  }
}
