enum SoundType { builtIn, custom }

class SelectedSound {
  final SoundType type;
  final String value;

  const SelectedSound({required this.type, required this.value});

  const SelectedSound.builtIn(this.value) : type = SoundType.builtIn;
  const SelectedSound.custom(this.value) : type = SoundType.custom;

  Map<String, dynamic> toMap() => {'type': type.name, 'value': value};

  factory SelectedSound.fromMap(
    Map<String, dynamic> map, {
    required String fallbackId,
  }) {
    final rawType = map['type'];
    final rawValue = map['value'];

    if (rawType is String && rawValue is String && rawValue.trim().isNotEmpty) {
      final type = SoundType.values.firstWhere(
        (t) => t.name == rawType,
        orElse: () => SoundType.builtIn,
      );
      return SelectedSound(type: type, value: rawValue);
    }

    return SelectedSound.builtIn(fallbackId);
  }

  static SelectedSound fromDynamic(dynamic raw, {required String fallbackId}) {
    if (raw is Map) {
      return SelectedSound.fromMap(
        Map<String, dynamic>.from(raw),
        fallbackId: fallbackId,
      );
    }
    if (raw is String) {
      final trimmed = raw.trim();
      return SelectedSound.builtIn(trimmed.isEmpty ? fallbackId : trimmed);
    }
    return SelectedSound.builtIn(fallbackId);
  }
}
