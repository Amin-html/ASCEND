import 'package:flutter_test/flutter_test.dart';

import 'package:ascend/features/notifications/domain/notification_payload.dart';
import 'package:ascend/features/notifications/presentation/notification_routing.dart';

void main() {
  group('payload', () {
    test('task payload roundtrip', () {
      expect(taskPayload('abc'), 'task:abc');
      expect(taskIdFromPayload(taskPayload('abc')), 'abc');
      expect(taskIdFromPayload(taskPayload('a:b')), 'a:b');
    });

    test('non-task payloads have no task id', () {
      expect(taskIdFromPayload(null), isNull);
      expect(taskIdFromPayload(''), isNull);
      expect(taskIdFromPayload(planPayload), isNull);
      expect(taskIdFromPayload('task:'), isNull);
      expect(taskIdFromPayload('other:abc'), isNull);
    });
  });

  group('targetForPayload', () {
    test('a task payload opens the task on top of the current screen', () {
      final target = targetForPayload('task:abc');

      expect(target?.path, '/tasks/abc');
      expect(target?.push, isTrue);
    });

    test('the plan payload goes to the planner', () {
      final target = targetForPayload('plan');

      expect(target?.path, '/planner');
      expect(target?.push, isFalse);
    });

    test('unknown or empty payloads are ignored', () {
      expect(targetForPayload(null), isNull);
      expect(targetForPayload(''), isNull);
      expect(targetForPayload('garbage'), isNull);
      expect(targetForPayload('task:'), isNull);
    });

    test('ids are encoded safely in the path', () {
      expect(targetForPayload('task:a b/c')?.path, '/tasks/a%20b%2Fc');
    });
  });
}