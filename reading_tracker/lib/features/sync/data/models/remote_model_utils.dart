DateTime? readDateTime(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is DateTime) return value;
  if (value is String && value.isNotEmpty) return DateTime.parse(value);
  return null;
}

DateTime readRequiredDateTime(Map<String, dynamic> json, String key) {
  final value = readDateTime(json, key);
  if (value == null) {
    throw FormatException('Missing required DateTime field: $key');
  }
  return value;
}

String? writeDateTime(DateTime? value) => value?.toUtc().toIso8601String();

String writeDate(DateTime value) {
  final normalized = DateTime(value.year, value.month, value.day);
  return normalized.toIso8601String().split('T').first;
}

DateTime readRequiredDate(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is DateTime) return DateTime(value.year, value.month, value.day);
  if (value is String && value.isNotEmpty) return DateTime.parse(value);
  throw FormatException('Missing required Date field: $key');
}

double? readDouble(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is num) return value.toDouble();
  if (value is String && value.isNotEmpty) return double.parse(value);
  return null;
}
