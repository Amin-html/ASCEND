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