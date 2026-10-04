import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ascend/app.dart';
import 'package:ascend/features/gamification/data/gamification_providers.dart';
import 'package:ascend/features/tasks/data/task_providers.dart';
import 'package:ascend/features/tasks/domain/category.dart';
import 'package:ascend/features/tasks/domain/task.dart';

/// Приложение с подставленными данными, без SQLite.
Widget testApp({List<Task> tasks = const [], int totalXp = 0}) {
  return ProviderScope(
    overrides: [
      tasksByDayProvider.overrideWith((ref, dayKey) => Stream.value(tasks)),
      categoriesProvider.overrideWith(
            (ref) => Stream.value(const <Category>[]),
      ),
      totalXpProvider.overrideWith((ref) => Stream.value(totalXp)),
      xpForDayProvider.overrideWith((ref, dayKey) => Stream.value(0)),
      activeDaysProvider.overrideWith(
            (ref) => Stream.value(const <String>{}),
      ),
    ],
    child: const AscendApp(),
  );
}

/// Высокое окно, чтобы ListView построил все секции.
void useTallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}