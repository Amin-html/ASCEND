const weekdayShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const weekdayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

String scheduleLabel(int mask) {
  final m = mask & 127;
  if (m == 127) return 'Every day';
  if (m == 31) return 'Weekdays';
  if (m == 96) return 'Weekends';
  final names = [
    for (var i = 0; i < 7; i++)
      if (((m >> i) & 1) == 1) weekdayShort[i],
  ];
  return names.isEmpty ? 'No days' : names.join(', ');
}

String streakLabel(int days) => days <= 0 ? 'No streak yet' : '$days-day streak';