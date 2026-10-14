import 'package:ascend/features/notifications/domain/notification_models.dart';
import 'package:ascend/features/notifications/domain/notification_service.dart';

class FakeNotificationService implements NotificationService {
  FakeNotificationService({
    this.supported = true,
    this.permissionGranted = true,
    this.testResult = true,
  });

  bool supported;
  bool permissionGranted;
  bool testResult;

  final List<List<PlannedNotification>> replaced = [];
  int permissionRequests = 0;
  int testCalls = 0;

  @override
  Future<bool> initialize() async => supported;

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return permissionGranted;
  }

  @override
  Future<void> replaceAll(List<PlannedNotification> items) async {
    replaced.add(List.of(items));
  }

  @override
  Future<bool> showTest() async {
    testCalls++;
    return testResult;
  }
}