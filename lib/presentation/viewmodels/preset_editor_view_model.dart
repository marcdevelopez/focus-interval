import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:just_audio/just_audio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/pomodoro_preset.dart';
import '../../data/models/pomodoro_task.dart';
import '../../data/models/selected_sound.dart';
import '../../domain/validators.dart';
import '../providers.dart';
import '../../data/services/local_sound_overrides.dart';
import '../../data/services/app_mode_service.dart';

enum PresetSoundPickTarget { pomodoroStart, breakStart }

class PresetSoundPickResult {
  final SelectedSound? sound;
  final String? error;

  const PresetSoundPickResult({this.sound, this.error});
}

class PresetSaveResult {
  final bool success;
  final String? message;

  const PresetSaveResult.success({this.message}) : success = true;

  const PresetSaveResult.failure(this.message) : success = false;
}

class PresetEditorViewModel extends Notifier<PomodoroPreset?> {
  static const int _maxSoundBytes = 2 * 1024 * 1024;
  static const int _maxSoundDurationSeconds = 10;

  final _uuid = const Uuid();
  late LocalSoundOverrides _soundOverrides;
  final Map<SoundSlot, String?> _customDisplayNames = {};

  @override
  PomodoroPreset? build() {
    _soundOverrides = ref.watch(localSoundOverridesProvider);
    return null;
  }

  void createNew({PomodoroPreset? seed}) {
    final now = DateTime.now();
    final base = seed;
    state = PomodoroPreset(
      id: _uuid.v4(),
      name: base?.name ?? '',
      pomodoroMinutes: base?.pomodoroMinutes ?? 25,
      shortBreakMinutes: base?.shortBreakMinutes ?? 5,
      longBreakMinutes: base?.longBreakMinutes ?? 15,
      longBreakInterval: base?.longBreakInterval ?? 4,
      startSound: base?.startSound ?? const SelectedSound.builtIn('default_chime'),
      startBreakSound:
          base?.startBreakSound ?? const SelectedSound.builtIn('default_chime_break'),
      finishTaskSound:
          base?.finishTaskSound ?? const SelectedSound.builtIn('default_chime_finish'),
      isDefault: base?.isDefault ?? false,
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<void> createFromTask(PomodoroTask task) async {
    final now = DateTime.now();
    final presetId = _uuid.v4();
    state = PomodoroPreset(
      id: presetId,
      name: '',
      pomodoroMinutes: task.pomodoroMinutes,
      shortBreakMinutes: task.shortBreakMinutes,
      longBreakMinutes: task.longBreakMinutes,
      longBreakInterval: task.longBreakInterval,
      startSound: task.startSound,
      startBreakSound: task.startBreakSound,
      finishTaskSound: task.finishTaskSound,
      isDefault: false,
      createdAt: now,
      updatedAt: now,
    );

    final startOverride = await _soundOverrides.getOverride(
      task.id,
      SoundSlot.pomodoroStart,
    );
    final breakOverride = await _soundOverrides.getOverride(
      task.id,
      SoundSlot.breakStart,
    );
    if (startOverride != null) {
      await _soundOverrides.setOverride(
        taskId: _overrideKey(presetId),
        slot: SoundSlot.pomodoroStart,
        sound: startOverride.sound,
        fallbackBuiltInId: startOverride.fallbackBuiltInId,
        displayName: startOverride.displayName,
      );
      _syncDisplayName(SoundSlot.pomodoroStart, startOverride);
    }
    if (breakOverride != null) {
      await _soundOverrides.setOverride(
        taskId: _overrideKey(presetId),
        slot: SoundSlot.breakStart,
        sound: breakOverride.sound,
        fallbackBuiltInId: breakOverride.fallbackBuiltInId,
        displayName: breakOverride.displayName,
      );
      _syncDisplayName(SoundSlot.breakStart, breakOverride);
    }
  }

  Future<void> load(String presetId) async {
    final repo = ref.read(presetRepositoryProvider);
    final preset = await repo.getById(presetId);
    if (preset == null) return;
    state = await _applyLocalOverrides(preset);
  }

  void update(PomodoroPreset preset) {
    state = preset;
  }

  BreakDurationGuidance? breakGuidanceFor(PomodoroPreset? preset) {
    if (preset == null) return null;
    return buildBreakDurationGuidance(
      pomodoroMinutes: preset.pomodoroMinutes,
      shortBreakMinutes: preset.shortBreakMinutes,
      longBreakMinutes: preset.longBreakMinutes,
    );
  }

  String? customDisplayName(PresetSoundPickTarget target) {
    return _customDisplayNames[_slotForTarget(target)];
  }

  Future<PresetSaveResult> save() async {
    final preset = state;
    if (preset == null) {
      return const PresetSaveResult.failure('No preset to save.');
    }
    final appMode = ref.read(appModeProvider);
    final user = ref.read(currentUserProvider);
    final syncEnabled = ref.read(accountSyncEnabledProvider);
    if (appMode == AppMode.account && user == null) {
      return const PresetSaveResult.failure('Sign in to save presets.');
    }
    final warning = (appMode == AppMode.account && !syncEnabled)
        ? 'Sync is disabled. Verify your email to save presets to your account.'
        : null;
    final repo = ref.read(presetRepositoryProvider);
    final now = DateTime.now();
    final withTimestamps = preset.copyWith(
      updatedAt: now,
      createdAt: preset.createdAt,
    );
    try {
      final sanitized = await _sanitizeForSync(withTimestamps);
      await repo.save(sanitized);
      if (sanitized.isDefault) {
        await _clearOtherDefaults(sanitized.id);
      }
      await _propagatePresetToTasks(sanitized);
      return PresetSaveResult.success(message: warning);
    } catch (error) {
      return PresetSaveResult.failure(_mapSaveError(error));
    }
  }

  Future<void> delete(String presetId) async {
    final repo = ref.read(presetRepositoryProvider);
    await repo.delete(presetId);
    await _clearPresetOverrides(presetId);
    await _detachPresetFromTasks(presetId);
  }

  String _mapSaveError(Object error) {
    final message = error.toString();
    if (message.contains('permission-denied')) {
      return 'Permission denied. Please check your account permissions.';
    }
    if (message.contains('No authenticated user')) {
      return 'Sign in to save presets.';
    }
    return 'Failed to save preset. Please try again.';
  }

  Future<void> setDefault(String presetId) async {
    final repo = ref.read(presetRepositoryProvider);
    final all = await repo.getAll();
    final now = DateTime.now();
    for (final preset in all) {
      final shouldDefault = preset.id == presetId;
      if (preset.isDefault == shouldDefault) continue;
      await repo.save(
        preset.copyWith(isDefault: shouldDefault, updatedAt: now),
      );
    }
  }

  Future<void> _clearOtherDefaults(String presetId) async {
    final repo = ref.read(presetRepositoryProvider);
    final all = await repo.getAll();
    final now = DateTime.now();
    for (final preset in all) {
      if (preset.id == presetId) continue;
      if (!preset.isDefault) continue;
      await repo.save(preset.copyWith(isDefault: false, updatedAt: now));
    }
  }

  Future<void> _propagatePresetToTasks(PomodoroPreset preset) async {
    final taskRepo = ref.read(taskRepositoryProvider);
    final tasks = await taskRepo.getAll();
    if (tasks.isEmpty) return;
    final now = DateTime.now();
    final startOverride = await _soundOverrides.getOverride(
      _overrideKey(preset.id),
      SoundSlot.pomodoroStart,
    );
    final breakOverride = await _soundOverrides.getOverride(
      _overrideKey(preset.id),
      SoundSlot.breakStart,
    );
    for (final task in tasks) {
      if (task.presetId != preset.id) continue;
      final updated = task.copyWith(
        pomodoroMinutes: preset.pomodoroMinutes,
        shortBreakMinutes: preset.shortBreakMinutes,
        longBreakMinutes: preset.longBreakMinutes,
        longBreakInterval: preset.longBreakInterval,
        startSound: preset.startSound,
        startBreakSound: preset.startBreakSound,
        finishTaskSound: preset.finishTaskSound,
        updatedAt: now,
      );
      await taskRepo.save(updated);
      await _applySoundOverrideToTarget(
        targetId: task.id,
        slot: SoundSlot.pomodoroStart,
        sourceSound: preset.startSound,
        sourceOverride: startOverride,
        fallbackBuiltInId: _fallbackBuiltInFromPreset(
          preset,
          SoundSlot.pomodoroStart,
        ),
      );
      await _applySoundOverrideToTarget(
        targetId: task.id,
        slot: SoundSlot.breakStart,
        sourceSound: preset.startBreakSound,
        sourceOverride: breakOverride,
        fallbackBuiltInId: _fallbackBuiltInFromPreset(
          preset,
          SoundSlot.breakStart,
        ),
      );
    }
  }

  Future<void> _detachPresetFromTasks(String presetId) async {
    final taskRepo = ref.read(taskRepositoryProvider);
    final tasks = await taskRepo.getAll();
    if (tasks.isEmpty) return;
    final now = DateTime.now();
    for (final task in tasks) {
      if (task.presetId != presetId) continue;
      await taskRepo.save(task.copyWith(presetId: null, updatedAt: now));
    }
  }

  Future<void> _clearPresetOverrides(String presetId) async {
    await _soundOverrides.clearOverride(_overrideKey(presetId), SoundSlot.pomodoroStart);
    await _soundOverrides.clearOverride(_overrideKey(presetId), SoundSlot.breakStart);
  }

  Future<PresetSoundPickResult> pickLocalSound(
    PresetSoundPickTarget target,
  ) async {
    if (kIsWeb) {
      return const PresetSoundPickResult(
        error: 'Custom sounds are not supported on web.',
      );
    }

    final storage = ref.read(localSoundStorageProvider);
    if (!storage.isSupported) {
      return const PresetSoundPickResult(
        error: 'Custom sounds are not supported on this platform.',
      );
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['mp3', 'wav', 'm4a'],
      withData: false,
    );

    if (result == null || result.files.isEmpty) {
      return const PresetSoundPickResult();
    }

    final file = result.files.first;
    final path = file.path;
    if (path == null || path.isEmpty) {
      return const PresetSoundPickResult(
        error: 'The selected file is not accessible.',
      );
    }

    final displayName = file.name.trim().isNotEmpty ? file.name.trim() : null;
    final extension = (file.extension ?? '').toLowerCase();
    const allowed = ['mp3', 'wav', 'm4a'];
    if (!allowed.contains(extension)) {
      return const PresetSoundPickResult(
        error: 'Unsupported format. Use mp3, wav, or m4a.',
      );
    }

    final size = await storage.fileSize(path);
    if (size != null && size > _maxSoundBytes) {
      return const PresetSoundPickResult(
        error: 'File is too large. Max size is 2 MB.',
      );
    }

    final okDuration = await _isDurationAcceptable(path);
    if (!okDuration) {
      return const PresetSoundPickResult(
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
      return PresetSoundPickResult(error: imported.error);
    }

    final storedPath = imported.path ?? path;
    final custom = SelectedSound.custom(storedPath);

    final preset = state;
    if (preset != null) {
      final slot = _slotForTarget(target);
      final fallbackBuiltInId = _fallbackBuiltInFromPreset(preset, slot);
      await _soundOverrides.setOverride(
        taskId: _overrideKey(preset.id),
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

    return PresetSoundPickResult(sound: custom);
  }

  Future<void> clearLocalSoundOverride(PresetSoundPickTarget target) async {
    final preset = state;
    if (preset == null) return;
    final slot = _slotForTarget(target);
    await _soundOverrides.clearOverride(_overrideKey(preset.id), slot);
    _customDisplayNames.remove(slot);
  }

  SoundSlot _slotForTarget(PresetSoundPickTarget target) {
    return switch (target) {
      PresetSoundPickTarget.pomodoroStart => SoundSlot.pomodoroStart,
      PresetSoundPickTarget.breakStart => SoundSlot.breakStart,
    };
  }

  String _overrideKey(String presetId) => 'preset:$presetId';

  Future<PomodoroPreset> _applyLocalOverrides(PomodoroPreset preset) async {
    final startOverride = await _soundOverrides.getOverride(
      _overrideKey(preset.id),
      SoundSlot.pomodoroStart,
    );
    final breakOverride = await _soundOverrides.getOverride(
      _overrideKey(preset.id),
      SoundSlot.breakStart,
    );
    _syncDisplayName(SoundSlot.pomodoroStart, startOverride);
    _syncDisplayName(SoundSlot.breakStart, breakOverride);
    return preset.copyWith(
      startSound: startOverride?.sound ?? preset.startSound,
      startBreakSound: breakOverride?.sound ?? preset.startBreakSound,
    );
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

  Future<PomodoroPreset> _sanitizeForSync(PomodoroPreset preset) async {
    final startFallback = await _fallbackBuiltInId(
      presetId: preset.id,
      slot: SoundSlot.pomodoroStart,
      current: preset.startSound,
      defaultId: 'default_chime',
    );
    final breakFallback = await _fallbackBuiltInId(
      presetId: preset.id,
      slot: SoundSlot.breakStart,
      current: preset.startBreakSound,
      defaultId: 'default_chime_break',
    );

    return preset.copyWith(
      startSound: preset.startSound.type == SoundType.custom
          ? SelectedSound.builtIn(startFallback)
          : preset.startSound,
      startBreakSound: preset.startBreakSound.type == SoundType.custom
          ? SelectedSound.builtIn(breakFallback)
          : preset.startBreakSound,
      finishTaskSound: preset.finishTaskSound.type == SoundType.custom
          ? const SelectedSound.builtIn('default_chime_finish')
          : preset.finishTaskSound,
    );
  }

  Future<String> _fallbackBuiltInId({
    required String presetId,
    required SoundSlot slot,
    required SelectedSound current,
    required String defaultId,
  }) async {
    if (current.type == SoundType.builtIn && current.value.isNotEmpty) {
      return current.value;
    }
    final override = await _soundOverrides.getOverride(
      _overrideKey(presetId),
      slot,
    );
    return override?.fallbackBuiltInId ?? defaultId;
  }

  String _fallbackBuiltInFromPreset(PomodoroPreset preset, SoundSlot slot) {
    final current = switch (slot) {
      SoundSlot.pomodoroStart => preset.startSound,
      SoundSlot.breakStart => preset.startBreakSound,
    };
    if (current.type == SoundType.builtIn && current.value.isNotEmpty) {
      return current.value;
    }
    return slot == SoundSlot.pomodoroStart
        ? 'default_chime'
        : 'default_chime_break';
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

  Future<bool> _isDurationAcceptable(String path) async {
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
    PresetSoundPickTarget target, {
    required String extension,
  }) {
    final base = switch (target) {
      PresetSoundPickTarget.pomodoroStart => 'preset_pomodoro_start',
      PresetSoundPickTarget.breakStart => 'preset_break_start',
    };
    return '$base.$extension';
  }
}
