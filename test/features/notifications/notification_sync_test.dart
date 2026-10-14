import 'package:flutter_test/flutter_test.dart';

import 'package:ascend/core/utils/day_key.dart';
import 'package:ascend/features/settings/domain/app_settings.dart';
import 'package:ascend/features/tasks/domain/task.dart';

import '../../helpers/fake_notification_service.dart';
import '../../helpers/test_app.dart';

void main() {
  Task tomorrowTask({int? lead = 30}) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final start = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 10);
    return Task(
      id: 't1',
      title: 'Call Anna',
      dayKey: dayKeyOf(start),
      startAt: start,
      reminderMinutesBefore: lead,
      createdAt: start,
      updatedAt: start,
    );
  }

  testWidgets('task reminders are scheduled from open tasks', (tester) async {
    final service = FakeNotificationService();
    final task = tomorrowTask();

    await tester.pumpWidget(testApp(tasks: [task], notifications: service));
    await tester.pumpAndSettle();

    final plan = service.replaced.last;
    final start = task.startAt!;
    expect(
      plan.any(
            (n) =>
        n.title == 'Call Anna' &&
            n.at == start.subtract(const Duration(minutes: 30)),
      ),
      isTrue,
    );
  });

  testWidgets('the schedule is built once when nothing changes', (tester) async {
    final service = FakeNotificationService();

    await tester.pumpWidget(
      testApp(tasks: [tomorrowTask()], notifications: service),
    );
    await tester.pumpAndSettle();

    expect(service.replaced.length, 1);
  });

  testWidgets('permission is requested once when there is something to remind',
          (tester) async {
        final service = FakeNotificationService();

        await tester.pumpWidget(
          testApp(tasks: [tomorrowTask()], notifications: service),
        );
        await tester.pumpAndSettle();

        expect(service.permissionRequests, 1);
      });

  testWidgets('with nothing to remind the old schedule is cleared',
          (tester) async {
        final service = FakeNotificationService();

        await tester.pumpWidget(testApp(notifications: service));
        await tester.pumpAndSettle();

        expect(service.replaced.single, isEmpty);
        expect(service.permissionRequests, 0);
      });

  testWidgets('disabled notifications clear the schedule', (tester) async {
    final service = FakeNotificationService();

    await tester.pumpWidget(
      testApp(
        tasks: [tomorrowTask()],
        settings: const AppSettings(notificationsEnabled: false),
        notifications: service,
      ),
    );
    await tester.pumpAndSettle();

    expect(service.replaced.single, isEmpty);
    expect(service.permissionRequests, 0);
  });
}