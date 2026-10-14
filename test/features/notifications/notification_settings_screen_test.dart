import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ascend/core/theme/app_theme.dart';
import 'package:ascend/features/notifications/data/notification_providers.dart';
import 'package:ascend/features/notifications/presentation/notification_settings_screen.dart';
import 'package:ascend/features/settings/data/settings_providers.dart';
import 'package:ascend/features/settings/domain/app_settings.dart';

import '../../helpers/fake_notification_service.dart';
import '../../helpers/fakes.dart';
import '../../helpers/test_app.dart';

void main() {
  late InMemorySettingsRepository repo;
  late FakeNotificationService service;

  Future<void> open(
      WidgetTester tester, {
        AppSettings settings = const AppSettings(),
      }) async {
    useTallScreen(tester);
    repo = InMemorySettingsRepository(settings);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(repo),
          notificationServiceProvider.overrideWithValue(service),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const NotificationSettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
    service = FakeNotificationService();
  });

  testWidgets('shows the options when notifications are on', (tester) async {
    await open(tester);

    expect(find.text('Allow notifications'), findsOneWidget);
    expect(find.text('Default reminder'), findsOneWidget);
    expect(find.text('At start'), findsOneWidget);
    expect(find.text('10 min before'), findsOneWidget);
    expect(find.text('Evening plan reminder'), findsOneWidget);
    expect(find.text('20:00'), findsOneWidget);
    expect(find.text('Send test notification'), findsOneWidget);
  });

  testWidgets('choosing a default reminder is saved', (tester) async {
    await open(tester);

    await tester.tap(find.text('30 min before'));
    await tester.pumpAndSettle();

    expect(repo.current.defaultReminderMinutesBefore, 30);
  });

  testWidgets('turning notifications off hides the options', (tester) async {
    await open(tester);

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    expect(repo.current.notificationsEnabled, isFalse);
    expect(find.text('Default reminder'), findsNothing);
    expect(find.text('Send test notification'), findsNothing);
  });

  testWidgets('turning them on asks for permission', (tester) async {
    await open(tester, settings: const AppSettings(notificationsEnabled: false));

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    expect(service.permissionRequests, 1);
    expect(repo.current.notificationsEnabled, isTrue);
    expect(find.text('Default reminder'), findsOneWidget);
  });

  testWidgets('a denied permission keeps them off and explains why',
          (tester) async {
        service.permissionGranted = false;
        await open(tester, settings: const AppSettings(notificationsEnabled: false));

        await tester.tap(find.byType(Switch).first);
        await tester.pumpAndSettle();

        expect(repo.current.notificationsEnabled, isFalse);
        expect(
          find.text(
            'Notifications are blocked for ASCEND. Allow them in the system settings.',
          ),
          findsOneWidget,
        );
      });

  testWidgets('the evening reminder can be switched off', (tester) async {
    await open(tester);

    await tester.tap(find.byType(Switch).at(1));
    await tester.pumpAndSettle();

    expect(repo.current.dailyPlanReminderEnabled, isFalse);
    expect(find.text('Reminder time'), findsNothing);
  });

  testWidgets('the test button schedules a notification', (tester) async {
    await open(tester);

    await tester.tap(find.text('Send test notification'));
    await tester.pumpAndSettle();

    expect(service.testCalls, 1);
    expect(
      find.text('Test notification scheduled. It should appear in a few seconds.'),
      findsOneWidget,
    );
  });

  testWidgets('an unavailable platform is explained and the test is disabled',
          (tester) async {
        service.supported = false;
        await open(tester);

        expect(
          find.text('Notifications are not available on this device.'),
          findsOneWidget,
        );
        final button = tester.widget<OutlinedButton>(
          find.widgetWithText(OutlinedButton, 'Send test notification'),
        );
        expect(button.onPressed, isNull);
      });
}