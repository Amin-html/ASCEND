import 'package:intl/intl.dart';

String weekdayName(DateTime d) => DateFormat('EEEE', 'en_US').format(d);

String longDate(DateTime d) => DateFormat('d MMMM y', 'en_US').format(d);

String shortDate(DateTime d) => DateFormat('EEE, d MMM', 'en_US').format(d);

String dateTimeLabel(DateTime d) =>
    DateFormat('d MMM y, HH:mm', 'en_US').format(d);

String formatMinutes(int minutes) {
  if (minutes < 60) return '$minutes min';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return m == 0 ? '$h h' : '$h h $m min';
}

String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  final kb = bytes / 1024;
  if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
  return '${(kb / 1024).toStringAsFixed(1)} MB';
}

/// «1 task», «2 tasks». Для неправильных форм передайте [many].
String plural(int n, String one, [String? many]) {
  return '$n ${n == 1 ? one : (many ?? '${one}s')}';
}

/// Часы таймера: 05:03 или 1:02:05.
String formatClock(Duration d) {
  final total = d.inSeconds < 0 ? 0 : d.inSeconds;
  final h = total ~/ 3600;
  final m = (total % 3600) ~/ 60;
  final s = total % 60;
  String two(int n) => n.toString().padLeft(2, '0');
  return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
}

/// Короткая подпись дня недели: Mon, Tue...
String weekdayAbbr(DateTime d) => DateFormat('EEE', 'en_US').format(d);

/// Длительность в сокращённом виде: 45m, 2h, 1h 30m.
String formatDurationShort(int seconds) {
  final minutes = seconds < 0 ? 0 : seconds ~/ 60;
  if (minutes < 60) return '${minutes}m';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return m == 0 ? '${h}h' : '${h}h ${m}m';
}