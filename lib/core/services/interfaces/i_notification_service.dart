import '../../models/session_models.dart';

/// Firebase Cloud Messaging boundary.
abstract class INotificationService {
  /// Đăng ký listener FCM (foreground / opened-app) – gọi 1 lần sau khi đăng nhập.
  Future<void> initialize();

  /// Xin quyền POST_NOTIFICATIONS (Android 13+).
  Future<NotificationPermission> requestPermission();

  Future<NotificationPermission> getPermissionStatus();

  /// FCM registration token (ghi log để gửi test message từ Console).
  Future<String?> getToken();

  /// Tin đến khi app đang mở (FirebaseMessaging.onMessage).
  Stream<AppNotification> get onForegroundMessage;

  /// Người dùng chạm thông báo khi app chạy nền (onMessageOpenedApp).
  Stream<AppNotification> get onNotificationOpened;

  /// Thông báo đã mở app từ trạng thái terminated (getInitialMessage).
  Future<AppNotification?> getInitialNotification();

  /// Lịch sử thông báo đã lưu cục bộ (bao gồm tin nhận lúc chạy nền).
  Future<List<AppNotification>> loadHistory();

  Future<void> saveHistory(List<AppNotification> items);

  /// Subscribe topic theo chi nhánh / vai trò (vd `store_lm81`, `role_viewer`).
  Future<void> subscribeToTopic(String topic);

  Future<void> unsubscribeFromTopic(String topic);
}
