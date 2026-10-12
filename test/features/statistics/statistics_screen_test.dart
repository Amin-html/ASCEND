import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ascend/core/services/service_providers.dart';
import 'package:ascend/core/theme/app_theme.dart';
import 'package:ascend/features/statistics/data/stats_providers.dart';
import 'package:ascend/features/statistics/domain/stats_models.dart';
import 'package:ascend/features/statistics/presentation/statistics_screen.dart';

import '../../helpers/fakes.dart';
import '../../helpers/test_app.dart';

void main() {
  // 8 октября 2026: четверг.
  final now = DateTime(2026, 10, 8, 10);

  const stored = [
    DayStat(
      dayKey: '2026-10-07',
      tasksCompleted: 2,
      xpEarned: 30,
    ),
    DayStat(
      dayKey: '2026-10-08',
      tasksCompleted: 3,
      focusSeconds: 5400,
      xpEarned: 55,
      planCompleted: true,
    ),
  ];

  Widget app(List<DayStat> data) {
    return ProviderScope(
      overrides: [
        clockProvider.overrideWithValue(FakeClock(now)),
        statsRangeProvider.overrideWith((ref, days) => Stream.value(data)),
      ],
      child: MaterialApp(theme: AppTheme.dark, home: const StatisticsScreen()),
    );
  }

  testWidgets('empty period shows the empty state', (tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(app(const []));
    await tester.pumpAndSettle();

    expect(find.text('No activity yet'), findsOneWidget);
    expect(find.text('Tasks done'), findsNothing);
  });

  testWidgets('shows the summary and the charts', (tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(app(stored));
    await tester.pumpAndSettle();

    expect(find.text('Tasks done'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('Focus time'), findsOneWidget);
    expect(find.text('1h 30m'), findsOneWidget);
    expect(find.text('XP earned'), findsNWidgets(2));
    expect(find.text('85'), findsOneWidget);
    expect(find.text('Perfect days'), findsOneWidget);
    expect(find.text('2 active days'), findsOneWidget);

    expect(find.text('Tasks completed'), findsOneWidget);
    expect(find.text('Total 5'), findsOneWidget);
    expect(find.text('Total 1h 30m'), findsOneWidget);
    expect(find.text('Total 85'), findsOneWidget);

    // Подписи дней недели у семидневного графика.
    expect(find.text('Thu'), findsNWidgets(3));
  });

  testWidgets('switching to 30 days keeps working', (tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(app(stored));
    await tester.pumpAndSettle();

    await tester.tap(find.text('30 days'));
    await tester.pumpAndSettle();

    expect(find.text('Tasks done'), findsOneWidget);
    expect(find.text('Total 5'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}