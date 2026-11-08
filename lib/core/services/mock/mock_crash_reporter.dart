import '../interfaces/i_crash_reporter.dart';

/// Crashlytics giả lập – ghi nhận để test kiểm chứng non-fatal + custom keys.
class MockCrashReporter implements ICrashReporter {
  String? userId;
  final Map<String, Object> customKeys = {};
  final List<String> logs = [];
  final List<Object> recordedErrors = [];
  int testCrashCount = 0;

  @override
  Future<void> setUserIdentifier(String? uid) async => userId = uid;

  @override
  Future<void> setCustomKey(String key, Object value) async => customKeys[key] = value;

  @override
  Future<void> log(String message) async => logs.add(message);

  @override
  Future<void> recordError(Object error, StackTrace? stackTrace, {String? reason, bool fatal = false}) async =>
      recordedErrors.add(error);

  @override
  void testCrash() => testCrashCount++;
}
