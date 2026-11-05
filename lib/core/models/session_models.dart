import 'dart:typed_data';

import 'app_models.dart';

/// Trạng thái chuẩn cho mọi luồng tải dữ liệu (Lab 3: loading / data / empty / error).
enum ViewState { idle, loading, ready, empty, error }

/// Phương thức đăng nhập.
enum AuthMethod { google, guest }

/// Người dùng đã xác thực (không chứa token / secret).
class AppUser {
  const AppUser({
    required this.uid,
    required this.method,
    this.displayName,
    this.email,
    this.photoUrl,
  });

  final String uid;
  final AuthMethod method;
  final String? displayName;
  final String? email;
  final String? photoUrl;

  bool get isGuest => method == AuthMethod.guest;

  String get initials {
    final name = (displayName == null || displayName!.trim().isEmpty)
        ? (isGuest ? 'Khách' : 'RecipeHub')
        : displayName!.trim();
    final parts = name.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }
}

/// Lỗi xác thực đã được chuẩn hóa để View hiển thị thân thiện.
enum AuthFailureCode { cancelled, network, configuration, disabled, unknown }

class AuthFailure implements Exception {
  const AuthFailure(this.code, [this.message]);

  final AuthFailureCode code;
  final String? message;

  String get userMessage {
    switch (code) {
      case AuthFailureCode.cancelled:
        return 'Bạn đã hủy đăng nhập Google. Chưa có thay đổi nào.';
      case AuthFailureCode.network:
        return 'Mất kết nối mạng. Kiểm tra Wi-Fi quầy rồi thử lại.';
      case AuthFailureCode.configuration:
        return 'Cấu hình Google Sign-In chưa đúng (SHA-1 / google-services.json).';
      case AuthFailureCode.disabled:
        return 'Tài khoản đã bị Admin khóa. Liên hệ quản lý cửa hàng để mở lại.';
      case AuthFailureCode.unknown:
        return 'Không thể đăng nhập lúc này. Vui lòng thử lại.';
    }
  }

  @override
  String toString() => 'AuthFailure($code, $message)';
}

/// Loại thông báo trong trung tâm thông báo (M-10).
enum NotificationKind { versionUpdate, feedbackReply, taskAssigned, sopUpdate, system }

NotificationKind notificationKindFrom(String? raw) {
  switch (raw) {
    case 'version_update':
    case 'recipe':
      return NotificationKind.versionUpdate;
    case 'feedback_reply':
    case 'feedback':
      return NotificationKind.feedbackReply;
    case 'task_assigned':
    case 'task':
      return NotificationKind.taskAssigned;
    case 'sop_update':
    case 'sop':
      return NotificationKind.sopUpdate;
    default:
      return NotificationKind.system;
  }
}

/// Đích điều hướng khi chạm thông báo.
enum DeepLinkTarget { recipe, sop, task, feedback, notifications }

class DeepLink {
  const DeepLink(this.target, this.id);

  final DeepLinkTarget target;
  final String? id;

  /// Ánh xạ payload FCM `data` → DeepLink.
  /// Ví dụ: `{ "type": "recipe", "target_id": "rc-02" }`.
  static DeepLink fromData(Map<String, dynamic> data) {
    final type = (data['type'] ?? data['screen'] ?? '').toString();
    final id = (data['target_id'] ?? data['targetId'] ?? data['id'])?.toString();
    switch (type) {
      case 'recipe':
      case 'version_update':
        return DeepLink(DeepLinkTarget.recipe, id);
      case 'sop':
      case 'sop_update':
        return DeepLink(DeepLinkTarget.sop, id);
      case 'task':
      case 'task_assigned':
        return DeepLink(DeepLinkTarget.task, id);
      case 'feedback':
      case 'feedback_reply':
        return DeepLink(DeepLinkTarget.feedback, id);
      default:
        return const DeepLink(DeepLinkTarget.notifications, null);
    }
  }

  @override
  String toString() => 'DeepLink(${target.name}, $id)';
}

/// Nguồn nhận thông báo – dùng để kiểm chứng 3 trạng thái FCM.
enum NotificationOrigin { foreground, background, terminated, local }

class AppNotification {
  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.receivedAt,
    this.data = const {},
    this.isRead = false,
    this.origin = NotificationOrigin.local,
  });

  final String id;
  final String title;
  final String body;
  final DateTime receivedAt;
  final Map<String, dynamic> data;
  bool isRead;
  final NotificationOrigin origin;

  NotificationKind get kind => notificationKindFrom(data['type']?.toString());
  DeepLink get deepLink => DeepLink.fromData(data);

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'receivedAt': receivedAt.toIso8601String(),
        'data': data.map((k, v) => MapEntry(k, v.toString())),
        'isRead': isRead,
        'origin': origin.name,
      };

  static AppNotification fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        receivedAt: DateTime.tryParse(json['receivedAt'] as String? ?? '') ?? DateTime.now(),
        data: Map<String, dynamic>.from(json['data'] as Map? ?? const {}),
        isRead: json['isRead'] as bool? ?? false,
        origin: NotificationOrigin.values.firstWhere(
          (o) => o.name == json['origin'],
          orElse: () => NotificationOrigin.local,
        ),
      );
}

/// Quyền nhận thông báo (Android 13+ POST_NOTIFICATIONS).
enum NotificationPermission { notDetermined, granted, denied, provisional }

/// Ảnh/tệp người dùng chọn (đã đọc bytes).
class PickedMedia {
  const PickedMedia({
    required this.bytes,
    required this.fileName,
    required this.mimeType,
  });

  final Uint8List bytes;
  final String fileName;
  final String mimeType;

  int get sizeBytes => bytes.lengthInBytes;
  double get sizeMb => sizeBytes / (1024 * 1024);
  bool get isImage => mimeType.startsWith('image/');
}

/// Trạng thái upload lên Storage.
enum UploadStatus { idle, validating, uploading, success, error }

/// Kết quả upload thành công.
class UploadResult {
  const UploadResult({
    required this.storagePath,
    required this.downloadUrl,
    required this.sizeBytes,
  });

  final String storagePath;
  final String downloadUrl;
  final int sizeBytes;
}

/// Lỗi Storage chuẩn hóa.
enum StorageFailureCode { tooLarge, invalidType, unauthorized, network, cancelled, unknown }

class StorageFailure implements Exception {
  const StorageFailure(this.code, [this.message]);

  final StorageFailureCode code;
  final String? message;

  String get userMessage {
    switch (code) {
      case StorageFailureCode.tooLarge:
        return 'Ảnh vượt quá 5MB. Hãy chụp lại hoặc chọn ảnh nhỏ hơn.';
      case StorageFailureCode.invalidType:
        return 'Chỉ hỗ trợ ảnh (JPG, PNG, WEBP).';
      case StorageFailureCode.unauthorized:
        return 'Bạn không có quyền ghi vào thư mục này (storage.rules).';
      case StorageFailureCode.network:
        return 'Mất kết nối khi tải lên. Kiểm tra mạng và thử lại.';
      case StorageFailureCode.cancelled:
        return 'Đã hủy tải lên.';
      case StorageFailureCode.unknown:
        return 'Tải lên thất bại. Vui lòng thử lại.';
    }
  }

  @override
  String toString() => 'StorageFailure($code, $message)';
}

/// Một sự kiện Analytics đã được chuẩn hóa (không PII).
class AnalyticsEvent {
  AnalyticsEvent(this.name, [Map<String, Object> parameters = const {}])
      : parameters = sanitize(parameters) {
    assert(isValidName(name), 'Analytics event name must be snake_case: $name');
  }

  final String name;
  final Map<String, Object> parameters;

  static final RegExp _snake = RegExp(r'^[a-z][a-z0-9_]{0,39}$');
  static const Set<String> _piiKeys = {
    'email',
    'name',
    'full_name',
    'display_name',
    'phone',
    'phone_number',
    'photo_url',
    'address',
  };

  static bool isValidName(String name) => _snake.hasMatch(name);

  /// Loại bỏ PII: key nằm trong blocklist, value chứa '@' hoặc dãy số ≥ 9 ký tự (SĐT).
  static Map<String, Object> sanitize(Map<String, Object> input) {
    final out = <String, Object>{};
    input.forEach((key, value) {
      if (_piiKeys.contains(key)) return;
      if (value is String) {
        if (value.contains('@')) return;
        if (RegExp(r'\d{9,}').hasMatch(value)) return;
        out[key] = value.length > 100 ? value.substring(0, 100) : value;
      } else if (value is num) {
        out[key] = value;
      } else if (value is bool) {
        out[key] = value ? 'true' : 'false';
      } else {
        out[key] = value.toString();
      }
    });
    return out;
  }

  @override
  String toString() => '$name $parameters';
}

/// Ảnh chụp giá trị Remote Config để hiển thị trên Diagnostics.
enum ConfigSource { defaults, remote, cached }

class RemoteConfigSnapshot {
  const RemoteConfigSnapshot({
    required this.enableAiAssist,
    required this.maxLookupResults,
    required this.source,
    this.lastFetch,
    this.lastStatus = 'not_fetched',
  });

  final bool enableAiAssist;
  final int maxLookupResults;
  final ConfigSource source;
  final DateTime? lastFetch;
  final String lastStatus;
}

/// Nhật ký kiểm toán (A-04).
class AuditLogEntry {
  const AuditLogEntry({
    required this.id,
    required this.action,
    required this.actor,
    required this.target,
    required this.time,
    required this.hash,
    required this.device,
    this.category = 'training',
  });

  final String id;
  final String action;
  final String actor;
  final String target;
  final DateTime time;
  final String hash;
  final String device;

  /// 'training' | 'evaluation' | 'feedback' | 'auth' | 'report'
  final String category;
}

/// Tóm tắt học viên tại chi nhánh (A-01, A-02).
class TraineeSummary {
  const TraineeSummary({
    required this.id,
    required this.name,
    required this.position,
    required this.shift,
    required this.readProgress,
    required this.quizScore,
    required this.practicalPassed,
    required this.practicalTotal,
    required this.overdueTasks,
    this.lastActive = '',
  });

  final String id;
  final String name;
  final String position;
  final String shift;
  final double readProgress;
  final int quizScore;
  final int practicalPassed;
  final int practicalTotal;
  final int overdueTasks;
  final String lastActive;

  bool get needsAttention => overdueTasks > 0 || quizScore < 70;
}

/// Kết quả một lần bấm giờ (TC-05).
class BrewTimerResult {
  const BrewTimerResult({
    required this.recipe,
    required this.sizeCode,
    required this.actualSeconds,
    required this.targetSeconds,
    required this.toleranceSeconds,
  });

  final RecipeItem recipe;
  final String sizeCode;
  final int actualSeconds;
  final int targetSeconds;
  final int toleranceSeconds;

  int get deviationSeconds => actualSeconds - targetSeconds;
  bool get withinTolerance => deviationSeconds.abs() <= toleranceSeconds;
}
