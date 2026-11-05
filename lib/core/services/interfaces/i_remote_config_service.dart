import '../../models/session_models.dart';

/// Firebase Remote Config boundary.
abstract class IRemoteConfigService {
  static const String keyEnableAiAssist = 'enable_ai_assist';
  static const String keyMaxLookupResults = 'max_lookup_results';

  static const Map<String, dynamic> defaults = {
    keyEnableAiAssist: false,
    keyMaxLookupResults: 50,
  };

  /// setDefaults + fetchAndActivate + lắng nghe realtime update.
  /// Không throw: lỗi mạng → giữ giá trị mặc định / cache.
  Future<void> initialize();

  /// Fetch & activate thủ công (nút "Đồng bộ cấu hình"). Trả `true` nếu có giá trị mới.
  Future<bool> refresh();

  bool get enableAiAssist;

  int get maxLookupResults;

  RemoteConfigSnapshot get snapshot;

  /// Phát mỗi khi giá trị đã được activate (realtime onConfigUpdated hoặc refresh).
  Stream<RemoteConfigSnapshot> get onUpdated;
}
