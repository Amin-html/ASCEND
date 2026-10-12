import 'package:flutter_test/flutter_test.dart';

import 'package:ascend/core/utils/formatters.dart';
import 'package:ascend/features/statistics/domain/stats_models.dart';

void main() {
  group('buildSeries', () {
    test('fills missing days with zeros, oldest first', () {
      final series = buildSeries(
        const [DayStat(dayKey: '2026-10-07', tasksCompleted: 2)],
        DateTime(2026, 10, 8, 15),
        3,
      );

      expect(series.map((s) => s.dayKey), ['2026-10-06', '2026-10-07', '2026-10-08']);
      expect(series.map((s) => s.tasksCompleted), [0, 2, 0]);
    });

    test('crosses a month boundary', () {
      final series = buildSeries(const [], DateTime(2026, 10, 2), 5);

      expect(series.first.dayKey, '2026-09-28');
      expect(series.last.dayKey, '2026-10-02');
      expect(series.length, 5);
    });

    test('ignores stored days outside the window', () {
      final series = buildSeries(
        const [DayStat(dayKey: '2026-09-01', tasksCompleted: 9)],
        DateTime(2026, 10, 8),
        7,
      );

      expect(series.every((s) => s.tasksCompleted == 0), isTrue);
    });
  });

  group('summarize', () {
    test('adds everything up', () {
      final summary = summarize(const [
        DayStat(
          dayKey: '2026-10-07',
          tasksCompleted: 2,
          focusSeconds: 600,
          xpEarned: 30,
        ),
        DayStat(
          dayKey: '2026-10-08',
          tasksCompleted: 3,
          focusSeconds: 5400,
          xpEarned: 55,
          planCompleted: true,
        ),
        DayStat(dayKey: '2026-10-09'),
      ]);

      expect(summary.days, 3);
      expect(summary.tasksCompleted, 5);
      expect(summary.focusSeconds, 6000);
      expect(summary.xpEarned, 85);
      expect(summary.activeDays, 2);
      expect(summary.perfectDays, 1);
      expect(summary.hasActivity, isTrue);
      expect(summary.avgFocusSeconds, 2000);
      expect(summary.avgXp, 28);
    });

    test('an empty period has no activity', () {
      final summary = summarize(buildSeries(const [], DateTime(2026, 10, 8), 7));

      expect(summary.hasActivity, isFalse);
      expect(summary.avgXp, 0);
    });

    test('an empty series does not divide by zero', () {
      final summary = summarize(const []);

      expect(summary.avgFocusSeconds, 0);
      expect(summary.avgXp, 0);
    });
  });

  test('formatDurationShort and weekdayAbbr', () {
    expect(formatDurationShort(0), '0m');
    expect(formatDurationShort(59), '0m');
    expect(formatDurationShort(90), '1m');
    expect(formatDurationShort(3600), '1h');
    expect(formatDurationShort(5400), '1h 30m');
    expect(formatDurationShort(-5), '0m');
    expect(weekdayAbbr(DateTime(2026, 10, 8)), 'Thu');
  });
}