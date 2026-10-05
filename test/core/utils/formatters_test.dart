import 'package:flutter_test/flutter_test.dart';

import 'package:ascend/core/utils/formatters.dart';

void main() {
  test('formatBytes', () {
    expect(formatBytes(500), '500 B');
    expect(formatBytes(1536), '1.5 KB');
    expect(formatBytes(1572864), '1.5 MB');
  });

  test('dateTimeLabel', () {
    expect(dateTimeLabel(DateTime(2026, 10, 4, 14, 5)), '4 Oct 2026, 14:05');
  });

  test('date formatting is English regardless of system locale', () {
    final d = DateTime(2026, 10, 3);
    expect(weekdayName(d), 'Saturday');
    expect(longDate(d), '3 October 2026');
    expect(shortDate(d), 'Sat, 3 Oct');
  });
}