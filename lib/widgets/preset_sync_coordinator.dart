import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../presentation/providers.dart';
import '../data/models/pomodoro_preset.dart';
import '../data/services/app_mode_service.dart';

class PresetSyncCoordinator extends ConsumerStatefulWidget {
  final Widget child;

  const PresetSyncCoordinator({super.key, required this.child});

  @override
  ConsumerState<PresetSyncCoordinator> createState() =>
      _PresetSyncCoordinatorState();
}

class _PresetSyncCoordinatorState
    extends ConsumerState<PresetSyncCoordinator> {
  bool _pushing = false;
  ProviderSubscription<bool>? _syncSub;

  @override
  void initState() {
    super.initState();
    _syncSub = ref.listenManual<bool>(
      accountSyncEnabledProvider,
      (_, enabled) {
        if (enabled) {
          _maybePushAccountLocalPresets();
        }
      },
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _syncSub?.close();
    super.dispose();
  }

  Future<void> _maybePushAccountLocalPresets() async {
    if (_pushing) return;
    final appMode = ref.read(appModeProvider);
    if (appMode != AppMode.account) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final syncEnabled = ref.read(accountSyncEnabledProvider);
    if (!syncEnabled) return;

    _pushing = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final pushedKey = 'account_presets_pushed_v1_${user.uid}';
      final alreadyPushed = prefs.getBool(pushedKey) ?? false;
      if (alreadyPushed) return;

      final localRepo = ref.read(accountLocalPresetRepositoryProvider);
      final presets = await localRepo.getAll();
      final firestoreRepo = ref.read(firestorePresetRepositoryProvider);
      final remotePresets = await firestoreRepo.getAll();
      final hasClassicRemote =
          remotePresets.any((preset) => _isClassicPreset(preset));
      final presetsToPush = _normalizeDefaults(presets).where((preset) {
        if (_isClassicPreset(preset) && hasClassicRemote) {
          return false;
        }
        return true;
      });
      for (final preset in presetsToPush) {
        await firestoreRepo.save(preset);
      }
      await prefs.setBool(pushedKey, true);
    } finally {
      _pushing = false;
    }
  }

  bool _isClassicPreset(PomodoroPreset preset) {
    return preset.name.trim().toLowerCase() == 'classic pomodoro';
  }

  List<PomodoroPreset> _normalizeDefaults(List<PomodoroPreset> presets) {
    if (presets.isEmpty) return presets;
    final hasDefault = presets.any((preset) => preset.isDefault);
    if (hasDefault) return presets;
    final first = presets.first;
    return [first.copyWith(isDefault: true), ...presets.skip(1)];
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
