import 'dart:async';

import '../../models/session_models.dart';
import '../interfaces/i_notification_service.dart';

/// FCM giả lập: test gọi [simulateForeground] / [simulateOpened] để phát tin.
class MockNotificationService implements INotificationService {
  MockNotificationService({
    this.permission = NotificationPermission.notDetermined,
    this.grantOnRequest = true,
    this.initialNotification,
  });

  NotificationPermission permission;
  bool grantOnRequest;
  AppNotification? initialNotification;
  final List<String> topics = [];
  List<AppNotification> _history = [];
  bool initialized = false;

  final StreamController<AppNotification> _foreground = StreamController<AppNotification>.broadcast();
  final StreamController<AppNotification> _opened = StreamController<AppNotification>.broadcast();

  void simulateForeground(AppNotification n) => _foreground.add(n);
  void simulateOpened(AppNotification n) => _opened.add(n);

  @override
  Future<void> initialize() async => initialized = true;

  @override
  Future<NotificationPermission> requestPermission() async {
    permission = grantOnRequest ? NotificationPermission.granted : NotificationPermission.denied;
    return permission;
  }

  @override
  Future<NotificationPermission> getPermissionStatus() async => permission;

  @override
  Future<String?> getToken() async => 'mock-fcm-token-RH-0001';

  @override
  Stream<AppNotification> get onForegroundMessage => _foreground.stream;

  @override
  Stream<AppNotification> get onNotificationOpened => _opened.stream;

  @override
  Future<AppNotification?> getInitialNotification() async {
    final n = initialNotification;
    initialNotification = null;
    return n;
  }

  @override
  Future<List<AppNotification>> loadHistory() async => List.of(_history);

  @override
  Future<void> saveHistory(List<AppNotification> items) async => _history = List.of(items);

  @override
  Future<void> subscribeToTopic(String topic) async {
    if (!topics.contains(topic)) topics.add(topic);
  }

  @override
  Future<void> unsubscribeFromTopic(String topic) async => topics.remove(topic);
}
