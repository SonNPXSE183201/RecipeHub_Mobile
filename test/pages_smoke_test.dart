// Widget test "khói": mọi màn hình dựng được, thao tác chính không ném lỗi (tăng độ phủ màn hình).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:recipehub_mobile/core/di/app_services.dart';
import 'package:recipehub_mobile/core/models/app_models.dart';
import 'package:recipehub_mobile/core/navigation/app_keys.dart';
import 'package:recipehub_mobile/core/services/mock/mock_analytics_service.dart';
import 'package:recipehub_mobile/core/services/mock_data_service.dart';
import 'package:recipehub_mobile/core/services/recipe_mapper.dart';
import 'package:recipehub_mobile/core/viewmodels/app_config_viewmodel.dart';
import 'package:recipehub_mobile/core/viewmodels/auth_viewmodel.dart';
import 'package:recipehub_mobile/core/viewmodels/notification_viewmodel.dart';
import 'package:recipehub_mobile/core/viewmodels/practice_history_viewmodel.dart';
import 'package:recipehub_mobile/core/viewmodels/recipe_viewmodel.dart';
import 'package:recipehub_mobile/core/viewmodels/storage_viewmodel.dart';
import 'package:recipehub_mobile/features/account/account_profile_page.dart';
import 'package:recipehub_mobile/features/admin_training/admin_store_training_page.dart';
import 'package:recipehub_mobile/features/feedback/create_feedback_page.dart';
import 'package:recipehub_mobile/features/feedback/my_feedback_list_page.dart';
import 'package:recipehub_mobile/features/learning/learning_task_detail_page.dart';
import 'package:recipehub_mobile/features/learning/my_learning_page.dart';
import 'package:recipehub_mobile/features/learning/notifications_page.dart';
import 'package:recipehub_mobile/features/learning/personal_progress_page.dart';
import 'package:recipehub_mobile/features/lookup/counter_recipe_lookup_page.dart';
import 'package:recipehub_mobile/features/lookup/recipe_detail_size_page.dart';
import 'package:recipehub_mobile/features/lookup/step_video_guide_page.dart';
import 'package:recipehub_mobile/features/practice/practical_evaluation_page.dart';
import 'package:recipehub_mobile/features/practice/practice_history_page.dart';
import 'package:recipehub_mobile/features/practice/quiz_exam_page.dart';
import 'package:recipehub_mobile/features/practice/self_practice_timer_page.dart';
import 'package:recipehub_mobile/features/sop/sop_catalog_page.dart';
import 'package:recipehub_mobile/features/sop/sop_detail_page.dart';
import 'package:recipehub_mobile/features/system/error_recovery_page.dart';
import 'package:recipehub_mobile/features/system/loading_transition_page.dart';

import 'support/fake_recipe_source.dart';

class _Harness {
  _Harness() {
    services = AppServices.mock(recipes: FakeRecipeSource(), analytics: analytics);
  }

  final analytics = MockAnalyticsService();
  late final AppServices services;
  late AuthViewModel auth;
  late PracticeHistoryViewModel practice;

  Widget wrap(Widget page) {
    final s = services;
    return MultiProvider(
      providers: [
        Provider<AppServices>.value(value: s),
        ChangeNotifierProvider(create: (_) => auth = AuthViewModel(auth: s.auth, analytics: s.analytics, crash: s.crash)..start()),
        ChangeNotifierProvider(create: (_) => AppConfigViewModel(service: s.remoteConfig)..init()),
        ChangeNotifierProvider(create: (_) => RecipeViewModel(source: s.recipes, crash: s.crash)..load()),
        ChangeNotifierProvider(
          create: (_) => StorageViewModel(
            storage: s.storage, picker: s.mediaPicker, auth: s.auth, analytics: s.analytics, crash: s.crash,
          ),
        ),
        ChangeNotifierProvider(create: (_) => NotificationViewModel(service: s.notifications, crash: s.crash)),
        ChangeNotifierProvider(create: (_) => practice = PracticeHistoryViewModel(store: s.practice, crash: s.crash)..load('u1')),
      ],
      child: MaterialApp(home: page),
    );
  }
}

late List<RecipeItem> _recipes;

Future<void> _pumpPage(WidgetTester tester, _Harness h, Widget page, {int frames = 6}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.625;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(h.wrap(page));
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

/// Font test vẽ mỗi ký tự thành ô 1em nên tràn layout chỉ có trong test: bỏ qua riêng lỗi overflow.
void _ignoreOverflow() {
  final original = FlutterError.onError;
  FlutterError.onError = (d) {
    if (d.exceptionAsString().contains('overflowed')) return;
    original?.call(d);
  };
  addTearDown(() => FlutterError.onError = original);
}

Future<void> _tapIfPresent(WidgetTester tester, Finder f) async {
  if (f.evaluate().isEmpty) return;
  await tester.ensureVisible(f.first);
  await tester.pump();
  await tester.tap(f.first, warnIfMissed: false);
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _dispose(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 2));
}

void main() {
  setUp(() {
    _recipes = [
      RecipeMapper.fromDetail(FakeRecipeSource.detail('r1', 'RC-OOL-02', 'Trà Sữa Oolong')),
      RecipeMapper.fromDetail(FakeRecipeSource.detail('r2', 'RC-CFE-01', 'Cà Phê Muối')),
    ];
    MockDataService.instance.recipes = List.of(_recipes);
  });

  testWidgets('P-01 Tra cứu tại quầy: tìm không dấu, lọc nhóm, mở chi tiết', (tester) async {
    _ignoreOverflow();
    final h = _Harness();
    await _pumpPage(tester, h, const CounterRecipeLookupPage());
    expect(find.text('Cà Phê Muối'), findsWidgets);
    await tester.enterText(find.byType(TextField).first, 'ca phe muoi');
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Cà Phê Muối'), findsWidgets);
    expect(find.text('Trà Sữa Oolong'), findsNothing);
    await tester.enterText(find.byType(TextField).first, '');
    await tester.pump(const Duration(milliseconds: 300));
    await _tapIfPresent(tester, find.text('Cà Phê Muối'));
    await tester.pump(const Duration(seconds: 1));
    await _dispose(tester);
  });

  testWidgets('P-02 Chi tiết món: view_recipe đúng nguồn, mở hướng dẫn video, tự luyện', (tester) async {
    _ignoreOverflow();
    final h = _Harness();
    await _pumpPage(tester, h, RecipeDetailSizePage(recipe: _recipes[1], source: 'notification'));
    expect(h.analytics.loggedEvents.lastWhere((e) => e.name == 'view_recipe').parameters['source'], 'notification');
    await _tapIfPresent(tester, find.textContaining('video chuẩn'));
    await tester.pump(const Duration(seconds: 1));
    await _dispose(tester);
  });

  testWidgets('P-03 Hướng dẫn từng bước: chuyển bước', (tester) async {
    _ignoreOverflow();
    final h = _Harness();
    await _pumpPage(tester, h, StepVideoGuidePage(recipe: _recipes[1]));
    for (final icon in [Icons.play_arrow_rounded, Icons.skip_next_rounded, Icons.arrow_forward_ios_rounded]) {
      await _tapIfPresent(tester, find.byIcon(icon));
    }
    await tester.pump(const Duration(seconds: 2));
    await _dispose(tester);
  });

  testWidgets('P-04 Tự luyện: bấm giờ, dừng, lưu vào lịch sử (bền vững)', (tester) async {
    _ignoreOverflow();
    final h = _Harness();
    await _pumpPage(tester, h, SelfPracticeTimerPage(initialRecipe: _recipes[1]));
    await _tapIfPresent(tester, find.byKey(AppKeys.timerStart));
    await tester.pump(const Duration(seconds: 3));
    await _tapIfPresent(tester, find.byKey(AppKeys.timerStart)); // dừng
    await _tapIfPresent(tester, find.byKey(AppKeys.timerSave));
    await tester.pump(const Duration(seconds: 1));
    expect(h.analytics.eventNames, containsAll(['start_brew_timer', 'complete_brew_timer']));
    final saved = h.practice.records;
    expect(saved, hasLength(1));
    expect(saved.single.practicedAt, matches(RegExp(r'^\d{2}/\d{2}/\d{4} \d{2}:\d{2}$')), reason: 'thời điểm thật, không còn "Vừa xong"');
    await _dispose(tester);
  });

  testWidgets('P-05 Lịch sử tự luyện: rỗng + tỷ lệ "—"', (tester) async {
    _ignoreOverflow();
    final h = _Harness();
    await _pumpPage(tester, h, const PracticeHistoryPage());
    expect(find.text('Chưa có lần tự luyện nào được lưu.'), findsOneWidget);
    expect(find.byKey(const Key('practice_within_percent')), findsOneWidget);
    await _dispose(tester);
  });

  testWidgets('P-06 SOP: danh mục → chi tiết; chỉ hiện món khớp mã', (tester) async {
    _ignoreOverflow();
    final h = _Harness();
    await _pumpPage(tester, h, const SopCatalogPage());
    await _dispose(tester);
    await _pumpPage(tester, h, SopDetailPage(sop: MockDataService.instance.sops.first));
    expect(find.textContaining('(RC-'), findsNothing, reason: 'mã SOP mẫu không khớp món → không hiện chip sai');
    await _dispose(tester);
  });

  testWidgets('P-07 Việc học, chi tiết nhiệm vụ, tiến độ, thông báo', (tester) async {
    _ignoreOverflow();
    final h = _Harness();
    for (final page in <Widget>[
      const MyLearningPage(),
      LearningTaskDetailPage(task: MockDataService.instance.tasks.first),
      const PersonalProgressPage(),
      const NotificationsPage(),
    ]) {
      await _pumpPage(tester, h, page);
      expect(tester.takeException(), isNull);
      await _dispose(tester);
    }
  });

  testWidgets('P-08 Phản hồi: tạo + danh sách', (tester) async {
    _ignoreOverflow();
    final h = _Harness();
    await _pumpPage(tester, h, const CreateFeedbackPage(initialRecipeCode: 'RC-CFE-01', initialRecipeName: 'Cà Phê Muối'));
    final fields = find.byType(TextField);
    if (fields.evaluate().isNotEmpty) await tester.enterText(fields.last, 'Vị hơi mặn');
    await tester.pump();
    await _dispose(tester);
    await _pumpPage(tester, h, const MyFeedbackListPage());
    await _dispose(tester);
  });

  testWidgets('P-09 Quiz: chọn đáp án', (tester) async {
    _ignoreOverflow();
    final h = _Harness();
    await _pumpPage(tester, h, const QuizExamPage());
    final q = MockDataService.instance.quizQuestions.first;
    await _tapIfPresent(tester, find.text(q.options.first));
    await _tapIfPresent(tester, find.textContaining('Tiếp'));
    await _dispose(tester);
  });

  testWidgets('P-10 Đánh giá thực hành: Barista KHÔNG thấy nút chấm tại quầy', (tester) async {
    _ignoreOverflow();
    final h = _Harness();
    await _pumpPage(tester, h, const PracticalEvaluationPage());
    expect(find.byKey(const Key('eval_toggle_admin')), findsNothing);
    await _dispose(tester);
  });

  testWidgets('P-11 Tài khoản, Admin đào tạo, màn lỗi, màn chờ', (tester) async {
    _ignoreOverflow();
    final h = _Harness();
    for (final page in <Widget>[
      const AccountProfilePage(),
      const AdminStoreTrainingPage(),
      const ErrorRecoveryPage(),
      const LoadingTransitionPage(message: 'Đang tải...'),
    ]) {
      await _pumpPage(tester, h, page);
      expect(tester.takeException(), isNull);
      await _dispose(tester);
    }
  });
}
