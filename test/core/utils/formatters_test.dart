import 'package:flutter_test/flutter_test.dart';

import 'package:ascend/core/utils/formatters.dart';

void main() {
  test('formatMinutes', () {
    expect(formatMinutes(15), '15 min');
    expect(formatMinutes(60), '1 h');
    expect(formatMinutes(90), '1 h 30 min');
    expect(formatMinutes(120), '2 h');
  });

  test('date formatting is English regardless of system locale', () {
    final d = DateTime(2026, 10, 3);
    expect(weekdayName(d), 'Saturday');
    expect(longDate(d), '3 October 2026');
    expect(shortDate(d), 'Sat, 3 Oct');
  });
}