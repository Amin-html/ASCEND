import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ascend/features/goals/presentation/goals_screen.dart';
import 'package:ascend/features/home/presentation/home_screen.dart';

import 'helpers/test_app.dart';

Future<void> pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(testApp());
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('starts on Home with bottom navigation', (tester) async {
    await pumpApp(tester);

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('switches tabs', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Goals'));
    await tester.pumpAndSettle();

    expect(find.byType(GoalsScreen), findsOneWidget);
  });

  testWidgets('FAB opens create sheet', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('New task'), findsOneWidget);
    expect(find.text('New goal'), findsOneWidget);
    expect(find.text('New habit'), findsOneWidget);
    expect(find.text('New note'), findsOneWidget);

    await tester.tap(find.text('New note'));
    await tester.pumpAndSettle();

    expect(find.text('Capture a thought'), findsNothing);
    expect(find.text('New note is coming soon'), findsOneWidget);
  });

  testWidgets('New habit opens the habit form', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New habit'));
    await tester.pumpAndSettle();

    expect(find.text('Create habit'), findsOneWidget);
  });

  testWidgets('New goal opens the goal form', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New goal'));
    await tester.pumpAndSettle();

    expect(find.text('Create goal'), findsOneWidget);
    expect(find.text('New goal is coming soon'), findsNothing);
  });

  testWidgets('uses navigation rail on wide screens', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpApp(tester);

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
}