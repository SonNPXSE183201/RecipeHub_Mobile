import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/session_models.dart';
import '../services/interfaces/i_crash_reporter.dart';
import '../services/interfaces/i_notification_service.dart';

/// Trung tâm thông báo (M-10) + FCM 3 trạng thái + deep link.
class NotificationViewModel extends ChangeNotifier {
  NotificationViewModel({
    required this._service,
    required this._crash,
  });

  final INotificationService _service;
  final ICrashReporter _crash;
  final List<StreamSubscription<AppNotification>> _subs = [];
  bool _disposed = false;
  bool _started = false;
  final List<String> _topics = [];

  List<AppNotification> _items = [];
  NotificationPermission _permission = NotificationPermission.notDetermined;
  String? _token;
  DeepLink? _pendingDeepLink;
  AppNotification? _pendingBanner;

  /// Id thông báo đã dùng để mở app (terminated hoặc background) đã xử lý. Không xóa khi đăng xuất:
  /// `getInitialMessage` có thể trả lại cùng tin trong suốt vòng đời process, nên đăng nhập lại
  /// không được mở lại deep link cũ.
  final Set<String> _handledInitialIds = {};
  bool _permissionPromptDismissed = false;

  List<AppNotification> get items {
    final sorted = List.of(_items)..sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
    return sorted;
  }

  int get unreadCount => _items.where((n) => !n.isRead).length;
  NotificationPermission get permission => _permission;
  String? get token => _token;
  bool get isStarted => _started;
  List<String> get topics => List.unmodifiable(_topics);

  /// Hiển thị primer xin quyền khi chưa từng hỏi (Android 13+).
  bool get shouldShowPermissionPrimer =>
      _started && !_permissionPromptDismissed && _permission == NotificationPermission.notDetermined;

  /// Gọi sau khi đăng nhập thành công.
  Future<void> start({required String roleCode, required String storeCode}) async {
    if (_started) return;
    _started = true;
    try {
      await _service.initialize();
      final history = await _service.loadHistory();
      _items = history;
      _permission = await _service.getPermissionStatus();
      _token = await _service.getToken();

      _subs.add(_service.onForegroundMessage.listen((n) {
        _upsert(n);
        _pendingBanner = n;
        _persist();
        _notify();
      }));
      _subs.add(_service.onNotificationOpened.listen((n) {
        // Android giữ intent của thông báo đã chạm; getInitialMessage có thể trả lại nó sau này.
        _handledInitialIds.add(n.id);
        _upsert(n..isRead = true);
        _pendingDeepLink = n.deepLink;
        _persist();
        _notify();
      }));

      final initial = await _service.getInitialNotification();
      if (initial != null && _handledInitialIds.add(initial.id)) {
        _upsert(initial..isRead = true);
        _pendingDeepLink = initial.deepLink;
      }

      for (final t in ['store_${storeCode.toLowerCase()}', 'role_$roleCode']) {
        try {
          await _service.subscribeToTopic(t);
          _topics.add(t);
        } catch (e, s) {
          await _crash.recordError(e, s, reason: 'fcm_subscribe');
        }
      }
      await _persist();
    } catch (e, s) {
      await _crash.recordError(e, s, reason: 'fcm_start');
    }
    _notify();
  }

  void _upsert(AppNotification n) {
    final i = _items.indexWhere((x) => x.id == n.id);
    if (i >= 0) {
      _items[i] = n;
    } else {
      _items.insert(0, n);
    }
  }

  Future<void> _persist() => _service.saveHistory(items);

  Future<NotificationPermission> requestPermission() async {
    _permission = await _service.requestPermission();
    _permissionPromptDismissed = true;
    if (_permission == NotificationPermission.granted) {
      _token = await _service.getToken();
    }
    _notify();
    return _permission;
  }

  void dismissPermissionPrimer() {
    _permissionPromptDismissed = true;
    _notify();
  }

  void markRead(String id) {
    for (final n in _items) {
      if (n.id == id) n.isRead = true;
    }
    _persist();
    _notify();
  }

  void markAllRead() {
    for (final n in _items) {
      n.isRead = true;
    }
    _persist();
    _notify();
  }

  /// Chạm 1 thông báo trong M-10 → đánh dấu đã đọc + phát deep link.
  void open(AppNotification n) {
    n.isRead = true;
    _pendingDeepLink = n.deepLink;
    _persist();
    _notify();
  }

  /// Shell gọi để lấy (và xóa) deep link chờ điều hướng.
  DeepLink? takePendingDeepLink() {
    final link = _pendingDeepLink;
    _pendingDeepLink = null;
    return link;
  }

  /// Shell gọi để lấy (và xóa) tin foreground cần hiện banner.
  AppNotification? takePendingBanner() {
    final b = _pendingBanner;
    _pendingBanner = null;
    return b;
  }

  Future<void> reset() async {
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
    for (final t in _topics) {
      try {
        await _service.unsubscribeFromTopic(t);
      } catch (_) {
        // Bỏ qua: topic có thể chưa từng subscribe khi offline.
      }
    }
    _topics.clear();
    _items = [];
    _pendingDeepLink = null;
    _pendingBanner = null;
    _started = false;
    _permissionPromptDismissed = false;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }
}
