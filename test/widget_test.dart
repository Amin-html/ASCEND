import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ascend/app.dart';
import 'package:ascend/features/goals/presentation/goals_screen.dart';
import 'package:ascend/features/home/presentation/home_screen.dart';

Future<void> pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(const ProviderScope(child: AscendApp()));
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

  testWidgets('FAB opens create sheet and closes on selection', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('New task'), findsOneWidget);
    expect(find.text('New goal'), findsOneWidget);
    expect(find.text('New habit'), findsOneWidget);
    expect(find.text('New note'), findsOneWidget);

    await tester.tap(find.text('New task'));
    await tester.pumpAndSettle();

    expect(find.text('Plan something and earn XP'), findsNothing);
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