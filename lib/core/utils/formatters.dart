import 'package:intl/intl.dart';

String weekdayName(DateTime d) => DateFormat('EEEE', 'en_US').format(d);

String longDate(DateTime d) => DateFormat('d MMMM y', 'en_US').format(d);

String shortDate(DateTime d) => DateFormat('EEE, d MMM', 'en_US').format(d);

String formatMinutes(int minutes) {
  if (minutes < 60) return '$minutes min';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return m == 0 ? '$h h' : '$h h $m min';
}