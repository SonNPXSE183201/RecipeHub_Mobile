
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../services/firebase/firebase_notification_service.dart';

/// Khởi tạo Firebase + gắn Crashlytics bắt lỗi toàn cục + FCM background handler.
///
/// Trả `false` nếu Firebase chưa cấu hình (thiếu google-services.json, chạy desktop…)
/// → app tự fallback sang Mock services để vẫn demo được.
class FirebaseBootstrap {
  FirebaseBootstrap._();

  static Future<bool> initialize() async {
    try {
      await Firebase.initializeApp();

      // Crashlytics: lỗi framework Flutter (fatal) + lỗi async ngoài framework.
      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      };
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
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
