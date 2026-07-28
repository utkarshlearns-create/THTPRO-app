/// Defensive readers for JSON coming off the Django API.
///
/// DRF is not consistent about types across this backend: `DecimalField` comes
/// back as a string (`"1500.00"`), `SerializerMethodField` can hand back an int
/// or a float, and any nullable column can be absent entirely rather than null.
/// Parsing with a bare cast crashes the screen on a value that is merely
/// unexpected, so every model reads through these instead.
library;

/// Reads [key] as a string, or [fallback] when missing/null.
String asString(Map<String, dynamic> json, String key, {String fallback = ''}) {
  final v = json[key];
  if (v == null) return fallback;
  return v is String ? v : v.toString();
}

/// Reads [key] as a string, or null when missing/null/blank.
String? asStringOrNull(Map<String, dynamic> json, String key) {
  final v = json[key];
  if (v == null) return null;
  final s = v is String ? v : v.toString();
  return s.trim().isEmpty ? null : s;
}

/// Reads [key] as an int. Accepts ints, doubles and numeric strings.
int asInt(Map<String, dynamic> json, String key, {int fallback = 0}) {
  final v = json[key];
  if (v == null) return fallback;
  if (v is int) return v;
  if (v is num) return v.round();
  return int.tryParse(v.toString()) ?? double.tryParse(v.toString())?.round() ?? fallback;
}

/// Reads [key] as an int, or null when missing/unparseable.
int? asIntOrNull(Map<String, dynamic> json, String key) {
  final v = json[key];
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.round();
  return int.tryParse(v.toString()) ?? double.tryParse(v.toString())?.round();
}

/// Reads [key] as a double. Accepts nums and the decimal strings DRF emits.
double asDouble(Map<String, dynamic> json, String key, {double fallback = 0}) {
  final v = json[key];
  if (v == null) return fallback;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? fallback;
}

/// Reads [key] as a double, or null when missing/unparseable.
double? asDoubleOrNull(Map<String, dynamic> json, String key) {
  final v = json[key];
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

/// Reads [key] as a bool. Accepts `true`, `"true"`, `1` and `"1"`.
bool asBool(Map<String, dynamic> json, String key, {bool fallback = false}) {
  final v = json[key];
  if (v == null) return fallback;
  if (v is bool) return v;
  if (v is num) return v != 0;
  final s = v.toString().toLowerCase();
  if (s == 'true' || s == '1' || s == 'yes') return true;
  if (s == 'false' || s == '0' || s == 'no') return false;
  return fallback;
}

/// Reads [key] as a list of strings, tolerating a JSON-ish string in a
/// `JSONField` that was stored as text (which happens on older rows).
List<String> asStringList(Map<String, dynamic> json, String key) {
  final v = json[key];
  if (v == null) return const [];
  if (v is List) {
    return v.where((e) => e != null).map((e) => e.toString()).toList();
  }
  final s = v.toString().trim();
  if (s.isEmpty || s == '[]') return const [];
  // "['Maths', 'Science']" or "Maths, Science"
  return s
      .replaceAll(RegExp(r'''^[\[\]]+|[\[\]]+$'''), '')
      .split(',')
      .map((e) => e.trim().replaceAll(RegExp('''^["']|["']\$'''), ''))
      .where((e) => e.isNotEmpty)
      .toList();
}

/// Reads [key] as a list of JSON objects, skipping anything that isn't a map.
List<Map<String, dynamic>> asMapList(Map<String, dynamic> json, String key) {
  final v = json[key];
  if (v is! List) return const [];
  return v.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
}

/// Reads [key] as a nested JSON object, or null.
Map<String, dynamic>? asMapOrNull(Map<String, dynamic> json, String key) {
  final v = json[key];
  if (v is Map) return v.cast<String, dynamic>();
  return null;
}

/// Reads [key] as a DateTime, or null. Handles ISO-8601 and `YYYY-MM-DD`.
DateTime? asDateOrNull(Map<String, dynamic> json, String key) {
  final v = json[key];
  if (v == null) return null;
  return DateTime.tryParse(v.toString())?.toLocal();
}
