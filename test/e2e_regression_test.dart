import 'dart:async';

// Hồi quy cho lỗi tìm thấy khi kiểm thử E2E trên Redmi 7 (05/11/2026).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:recipehub_mobile/app.dart';
import 'package:recipehub_mobile/core/di/app_services.dart';
import 'package:recipehub_mobile/core/models/session_models.dart';
import 'package:recipehub_mobile/core/navigation/app_keys.dart';
import 'package:recipehub_mobile/core/services/mock/mock_analytics_service.dart';
import 'package:recipehub_mobile/core/services/mock/mock_auth_service.dart';
import 'package:recipehub_mobile/core/services/mock/mock_crash_reporter.dart';
import 'package:recipehub_mobile/core/services/mock/mock_notification_service.dart';
import 'package:recipehub_mobile/core/viewmodels/app_config_viewmodel.dart';
import 'package:recipehub_mobile/core/viewmodels/notification_viewmodel.dart';
import 'package:recipehub_mobile/core/viewmodels/practice_history_viewmodel.dart';
import 'package:recipehub_mobile/core/viewmodels/storage_viewmodel.dart';
import 'package:recipehub_mobile/features/learning/notifications_page.dart';
import 'package:recipehub_mobile/features/shell/main_app_shell.dart';
import 'package:recipehub_mobile/core/services/mock_data_service.dart';
import 'package:recipehub_mobile/core/services/recipe_mapper.dart';
import 'package:recipehub_mobile/core/viewmodels/auth_viewmodel.dart';
import 'package:recipehub_mobile/core/viewmodels/recipe_viewmodel.dart';
import 'package:recipehub_mobile/features/lookup/recipe_detail_size_page.dart';
import 'package:recipehub_mobile/features/sop/sop_catalog_page.dart';

import 'support/fake_recipe_source.dart';

/// Kích thước màn Redmi 7 (720x1520 px, DPR 2).
void _redmi7(WidgetTester tester) {
  tester.view.physicalSize = const Size(720, 1520);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
}

Future<void> _frames(WidgetTester tester, [int n = 10]) async {
  for (var i = 0; i < n; i++) {
    await tester.pump(const Duration(milliseconds: 300));
  }
}

void main() {
  testWidgets('E2E-01 Thông báo khi app đang mở: SnackBar có nút "Xem" mở đúng món, nguồn notification',
      (tester) async {
    _redmi7(tester);
    final original = FlutterError.onError;
    FlutterError.onError = (d) {
      if (d.exceptionAsString().contains('overflowed')) return; // font test 1em/ký tự
      original?.call(d);
    };
    addTearDown(() => FlutterError.onError = original);

    final notifications = MockNotificationService();
    final analytics = MockAnalyticsService();
    final services = AppServices.mock(recipes: FakeRecipeSource(), notifications: notifications, analytics: analytics);
    await tester.pumpWidget(RecipeHubApp(services: services));
    await _frames(tester);
    await tester.tap(find.byKey(AppKeys.guestSignIn));
    await _frames(tester, 20);

    notifications.simulateForeground(AppNotification(
      id: 'fg-1',
      title: 'Họp ca tối',
      body: 'Kiểm tra Cà Phê Muối',
      receivedAt: DateTime(2026, 11, 5, 16, 27),
      data: const {'type': 'recipe', 'target_id': 'RC-CFE-01'},
    ));
    await _frames(tester, 3);
    expect(find.byKey(AppKeys.bannerOpen), findsOneWidget);
    // Font test (1em/ký tự) làm nội dung SnackBar tràn, lệch vùng chạm → kích hoạt action trực tiếp.
    tester.widget<SnackBarAction>(find.byKey(AppKeys.bannerOpen)).onPressed();
    await _frames(tester, 6);
    expect(find.byType(RecipeDetailSizePage), findsOneWidget);
    expect(analytics.loggedEvents.lastWhere((e) => e.name == 'view_recipe').parameters['source'], 'notification');
  });

  testWidgets('E2E-02 Thư viện SOP không tràn ngang trên màn 720px', (tester) async {
    _redmi7(tester);
    final services = AppServices.mock(recipes: FakeRecipeSource());
    final overflows = <String>[];
    final original = FlutterError.onError;
    FlutterError.onError = (d) {
      final msg = d.exceptionAsString();
      // Chỉ bắt tràn trong card SOP (hàng mã/phiên bản/phân loại và hàng "Áp dụng").
      if (msg.contains('overflowed') && d.toString().contains('sop_catalog_page.dart')) overflows.add(msg);
    };
    addTearDown(() => FlutterError.onError = original);
    await tester.pumpWidget(MultiProvider(
      providers: [Provider<AppServices>.value(value: services)],
      child: const MaterialApp(home: SopCatalogPage()),
    ));
    await _frames(tester, 3);
    FlutterError.onError = original;
    expect(overflows, isEmpty);
  });

  testWidgets('E2E-03 Chi tiết món: không hiện nhãn "Quy cách phục vụ chuẩn:" trống', (tester) async {
    _redmi7(tester);
    final original = FlutterError.onError;
    FlutterError.onError = (d) {
      if (d.exceptionAsString().contains('overflowed')) return;
      original?.call(d);
    };
    addTearDown(() => FlutterError.onError = original);
    final recipe = RecipeMapper.fromDetail(FakeRecipeSource.detail('r2', 'RC-CFE-01', 'Cà Phê Muối'));
    MockDataService.instance.recipes = [recipe];
    final services = AppServices.mock(recipes: FakeRecipeSource());
    await tester.pumpWidget(MultiProvider(
      providers: [
        Provider<AppServices>.value(value: services),
        ChangeNotifierProvider(
          create: (_) => AuthViewModel(auth: services.auth, analytics: services.analytics, crash: services.crash),
        ),
        ChangeNotifierProvider(create: (_) => RecipeViewModel(source: services.recipes, crash: services.crash)),
      ],
      child: MaterialApp(home: RecipeDetailSizePage(recipe: recipe)),
    ));
    await _frames(tester, 3);
    expect(recipe.sizes.first.servingNotes, isEmpty);
    expect(find.textContaining('Quy cách phục vụ chuẩn'), findsNothing);
  });

  testWidgets('E2E-04 Đang ở trang Thông báo thì shell bị gỡ (đổi vai trò/đăng xuất): back về không lỗi setState',
      (tester) async {
    _redmi7(tester);
    final errors = <String>[];
    final original = FlutterError.onError;
    FlutterError.onError = (d) {
      final msg = d.exceptionAsString();
      if (!msg.contains('overflowed')) errors.add(msg);
    };
    addTearDown(() => FlutterError.onError = original);
    final s = AppServices.mock(recipes: FakeRecipeSource());
    final showShell = ValueNotifier(true);
    final nav = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MultiProvider(
      providers: [
        Provider<AppServices>.value(value: s),
        ChangeNotifierProvider(create: (_) => AuthViewModel(auth: s.auth, analytics: s.analytics, crash: s.crash)),
        ChangeNotifierProvider(create: (_) => AppConfigViewModel(service: s.remoteConfig)..init()),
        ChangeNotifierProvider(create: (_) => RecipeViewModel(source: s.recipes, crash: s.crash)..load()),
        ChangeNotifierProvider(
          create: (_) => StorageViewModel(
            storage: s.storage, picker: s.mediaPicker, auth: s.auth, analytics: s.analytics, crash: s.crash,
          ),
        ),
        ChangeNotifierProvider(create: (_) => NotificationViewModel(service: s.notifications, crash: s.crash)),
        ChangeNotifierProvider(create: (_) => PracticeHistoryViewModel(store: s.practice, crash: s.crash)),
      ],
      child: MaterialApp(
        navigatorKey: nav,
        home: ValueListenableBuilder<bool>(
          valueListenable: showShell,
          builder: (_, show, _) => show ? const MainAppShell(key: ValueKey('shell_viewer')) : const Text('GONE'),
        ),
      ),
    ));
    await _frames(tester, 3);
    tester.widget<IconButton>(find.byKey(AppKeys.notificationBell)).onPressed!();
    await _frames(tester, 3);
    expect(find.byType(NotificationsPage), findsOneWidget);
    showShell.value = false; // AuthGate dựng shell mới theo vai trò → shell cũ bị dispose
    await _frames(tester, 2);
    nav.currentState!.pop();
    await _frames(tester, 3);
    FlutterError.onError = original;
    expect(errors.where((e) => e.contains('setState() called after dispose')), isEmpty);
  });

  test('E2E-05 Đăng nhập lỗi mạng/hủy: báo người dùng, không ghi Crashlytics; lỗi lạ vẫn ghi', () async {
    final auth = MockAuthService();
    final crash = MockCrashReporter();
    final vm = AuthViewModel(auth: auth, analytics: MockAnalyticsService(), crash: crash);
    auth.nextGoogleFailure = const AuthFailure(AuthFailureCode.network);
    expect(await vm.signInWithGoogle(), isFalse);
    expect(vm.errorMessage, isNotNull);
    auth.nextGoogleFailure = const AuthFailure(AuthFailureCode.cancelled);
    await vm.signInWithGoogle();
    expect(crash.recordedErrors, isEmpty);
    auth.nextGoogleFailure = const AuthFailure(AuthFailureCode.unknown);
    await vm.signInWithGoogle();
    expect(crash.recordedErrors, hasLength(1));
  });

  test('E2E-06 Chạm thông báo lúc app tắt: tin vẫn "đã đọc" dù background handler đã lưu bản chưa đọc', () async {
    AppNotification msg({bool read = false}) => AppNotification(
          id: 'm-cold', title: 'Cold Brew mẻ mới', body: 'Ủ đủ 16 giờ', receivedAt: DateTime(2026, 11, 5, 16, 59),
          data: const {'type': 'recipe', 'target_id': 'CF-COLDBREW'}, origin: NotificationOrigin.background,
        )..isRead = read;
    final service = _OpenedBeforeHistoryService(msg(read: true))..histories['u1'] = [msg()];
    final vm = NotificationViewModel(service: service, crash: MockCrashReporter());
    await vm.start(roleCode: 'viewer', storeCode: 'hcm01', uid: 'u1');
    expect(vm.items.where((n) => n.id == 'm-cold'), hasLength(1));
    expect(vm.items.single.isRead, isTrue);
    expect(vm.takePendingDeepLink()?.id, 'CF-COLDBREW');
    expect(service.histories['u1']!.single.isRead, isTrue, reason: 'lưu lại trạng thái đã đọc');
  });
}

/// FCM thật phát lại "đã chạm" (buffer) ngay khi có listener, trước khi lịch sử nạp xong.
class _OpenedBeforeHistoryService extends MockNotificationService {
  _OpenedBeforeHistoryService(this.opened);
  final AppNotification opened;
  final _openedSync = StreamController<AppNotification>.broadcast(sync: true);

  @override
  Stream<AppNotification> get onNotificationOpened => _openedSync.stream;

  @override
  Future<List<AppNotification>> loadHistory(String scope) async {
    // Bản đọc từ đĩa (background handler lưu: chưa đọc) — có thể cũ hơn lệnh ghi vừa phát.
    final snapshot = await super.loadHistory(scope);
    _openedSync.add(opened); // "đã chạm" tới VM trước khi lịch sử trả về
    return snapshot;
  }
}
