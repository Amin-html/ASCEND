import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ascend/core/theme/app_theme.dart';
import 'package:ascend/features/tasks/domain/task.dart';
import 'package:ascend/features/tasks/presentation/task_card.dart';

void main() {
  final created = DateTime(2026, 10, 13, 8);

  Widget card(Task task) {
    return MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: TaskCard(
          task: task,
          onToggle: () {},
          onEdit: () {},
          onDelete: () {},
        ),
      ),
    );
  }

  testWidgets('shows the start time and a bell when a reminder is set',
          (tester) async {
        await tester.pumpWidget(
          card(
            Task(
              id: 't',
              title: 'Call Anna',
              startAt: DateTime(2026, 10, 13, 10, 30),
              reminderMinutesBefore: 10,
              createdAt: created,
              updatedAt: created,
            ),
          ),
        );

        expect(find.text('10:30'), findsOneWidget);
        expect(find.byIcon(Icons.notifications_active_rounded), findsOneWidget);
      });

  testWidgets('a time without a reminder uses a plain alarm icon',
          (tester) async {
        await tester.pumpWidget(
          card(
            Task(
              id: 't',
              title: 'Call Anna',
              startAt: DateTime(2026, 10, 13, 9, 5),
              createdAt: created,
              updatedAt: created,
            ),
          ),
        );

        expect(find.text('09:05'), findsOneWidget);
        expect(find.byIcon(Icons.alarm_rounded), findsOneWidget);
        expect(find.byIcon(Icons.notifications_active_rounded), findsNothing);
      });

  testWidgets('no time means no time label', (tester) async {
    await tester.pumpWidget(
      card(
        Task(
          id: 't',
          title: 'Read',
          createdAt: created,
          updatedAt: created,
        ),
      ),
    );

    expect(find.byIcon(Icons.alarm_rounded), findsNothing);
    expect(find.byIcon(Icons.notifications_active_rounded), findsNothing);
  });
}