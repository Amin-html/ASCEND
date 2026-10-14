import 'package:flutter_test/flutter_test.dart';

import 'package:ascend/features/home/presentation/home_screen.dart';
import 'package:ascend/features/planner/presentation/planner_screen.dart';
import 'package:ascend/features/tasks/domain/task.dart';
import 'package:ascend/features/tasks/presentation/task_detail_screen.dart';

import '../../helpers/fake_notification_service.dart';
import '../../helpers/test_app.dart';

void main() {
  final created = DateTime(2026, 10, 14, 9);
  final task = Task(
    id: 't1',
    title: 'Call Anna',
    createdAt: created,
    updatedAt: created,
  );

  testWidgets('tapping a task notification opens the task', (tester) async {
    final service = FakeNotificationService();
    await tester.pumpWidget(testApp(tasks: [task], notifications: service));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);

    service.tap('task:t1');
    await tester.pumpAndSettle();

    expect(find.byType(TaskDetailScreen), findsOneWidget);
    expect(find.text('Call Anna'), findsOneWidget);
    expect(find.text('Mark as done'), findsOneWidget);
  });

  testWidgets('tapping the evening reminder opens the planner', (tester) async {
    final service = FakeNotificationService();
    await tester.pumpWidget(testApp(notifications: service));
    await tester.pumpAndSettle();

    service.tap('plan');
    await tester.pumpAndSettle();

    expect(find.byType(PlannerScreen), findsOneWidget);
  });

  testWidgets('an app launched from a notification opens the task',
          (tester) async {
        final service = FakeNotificationService(launchPayload: 'task:t1');
        await tester.pumpWidget(testApp(tasks: [task], notifications: service));
        await tester.pumpAndSettle();

        expect(find.byType(TaskDetailScreen), findsOneWidget);
        expect(find.text('Call Anna'), findsOneWidget);
      });

  testWidgets('an app launched from the evening reminder opens the planner',
          (tester) async {
        final service = FakeNotificationService(launchPayload: 'plan');
        await tester.pumpWidget(testApp(notifications: service));
        await tester.pumpAndSettle();

        expect(find.byType(PlannerScreen), findsOneWidget);
      });

  testWidgets('unknown payloads change nothing', (tester) async {
    final service = FakeNotificationService();
    await tester.pumpWidget(testApp(notifications: service));
    await tester.pumpAndSettle();

    service.tap('garbage');
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(TaskDetailScreen), findsNothing);
  });

  testWidgets('a task that no longer exists shows a friendly message',
          (tester) async {
        final service = FakeNotificationService();
        await tester.pumpWidget(testApp(notifications: service));
        await tester.pumpAndSettle();

        service.tap('task:ghost');
        await tester.pumpAndSettle();

        expect(find.text('Task not found'), findsOneWidget);
      });
}