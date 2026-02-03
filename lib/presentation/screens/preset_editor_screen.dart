import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/pomodoro_preset.dart';
import '../../data/models/selected_sound.dart';
import '../../data/services/local_sound_overrides.dart';
import '../../domain/validators.dart';
import '../../widgets/sound_selector.dart';
import '../../widgets/mode_indicator.dart';
import '../providers.dart';
import '../viewmodels/preset_editor_view_model.dart';

enum _UnsavedDecision { save, discard, cancel }

enum _DuplicateDecision { useExisting, renameExisting, saveAnyway, cancel }

enum _SaveOutcome { savedAndExit, blocked }

class _DuplicateResolution {
  final _DuplicateDecision decision;

  const _DuplicateResolution(this.decision);
}

class PresetEditorScreen extends ConsumerStatefulWidget {
  final bool isEditing;
  final String? presetId;
  final PomodoroPreset? seed;

  const PresetEditorScreen({
    super.key,
    required this.isEditing,
    this.presetId,
    this.seed,
  });

  @override
  ConsumerState<PresetEditorScreen> createState() => _PresetEditorScreenState();
}

class _PresetEditorScreenState extends ConsumerState<PresetEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _shortBreakFieldKey = GlobalKey<FormFieldState<String>>();
  final _longBreakFieldKey = GlobalKey<FormFieldState<String>>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _pomodoroCtrl;
  late final TextEditingController _shortBreakCtrl;
  late final TextEditingController _longBreakCtrl;
  late final TextEditingController _longBreakIntervalCtrl;
  late final FocusNode _shortBreakFocus;
  late final FocusNode _longBreakFocus;
  bool _intervalTouched = false;
  bool _breaksTouched = false;
  bool _shortBreakAutoAdjusted = false;
  bool _longBreakAutoAdjusted = false;
  bool _applyingBreakAutoAdjust = false;
  String? _loadedPresetId;
  bool _initializing = true;
  PomodoroPreset? _initialPresetSnapshot;
  LocalSoundOverride? _initialStartOverride;
  LocalSoundOverride? _initialBreakOverride;
  bool _handlingExit = false;
  bool _allowPop = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _pomodoroCtrl = TextEditingController();
    _shortBreakCtrl = TextEditingController();
    _longBreakCtrl = TextEditingController();
    _longBreakIntervalCtrl = TextEditingController();
    _shortBreakFocus = FocusNode();
    _longBreakFocus = FocusNode();
    _shortBreakFocus.addListener(() {
      if (_shortBreakFocus.hasFocus) return;
      _applyBreakAutoAdjust(BreakOrderField.shortBreak);
    });
    _longBreakFocus.addListener(() {
      if (_longBreakFocus.hasFocus) return;
      _applyBreakAutoAdjust(BreakOrderField.longBreak);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePreset();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _pomodoroCtrl.dispose();
    _shortBreakCtrl.dispose();
    _longBreakCtrl.dispose();
    _longBreakIntervalCtrl.dispose();
    _shortBreakFocus.dispose();
    _longBreakFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final preset = ref.watch(presetEditorProvider);
    if (_initializing) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final editor = ref.read(presetEditorProvider.notifier);
    final guidance = editor.breakGuidanceFor(preset);
    final breakOrderInvalid = preset != null &&
        !isBreakOrderValid(
          shortBreakMinutes: preset.shortBreakMinutes,
          longBreakMinutes: preset.longBreakMinutes,
        );
    final shortBlocking =
        breakOrderInvalid || (guidance?.shortExceedsPomodoro ?? false);
    final longBlocking =
        breakOrderInvalid || (guidance?.longExceedsPomodoro ?? false);
    final shortStatus = shortBlocking
        ? BreakDurationStatus.invalid
        : (guidance?.shortStatus ?? BreakDurationStatus.optimal);
    final longStatus = longBlocking
        ? BreakDurationStatus.invalid
        : (guidance?.longStatus ?? BreakDurationStatus.optimal);
    final breakAutovalidateMode =
        (_breaksTouched || shortBlocking || longBlocking)
            ? AutovalidateMode.always
            : AutovalidateMode.onUserInteraction;
    final pomodoroGuidance = preset == null
        ? null
        : buildPomodoroDurationGuidance(minutes: preset.pomodoroMinutes);
    final intervalInput = _parseIntervalInput();
    final intervalValue = preset == null
        ? null
        : intervalInput ?? preset.longBreakInterval;
    final intervalGuidance = preset == null || intervalValue == null
        ? null
        : buildLongBreakIntervalGuidance(
            interval: intervalValue,
            totalPomodoros: 4,
          );
    final intervalInvalid = _intervalTouched &&
        (intervalInput == null ||
            intervalInput < 1 ||
            intervalInput > maxLongBreakInterval);
    final shortRangeLabel = guidance?.shortRange.label;
    final longRangeLabel = guidance?.longRange.label;
    final showShortHelper = guidance != null && !shortBlocking;
    final showLongHelper = guidance != null && !longBlocking;
    final shortHelperBase = showShortHelper && shortRangeLabel != null
        ? 'Optimal range: $shortRangeLabel min'
        : null;
    final longHelperBase = showLongHelper && longRangeLabel != null
        ? 'Optimal range: $longRangeLabel min'
        : null;
    final shortHelper = showShortHelper
        ? _withAutoAdjustNote(shortHelperBase, _shortBreakAutoAdjusted)
        : null;
    final longHelper = showLongHelper
        ? _withAutoAdjustNote(longHelperBase, _longBreakAutoAdjusted)
        : null;
    final pomodoroHelper = pomodoroGuidance?.helperText;
    final pomodoroStatus =
        pomodoroGuidance?.status ?? PomodoroDurationStatus.optimal;
    final intervalHelper =
        intervalInvalid ? null : intervalGuidance?.helperText;
    final intervalStatus =
        intervalGuidance?.status ?? LongBreakIntervalStatus.optimal;
    _maybeSyncControllers(preset);
    if (preset != null) {
      _captureInitialSnapshot(preset);
    }

    if (preset == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final pomodoroDisplayName =
        editor.customDisplayName(PresetSoundPickTarget.pomodoroStart);
    final breakDisplayName =
        editor.customDisplayName(PresetSoundPickTarget.breakStart);

    const pomodoroSounds = [
      SoundOption('default_chime', 'Chime (pomodoro start)'),
      SoundOption('default_chime_break', 'Chime (break start)'),
      SoundOption('default_chime_finish', 'Finish chime'),
    ];

    const breakSounds = [
      SoundOption('default_chime_break', 'Chime (break start)'),
      SoundOption('default_chime', 'Chime (pomodoro start)'),
      SoundOption('default_chime_finish', 'Finish chime'),
    ];

    const finishSounds = [
      SoundOption('default_chime_finish', 'Finish chime'),
      SoundOption('default_chime', 'Chime'),
      SoundOption('default_chime_break', 'Break chime'),
    ];

    return PopScope(
      canPop: _allowPop || !_hasUnsavedChanges(preset),
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _handleExitRequest(preset);
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: Text(widget.isEditing ? "Edit preset" : "New preset"),
          actions: [
            const ModeIndicatorAction(compact: true),
            TextButton(
              onPressed: () async {
                final outcome = await _handleSave();
                if (!context.mounted) return;
                if (outcome == _SaveOutcome.savedAndExit) {
                  _allowPopAndExit();
                }
              },
              child: const Text("Save"),
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _textField(
                label: "Preset name",
                controller: _nameCtrl,
                onChanged: (v) => _update(preset.copyWith(name: v)),
                validator: (v) {
                  final trimmed = v?.trim() ?? '';
                  if (trimmed.isEmpty) return 'Required';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                value: preset.isDefault,
                onChanged: preset.isDefault
                    ? null
                    : (value) => _update(preset.copyWith(isDefault: value)),
                activeThumbColor: Colors.amberAccent,
                title: const Text(
                  'Set as default preset',
                  style: TextStyle(color: Colors.white70),
                ),
                subtitle: preset.isDefault
                    ? const Text(
                        'Default preset (choose another preset to change it).',
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      )
                    : null,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 12),
              _numberField(
                label: "Pomodoro duration (min)",
                controller: _pomodoroCtrl,
                onChanged: (v) {
                  final pomodoroGuidance = buildPomodoroDurationGuidance(
                    minutes: v,
                  );
                  if (pomodoroGuidance.isValid) {
                    final adjustment = adjustBreakDurations(
                      pomodoroMinutes: v,
                      shortBreakMinutes: preset.shortBreakMinutes,
                      longBreakMinutes: preset.longBreakMinutes,
                    );
                    final updated = preset.copyWith(
                      pomodoroMinutes: v,
                      shortBreakMinutes: adjustment.shortBreakMinutes,
                      longBreakMinutes: adjustment.longBreakMinutes,
                    );
                    _update(updated);
                    if (adjustment.anyAdjusted) {
                      _applyingBreakAutoAdjust = true;
                      try {
                        _shortBreakCtrl.text =
                            adjustment.shortBreakMinutes.toString();
                        _longBreakCtrl.text =
                            adjustment.longBreakMinutes.toString();
                        _setBreakAutoAdjustFlags(adjustment);
                      } finally {
                        _applyingBreakAutoAdjust = false;
                      }
                    } else {
                      _clearBreakAutoAdjustFlags();
                    }
                  } else {
                    _clearBreakAutoAdjustFlags();
                    _update(preset.copyWith(pomodoroMinutes: v));
                  }
                  _revalidateBreakFields();
                },
                helperText: pomodoroHelper,
                helperColor: _pomodoroHelperColor(pomodoroStatus),
                borderColor: _pomodoroBorderColor(
                  pomodoroStatus,
                  focused: false,
                ),
                focusedBorderColor: _pomodoroBorderColor(
                  pomodoroStatus,
                  focused: true,
                ),
                helperMaxLines: 2,
                additionalValidator: (value) => _pomodoroRangeValidator(value),
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),
              _numberField(
                label: "Short break (min)",
                fieldKey: _shortBreakFieldKey,
                controller: _shortBreakCtrl,
                focusNode: _shortBreakFocus,
                onChanged: (v) {
                  if (_applyingBreakAutoAdjust) return;
                  if (!_breaksTouched) {
                    setState(() {
                      _breaksTouched = true;
                    });
                  }
                  _clearBreakAutoAdjustFlags();
                  _update(preset.copyWith(shortBreakMinutes: v));
                  _revalidateBreakFields();
                },
                helperText: shortHelper,
                helperColor: _statusHelperColor(shortStatus),
                borderColor: _statusBorderColor(shortStatus, focused: false),
                focusedBorderColor:
                    _statusBorderColor(shortStatus, focused: true),
                additionalValidator: (value) => _breakFieldValidator(
                  value: value,
                  label: 'Short break',
                  orderField: BreakOrderField.shortBreak,
                  otherController: _longBreakCtrl,
                ),
                autovalidateMode: breakAutovalidateMode,
              ),
              _numberField(
                label: "Long break (min)",
                fieldKey: _longBreakFieldKey,
                controller: _longBreakCtrl,
                focusNode: _longBreakFocus,
                onChanged: (v) {
                  if (_applyingBreakAutoAdjust) return;
                  if (!_breaksTouched) {
                    setState(() {
                      _breaksTouched = true;
                    });
                  }
                  _clearBreakAutoAdjustFlags();
                  _update(preset.copyWith(longBreakMinutes: v));
                  _revalidateBreakFields();
                },
                helperText: longHelper,
                helperColor: _statusHelperColor(longStatus),
                borderColor: _statusBorderColor(longStatus, focused: false),
                focusedBorderColor:
                    _statusBorderColor(longStatus, focused: true),
                additionalValidator: (value) => _breakFieldValidator(
                  value: value,
                  label: 'Long break',
                  orderField: BreakOrderField.longBreak,
                  otherController: _shortBreakCtrl,
                ),
                autovalidateMode: breakAutovalidateMode,
              ),
              const SizedBox(height: 12),
              _numberField(
                label: "Pomodoros per long break",
                controller: _longBreakIntervalCtrl,
                onChanged: (v) =>
                    _update(preset.copyWith(longBreakInterval: v)),
                onTextChanged: (raw) {
                  if (!_intervalTouched) {
                    _intervalTouched = true;
                  }
                  if (int.tryParse(raw.trim()) == null) {
                    setState(() {});
                  }
                },
                helperText: intervalHelper,
                helperColor: _intervalHelperColor(
                  intervalStatus,
                  isInvalid: intervalInvalid,
                ),
                borderColor: _intervalBorderColor(
                  intervalStatus,
                  focused: false,
                  isInvalid: intervalInvalid,
                ),
                focusedBorderColor: _intervalBorderColor(
                  intervalStatus,
                  focused: true,
                  isInvalid: intervalInvalid,
                ),
                helperMaxLines: 2,
                additionalValidator: _longBreakIntervalValidator,
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),
            const SizedBox(height: 24),
            const Text(
              "Sounds",
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 4),
            const Text(
              "Custom sounds are stored on this device only.",
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 8),
            SoundSelector(
              label: "Pomodoro start",
              value: preset.startSound,
              options: pomodoroSounds,
              customDisplayName: pomodoroDisplayName,
              leading: const Icon(
                Icons.volume_up_rounded,
                color: Colors.redAccent,
                size: 16,
              ),
              onPickLocal: () async {
                final result = await ref
                    .read(presetEditorProvider.notifier)
                    .pickLocalSound(PresetSoundPickTarget.pomodoroStart);
                if (!context.mounted) return;
                if (result.error != null) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(result.error!)));
                  return;
                }
                if (result.sound != null) {
                  _update(preset.copyWith(startSound: result.sound));
                }
              },
              onChanged: (v) async {
                await ref
                    .read(presetEditorProvider.notifier)
                    .clearLocalSoundOverride(
                      PresetSoundPickTarget.pomodoroStart,
                    );
                _update(preset.copyWith(startSound: v));
              },
            ),
            const SizedBox(height: 12),
            SoundSelector(
              label: "Break start",
              value: preset.startBreakSound,
              options: breakSounds,
              customDisplayName: breakDisplayName,
              leading: const Icon(
                Icons.volume_up_rounded,
                color: Colors.blueAccent,
                size: 16,
              ),
              onPickLocal: () async {
                final result = await ref
                    .read(presetEditorProvider.notifier)
                    .pickLocalSound(PresetSoundPickTarget.breakStart);
                if (!context.mounted) return;
                if (result.error != null) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(result.error!)));
                  return;
                }
                if (result.sound != null) {
                  _update(preset.copyWith(startBreakSound: result.sound));
                }
              },
              onChanged: (v) async {
                await ref
                    .read(presetEditorProvider.notifier)
                    .clearLocalSoundOverride(
                      PresetSoundPickTarget.breakStart,
                    );
                _update(preset.copyWith(startBreakSound: v));
              },
            ),
            const SizedBox(height: 12),
            SoundSelector(
              label: "Task finish",
              value: preset.finishTaskSound,
              options: finishSounds,
              onChanged: (v) => _update(preset.copyWith(finishTaskSound: v)),
              leading: const Icon(
                Icons.volume_up_rounded,
                color: Colors.white70,
                size: 16,
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }

  void _exitEditor() {
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/settings/presets');
    }
  }

  void _allowPopAndExit() {
    if (_allowPop) {
      _exitEditor();
      return;
    }
    setState(() {
      _allowPop = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _exitEditor();
    });
  }

  void _captureInitialSnapshot(PomodoroPreset preset) {
    if (_initialPresetSnapshot != null) return;
    _initialPresetSnapshot = preset;
    Future.microtask(() async {
      final overrides = ref.read(localSoundOverridesProvider);
      final key = 'preset:${preset.id}';
      _initialStartOverride ??= await overrides.getOverride(
        key,
        SoundSlot.pomodoroStart,
      );
      _initialBreakOverride ??= await overrides.getOverride(
        key,
        SoundSlot.breakStart,
      );
    });
  }

  String _normalizeNumberText(String raw) {
    final trimmed = raw.trim();
    final value = int.tryParse(trimmed);
    return value == null ? trimmed : value.toString();
  }

  bool _hasUnsavedChanges(PomodoroPreset preset) {
    final baseline = _initialPresetSnapshot;
    if (baseline == null || baseline.id != preset.id) return false;
    if (_nameCtrl.text.trim() != baseline.name.trim()) return true;
    if (_normalizeNumberText(_pomodoroCtrl.text) !=
        baseline.pomodoroMinutes.toString()) {
      return true;
    }
    if (_normalizeNumberText(_shortBreakCtrl.text) !=
        baseline.shortBreakMinutes.toString()) {
      return true;
    }
    if (_normalizeNumberText(_longBreakCtrl.text) !=
        baseline.longBreakMinutes.toString()) {
      return true;
    }
    if (_normalizeNumberText(_longBreakIntervalCtrl.text) !=
        baseline.longBreakInterval.toString()) {
      return true;
    }
    if (preset.isDefault != baseline.isDefault) return true;
    if (!_soundMatches(preset.startSound, baseline.startSound)) return true;
    if (!_soundMatches(preset.startBreakSound, baseline.startBreakSound)) {
      return true;
    }
    if (!_soundMatches(preset.finishTaskSound, baseline.finishTaskSound)) {
      return true;
    }
    return false;
  }

  bool _soundMatches(SelectedSound current, SelectedSound baseline) {
    return current.type == baseline.type && current.value == baseline.value;
  }

  Future<_UnsavedDecision> _showUnsavedDialog() async {
    final result = await showDialog<_UnsavedDecision>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Unsaved changes'),
          content: const Text(
            'You have unsaved changes. What would you like to do?',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(_UnsavedDecision.cancel),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(_UnsavedDecision.discard),
              child: const Text('Discard'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(context).pop(_UnsavedDecision.save),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    return result ?? _UnsavedDecision.cancel;
  }

  Future<_DuplicateResolution> _showDuplicateDialog({
    required PomodoroPreset duplicate,
    required String useExistingLabel,
    required String renameLabel,
  }) async {
    final result = await showDialog<_DuplicateResolution>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Preset already exists'),
          content: Text(
            'The configuration you entered matches the preset '
            '"${duplicate.name}".',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context)
                  .pop(const _DuplicateResolution(_DuplicateDecision.cancel)),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(
                const _DuplicateResolution(_DuplicateDecision.useExisting),
              ),
              child: Text(useExistingLabel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(
                const _DuplicateResolution(_DuplicateDecision.renameExisting),
              ),
              child: Text(renameLabel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(
                const _DuplicateResolution(_DuplicateDecision.saveAnyway),
              ),
              child: const Text('Save anyway'),
            ),
          ],
        );
      },
    );
    return result ?? const _DuplicateResolution(_DuplicateDecision.cancel);
  }

  Future<String?> _promptRenameExisting({
    required String initialName,
  }) async {
    return Navigator.of(context).push<String>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => _RenamePresetScreen(
          initialName: initialName,
        ),
      ),
    );
  }

  Future<_SaveOutcome> _handleSave() async {
    if (!_formKey.currentState!.validate()) return _SaveOutcome.blocked;
    final messenger = ScaffoldMessenger.of(context);
    if (!await _validateBusinessRules()) return _SaveOutcome.blocked;
    final editor = ref.read(presetEditorProvider.notifier);
    final preset = ref.read(presetEditorProvider);
    if (preset == null) return _SaveOutcome.blocked;

    final duplicate = await editor.findDuplicatePreset(preset);
    if (!mounted) return _SaveOutcome.blocked;
    if (duplicate != null) {
      final useExistingLabel =
          widget.isEditing ? 'Discard changes' : 'Use existing';
      final trimmedName = preset.name.trim();
      final renameLabel = 'Rename "${duplicate.name}"';
      final resolution = await _showDuplicateDialog(
        duplicate: duplicate,
        useExistingLabel: useExistingLabel,
        renameLabel: renameLabel,
      );
      if (!mounted) return _SaveOutcome.blocked;
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return _SaveOutcome.blocked;
      switch (resolution.decision) {
        case _DuplicateDecision.useExisting:
          await _discardChanges(preset);
          if (!mounted) return _SaveOutcome.blocked;
          return _SaveOutcome.savedAndExit;
        case _DuplicateDecision.renameExisting:
          final suggestedName = widget.isEditing
              ? duplicate.name
              : (trimmedName.isEmpty ? duplicate.name : trimmedName);
          final renameTargetName = await _promptRenameExisting(
            initialName: suggestedName,
          );
          if (!mounted) return _SaveOutcome.blocked;
          final resolvedName = renameTargetName?.trim() ?? '';
          if (resolvedName.isEmpty) return _SaveOutcome.blocked;
          final renameResult = await editor.renamePreset(
            preset: duplicate,
            newName: resolvedName,
          );
          if (!mounted) return _SaveOutcome.blocked;
          if (!renameResult.success) {
            final message = renameResult.message ??
                'Failed to rename preset. Please try again.';
            messenger.showSnackBar(SnackBar(content: Text(message)));
            return _SaveOutcome.blocked;
          }
          if (renameResult.message != null) {
            messenger.showSnackBar(
              SnackBar(content: Text(renameResult.message!)),
            );
          }
          await _discardChanges(preset);
          if (!mounted) return _SaveOutcome.blocked;
          return _SaveOutcome.savedAndExit;
        case _DuplicateDecision.saveAnyway:
          break;
        case _DuplicateDecision.cancel:
          return _SaveOutcome.blocked;
      }
    }

    final result = await editor.save();
    if (!mounted) return _SaveOutcome.blocked;
    if (!result.success) {
      final message =
          result.message ?? 'Failed to save preset. Please try again.';
      messenger.showSnackBar(SnackBar(content: Text(message)));
      return _SaveOutcome.blocked;
    }
    if (result.message != null) {
      messenger.showSnackBar(SnackBar(content: Text(result.message!)));
    }
    return _SaveOutcome.savedAndExit;
  }

  Future<void> _restoreOverride({
    required LocalSoundOverrides overrides,
    required String presetKey,
    required SoundSlot slot,
    required LocalSoundOverride? baseline,
  }) async {
    if (baseline == null) {
      await overrides.clearOverride(presetKey, slot);
      return;
    }
    await overrides.setOverride(
      taskId: presetKey,
      slot: slot,
      sound: baseline.sound,
      fallbackBuiltInId: baseline.fallbackBuiltInId,
      displayName: baseline.displayName,
    );
  }

  Future<void> _discardChanges(PomodoroPreset preset) async {
    final baseline = _initialPresetSnapshot;
    if (baseline == null) return;
    final overrides = ref.read(localSoundOverridesProvider);
    final key = 'preset:${baseline.id}';
    await _restoreOverride(
      overrides: overrides,
      presetKey: key,
      slot: SoundSlot.pomodoroStart,
      baseline: _initialStartOverride,
    );
    await _restoreOverride(
      overrides: overrides,
      presetKey: key,
      slot: SoundSlot.breakStart,
      baseline: _initialBreakOverride,
    );
    ref.read(presetEditorProvider.notifier).update(baseline);
  }

  Future<void> _handleExitRequest(PomodoroPreset? preset) async {
    if (_handlingExit) return;
    _handlingExit = true;
    try {
      if (preset == null || !_hasUnsavedChanges(preset)) {
        _allowPopAndExit();
        return;
      }
      final decision = await _showUnsavedDialog();
      if (!mounted) return;
      switch (decision) {
        case _UnsavedDecision.save:
          final outcome = await _handleSave();
          if (!mounted) return;
          if (outcome == _SaveOutcome.savedAndExit) {
            _allowPopAndExit();
          }
          break;
        case _UnsavedDecision.discard:
          await _discardChanges(preset);
          if (!mounted) return;
          _allowPopAndExit();
          break;
        case _UnsavedDecision.cancel:
          break;
      }
    } finally {
      _handlingExit = false;
    }
  }

  void _update(PomodoroPreset updated) {
    ref.read(presetEditorProvider.notifier).update(updated);
  }

  void _applyBreakAutoAdjust(BreakOrderField preferred) {
    if (_applyingBreakAutoAdjust) return;
    final preset = ref.read(presetEditorProvider);
    if (preset == null) return;
    final pomodoroGuidance = buildPomodoroDurationGuidance(
      minutes: preset.pomodoroMinutes,
    );
    if (!pomodoroGuidance.isValid) {
      _clearBreakAutoAdjustFlags();
      return;
    }
    final shortValue = int.tryParse(_shortBreakCtrl.text.trim());
    final longValue = int.tryParse(_longBreakCtrl.text.trim());
    if (shortValue == null || longValue == null) return;
    final adjustment = adjustBreakDurationsForPreferred(
      pomodoroMinutes: preset.pomodoroMinutes,
      shortBreakMinutes: shortValue,
      longBreakMinutes: longValue,
      preferred: preferred,
    );
    if (!adjustment.anyAdjusted) {
      _clearBreakAutoAdjustFlags();
      return;
    }
    _applyingBreakAutoAdjust = true;
    try {
      _update(preset.copyWith(
        shortBreakMinutes: adjustment.shortBreakMinutes,
        longBreakMinutes: adjustment.longBreakMinutes,
      ));
      _shortBreakCtrl.text = adjustment.shortBreakMinutes.toString();
      _longBreakCtrl.text = adjustment.longBreakMinutes.toString();
      _setBreakAutoAdjustFlags(adjustment);
      _revalidateBreakFields();
    } finally {
      _applyingBreakAutoAdjust = false;
    }
  }

  void _clearBreakAutoAdjustFlags() {
    if (!_shortBreakAutoAdjusted && !_longBreakAutoAdjusted) return;
    setState(() {
      _shortBreakAutoAdjusted = false;
      _longBreakAutoAdjusted = false;
    });
  }

  void _setBreakAutoAdjustFlags(BreakDurationAdjustment adjustment) {
    setState(() {
      _shortBreakAutoAdjusted = adjustment.shortAdjusted;
      _longBreakAutoAdjusted = adjustment.longAdjusted;
    });
  }

  String? _withAutoAdjustNote(String? base, bool adjusted) {
    if (!adjusted) return base;
    const note = 'Adjusted to match the new pomodoro duration.';
    if (base == null || base.isEmpty) return note;
    return '$note\n$base';
  }

  void _revalidateBreakFields() {
    _shortBreakFieldKey.currentState?.validate();
    _longBreakFieldKey.currentState?.validate();
  }

  void _syncControllers(PomodoroPreset preset) {
    _loadedPresetId = preset.id;
    _nameCtrl.text = preset.name;
    _pomodoroCtrl.text = preset.pomodoroMinutes.toString();
    _shortBreakCtrl.text = preset.shortBreakMinutes.toString();
    _longBreakCtrl.text = preset.longBreakMinutes.toString();
    _longBreakIntervalCtrl.text = preset.longBreakInterval.toString();
    _intervalTouched = false;
    _breaksTouched = false;
    _shortBreakAutoAdjusted = false;
    _longBreakAutoAdjusted = false;
  }

  Future<void> _initializePreset() async {
    final editor = ref.read(presetEditorProvider.notifier);
    if (widget.isEditing && widget.presetId != null) {
      await editor.load(widget.presetId!);
    } else {
      final existing = ref.read(presetEditorProvider);
      if (existing == null) {
        editor.createNew(seed: widget.seed);
      }
    }
    if (!mounted) return;
    final preset = ref.read(presetEditorProvider);
    if (preset != null) {
      _syncControllers(preset);
      _captureInitialSnapshot(preset);
    }
    if (mounted) {
      setState(() {
        _initializing = false;
      });
    }
  }

  void _maybeSyncControllers(PomodoroPreset? preset) {
    if (preset == null) return;
    if (_loadedPresetId == preset.id) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_loadedPresetId == preset.id) return;
      _syncControllers(preset);
    });
  }

  int? _parseIntervalInput() {
    final raw = _longBreakIntervalCtrl.text.trim();
    if (raw.isEmpty) return null;
    return int.tryParse(raw);
  }

  Future<bool> _validateBusinessRules() async {
    final preset = ref.read(presetEditorProvider);
    if (preset == null) return false;
    final guidance =
        ref.read(presetEditorProvider.notifier).breakGuidanceFor(preset);
    if (guidance == null) return true;
    if (guidance.hasHardViolation) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Breaks must be shorter than the pomodoro duration "
            "(${preset.pomodoroMinutes} min).",
          ),
        ),
      );
      return false;
    }
    if (!guidance.hasSoftWarning) return true;
    final shouldContinue = await _showBreakWarningDialog(preset, guidance);
    return shouldContinue;
  }

  Future<bool> _showBreakWarningDialog(
    PomodoroPreset preset,
    BreakDurationGuidance guidance,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Break durations are outside the optimal range'),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                Text(
                  'For a ${preset.pomodoroMinutes} min pomodoro, recommended '
                  'ranges are:',
                ),
                const SizedBox(height: 8),
                Text(
                  'Short break: ${guidance.shortRange.label} min '
                  '(current: ${preset.shortBreakMinutes} min)',
                ),
                Text(
                  'Long break: ${guidance.longRange.label} min '
                  '(current: ${preset.longBreakMinutes} min)',
                ),
                const SizedBox(height: 8),
                const Text('Do you want to continue anyway?'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Adjust'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Save anyway'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  String? _breakMaxValidator({
    required int value,
    required int pomodoroMinutes,
    required String label,
  }) {
    if (pomodoroMinutes <= 0) return null;
    if (value >= pomodoroMinutes) {
      return '$label must be shorter than the pomodoro duration '
          '($pomodoroMinutes min).';
    }
    return null;
  }

  String? _breakFieldValidator({
    required int value,
    required String label,
    required BreakOrderField orderField,
    required TextEditingController otherController,
  }) {
    final pomodoroMinutes = _currentPomodoroMinutes();
    if (pomodoroMinutes == null) return null;
    final maxError = _breakMaxValidator(
      value: value,
      pomodoroMinutes: pomodoroMinutes,
      label: label,
    );
    if (maxError != null) return maxError;

    final otherValue = int.tryParse(otherController.text.trim());
    if (otherValue == null || otherValue <= 0) return null;

    final shortBreakMinutes = orderField == BreakOrderField.shortBreak
        ? value
        : otherValue;
    final longBreakMinutes = orderField == BreakOrderField.longBreak
        ? value
        : otherValue;

    return breakOrderError(
      shortBreakMinutes: shortBreakMinutes,
      longBreakMinutes: longBreakMinutes,
      field: orderField,
    );
  }

  int? _currentPomodoroMinutes() {
    final raw = _pomodoroCtrl.text.trim();
    final value = int.tryParse(raw);
    if (value == null || value <= 0) return null;
    return value;
  }

  String? _longBreakIntervalValidator(int value) {
    if (value > maxLongBreakInterval) {
      return 'Max $maxLongBreakInterval pomodoros. Longer cycles '
          'increase fatigue and reduce focus.';
    }
    return null;
  }

  String? _pomodoroRangeValidator(int value) {
    if (value < 15) {
      return 'Pomodoro must be at least 15 minutes.';
    }
    if (value > 60) {
      return 'Pomodoro must be 60 minutes or less.';
    }
    return null;
  }

  Color _statusHelperColor(BreakDurationStatus status) {
    return switch (status) {
      BreakDurationStatus.optimal => Colors.greenAccent,
      BreakDurationStatus.suboptimal => Colors.orangeAccent,
      BreakDurationStatus.invalid => Colors.redAccent,
    };
  }

  Color _statusBorderColor(
    BreakDurationStatus status, {
    required bool focused,
  }) {
    if (status == BreakDurationStatus.optimal) {
      return focused ? Colors.white54 : Colors.white24;
    }
    final base = _statusHelperColor(status);
    return focused ? base : base.withValues(alpha: 0.6);
  }

  Color _pomodoroHelperColor(PomodoroDurationStatus status) {
    return switch (status) {
      PomodoroDurationStatus.optimal => Colors.greenAccent,
      PomodoroDurationStatus.creative => Colors.lightGreenAccent,
      PomodoroDurationStatus.general => Colors.lightGreenAccent,
      PomodoroDurationStatus.deep => Colors.amberAccent,
      PomodoroDurationStatus.warning => Colors.orangeAccent,
      PomodoroDurationStatus.invalid => Colors.redAccent,
    };
  }

  Color _pomodoroBorderColor(
    PomodoroDurationStatus status, {
    required bool focused,
  }) {
    final base = _pomodoroHelperColor(status);
    return focused ? base : base.withValues(alpha: 0.6);
  }

  Color _intervalHelperColor(
    LongBreakIntervalStatus status, {
    required bool isInvalid,
  }) {
    if (isInvalid) return Colors.redAccent;
    return switch (status) {
      LongBreakIntervalStatus.optimal => Colors.greenAccent,
      LongBreakIntervalStatus.acceptable => Colors.amberAccent,
      LongBreakIntervalStatus.warning => Colors.orangeAccent,
    };
  }

  Color _intervalBorderColor(
    LongBreakIntervalStatus status, {
    required bool focused,
    required bool isInvalid,
  }) {
    final base = _intervalHelperColor(status, isInvalid: isInvalid);
    return focused ? base : base.withValues(alpha: 0.6);
  }

  Widget _textField({
    required String label,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      cursorColor: Colors.white,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: Colors.white10,
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white24),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white54),
        ),
      ),
    );
  }

  Widget _numberField({
    required String label,
    Key? fieldKey,
    required TextEditingController controller,
    FocusNode? focusNode,
    required ValueChanged<int> onChanged,
    ValueChanged<String>? onTextChanged,
    String? helperText,
    Color? helperColor,
    Color? borderColor,
    Color? focusedBorderColor,
    String? Function(int value)? additionalValidator,
    int? helperMaxLines,
    int errorMaxLines = 2,
    AutovalidateMode? autovalidateMode,
  }) {
    return TextFormField(
      key: fieldKey,
      controller: controller,
      focusNode: focusNode,
      keyboardType: TextInputType.number,
      style: const TextStyle(
        color: Colors.white,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
      cursorColor: Colors.white,
      autovalidateMode: autovalidateMode,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: Colors.white10,
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: borderColor ?? Colors.white24),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: focusedBorderColor ?? Colors.white54),
        ),
        helperText: helperText,
        helperStyle: TextStyle(
          color: helperColor ?? Colors.white38,
          fontSize: 11,
        ),
        helperMaxLines: helperMaxLines,
        errorMaxLines: errorMaxLines,
      ),
      validator: (v) {
        final value = int.tryParse(v ?? '');
        if (value == null || value <= 0) {
          return "Enter a valid number";
        }
        final extraError = additionalValidator?.call(value);
        if (extraError != null) return extraError;
        return null;
      },
      onChanged: (v) {
        onTextChanged?.call(v);
        final value = int.tryParse(v);
        if (value == null) return;
        onChanged(value);
      },
    );
  }
}

class _RenamePresetScreen extends StatefulWidget {
  final String initialName;

  const _RenamePresetScreen({
    required this.initialName,
  });

  @override
  State<_RenamePresetScreen> createState() => _RenamePresetScreenState();
}

class _RenamePresetScreenState extends State<_RenamePresetScreen> {
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      setState(() {
        _errorText = 'Preset name is required.';
      });
      return;
    }
    FocusScope.of(context).unfocus();
    Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Rename preset'),
        actions: [
          TextButton(
            onPressed: _submit,
            child: const Text('Rename'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            labelText: 'New preset name',
            errorText: _errorText,
          ),
        ),
      ),
    );
  }
}
