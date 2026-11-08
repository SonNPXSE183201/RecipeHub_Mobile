
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../models/incident_report.dart';
import '../services/firebase/firebase_notification_service.dart';
import '../services/interfaces/i_incident_reporter.dart';

/// Khởi tạo Firebase + gắn Crashlytics bắt lỗi toàn cục + FCM background handler.
///
/// Trả `false` nếu Firebase chưa cấu hình (thiếu google-services.json, chạy desktop…)
/// → app tự fallback sang Mock services để vẫn demo được.
class FirebaseBootstrap {
  FirebaseBootstrap._();

  static IIncidentReporter? _incidents;

  /// Gắn bộ báo sự cố (sau khi tạo AppServices). Gửi bù sự cố lần chạy trước được hẹn tới khi
  /// có người đăng nhập (rules yêu cầu đăng nhập), reporter tự gửi trong `setUser`.
  static Future<void> attachIncidentReporter(IIncidentReporter reporter) async {
    _incidents = reporter;
    try {
      final crashed = await FirebaseCrashlytics.instance.didCrashOnPreviousExecution();
      reporter.scheduleFlush(crashedLastRun: crashed);
    } catch (e) {
      debugPrint('[Bootstrap] check previous crash failed: $e');
      reporter.scheduleFlush(crashedLastRun: false);
    }
  }

  /// Mỗi lỗi (loại + nội dung) chỉ báo một lần mỗi phiên – lỗi lặp lại mỗi frame không làm ngập web Admin.
  static final Set<String> _reportedThisRun = {};

  /// Lưu cục bộ trước (app có thể chết ngay), rồi thử gửi luôn.
  static void _report(Object error, StackTrace? stack, IncidentSource source, IncidentKind kind) {
    final r = _incidents;
    if (r == null) return;
    final report = IncidentReport.fromError(error, stack, kind: kind, source: source);
    if (!_reportedThisRun.add('${report.errorType}|${report.message}')) return;
    // Lưu tạm trước (app có thể chết ngay), gửi được thì bỏ bản lưu tạm → lần mở sau không gửi trùng.
    r
        .stashForNextLaunch(report)
        .then((_) => r.report(report))
        .then((ok) => ok ? r.removeStashed(report.id) : null)
        .ignore();
  }

  static Future<bool> initialize() async {
    try {
      await Firebase.initializeApp();

      // Crashlytics: lỗi framework Flutter (non-fatal) + lỗi async ngoài framework (fatal).
      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        // Ghi non-fatal: ghi fatal làm `didCrashOnPreviousExecution` = true ở lần mở sau dù app
        // không chết → sinh sự cố "Crash" giả trên web Admin.
        FirebaseCrashlytics.instance.recordFlutterError(details);
        // Lỗi framework (overflow, lỗi ảnh…) không làm app chết → non-fatal cho Admin.
        _report(details.exception, details.stack, IncidentSource.flutterError, IncidentKind.nonFatal);
      };
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        _report(error, stack, IncidentSource.platformError, IncidentKind.fatal);
        return true;
      };
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
      await FirebaseCrashlytics.instance.setCustomKey('build_mode', kReleaseMode ? 'release' : 'debug');

      // FCM: tin đến khi app chạy nền / đã đóng.
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      return true;
    } catch (e, s) {
      debugPrint('[Bootstrap] Firebase init failed → Mock mode. $e\n$s');
      return false;
    }
  }
}
