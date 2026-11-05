import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/session_models.dart';
import '../services/interfaces/i_crash_reporter.dart';
import '../services/interfaces/i_device_registry.dart';
import '../services/interfaces/i_notification_service.dart';

/// Trung tâm thông báo (M-10) + FCM 3 trạng thái + deep link.
class NotificationViewModel extends ChangeNotifier {
  NotificationViewModel({
    required this._service,
    required this._crash,
    this._devices,
  });

  /// Topic mọi máy đã đăng nhập đều nhận (Admin gửi "Tất cả nhân viên" trên web).
  static const String topicAll = 'all_staff';

  final INotificationService _service;
  final ICrashReporter _crash;
  final IDeviceRegistry? _devices;
  final List<StreamSubscription<dynamic>> _subs = [];
  String? _uid;
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

  /// Thời gian chờ tối đa cho thao tác cần server (offline: Firestore / FCM có thể treo rất lâu).
  static const Duration serverTimeout = Duration(seconds: 5);

  /// Tăng mỗi lần reset: phần còn chạy của start() cũ phát hiện và dừng, không ghi vào phiên mới.
  int _generation = 0;
  String? _roleTopic;

  /// Gọi sau khi đăng nhập thành công. [uid] dùng để lưu FCM token lên server (Firestore) và tách lịch sử.
  Future<void> start({required String roleCode, required String storeCode, String? uid}) async {
    if (_started) return;
    _started = true;
    _uid = uid;
    final gen = _generation;
    bool stale() => gen != _generation;
    try {
      await _service.initialize();
      if (stale()) return;
      // 1. Listener + thông báo mở app TRƯỚC: không phụ thuộc mạng.
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
      _subs.add(_service.onTokenRefresh.listen((t) {
        _token = t;
        unawaited(_registerToken(t));
        _notify();
      }));
      final history = await _service.loadHistory(_historyScope);
      if (stale()) return;
      // Tin vừa nhận/chạm trong bộ nhớ (vd. tin chạm lúc app tắt, phát ngay khi listen) mới hơn bản
      // background handler lưu → giữ bản bộ nhớ, cộng dồn cờ đã đọc; không để lịch sử cũ ghi đè.
      final fresh = {for (final n in _items) n.id: n};
      final merged = [
        for (final h in history)
          if (fresh.remove(h.id) case final m?) (m..isRead = m.isRead || h.isRead) else h,
      ];
      _items = [...fresh.values, ...merged];
      final initial = await _service.getInitialNotification();
      if (stale()) return;
      if (initial != null && _handledInitialIds.add(initial.id)) {
        _upsert(initial..isRead = true);
        _pendingDeepLink = initial.deepLink;
      }
      _permission = await _service.getPermissionStatus();
      if (stale()) return;
      _notify();

      // 2. Phần cần mạng: chạy nền, có timeout, kiểm tra thế hệ trước khi ghi vào state.
      unawaited(_connect(gen, roleCode: roleCode, storeCode: storeCode));
      await _persist();
    } catch (e, s) {
      await _crash.recordError(e, s, reason: 'fcm_start');
    }
    if (!stale()) _notify();
  }

  Future<void> _connect(int gen, {required String roleCode, required String storeCode}) async {
    try {
      final token = await _service.getToken().timeout(serverTimeout, onTimeout: () => null);
      if (gen != _generation) return;
      _token = token;
      await _registerToken(token);
      for (final t in [topicAll, 'store_${storeCode.toLowerCase()}']) {
        if (await _subscribe(t, gen)) _topics.add(t);
      }
      await updateRole(roleCode);
    } catch (e, s) {
      await _crash.recordError(e, s, reason: 'fcm_connect');
    }
    if (gen == _generation) _notify();
  }

  Future<bool> _subscribe(String topic, int gen) async {
    try {
      await _service.subscribeToTopic(topic).timeout(serverTimeout);
      return gen == _generation;
    } catch (e, s) {
      await _crash.recordError(e, s, reason: 'fcm_subscribe');
      return false;
    }
  }

  /// Vai trò đổi (server cấp / Admin đổi trên web) → đổi topic `role_*`.
  Future<void> updateRole(String roleCode) async {
    if (!_started) return;
    final next = 'role_$roleCode';
    if (_roleTopic == next) return;
    final gen = _generation;
    final old = _roleTopic;
    _roleTopic = next;
    if (old != null) {
      _topics.remove(old);
      try {
        await _service.unsubscribeFromTopic(old).timeout(serverTimeout);
      } catch (_) {}
    }
    if (await _subscribe(next, gen)) _topics.add(next);
    _notify();
  }

  String get _historyScope => _uid ?? 'guest';

  Future<void> _registerToken(String? token) async {
    final uid = _uid;
    if (_devices == null || uid == null || token == null) return;
    try {
      await _devices.register(uid, token).timeout(serverTimeout);
    } catch (e, s) {
      // Offline: Firestore vẫn giữ lệnh ghi trong hàng đợi và tự gửi khi có mạng.
      await _crash.recordError(e, s, reason: 'fcm_register_device');
    }
  }

  /// Xóa token của máy này khỏi server. Gọi TRƯỚC khi đăng xuất (sau đó không còn quyền ghi).
  Future<void> unregisterDevice() async {
    final uid = _uid;
    final token = _token;
    if (_devices == null || uid == null || token == null) return;
    try {
      await _devices.unregister(uid, token).timeout(serverTimeout);
    } catch (e, s) {
      await _crash.recordError(e, s, reason: 'fcm_unregister_device');
    }
  }

  void _upsert(AppNotification n) {
    final i = _items.indexWhere((x) => x.id == n.id);
    if (i >= 0) {
      _items[i] = n;
    } else {
      _items.insert(0, n);
    }
  }

  Future<void> _persist() => _service.saveHistory(_historyScope, items);

  Future<NotificationPermission> requestPermission() async {
    _permission = await _service.requestPermission();
    _permissionPromptDismissed = true;
    if (_permission == NotificationPermission.granted) {
      _token = await _service.getToken();
      await _registerToken(_token);
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

  /// Dọn phiên khi đăng xuất. Xóa trạng thái NGAY (đồng bộ) rồi mới hủy subscription / topic trên bản sao,
  /// để `start()` của lần đăng nhập kế tiếp không đụng danh sách đang được duyệt
  /// (lỗi thật bắt được qua Crashlytics: "Concurrent modification during iteration").
  Future<void> reset() async {
    _generation++;
    final subs = List.of(_subs);
    final topics = List.of(_topics);
    _roleTopic = null;
    _subs.clear();
    _topics.clear();
    _uid = null;
    _items = [];
    _pendingDeepLink = null;
    _pendingBanner = null;
    _started = false;
    _permissionPromptDismissed = false;
    _notify();
    for (final s in subs) {
      await s.cancel();
    }
    for (final t in topics) {
      try {
        await _service.unsubscribeFromTopic(t).timeout(serverTimeout);
      } catch (_) {
        // Bỏ qua: topic có thể chưa từng subscribe khi offline.
      }
    }
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
