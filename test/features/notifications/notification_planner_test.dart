import 'package:flutter_test/flutter_test.dart';

import 'package:ascend/features/notifications/domain/notification_models.dart';
import 'package:ascend/features/notifications/domain/notification_planner.dart';
import 'package:ascend/features/settings/domain/app_settings.dart';
import 'package:ascend/features/tasks/domain/task.dart';
import 'package:ascend/features/tasks/domain/task_enums.dart';

void main() {
  // 13 октября 2026, 15:00.
  final now = DateTime(2026, 10, 13, 15);
  const noEvening = AppSettings(dailyPlanReminderEnabled: false);

  Task task(
      String id, {
        String title = 'Task',
        String? dayKey,
        DateTime? start,
        int? lead,
        TaskStatus status = TaskStatus.todo,
      }) {
    return Task(
      id: id,
      title: title,
      dayKey: dayKey,
      startAt: start,
      reminderMinutesBefore: lead,
      status: status,
      createdAt: now,
      updatedAt: now,
    );
  }

  group('task reminders', () {
    test('disabled notifications plan nothing', () {
      final plan = planNotifications(
        now: now,
        settings: const AppSettings(notificationsEnabled: false),
        openTasks: [
          task('a', dayKey: '2026-10-13', start: DateTime(2026, 10, 13, 18), lead: 10),
        ],
      );

      expect(plan, isEmpty);
    });

    test('reminder fires the requested time before the start', () {
      final plan = planNotifications(
        now: now,
        settings: noEvening,
        openTasks: [
          task(
            'a',
            title: 'Call Anna',
            dayKey: '2026-10-13',
            start: DateTime(2026, 10, 13, 18),
            lead: 30,
          ),
        ],
      );

      expect(plan.length, 1);
      expect(plan.single.title, 'Call Anna');
      expect(plan.single.at, DateTime(2026, 10, 13, 17, 30));
      expect(plan.single.body, 'Starts in 30 min (at 18:00)');
      expect(plan.single.payload, 'task:a');
    });

    test('a reminder at the start time says so', () {
      final plan = planNotifications(
        now: now,
        settings: noEvening,
        openTasks: [
          task('a', dayKey: '2026-10-13', start: DateTime(2026, 10, 13, 18), lead: 0),
        ],
      );

      expect(plan.single.at, DateTime(2026, 10, 13, 18));
      expect(plan.single.body, 'Starts now');
    });

    test('reminders that are already in the past are skipped', () {
      final plan = planNotifications(
        now: now,
        settings: noEvening,
        openTasks: [
          // Напоминание было бы в 14:50, сейчас 15:00.
          task('a', dayKey: '2026-10-13', start: DateTime(2026, 10, 13, 15, 20), lead: 30),
        ],
      );

      expect(plan, isEmpty);
    });

    test('tasks without a time or a reminder are skipped', () {
      final plan = planNotifications(
        now: now,
        settings: noEvening,
        openTasks: [
          task('a', dayKey: '2026-10-13', start: DateTime(2026, 10, 13, 18)),
          task('b', dayKey: '2026-10-13', lead: 10),
        ],
      );

      expect(plan, isEmpty);
    });

    test('completed and cancelled tasks are skipped', () {
      final start = DateTime(2026, 10, 13, 18);
      final plan = planNotifications(
        now: now,
        settings: noEvening,
        openTasks: [
          task('a', dayKey: '2026-10-13', start: start, lead: 10, status: TaskStatus.completed),
          task('b', dayKey: '2026-10-13', start: start, lead: 10, status: TaskStatus.cancelled),
        ],
      );

      expect(plan, isEmpty);
    });

    test('reminders beyond the horizon are skipped', () {
      final plan = planNotifications(
        now: now,
        settings: noEvening,
        openTasks: [
          task('a', dayKey: '2026-11-20', start: DateTime(2026, 11, 20, 10), lead: 10),
        ],
      );

      expect(plan, isEmpty);
    });
  });

  group('evening plan reminder', () {
    final todayTasks = [
      task('a', dayKey: '2026-10-13'),
      task('b', dayKey: '2026-10-13'),
    ];

    test('today: planned while the time is still ahead', () {
      final plan = planNotifications(
        now: now,
        settings: const AppSettings(),
        openTasks: todayTasks,
      );

      expect(plan.length, 1);
      expect(plan.single.title, "Today's plan");
      expect(plan.single.at, DateTime(2026, 10, 13, 20));
      expect(plan.single.body, 'You still have 2 tasks to finish today.');
      expect(plan.single.id, dailyPlanIdBase);
      expect(plan.single.payload, 'plan');
    });

    test('a single task uses the singular', () {
      final plan = planNotifications(
        now: now,
        settings: const AppSettings(),
        openTasks: [task('a', dayKey: '2026-10-13')],
      );

      expect(plan.single.body, 'You still have 1 task to finish today.');
    });

    test('after the reminder time nothing is planned for today', () {
      final plan = planNotifications(
        now: DateTime(2026, 10, 13, 21),
        settings: const AppSettings(),
        openTasks: todayTasks,
      );

      expect(plan, isEmpty);
    });

    test('no open tasks today means no reminder', () {
      final plan = planNotifications(
        now: now,
        settings: const AppSettings(),
        openTasks: const [],
      );

      expect(plan, isEmpty);
    });

    test('future days get a reminder only when tasks are planned', () {
      final plan = planNotifications(
        now: now,
        settings: const AppSettings(),
        openTasks: [
          task('a', dayKey: '2026-10-15'),
          task('b', dayKey: '2026-10-17'),
          task('c', dayKey: '2026-10-17'),
        ],
      );

      expect(plan.map((n) => n.at), [
        DateTime(2026, 10, 15, 20),
        DateTime(2026, 10, 17, 20),
      ]);
      expect(plan.map((n) => n.id), [dailyPlanIdBase + 2, dailyPlanIdBase + 4]);
      expect(plan.last.body, 'You still have 2 tasks to finish today.');
    });

    test('days beyond the plan horizon are ignored', () {
      final plan = planNotifications(
        now: now,
        settings: const AppSettings(),
        openTasks: [task('a', dayKey: '2026-10-25')],
      );

      expect(plan, isEmpty);
    });

    test('custom time and switching it off', () {
      final custom = planNotifications(
        now: now,
        settings: const AppSettings(dailyPlanReminderMinutes: 18 * 60 + 30),
        openTasks: todayTasks,
      );
      expect(custom.single.at, DateTime(2026, 10, 13, 18, 30));

      final off = planNotifications(
        now: now,
        settings: noEvening,
        openTasks: todayTasks,
      );
      expect(off, isEmpty);
    });

    test('tasks without a date are ignored', () {
      final plan = planNotifications(
        now: now,
        settings: const AppSettings(),
        openTasks: [task('a')],
      );

      expect(plan, isEmpty);
    });
  });

  group('ordering, limits and ids', () {
    test('everything is sorted by time', () {
      final plan = planNotifications(
        now: now,
        settings: const AppSettings(),
        openTasks: [
          task('late', dayKey: '2026-10-13', start: DateTime(2026, 10, 13, 23), lead: 0),
          task('early', dayKey: '2026-10-13', start: DateTime(2026, 10, 13, 16), lead: 0),
        ],
      );

      expect(plan.map((n) => n.at).toList(), [
        DateTime(2026, 10, 13, 16),
        DateTime(2026, 10, 13, 20),
        DateTime(2026, 10, 13, 23),
      ]);
    });

    test('the plan is capped, keeping the earliest', () {
      final first = DateTime(2026, 10, 14, 10);
      final tasks = [
        for (var i = 0; i < 60; i++)
          task(
            't$i',
            dayKey: '2026-10-14',
            start: first.add(Duration(minutes: i)),
            lead: 0,
          ),
      ];

      final plan = planNotifications(now: now, settings: noEvening, openTasks: tasks);

      expect(plan.length, 50);
      expect(plan.first.at, first);
      expect(plan.last.at, first.add(const Duration(minutes: 49)));
    });

    test('ids are unique and stable', () {
      final first = DateTime(2026, 10, 14, 10);
      final tasks = [
        for (var i = 0; i < 200; i++)
          task('task-$i', dayKey: '2026-10-14', start: first.add(Duration(minutes: i)), lead: 0),
      ];

      final plan = planNotifications(
        now: now,
        settings: noEvening,
        openTasks: tasks,
        maxCount: 200,
      );

      expect(plan.map((n) => n.id).toSet().length, 200);
      expect(plan.every((n) => n.id >= 0 && n.id < dailyPlanIdBase), isTrue);
      expect(stableNotificationId('task:a'), stableNotificationId('task:a'));
      expect(stableNotificationId('task:a'), isNot(stableNotificationId('task:b')));
    });

    test('notifications are compared by value', () {
      final a = PlannedNotification(id: 1, title: 't', body: 'b', at: now);
      final b = PlannedNotification(id: 1, title: 't', body: 'b', at: now);
      final c = PlannedNotification(id: 2, title: 't', body: 'b', at: now);

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a == c, isFalse);
    });
  });
}