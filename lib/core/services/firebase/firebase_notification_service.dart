import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  final uid = FirebaseAuth.instance.currentUser?.uid;
  // Tin nhận thuộc phiên hiện tại; không đưa sang tài khoản khác trên máy dùng chung.
  if (uid == null) return;
  await FirebaseNotificationService.saveScopedPending(
    prefs,
    uid,
    FirebaseNotificationService.toAppNotification(
      message,
      NotificationOrigin.background,
    ),
  );
}

/// Firebase Cloud Messaging – 3 trạng thái: foreground / background / terminated.
class FirebaseNotificationService implements INotificationService {
  FirebaseNotificationService({FirebaseMessaging? messaging})
    : _messaging = messaging ?? FirebaseMessaging.instance {
    // Nghe "chạm thông báo khi app chạy nền" NGAY từ lúc khởi động (kể cả khi đang ở màn đăng nhập);
    // giữ lại tới khi NotificationViewModel nghe sau đăng nhập, không để mất deep link.
    _openedController = StreamController<AppNotification>.broadcast(
      onListen: _flushPendingOpened,
    );
    _subs.add(
      FirebaseMessaging.onMessageOpenedApp.listen((m) {
        if (!_belongsToCurrentSession(m)) return;
        final n = toAppNotification(m, NotificationOrigin.background);
        if (_openedController.hasListener) {
          _openedController.add(n);
        } else {
          _pendingOpened.add((
            uid: FirebaseAuth.instance.currentUser!.uid,
            item: n,
          ));
        }
      }),
    );
  }

  final FirebaseMessaging _messaging;
  final StreamController<AppNotification> _foreground =
      StreamController<AppNotification>.broadcast();
  late final StreamController<AppNotification> _openedController;
  final List<({String uid, AppNotification item})> _pendingOpened = [];

  void _flushPendingOpened() {
    final pending = List.of(_pendingOpened);
    _pendingOpened.clear();
    for (final n in pending) {
      scheduleMicrotask(() {
        if (n.uid == FirebaseAuth.instance.currentUser?.uid) {
          _openedController.add(n.item);
        }
      });
    }
  }

  final List<StreamSubscription<dynamic>> _subs = [];
  bool _initialized = false;

  static AppNotification toAppNotification(
    RemoteMessage m,
    NotificationOrigin origin,
  ) {
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
    if (status == AuthorizationStatus.authorized) {
      return NotificationPermission.granted;
    }
    if (status == AuthorizationStatus.provisional) {
      return NotificationPermission.provisional;
    }
    if (status == AuthorizationStatus.denied) {
      return NotificationPermission.denied;
    }
    return NotificationPermission.notDetermined;
  }

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    _subs.add(
      FirebaseMessaging.onMessage.listen(
        (m) => _foreground.add(
          toAppNotification(m, NotificationOrigin.foreground),
        ),
      ),
    );
  }

  @override
  Future<NotificationPermission> requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
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
      if (kDebugMode && token != null) {
        debugPrint('[FCM] token ${token.substring(0, 8)}…');
      }
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
    return m == null || !_belongsToCurrentSession(m)
        ? null
        : toAppNotification(m, NotificationOrigin.terminated);
  }

  // FCM giữ intent cũ qua đăng xuất; tin gửi trước phiên mới không thuộc phiên đó.
  static bool _belongsToCurrentSession(RemoteMessage message) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    final signedIn = user.metadata.lastSignInTime;
    final sent = message.sentTime;
    return signedIn == null || sent == null || !sent.isBefore(signedIn);
  }

  @override
  Future<List<AppNotification>> loadHistory(String scope) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload(); // nhận dữ liệu do background isolate ghi
    return loadScopedHistory(prefs, scope);
  }

  /// Giữ 100 thông báo đến sau cùng trong lúc chờ tải lịch sử.
  static Future<void> saveScopedPending(
    SharedPreferences prefs,
    String scope,
    AppNotification item,
  ) async {
    final key = '${_kPendingKey}_$scope';
    final pending = prefs.getStringList(key) ?? <String>[];
    pending.add(jsonEncode(item.toJson()));
    if (pending.length > 100) {
      pending.removeRange(0, pending.length - 100);
    }
    await prefs.setStringList(key, pending);
  }

  /// Tách phần lưu trữ để kiểm chứng đổi tài khoản mà không khởi tạo FCM.
  static Future<List<AppNotification>> loadScopedHistory(
    SharedPreferences prefs,
    String scope,
  ) async {
    // Lịch sử tách theo người dùng: máy dùng chung không lộ thông báo riêng của người trước.
    final history =
        (prefs.getStringList('${_kHistoryKey}_$scope') ?? const <String>[])
            .map(
              (s) => AppNotification.fromJson(
                jsonDecode(s) as Map<String, dynamic>,
              ),
            )
            .toList();
    final pendingKey = '${_kPendingKey}_$scope';
    final pending = (prefs.getStringList(pendingKey) ?? const <String>[]).map(
      (s) => AppNotification.fromJson(jsonDecode(s) as Map<String, dynamic>),
    );
    for (final n in pending) {
      if (history.every((h) => h.id != n.id)) history.insert(0, n);
    }
    await prefs.remove(pendingKey);
    // Hàng đợi cũ không có chủ sở hữu: bỏ thay vì đoán người nhận.
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
  Future<void> subscribeToTopic(String topic) =>
      _messaging.subscribeToTopic(topic);

  @override
  Future<void> unsubscribeFromTopic(String topic) =>
      _messaging.unsubscribeFromTopic(topic);
}
