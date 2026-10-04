import 'package:flutter_test/flutter_test.dart';

import 'package:ascend/features/tasks/domain/task.dart';
import 'package:ascend/features/tasks/domain/task_enums.dart';

import '../../helpers/test_app.dart';

void main() {
  final created = DateTime(2026, 10, 4, 9);

  Task task(
      String id,
      String title, {
        int xp = 10,
        TaskStatus status = TaskStatus.todo,
      }) {
    return Task(
      id: id,
      title: title,
      status: status,
      xpReward: xp,
      createdAt: created,
      updatedAt: created,
    );
  }

  testWidgets('empty day shows empty state and level 1', (tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();

    expect(find.text('No tasks for today'), findsOneWidget);
    expect(find.text('No tasks planned yet'), findsOneWidget);
    expect(find.text('Level 1'), findsOneWidget);
  });

  testWidgets('shows progress and tasks of today', (tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(
      testApp(
        tasks: [
          task('1', 'Write report', xp: 15),
          task('2', 'Read chapter', status: TaskStatus.completed),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1 of 2 tasks completed'), findsOneWidget);
    expect(find.text('15 XP still available'), findsOneWidget);
    expect(find.text('Write report'), findsOneWidget);
    expect(find.text('Read chapter'), findsOneWidget);
  });

  testWidgets('shows level progress from total XP', (tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(testApp(totalXp: 150));
    await tester.pumpAndSettle();

    expect(find.text('Level 2'), findsOneWidget);
    expect(find.text('50 / 283 XP'), findsOneWidget);
    expect(find.text('Beginner'), findsOneWidget);
    expect(find.text('150 XP total'), findsOneWidget);
  });
}