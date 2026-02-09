const int kCurrentDataVersion = 1;

int readDataVersion(Map<String, dynamic> map, {int fallback = kCurrentDataVersion}) {
  final value = map['dataVersion'];
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}
