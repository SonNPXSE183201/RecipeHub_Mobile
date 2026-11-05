import '../services/device/image_picker_media_service.dart';
import '../services/firebase/firebase_analytics_service.dart';
import '../services/firebase/firebase_auth_service.dart';
import '../services/firebase/firebase_crash_reporter.dart';
import '../services/firebase/firebase_notification_service.dart';
import '../services/firebase/firebase_remote_config_service.dart';
import '../services/firebase/firebase_storage_service.dart';
import '../services/i_recipe_source.dart';
import '../services/interfaces/i_analytics_service.dart';
import '../services/interfaces/i_auth_service.dart';
import '../services/interfaces/i_crash_reporter.dart';
import '../services/interfaces/i_media_picker_service.dart';
import '../services/interfaces/i_notification_service.dart';
import '../services/interfaces/i_remote_config_service.dart';
import '../services/interfaces/i_storage_service.dart';
import '../services/mock/mock_analytics_service.dart';
import '../services/mock/mock_auth_service.dart';
import '../services/mock/mock_crash_reporter.dart';
import '../services/mock/mock_media_picker_service.dart';
import '../services/mock/mock_notification_service.dart';
import '../services/mock/mock_remote_config_service.dart';
import '../services/mock/mock_storage_service.dart';

/// Composition root: gom service (interface) để inject vào ViewModel.
class AppServices {
  const AppServices({
    required this.auth,
    required this.storage,
    required this.notifications,
    required this.analytics,
    required this.crash,
    required this.remoteConfig,
    required this.mediaPicker,
    required this.recipes,
    this.usesFirebase = false,
  });

  final IAuthService auth;
  final IStorageService storage;
  final INotificationService notifications;
  final IAnalyticsService analytics;
  final ICrashReporter crash;
  final IRemoteConfigService remoteConfig;
  final IMediaPickerService mediaPicker;
  final IRecipeSource recipes;

  /// `true` khi chạy 6 dịch vụ Firebase thật.
  final bool usesFirebase;

  /// Production: 6 Firebase services + image_picker + Gateway thật cho công thức.
  factory AppServices.firebase() => AppServices(
        auth: FirebaseAuthService(),
        storage: FirebaseStorageService(),
        notifications: FirebaseNotificationService(),
        analytics: FirebaseAnalyticsService(),
        crash: FirebaseCrashReporter(),
        remoteConfig: FirebaseRemoteConfigService(),
        mediaPicker: ImagePickerMediaService(),
        recipes: GatewayRecipeSource(),
        usesFirebase: true,
      );

  /// Test (ARTEMIS E2E) hoặc máy chưa cấu hình Firebase: không chạm plugin native.
  /// `recipes` phải do test truyền vào (fake source), không có dữ liệu giả trong app.
  factory AppServices.mock({
    required IRecipeSource recipes,
    IAuthService? auth,
    IStorageService? storage,
    INotificationService? notifications,
    IAnalyticsService? analytics,
    ICrashReporter? crash,
    IRemoteConfigService? remoteConfig,
    IMediaPickerService? mediaPicker,
  }) =>
      AppServices(
        auth: auth ?? MockAuthService(),
        storage: storage ?? MockStorageService(),
        notifications: notifications ?? MockNotificationService(),
        analytics: analytics ?? MockAnalyticsService(),
        crash: crash ?? MockCrashReporter(),
        remoteConfig: remoteConfig ?? MockRemoteConfigService(),
        mediaPicker: mediaPicker ?? MockMediaPickerService(),
        recipes: recipes,
      );
}
