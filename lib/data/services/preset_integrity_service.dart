import '../models/pomodoro_preset.dart';

class PresetIntegrityResult {
  final List<PomodoroPreset> presets;
  final Map<String, PomodoroPreset> updates;

  const PresetIntegrityResult({
    required this.presets,
    required this.updates,
  });

  bool get changed => updates.isNotEmpty;
}

PresetIntegrityResult normalizePresets({
  required List<PomodoroPreset> presets,
  required DateTime now,
}) {
  if (presets.isEmpty) {
    return const PresetIntegrityResult(presets: [], updates: {});
  }

  final ordered = [...presets]
    ..sort((a, b) {
      final created = a.createdAt.compareTo(b.createdAt);
      if (created != 0) return created;
      return a.id.compareTo(b.id);
    });

  final defaultId = _pickDefaultId(presets);
  final used = <String>{};
  final updates = <String, PomodoroPreset>{};

  for (final preset in ordered) {
    final baseName = _normalizeName(preset.name);
    final uniqueName = _ensureUniqueName(baseName, used);
    final shouldDefault = preset.id == defaultId;

    if (uniqueName != preset.name || preset.isDefault != shouldDefault) {
      updates[preset.id] = preset.copyWith(
        name: uniqueName,
        isDefault: shouldDefault,
        updatedAt: now,
      );
    }
  }

  if (updates.isEmpty) {
    return PresetIntegrityResult(presets: presets, updates: updates);
  }

  final normalized = [
    for (final preset in presets) updates[preset.id] ?? preset,
  ];

  return PresetIntegrityResult(presets: normalized, updates: updates);
}

String _pickDefaultId(List<PomodoroPreset> presets) {
  if (presets.isEmpty) return '';

  final defaults = presets.where((preset) => preset.isDefault).toList();
  if (defaults.isNotEmpty) {
    defaults.sort((a, b) {
      final updated = b.updatedAt.compareTo(a.updatedAt);
      if (updated != 0) return updated;
      final created = b.createdAt.compareTo(a.createdAt);
      if (created != 0) return created;
      return a.id.compareTo(b.id);
    });
    return defaults.first.id;
  }

  final classic = presets.where((preset) {
    return _canonicalKey(preset.name) == 'classic pomodoro';
  }).toList();
  if (classic.isNotEmpty) {
    classic.sort((a, b) {
      final created = a.createdAt.compareTo(b.createdAt);
      if (created != 0) return created;
      return a.id.compareTo(b.id);
    });
    return classic.first.id;
  }

  final ordered = [...presets]
    ..sort((a, b) {
      final created = a.createdAt.compareTo(b.createdAt);
      if (created != 0) return created;
      return a.id.compareTo(b.id);
    });
  return ordered.first.id;
}

String _normalizeName(String name) {
  final trimmed = name.trim();
  return trimmed.isEmpty ? 'Untitled preset' : trimmed;
}

String _ensureUniqueName(String baseName, Set<String> used) {
  var candidate = baseName;
  var suffix = 2;
  while (used.contains(_canonicalKey(candidate))) {
    candidate = '$baseName ($suffix)';
    suffix += 1;
  }
  used.add(_canonicalKey(candidate));
  return candidate;
}

String _canonicalKey(String name) => name.trim().toLowerCase();
