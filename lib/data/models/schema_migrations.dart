int readIntWithLegacy(
  Map<String, dynamic> map,
  String primaryKey, {
  List<String> legacyKeys = const [],
  required int fallback,
}) {
  final primary = map[primaryKey];
  if (primary is int) return primary;
  if (primary is num) return primary.toInt();
  if (primary is String) return int.tryParse(primary) ?? fallback;

  for (final key in legacyKeys) {
    final legacy = map[key];
    if (legacy is int) return legacy;
    if (legacy is num) return legacy.toInt();
    if (legacy is String) {
      final parsed = int.tryParse(legacy);
      if (parsed != null) return parsed;
    }
  }

  return fallback;
}

void writeIntWithLegacy(
  Map<String, dynamic> map,
  String primaryKey,
  int value, {
  List<String> legacyKeys = const [],
}) {
  map[primaryKey] = value;
  for (final key in legacyKeys) {
    map[key] = value;
  }
}
