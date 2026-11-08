import '../../models/session_models.dart';

/// Firebase Remote Config boundary.
abstract class IRemoteConfigService {
  static const String keyEnableAiAssist = 'enable_ai_assist';
  static const String keyMaxLookupResults = 'max_lookup_results';
  static const String keyShowCrashDemo = 'show_crash_demo';

  static const Map<String, dynamic> defaults = {
    keyEnableAiAssist: false,
    keyMaxLookupResults: 50,
    keyShowCrashDemo: true,
  };

  /// setDefaults + fetchAndActivate + lắng nghe realtime update.
  /// Không throw: lỗi mạng → giữ giá trị mặc định / cache.
  Future<void> initialize();

  /// Fetch & activate thủ công (nút "Đồng bộ cấu hình"). Trả `true` nếu có giá trị mới.
  Future<bool> refresh();

  bool get enableAiAssist;

  int get maxLookupResults;

  /// Hiện ô "Kiểm thử sự cố" (nút Gây crash) ở màn Tài khoản.
  bool get showCrashDemo;

  RemoteConfigSnapshot get snapshot;

  /// Phát mỗi khi giá trị đã được activate (realtime onConfigUpdated hoặc refresh).
  Stream<RemoteConfigSnapshot> get onUpdated;
}
