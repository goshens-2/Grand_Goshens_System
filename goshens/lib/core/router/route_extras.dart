Map<String, dynamic>? asStringKeyedMap(Object? extra) {
  if (extra is Map<String, dynamic>) return extra;
  if (extra is Map) {
    return extra.map((key, value) => MapEntry(key.toString(), value));
  }
  return null;
}

String embeddedName(dynamic value, [String fallback = 'Unknown']) {
  if (value is Map) {
    return (value['full_name'] ?? value['name'] ?? fallback).toString();
  }
  return fallback;
}

String sanitizeSearchNeedle(String raw) {
  return raw.replaceAll(RegExp(r'[,*%()]'), ' ').trim();
}
