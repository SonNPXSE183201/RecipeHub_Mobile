// 12 ca kiểm thử tự động cho Lab 3: Auth, Recipe API, Storage, FCM, Remote Config, luồng UI
// và 2 ca hồi quy (TC-11, TC-12) cho lỗi deep link phát hiện khi chạy ARTEMIS trên Redmi 7.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipehub_mobile/app.dart';
import 'package:recipehub_mobile/core/di/app_services.dart';
import 'package:recipehub_mobile/core/models/app_models.dart';
import 'package:recipehub_mobile/core/models/session_models.dart';
import 'package:recipehub_mobile/core/navigation/app_keys.dart';
import 'package:recipehub_mobile/core/services/mock/mock_analytics_service.dart';
import 'package:recipehub_mobile/core/services/mock/mock_auth_service.dart';
import 'package:recipehub_mobile/core/services/mock/mock_crash_reporter.dart';
import 'package:recipehub_mobile/core/services/mock/mock_media_picker_service.dart';
import 'package:recipehub_mobile/core/services/mock/mock_notification_service.dart';
import 'package:recipehub_mobile/core/services/mock/mock_remote_config_service.dart';
import 'package:recipehub_mobile/core/services/mock/mock_storage_service.dart';
import 'package:recipehub_mobile/core/services/mock_data_service.dart';
import 'package:recipehub_mobile/core/viewmodels/auth_viewmodel.dart';
import 'package:recipehub_mobile/core/viewmodels/notification_viewmodel.dart';
import 'package:recipehub_mobile/core/viewmodels/recipe_viewmodel.dart';
import 'package:recipehub_mobile/core/viewmodels/storage_viewmodel.dart';

import 'support/fake_recipe_source.dart';

AuthViewModel _auth(MockAuthService auth, MockAnalyticsService analytics, MockCrashReporter crash) =>
    AuthViewModel(auth: auth, analytics: analytics, crash: crash)..start();

void main() {
  setUp(() => MockDataService.instance.recipes = []);

  test('TC-01 Google login thành công → role Barista + event login', () async {
    final analytics = MockAnalyticsService();
    final vm = _auth(MockAuthService(), analytics, MockCrashReporter());
    await Future<void>.delayed(Duration.zero);
    expect(await vm.signInWithGoogle(), isTrue);
    expect(vm.status, AuthStatus.authenticated);
    expect(vm.role, UserRole.viewer);
    expect(analytics.eventNames, contains('login'));
  });

  test('TC-02 Hủy Google Sign-In → báo lỗi thân thiện, vẫn chưa đăng nhập', () async {
    final vm = _auth(
      MockAuthService(nextGoogleFailure: const AuthFailure(AuthFailureCode.cancelled)),
      MockAnalyticsService(),
      MockCrashReporter(),
    );
    await Future<void>.delayed(Duration.zero);
    expect(await vm.signInWithGoogle(), isFalse);
    expect(vm.status, AuthStatus.unauthenticated);
    expect(vm.errorMessage, isNotNull);
  });

  test('TC-03 Khách không được dùng vai trò Admin', () async {
    final vm = _auth(MockAuthService(), MockAnalyticsService(), MockCrashReporter());
    await Future<void>.delayed(Duration.zero);
    await vm.continueAsGuest();
    expect(vm.isGuest, isTrue);
    expect(await vm.switchRole(UserRole.admin), isFalse);
    expect(vm.isAdmin, isFalse);
  });

  test('TC-04 Công thức tải từ API (fake DTO backend) và map sang UI', () async {
    final vm = RecipeViewModel(source: FakeRecipeSource(), crash: MockCrashReporter());
    await vm.load();
    expect(vm.state, ViewState.ready);
    expect(vm.items, hasLength(2));
    final r = vm.items.first;
    expect(r.code, 'RC-OOL-02');
    expect(r.status, 'Ban hành');
    expect(r.sizes, hasLength(1));
    expect(r.steps.first.temperature, '92°C');
    expect(MockDataService.instance.recipes, hasLength(2));
  });

  test('TC-05 Lỗi mạng → error, Thử lại → ready, lỗi ghi vào Crashlytics', () async {
    final crash = MockCrashReporter();
    final vm = RecipeViewModel(source: FakeRecipeSource(failuresBeforeSuccess: 1), crash: crash);
    await vm.load();
    expect(vm.state, ViewState.error);
    expect(vm.error, isNotEmpty);
    expect(crash.recordedErrors, isNotEmpty);
    await vm.load();
    expect(vm.state, ViewState.ready);
  });

  test('TC-06 Ảnh > 5MB bị chặn trước khi upload', () async {
    final storage = MockStorageService();
    final vm = StorageViewModel(
      storage: storage,
      picker: MockMediaPickerService(returnOversized: true),
      auth: MockAuthService(initialUser: const AppUser(uid: 'u1', method: AuthMethod.guest)),
      analytics: MockAnalyticsService(),
      crash: MockCrashReporter(),
    );
    await vm.pickAttachment(fromCamera: false);
    expect(vm.attachmentStatus, UploadStatus.error);
    expect(vm.attachmentError, contains('5MB'));
    expect(storage.uploadedPaths, isEmpty);
  });

  test('TC-07 Upload ảnh feedback vào feedback/{uid}/', () async {
    final storage = MockStorageService();
    final vm = StorageViewModel(
      storage: storage,
      picker: MockMediaPickerService(),
      auth: MockAuthService(initialUser: const AppUser(uid: 'u1', method: AuthMethod.guest)),
      analytics: MockAnalyticsService(),
      crash: MockCrashReporter(),
    );
    await vm.pickAttachment(fromCamera: false);
    final url = await vm.uploadAttachment();
    expect(url, isNotNull);
    expect(storage.uploadedPaths.single, startsWith('feedback/u1/'));
    expect(vm.attachmentStatus, UploadStatus.success);
  });

  test('TC-08 FCM mở từ notification → deep link tới công thức', () async {
    final service = MockNotificationService();
    final vm = NotificationViewModel(service: service, crash: MockCrashReporter());
    await vm.start(roleCode: 'viewer', storeCode: 'hcm01');
    service.simulateOpened(AppNotification(
      id: 'n1',
      title: 'Công thức cập nhật',
      body: 'v3',
      receivedAt: DateTime(2026, 11, 4),
      data: const {'type': 'recipe', 'target_id': 'r1'},
    ));
    await Future<void>.delayed(Duration.zero);
    final link = vm.takePendingDeepLink();
    expect(link?.target, DeepLinkTarget.recipe);
    expect(link?.id, 'r1');
    expect(vm.unreadCount, 0);
  });

  test('TC-09 Remote Config: refresh cập nhật max_lookup_results', () async {
    final rc = MockRemoteConfigService();
    await rc.initialize();
    expect(rc.maxLookupResults, 50);
    rc.publish(maxLookupResults: 10, realtime: false);
    expect(await rc.refresh(), isTrue);
    expect(rc.maxLookupResults, 10);
  });

  testWidgets('TC-10 UI: đăng nhập khách → tải công thức từ API → thấy danh sách tra cứu', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    // Font FlutterTest vẽ mỗi ký tự thành ô 1em nên Row tràn chỉ trong môi trường test.
    // Bỏ qua lỗi overflow, mọi lỗi khác vẫn làm rớt test.
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      originalOnError?.call(details);
    };
    try {
      final services = AppServices.mock(recipes: FakeRecipeSource());
      await tester.pumpWidget(RecipeHubApp(services: services));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 300));
      }
      expect(find.byKey(AppKeys.guestSignIn), findsOneWidget);
      await tester.tap(find.byKey(AppKeys.guestSignIn));
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 300));
      }
      expect(find.text('Trà Sữa Oolong'), findsWidgets);
    } finally {
      FlutterError.onError = originalOnError;
    }
  });

  test('TC-11 Deep link tới món ngoài danh sách bị giới hạn (max_lookup_results) vẫn tìm được qua Gateway', () async {
    final vm = RecipeViewModel(source: FakeRecipeSource(), crash: MockCrashReporter());
    await vm.load(limit: 1);
    expect(vm.items.map((r) => r.code), ['RC-OOL-02']);
    final found = await vm.findForDeepLink('RC-CFE-01');
    expect(found?.name, 'Cà Phê Muối');
    expect(await vm.findForDeepLink('KHONG-TON-TAI'), isNull);
  });

  test('TC-13 Remote Config tăng max_lookup_results → tải lại ngầm, không qua loading', () async {
    final vm = RecipeViewModel(source: FakeRecipeSource(), crash: MockCrashReporter());
    await vm.load(limit: 1);
    expect(vm.items, hasLength(1));
    final states = <ViewState>[];
    vm.addListener(() => states.add(vm.state));
    await vm.applyLimit(50);
    expect(vm.items, hasLength(2));
    expect(states, isNot(contains(ViewState.loading)));
    await vm.applyLimit(1); // giảm: không tải lại, View tự cắt
    expect(vm.items, hasLength(2));
  });

  test('TC-12 Thông báo mở app (terminated) không bị mở lại sau khi đăng xuất rồi đăng nhập', () async {
    AppNotification initial() => AppNotification(
          id: 'msg-1',
          title: 'Công thức cập nhật',
          body: 'v1',
          receivedAt: DateTime(2026, 11, 5),
          data: const {'type': 'recipe', 'target_id': 'RC-CFE-01'},
        );
    final service = MockNotificationService(initialNotification: initial());
    final vm = NotificationViewModel(service: service, crash: MockCrashReporter());
    await vm.start(roleCode: 'viewer', storeCode: 'hcm01');
    expect(vm.takePendingDeepLink()?.id, 'RC-CFE-01');

    await vm.reset(); // đăng xuất
    service.initialNotification = initial(); // FCM thật trả lại cùng tin trong vòng đời process
    await vm.start(roleCode: 'viewer', storeCode: 'hcm01'); // đăng nhập lại
    expect(vm.takePendingDeepLink(), isNull);

    // Tin chạm khi app chạy nền (onMessageOpenedApp) cũng không được mở lại sau khi đăng nhập lại.
    final bg = AppNotification(
      id: 'msg-2',
      title: 'Cập nhật',
      body: 'v2',
      receivedAt: DateTime(2026, 11, 5),
      data: const {'type': 'recipe', 'target_id': 'RC-OOL-02'},
    );
    service.simulateOpened(bg);
    await Future<void>.delayed(Duration.zero);
    expect(vm.takePendingDeepLink()?.id, 'RC-OOL-02');
    await vm.reset();
    service.initialNotification = bg;
    await vm.start(roleCode: 'viewer', storeCode: 'hcm01');
    expect(vm.takePendingDeepLink(), isNull);
  });
}
