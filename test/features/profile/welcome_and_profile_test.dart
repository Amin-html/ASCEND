import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ascend/features/home/presentation/home_screen.dart';
import 'package:ascend/features/profile/domain/user_profile.dart';
import 'package:ascend/features/profile/presentation/welcome_screen.dart';
import 'package:ascend/features/settings/domain/app_settings.dart';

import '../../helpers/fake_profile_actions.dart';
import '../../helpers/test_app.dart';

void main() {
  group('welcome', () {
    testWidgets('new users start on the welcome screen', (tester) async {
      useTallScreen(tester);
      await tester.pumpWidget(testApp(settings: const AppSettings()));
      await tester.pumpAndSettle();

      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(find.text('Get started'), findsOneWidget);
      expect(find.text('Restore from a backup'), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('continuing without a name goes Home and saves nothing',
            (tester) async {
          useTallScreen(tester);
          final profile = FakeProfileActions();
          await tester.pumpWidget(
            testApp(settings: const AppSettings(), profileActions: profile),
          );
          await tester.pumpAndSettle();

          await tester.tap(find.text('Get started'));
          await tester.pumpAndSettle();

          expect(find.byType(HomeScreen), findsOneWidget);
          expect(find.byType(WelcomeScreen), findsNothing);
          expect(profile.calls, isEmpty);
        });

    testWidgets('the entered name is saved', (tester) async {
      useTallScreen(tester);
      final profile = FakeProfileActions();
      await tester.pumpWidget(
        testApp(settings: const AppSettings(), profileActions: profile),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '  Amin  ');
      await tester.tap(find.text('Get started'));
      await tester.pumpAndSettle();

      expect(profile.calls, ['setName:Amin']);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('restore from a backup opens the backup screen',
            (tester) async {
          useTallScreen(tester);
          await tester.pumpWidget(testApp(settings: const AppSettings()));
          await tester.pumpAndSettle();

          await tester.tap(find.text('Restore from a backup'));
          await tester.pumpAndSettle();

          expect(find.text('Data & Backup'), findsOneWidget);
        });

    testWidgets('onboarded users never see the welcome screen',
            (tester) async {
          await tester.pumpWidget(testApp());
          await tester.pumpAndSettle();

          expect(find.byType(HomeScreen), findsOneWidget);
          expect(find.byType(WelcomeScreen), findsNothing);
        });
  });

  group('greeting', () {
    testWidgets('Home greets the user by name', (tester) async {
      await tester.pumpWidget(
        testApp(profile: const UserProfile(name: 'Amin')),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining(', Amin'), findsOneWidget);
    });

    testWidgets('without a name the greeting has no comma', (tester) async {
      await tester.pumpWidget(testApp());
      await tester.pumpAndSettle();

      expect(find.textContaining('Good'), findsOneWidget);
      expect(find.textContaining(','), findsNothing);
    });
  });

  group('profile header', () {
    Future<void> openProfile(WidgetTester tester, Widget app) async {
      useTallScreen(tester);
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
    }

    testWidgets('invites to add a name when there is none', (tester) async {
      await openProfile(tester, testApp());

      expect(find.text('Add your name'), findsOneWidget);
    });

    testWidgets('shows the name and its initial', (tester) async {
      await openProfile(
        tester,
        testApp(profile: const UserProfile(name: 'Amin')),
      );

      expect(find.text('Amin'), findsOneWidget);
      expect(find.text('A'), findsOneWidget);
      expect(find.text('Add your name'), findsNothing);
    });

    testWidgets('tapping the header renames the user', (tester) async {
      final profile = FakeProfileActions();
      await openProfile(
        tester,
        testApp(
          profile: const UserProfile(name: 'Amin'),
          profileActions: profile,
        ),
      );

      await tester.tap(find.text('Amin'));
      await tester.pumpAndSettle();
      expect(find.text('Your name'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Sam');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(profile.calls, ['setName:Sam']);
    });

    testWidgets('cancelling keeps the name', (tester) async {
      final profile = FakeProfileActions();
      await openProfile(
        tester,
        testApp(
          profile: const UserProfile(name: 'Amin'),
          profileActions: profile,
        ),
      );

      await tester.tap(find.text('Amin'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(profile.calls, isEmpty);
    });
  });
}