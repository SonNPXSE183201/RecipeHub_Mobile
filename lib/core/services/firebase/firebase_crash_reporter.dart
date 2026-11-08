import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import '../interfaces/i_crash_reporter.dart';

/// Firebase Crashlytics – non-fatal errors, user id, custom keys, test crash.
class FirebaseCrashReporter implements ICrashReporter {
  FirebaseCrashReporter({FirebaseCrashlytics? crashlytics})
      : _c = crashlytics ?? FirebaseCrashlytics.instance;

  final FirebaseCrashlytics _c;

  @override
  Future<void> setUserIdentifier(String? uid) => _c.setUserIdentifier(uid ?? '');

  @override
  Future<void> setCustomKey(String key, Object value) => _c.setCustomKey(key, value);

  @override
  Future<void> log(String message) => _c.log(message);

  @override
  Future<void> recordError(Object error, StackTrace? stackTrace, {String? reason, bool fatal = false}) =>
      _c.recordError(error, stackTrace, reason: reason, fatal: fatal);

  @override
  void testCrash() => _c.crash();
}
