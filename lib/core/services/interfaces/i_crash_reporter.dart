/// Firebase Crashlytics boundary.
abstract class ICrashReporter {
  Future<void> setUserIdentifier(String? uid);

  Future<void> setCustomKey(String key, Object value);

  Future<void> log(String message);

  /// Ghi nhận lỗi đã xử lý (non-fatal) – UI vẫn hiển thị thông báo cho người dùng.
  Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  });

  /// Crash có chủ đích – CHỈ gọi từ khu vực Diagnostics (SYS-03).
  void testCrash();
}
