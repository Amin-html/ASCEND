import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ascend/core/theme/app_theme.dart';
import 'package:ascend/shared/widgets/segment_control.dart';
import 'package:ascend/shared/widgets/split_row.dart';

Widget _host(Widget child, {double width = 300, double scale = 1.0}) {
  return MaterialApp(
    theme: AppTheme.dark,
    builder: (context, app) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(scale),
      ),
      child: app!,
    ),
    home: Scaffold(
      body: Center(child: SizedBox(width: width, child: child)),
    ),
  );
}

void main() {
  group('SplitRow', () {
    testWidgets('keeps both parts on one line when they fit', (tester) async {
      await tester.pumpWidget(
        _host(const SplitRow(left: Text('Left'), right: Text('Right'))),
      );

      final left = tester.getTopLeft(find.text('Left'));
      final right = tester.getTopLeft(find.text('Right'));
      expect(left.dy, right.dy);
      expect(right.dx, greaterThan(left.dx));
    });

    testWidgets('wraps instead of overflowing when space runs out',
            (tester) async {
          await tester.pumpWidget(
            _host(
              const SplitRow(
                left: Text('Your progress this week'),
                right: Text('2 of 6 unlocked'),
              ),
              width: 220,
              scale: 2,
            ),
          );

          expect(tester.takeException(), isNull);
          expect(find.text('Your progress this week'), findsOneWidget);
          expect(find.text('2 of 6 unlocked'), findsOneWidget);
        });
  });

  group('SegmentControl', () {
    const segments = [
      ('low', 'Low'),
      ('medium', 'Medium'),
      ('high', 'High'),
      ('urgent', 'Urgent'),
    ];

    testWidgets('shows every option and reports taps', (tester) async {
      final changes = <String>[];
      await tester.pumpWidget(
        _host(
          SegmentControl<String>(
            segments: segments,
            selected: 'medium',
            onChanged: changes.add,
          ),
        ),
      );

      for (final s in segments) {
        expect(find.text(s.$2), findsOneWidget);
      }

      await tester.tap(find.text('High'));
      await tester.pump();

      expect(changes, ['high']);
    });

    testWidgets('fits a narrow width with a huge font', (tester) async {
      await tester.pumpWidget(
        _host(
          SegmentControl<String>(
            segments: segments,
            selected: 'urgent',
            onChanged: (_) {},
          ),
          width: 260,
          scale: 2,
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Urgent'), findsOneWidget);
    });
  });
}