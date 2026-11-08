// Bổ sung độ phủ: deep link, PDF báo cáo, luồng upload, model phiên / analytics.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:recipehub_mobile/core/di/app_services.dart';
import 'package:recipehub_mobile/core/models/app_models.dart';
import 'package:recipehub_mobile/core/models/session_models.dart';
import 'package:recipehub_mobile/core/navigation/deep_link_router.dart';
import 'package:recipehub_mobile/core/services/mock/mock_auth_service.dart';
import 'package:recipehub_mobile/core/services/mock/mock_media_picker_service.dart';
import 'package:recipehub_mobile/core/services/mock/mock_storage_service.dart';
import 'package:recipehub_mobile/core/services/mock_data_service.dart';
import 'package:recipehub_mobile/core/services/recipe_mapper.dart';
import 'package:recipehub_mobile/core/services/report/practice_report_pdf.dart';
import 'package:recipehub_mobile/core/viewmodels/auth_viewmodel.dart';
import 'package:recipehub_mobile/core/viewmodels/recipe_viewmodel.dart';
import 'package:recipehub_mobile/core/viewmodels/storage_viewmodel.dart';
import 'package:recipehub_mobile/features/feedback/my_feedback_list_page.dart';
import 'package:recipehub_mobile/features/learning/notifications_page.dart';
import 'package:recipehub_mobile/features/lookup/recipe_detail_size_page.dart';
import 'package:recipehub_mobile/core/services/mock/mock_analytics_service.dart';
import 'package:recipehub_mobile/core/services/mock/mock_crash_reporter.dart';

import 'support/fake_recipe_source.dart';

SelfPracticeRecord _rec(String id, {int secs = 30, int target = 30}) => SelfPracticeRecord(
      id: id, recipeName: 'Cà Phê Muối', recipeCode: 'CF-MUOI', size: 'M', durationSeconds: secs,
      notes: 'Ổn (đủ) \\ định lượng', practicedAt: '05/11/2026 10:00', targetSeconds: target,
    );

void main() {
  group('Model phiên', () {
    test('C-01 DeepLink.fromData mọi loại + mặc định', () {
      expect(DeepLink.fromData({'type': 'recipe', 'target_id': 'CF-MUOI'}).target, DeepLinkTarget.recipe);
      expect(DeepLink.fromData({'type': 'version_update', 'targetId': 'X'}).id, 'X');
      expect(DeepLink.fromData({'screen': 'sop', 'id': 'S1'}).target, DeepLinkTarget.sop);
      expect(DeepLink.fromData({'type': 'task_assigned'}).target, DeepLinkTarget.task);
      expect(DeepLink.fromData({'type': 'feedback_reply'}).target, DeepLinkTarget.feedback);
      expect(DeepLink.fromData({'type': 'none'}).target, DeepLinkTarget.notifications);
      expect(DeepLink.fromData(const {}).toString(), contains('notifications'));
    });

    test('C-02 thông báo JSON hai chiều, loại thông báo', () {
      final n = AppNotification(
        id: 'n1', title: 'T', body: 'B', receivedAt: DateTime(2026, 11, 5), data: {'type': 'recipe', 'target_id': 'CF-MUOI'},
        origin: NotificationOrigin.background,
      );
      final back = AppNotification.fromJson(jsonDecode(jsonEncode(n.toJson())) as Map<String, dynamic>);
      expect(back.origin, NotificationOrigin.background);
      expect(back.kind, NotificationKind.versionUpdate);
      expect(back.deepLink.id, 'CF-MUOI');
      for (final t in ['feedback', 'task', 'sop', 'xyz']) {
        expect(notificationKindFrom(t), isNotNull);
      }
    });

    test('C-03 thông điệp lỗi xác thực / storage đều tiếng Việt', () {
      for (final c in AuthFailureCode.values) {
        expect(AuthFailure(c).userMessage, isNotEmpty);
        expect(AuthFailure(c, 'x').toString(), contains(c.name));
      }
      for (final c in StorageFailureCode.values) {
        expect(StorageFailure(c).userMessage, isNotEmpty);
      }
    });

    test('C-04 Analytics: tên snake_case, lọc PII khỏi tham số', () {
      final e = AnalyticsEvent('view_recipe', {'recipe_code': 'CF-MUOI', 'email': 'a@b.com', 'note': 'gọi 0912345678'});
      expect(e.parameters.containsKey('email'), isFalse);
      expect(e.parameters['recipe_code'], 'CF-MUOI');
      expect(AnalyticsEvent.isValidName('view_recipe'), isTrue);
      expect(AnalyticsEvent.isValidName('ViewRecipe'), isFalse);
    });

    test('C-05 AppUser initials, khách', () {
      expect(const AppUser(uid: 'u', method: AuthMethod.google, displayName: 'Nguyễn Văn An').initials, 'NA');
      expect(const AppUser(uid: 'u', method: AuthMethod.guest).initials, 'K');
      expect(const AppUser(uid: 'u', method: AuthMethod.guest).isGuest, isTrue);
    });
  });

  test('C-06 PDF báo cáo tự luyện: hợp lệ, chịu được ký tự đặc biệt và tiếng Việt', () {
    final bytes = PracticeReportPdf.build(
      storeLabel: 'Landmark 81',
      traineeLabel: 'Barista (khách)',
      records: [_rec('a'), _rec('b', secs: 50), _rec('c', target: 0)],
      generatedAt: DateTime(2026, 11, 5, 9),
    );
    final text = latin1.decode(bytes, allowInvalid: true);
    expect(text.startsWith('%PDF-'), isTrue);
    expect(text.trimRight().endsWith('%%EOF'), isTrue);
    expect(bytes.length, greaterThan(500));
    expect(PracticeReportPdf.build(storeLabel: 's', traineeLabel: 't', records: const []).length, greaterThan(100));
  });

  group('StorageViewModel', () {
    StorageViewModel vm({MockMediaPickerService? picker, MockStorageService? storage, MockAuthService? auth}) =>
        StorageViewModel(
          storage: storage ?? MockStorageService(),
          picker: picker ?? MockMediaPickerService(),
          auth: auth ?? (MockAuthService()..signInAsGuest()),
          analytics: MockAnalyticsService(),
          crash: MockCrashReporter(),
        );

    test('C-07 chọn ảnh → upload thành công; hủy chọn; ảnh quá cỡ', () async {
      final ok = vm();
      await Future<void>.delayed(Duration.zero);
      await ok.pickAttachment(fromCamera: false);
      expect(ok.attachment, isNotNull);
      final url = await ok.uploadAttachment();
      expect(url, isNotNull);
      expect(ok.attachmentStatus, UploadStatus.success);
      ok.reset();
      expect(ok.attachment, isNull);

      final cancelled = vm(picker: MockMediaPickerService(cancel: true));
      await cancelled.pickAttachment(fromCamera: true);
      expect(cancelled.attachment, isNull);

      final big = vm(picker: MockMediaPickerService(returnOversized: true));
      await big.pickAttachment(fromCamera: false);
      expect(big.attachmentStatus, UploadStatus.error);
      expect(big.attachmentError, contains('5MB'));
    });

    test('C-08 upload lỗi quyền → báo lỗi; xuất PDF: chưa đăng nhập thì từ chối, đăng nhập thì lưu', () async {
      final failing = vm(storage: MockStorageService(failNext: const StorageFailure(StorageFailureCode.unauthorized)));
      await Future<void>.delayed(Duration.zero);
      await failing.pickAttachment(fromCamera: false);
      expect(await failing.uploadAttachment(), isNull);
      expect(failing.attachmentError, isNotNull);

      final anon = vm(auth: MockAuthService());
      expect(await anon.exportPracticeReport(records: [_rec('a')], traineeLabel: 'x'), isNull);
      expect(anon.reportStatus, UploadStatus.error);

      final signed = vm();
      await Future<void>.delayed(Duration.zero);
      final r = await signed.exportPracticeReport(records: [_rec('a')], traineeLabel: 'x');
      expect(r, isNotNull);
      expect(signed.lastReport, isNotNull);
      expect(signed.lastReportBytes, greaterThan(0));
    });
  });

  group('DeepLinkRouter', () {
    late List<RecipeItem> recipes;
    setUp(() {
      recipes = [RecipeMapper.fromDetail(FakeRecipeSource.detail('r2', 'RC-CFE-01', 'Cà Phê Muối'))];
      MockDataService.instance.recipes = List.of(recipes);
    });

    Widget host(Widget child, RecipeViewModel rvm, AuthViewModel auth) => MultiProvider(
          providers: [
            Provider<AppServices>.value(value: AppServices.mock(recipes: FakeRecipeSource())),
            ChangeNotifierProvider.value(value: rvm),
            ChangeNotifierProvider.value(value: auth),
          ],
          child: MaterialApp(home: child),
        );

    testWidgets('C-09 resolve: món có sẵn / SOP / nhiệm vụ / phản hồi / mặc định', (tester) async {
      final rvm = RecipeViewModel(source: FakeRecipeSource(), crash: MockCrashReporter());
      await rvm.load();
      final auth = AuthViewModel(auth: MockAuthService(), analytics: MockAnalyticsService(), crash: MockCrashReporter());
      late BuildContext ctx;
      await tester.pumpWidget(host(Builder(builder: (c) {
        ctx = c;
        return const SizedBox();
      }), rvm, auth));
      expect(DeepLinkRouter.resolve(ctx, const DeepLink(DeepLinkTarget.recipe, 'RC-CFE-01')), isA<RecipeDetailSizePage>());
      expect(DeepLinkRouter.resolve(ctx, const DeepLink(DeepLinkTarget.recipe, 'KHONG-CO')), isA<NotificationsPage>());
      final sop = MockDataService.instance.sops.first;
      expect(DeepLinkRouter.resolve(ctx, DeepLink(DeepLinkTarget.sop, sop.id)).runtimeType.toString(), 'SopDetailPage');
      final task = MockDataService.instance.tasks.first;
      expect(DeepLinkRouter.resolve(ctx, DeepLink(DeepLinkTarget.task, task.id)).runtimeType.toString(), 'LearningTaskDetailPage');
      expect(DeepLinkRouter.resolve(ctx, const DeepLink(DeepLinkTarget.feedback, null)), isA<MyFeedbackListPage>());
      expect(DeepLinkRouter.resolve(ctx, const DeepLink(DeepLinkTarget.notifications, null)), isA<NotificationsPage>());
    });

    testWidgets('C-10 open: đã đăng xuất trong lúc tra món → không đẩy trang lên', (tester) async {
      final rvm = RecipeViewModel(source: FakeRecipeSource(), crash: MockCrashReporter());
      final auth = AuthViewModel(auth: MockAuthService(), analytics: MockAnalyticsService(), crash: MockCrashReporter())..start();
      final nav = GlobalKey<NavigatorState>();
      await tester.pumpWidget(MultiProvider(
        providers: [
          Provider<AppServices>.value(value: AppServices.mock(recipes: FakeRecipeSource())),
          ChangeNotifierProvider.value(value: rvm),
          ChangeNotifierProvider.value(value: auth),
        ],
        child: MaterialApp(navigatorKey: nav, home: const Text('HOME')),
      ));
      await tester.pump();
      await tester.runAsync(() => DeepLinkRouter.open(nav.currentContext!, const DeepLink(DeepLinkTarget.recipe, 'RC-CFE-01')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('HOME'), findsOneWidget, reason: 'chưa đăng nhập → không mở chi tiết');
    });
  });
}
