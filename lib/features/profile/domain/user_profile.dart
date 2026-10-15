const int maxNameLength = 40;

/// Убирает лишние пробелы и обрезает имя до допустимой длины.
String normalizeName(String raw) {
  final collapsed = raw
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .join(' ');
  if (collapsed.length <= maxNameLength) return collapsed;
  return collapsed.substring(0, maxNameLength).trimRight();
}

class UserProfile {
  const UserProfile({this.name = ''});

  final String name;

  bool get hasName => name.isNotEmpty;

  /// Первая буква имени для аватара, пустая строка без имени.
  String get initial =>
      hasName ? String.fromCharCode(name.runes.first).toUpperCase() : '';
}