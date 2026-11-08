import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/session_models.dart';
import '../interfaces/i_notification_service.dart';

const String _kHistoryKey = 'rh_notification_history_v1';
const String _kPendingKey = 'rh_notification_pending_bg_v1';

/// Handler cho tin nhận khi app chạy nền / đã đóng (isolate riêng).
/// Lưu tạm vào SharedPreferences để trung tâm thông báo hiển thị khi mở app.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  final prefs = await SharedPreferences.getInstance();
  final pending = prefs.getStringList(_kPendingKey) ?? <String>[];
  pending.add(jsonEncode(
    FirebaseNotificationService.toAppNotification(message, NotificationOrigin.background).toJson(),
  ));
  await prefs.setStringList(_kPendingKey, pending);
}

/// Firebase Cloud Messaging – 3 trạng thái: foreground / background / terminated.
class FirebaseNotificationService implements INotificationService {
  FirebaseNotificationService({FirebaseMessaging? messaging})
      : _messaging = messaging ?? FirebaseMessaging.instance {
    // Nghe "chạm thông báo khi app chạy nền" NGAY từ lúc khởi động (kể cả khi đang ở màn đăng nhập);
    // giữ lại tới khi NotificationViewModel nghe sau đăng nhập, không để mất deep link.
    _openedController = StreamController<AppNotification>.broadcast(onListen: _flushPendingOpened);
    _subs.add(FirebaseMessaging.onMessageOpenedApp.listen((m) {
      final n = toAppNotification(m, NotificationOrigin.background);
      if (_openedController.hasListener) {
        _openedController.add(n);
      } else {
        _pendingOpened.add(n);
      }
    }));
  }

  final FirebaseMessaging _messaging;
  final StreamController<AppNotification> _foreground = StreamController<AppNotification>.broadcast();
  late final StreamController<AppNotification> _openedController;
  final List<AppNotification> _pendingOpened = [];

  void _flushPendingOpened() {
    final pending = List.of(_pendingOpened);
    _pendingOpened.clear();
    for (final n in pending) {
      scheduleMicrotask(() => _openedController.add(n));
    }
  }
  final List<StreamSubscription<dynamic>> _subs = [];
  bool _initialized = false;

  static AppNotification toAppNotification(RemoteMessage m, NotificationOrigin origin) {
    final data = Map<String, dynamic>.from(m.data);
    return AppNotification(
      id: m.messageId ?? 'fcm-${DateTime.now().millisecondsSinceEpoch}',
      title: m.notification?.title ?? data['title']?.toString() ?? 'RecipeHub',
      body: m.notification?.body ?? data['body']?.toString() ?? '',
      receivedAt: m.sentTime ?? DateTime.now(),
      data: data,
      origin: origin,
    );
  }

  static NotificationPermission _mapStatus(AuthorizationStatus status) {
    if (status == AuthorizationStatus.authorized) return NotificationPermission.granted;
    if (status == AuthorizationStatus.provisional) return NotificationPermission.provisional;
    if (status == AuthorizationStatus.denied) return NotificationPermission.denied;
    return NotificationPermission.notDetermined;
  }

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    _subs.add(FirebaseMessaging.onMessage.listen(
      (m) => _foreground.add(toAppNotification(m, NotificationOrigin.foreground)),
    ));
  }

  @override
  Future<NotificationPermission> requestPermission() async {
    final settings = await _messaging.requestPermission(alert: true, badge: true, sound: true);
    return _mapStatus(settings.authorizationStatus);
  }

  @override
  Future<NotificationPermission> getPermissionStatus() async {
    final settings = await _messaging.getNotificationSettings();
    return _mapStatus(settings.authorizationStatus);
  }

  @override
  Future<String?> getToken() async {
    try {
      final token = await _messaging.getToken();
      // Không in cả token ra log: chỉ 8 ký tự đầu để đối chiếu với Firestore khi debug.
      if (kDebugMode && token != null) debugPrint('[FCM] token ${token.substring(0, 8)}…');
      return token;
    } catch (e) {
      debugPrint('[FCM] getToken failed: $e');
      return null;
    }
  }

  @override
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  @override
  Stream<AppNotification> get onForegroundMessage => _foreground.stream;

  @override
  Stream<AppNotification> get onNotificationOpened => _openedController.stream;

  @override
  Future<AppNotification?> getInitialNotification() async {
    final m = await _messaging.getInitialMessage();
    return m == null ? null : toAppNotification(m, NotificationOrigin.terminated);
  }

  @override
  Future<List<AppNotification>> loadHistory(String scope) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload(); // nhận dữ liệu do background isolate ghi
    // Lịch sử tách theo người dùng: máy dùng chung không lộ thông báo riêng của người trước.
    final history = (prefs.getStringList('${_kHistoryKey}_$scope') ?? const <String>[])
        .map((s) => AppNotification.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
    final pending = (prefs.getStringList(_kPendingKey) ?? const <String>[])
        .map((s) => AppNotification.fromJson(jsonDecode(s) as Map<String, dynamic>));
    for (final n in pending) {
      if (history.every((h) => h.id != n.id)) history.insert(0, n);
    }
    await prefs.remove(_kPendingKey);
    return history;
  }

  @override
  Future<void> saveHistory(String scope, List<AppNotification> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      '${_kHistoryKey}_$scope',
      items.take(100).map((n) => jsonEncode(n.toJson())).toList(),
    );
  }

  @override
  Future<void> subscribeToTopic(String topic) => _messaging.subscribeToTopic(topic);

  @override
  Future<void> unsubscribeFromTopic(String topic) => _messaging.unsubscribeFromTopic(topic);
}
