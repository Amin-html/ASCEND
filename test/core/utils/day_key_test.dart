import 'package:flutter_test/flutter_test.dart';

import 'package:ascend/core/utils/day_key.dart';

void main() {
  test('dayKeyOf formats local date', () {
    expect(dayKeyOf(DateTime(2026, 10, 3)), '2026-10-03');
    expect(dayKeyOf(DateTime(2026, 1, 9, 23, 59)), '2026-01-09');
  });

  test('dateFromDayKey roundtrip', () {
    expect(dateFromDayKey('2026-10-03'), DateTime(2026, 10, 3));
  });
}