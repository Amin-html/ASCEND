import 'dart:async';

import 'package:ascend/features/notifications/domain/notification_models.dart';
import 'package:ascend/features/notifications/domain/notification_service.dart';

class FakeNotificationService implements NotificationService {
  FakeNotificationService({
    this.supported = true,
    this.permissionGranted = true,
    this.testResult = true,
    this.launchPayload,
  });

  bool supported;
  bool permissionGranted;
  bool testResult;

  /// Что вернуть как «уведомление, запустившее приложение».
  String? launchPayload;

  final List<List<PlannedNotification>> replaced = [];
  int permissionRequests = 0;
  int testCalls = 0;

  final StreamController<String> _taps = StreamController<String>.broadcast();

  /// Имитирует нажатие на уведомление.
  void tap(String payload) => _taps.add(payload);

  @override
  Stream<String> get taps => _taps.stream;

  @override
  Future<String?> takeLaunchPayload() async {
    final payload = launchPayload;
    launchPayload = null;
    return payload;
  }

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