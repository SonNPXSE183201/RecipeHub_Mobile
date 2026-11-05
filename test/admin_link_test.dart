// Ca kiểm thử cho phần nối với web Admin (plan 261105-admin-web-firebase):
// vai trò từ server, khóa tài khoản, đăng ký FCM token, báo sự cố, nguồn món Firestore.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipehub_mobile/app.dart';
import 'package:recipehub_mobile/core/di/app_services.dart';
import 'package:recipehub_mobile/core/models/app_models.dart';
import 'package:recipehub_mobile/core/models/incident_report.dart';
import 'package:recipehub_mobile/core/models/recipe_models.dart';
import 'package:recipehub_mobile/core/models/session_models.dart';
import 'package:recipehub_mobile/core/navigation/app_keys.dart';
import 'package:recipehub_mobile/core/services/firebase/firestore_recipe_source.dart';
import 'package:recipehub_mobile/core/services/interfaces/i_user_profile_service.dart';
import 'package:recipehub_mobile/core/services/mock/mock_analytics_service.dart';
import 'package:recipehub_mobile/core/services/mock/mock_auth_service.dart';
import 'package:recipehub_mobile/core/services/mock/mock_crash_reporter.dart';
import 'package:recipehub_mobile/core/services/mock/mock_device_registry.dart';
import 'package:recipehub_mobile/core/services/mock/mock_incident_reporter.dart';
import 'package:recipehub_mobile/core/services/mock/mock_notification_service.dart';
import 'package:recipehub_mobile/core/services/mock/mock_remote_config_service.dart';
import 'package:recipehub_mobile/core/services/mock/mock_user_profile_service.dart';
import 'package:recipehub_mobile/core/services/mock_data_service.dart';
import 'package:recipehub_mobile/core/services/recipe_mapper.dart';
import 'package:recipehub_mobile/core/viewmodels/auth_viewmodel.dart';
import 'package:recipehub_mobile/core/viewmodels/notification_viewmodel.dart';

import 'support/fake_recipe_source.dart';

Future<void> _settle() => Future<void>.delayed(const Duration(milliseconds: 10));

/// Ghi lại số sự cố đã gửi tại thời điểm crash để kiểm tra thứ tự "gửi trước, crash sau".
class _OrderCrashReporter extends MockCrashReporter {
  _OrderCrashReporter(this.incidents);
  final MockIncidentReporter incidents;
  int reportedBeforeCrash = -1;

  @override
  void testCrash() {
    reportedBeforeCrash = incidents.reported.length;
    super.testCrash();
  }
}

void main() {
  setUp(() => MockDataService.instance.recipes = []);

  test('TC-14 Vai trò lấy từ server: chọn Admin nhưng claim là viewer → Barista + thông báo', () async {
    final profile = MockUserProfileService(role: 'viewer');
    final vm = AuthViewModel(
      auth: MockAuthService(),
      analytics: MockAnalyticsService(),
      crash: MockCrashReporter(),
      profile: profile,
    )..start();
    await _settle();
    vm.selectRole(UserRole.admin);
    expect(await vm.signInWithGoogle(), isTrue);
    await _settle();
    expect(vm.isAdmin, isFalse);
    expect(vm.notice, contains('chưa được cấp quyền Admin'));
    expect(await vm.switchRole(UserRole.admin), isFalse);

    final adminProfile = MockUserProfileService(role: 'admin');
    final admin = AuthViewModel(
      auth: MockAuthService(),
      analytics: MockAnalyticsService(),
      crash: MockCrashReporter(),
      profile: adminProfile,
    )..start();
    await _settle();
    admin.selectRole(UserRole.admin);
    await admin.signInWithGoogle();
    await _settle();
    expect(admin.isAdmin, isTrue);
    expect(admin.serverRole, UserRole.admin);
  });

  test('TC-15 Admin khóa tài khoản → app đăng xuất ngay, báo lý do', () async {
    final profile = MockUserProfileService(role: 'viewer');
    final vm = AuthViewModel(
      auth: MockAuthService(),
      analytics: MockAnalyticsService(),
      crash: MockCrashReporter(),
      profile: profile,
    )..start();
    await _settle();
    await vm.signInWithGoogle();
    await _settle();
    expect(vm.status, AuthStatus.authenticated);
    profile.emit(const ProfileState(role: 'viewer', disabled: true));
    await _settle();
    expect(vm.status, AuthStatus.unauthenticated);
    expect(vm.lastFailure, AuthFailureCode.disabled);
    expect(vm.errorMessage, contains('khóa'));
    expect(vm.notice, contains('khóa'), reason: 'AuthGate hiện lý do ở màn đăng nhập');
  });

  test('TC-16 FCM token lên server khi đăng nhập, gỡ TRƯỚC khi đăng xuất, đổi token thì gửi lại', () async {
    final auth = MockAuthService();
    final devices = MockDeviceRegistry();
    final notifications = MockNotificationService();
    final vm = AuthViewModel(auth: auth, analytics: MockAnalyticsService(), crash: MockCrashReporter())..start();
    final notif = NotificationViewModel(service: notifications, crash: MockCrashReporter(), devices: devices);
    var signedInDuringUnregister = false;
    vm.addBeforeSignOut(() async {
      signedInDuringUnregister = auth.currentUser != null;
      await notif.unregisterDevice();
    });
    await _settle();
    await vm.signInWithGoogle();
    await notif.start(roleCode: vm.roleCode, storeCode: 'Q1', uid: vm.user!.uid);
    await _settle(); // token + topic đăng ký ở nền (không chặn khi offline)
    expect(devices.registered, {'mock-fcm-token-RH-0001'});
    expect(notif.topics, contains(NotificationViewModel.topicAll));

    notifications.tokenRefreshes.add('new-token');
    await _settle();
    expect(devices.registered, containsAll(['mock-fcm-token-RH-0001', 'new-token']));

    await vm.signOut();
    expect(signedInDuringUnregister, isTrue);
    expect(devices.log.last, startsWith('unregister:'));
    expect(devices.registered, isNot(contains('new-token')));
  });

  test('TC-17 Admin đổi vai trò trên web → app cập nhật không cần đăng nhập lại', () async {
    final profile = MockUserProfileService(role: 'viewer');
    final vm = AuthViewModel(
      auth: MockAuthService(),
      analytics: MockAnalyticsService(),
      crash: MockCrashReporter(),
      profile: profile,
    )..start();
    await _settle();
    await vm.signInWithGoogle();
    await _settle();
    profile.emit(const ProfileState(role: 'viewer', disabled: false, claimsVersion: 1));
    await _settle();
    expect(vm.isAdmin, isFalse);
    profile.emit(const ProfileState(role: 'admin', disabled: false, claimsVersion: 2));
    await _settle();
    expect(vm.isAdmin, isTrue);
    expect(vm.status, AuthStatus.authenticated);
  });

  testWidgets('TC-18 Nút "Gây crash": gửi sự cố cho Admin TRƯỚC rồi mới crash; TC-20 ẩn theo Remote Config', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      originalOnError?.call(details);
    };
    try {
      final incidents = MockIncidentReporter();
      final crash = _OrderCrashReporter(incidents);
      final rc = MockRemoteConfigService();
      final analytics = MockAnalyticsService();
      await tester.pumpWidget(
        RecipeHubApp(
          services: AppServices.mock(
            recipes: FakeRecipeSource(),
            crash: crash,
            incidents: incidents,
            remoteConfig: rc,
            analytics: analytics,
          ),
        ),
      );
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 300));
      }
      await tester.tap(find.byKey(AppKeys.guestSignIn));
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 300));
      }
      if (find.byKey(AppKeys.permissionLater).evaluate().isNotEmpty) {
        await tester.tap(find.byKey(AppKeys.permissionLater));
        await tester.pump(const Duration(milliseconds: 300));
      }
      await tester.tap(find.byType(NavigationDestination).at(3));
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 300));
      }
      final tile = find.byKey(AppKeys.crashDemoTile);
      await tester.ensureVisible(tile);
      await tester.pump();
      await tester.tap(tile);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byKey(AppKeys.testCrash));
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(crash.testCrashCount, 1);
      expect(crash.reportedBeforeCrash, 1);
      expect(incidents.reported.single.kind, IncidentKind.fatal);
      expect(incidents.reported.single.source, IncidentSource.demoButton);
      expect(analytics.eventNames, contains('trigger_test_crash'));

      // TC-20: tắt show_crash_demo → ô biến mất.
      rc.crashDemo = false;
      rc.publish(maxLookupResults: 50);
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 300));
      }
      expect(find.byKey(AppKeys.crashDemoTile), findsNothing);
    } finally {
      FlutterError.onError = originalOnError;
    }
  });

  test('TC-19 Crash ở lần chạy trước được gửi bù khi mở app', () async {
    final r = MockIncidentReporter();
    await r.stashForNextLaunch(
      IncidentReport.fromError(
        StateError('boom'),
        StackTrace.current,
        kind: IncidentKind.fatal,
        source: IncidentSource.flutterError,
      ),
    );
    expect(await r.flushPending(crashedLastRun: true), 1);
    expect(r.stashed, isEmpty);
    expect(r.reported.single.source, IncidentSource.flutterError);

    final native = MockIncidentReporter();
    expect(await native.flushPending(crashedLastRun: true), 1);
    expect(native.reported.single.source, IncidentSource.previousCrash);

    // Nút demo đã tự báo trước khi crash → lần mở sau không báo trùng.
    final demo = MockIncidentReporter();
    await demo.markCrashAlreadyReported();
    expect(await demo.flushPending(crashedLastRun: true), 0);
    expect(demo.reported, isEmpty);

    final long = IncidentReport.fromError(
      StateError('x' * 900),
      null,
      kind: IncidentKind.nonFatal,
      source: IncidentSource.nonFatalReport,
    );
    expect(long.message.length, IncidentReport.maxMessage);
    expect(long.toJson()['kind'], 'non_fatal');
  });

  test('TC-22 Đăng xuất rồi đăng nhập lại ngay: reset() không làm hỏng start() (lỗi Crashlytics thật)', () async {
    final notif = NotificationViewModel(
      service: MockNotificationService(),
      crash: MockCrashReporter(),
      devices: MockDeviceRegistry(),
    );
    await notif.start(roleCode: 'viewer', storeCode: 'Q1', uid: 'u1');
    await _settle();
    expect(notif.topics, contains(NotificationViewModel.topicAll));
    final resetting = notif.reset(); // chưa await: đang hủy subscription
    await notif.start(roleCode: 'admin', storeCode: 'Q1', uid: 'u1');
    await resetting;
    await _settle();
    expect(notif.isStarted, isTrue);
    expect(notif.topics, contains('role_admin'));
  });

  test('TC-21 Món trên Firestore chuyển đúng sang DTO Gateway → RecipeMapper', () {
    final json = FirestoreRecipeSource.detailJson('CF-MUOI', {
      'code': 'CF-MUOI',
      'name': 'Cà Phê Muối',
      'description': 'Espresso + kem muối',
      'status': 'published',
      'versionNumber': 2,
      'ingredients': [
        {'name': 'Espresso', 'quantity': 40, 'unit': 'ml', 'stage': 'Cốt'},
        {'name': 'Kem muối', 'quantity': 40, 'unit': 'ml', 'warning': 'Chứa sữa'},
      ],
      'steps': [
        {'title': 'Chiết xuất', 'description': '2 shot', 'durationSeconds': 28, 'temperatureCelsius': 93},
        {'title': 'Phủ kem', 'description': 'Rót nhẹ'},
      ],
    });
    final item = RecipeMapper.fromDetail(RecipeDetailResponse.fromJson(json));
    expect(item.code, 'CF-MUOI');
    expect(item.version, 'v2.0');
    expect(item.status, 'Ban hành');
    expect(item.sizes.single.ingredients.map((i) => i.name), ['Espresso', 'Kem muối']);
    expect(item.sizes.single.ingredients.last.warning, 'Chứa sữa');
    expect(item.steps.first.temperature, '93°C');
    expect(item.standardTime, '28 giây');
    expect(FirestoreRecipeSource.normalize('Cà Phê Muối Đá'), 'ca phe muoi da');
  });
}
