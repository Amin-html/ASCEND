import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ascend/core/theme/app_theme.dart';
import 'package:ascend/shared/widgets/xp_bar.dart';

void main() {
  testWidgets('XpBar shows level and xp', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(
          body: XpBar(level: 7, currentXp: 340, nextLevelXp: 520),
        ),
      ),
    );

    expect(find.text('Level 7'), findsOneWidget);
    expect(find.text('340 / 520 XP'), findsOneWidget);
  });
}