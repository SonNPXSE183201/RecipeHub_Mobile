import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:recipehub_mobile/core/di/app_services.dart';
import 'package:recipehub_mobile/core/models/app_models.dart';
import 'package:recipehub_mobile/core/navigation/app_keys.dart';
import 'package:recipehub_mobile/core/services/mock/mock_auth_service.dart';
import 'package:recipehub_mobile/core/services/mock/mock_user_profile_service.dart';
import 'package:recipehub_mobile/core/viewmodels/app_config_viewmodel.dart';
import 'package:recipehub_mobile/core/viewmodels/auth_viewmodel.dart';
import 'package:recipehub_mobile/core/viewmodels/notification_viewmodel.dart';
import 'package:recipehub_mobile/core/viewmodels/practice_history_viewmodel.dart';
import 'package:recipehub_mobile/core/viewmodels/recipe_viewmodel.dart';
import 'package:recipehub_mobile/core/viewmodels/storage_viewmodel.dart';
import 'package:recipehub_mobile/core/viewmodels/training_viewmodel.dart';
import 'package:recipehub_mobile/features/account/account_profile_page.dart';
import 'package:recipehub_mobile/features/account/change_password_page.dart';
import 'package:recipehub_mobile/features/sop_book/sop_book_page.dart';
import 'package:recipehub_mobile/features/feedback/create_feedback_page.dart';
import 'package:recipehub_mobile/features/feedback/my_feedback_list_page.dart';
import 'package:recipehub_mobile/features/learning/learning_task_detail_page.dart';
import 'package:recipehub_mobile/features/learning/my_learning_page.dart';
import 'package:recipehub_mobile/features/learning/personal_progress_page.dart';
import 'package:recipehub_mobile/features/lookup/counter_recipe_lookup_page.dart';
import 'package:recipehub_mobile/features/practice/practical_evaluation_page.dart';
import 'package:recipehub_mobile/features/practice/practice_history_page.dart';
import 'package:recipehub_mobile/features/practice/quiz_exam_page.dart';
import 'package:recipehub_mobile/features/practice/self_practice_timer_page.dart';

import 'support/fake_recipe_source.dart';
import 'support/training_fixtures.dart';

Future<AuthViewModel> _pump(
  WidgetTester tester,
  Widget page, {
  bool admin = true,
}) async {
  tester.view.physicalSize = const Size(600, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final s = AppServices.mock(
    recipes: FakeRecipeSource(),
    training: testTrainingRepo(),
  );
  final auth = AuthViewModel(
    auth: s.auth,
    analytics: s.analytics,
    crash: s.crash,
    profile: MockUserProfileService(role: admin ? 'admin' : 'viewer'),
  );
  addTearDown(auth.dispose);
  await auth.signInWithEmail(
    MockAuthService.validEmail,
    MockAuthService.validPassword,
  );
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<AppServices>.value(value: s),
        ChangeNotifierProvider<AuthViewModel>.value(value: auth),
        ChangeNotifierProvider(
          create: (_) => AppConfigViewModel(service: s.remoteConfig)..init(),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              RecipeViewModel(source: s.recipes, crash: s.crash)..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => StorageViewModel(
            storage: s.storage,
            picker: s.mediaPicker,
            auth: s.auth,
            analytics: s.analytics,
            crash: s.crash,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              NotificationViewModel(service: s.notifications, crash: s.crash),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              TrainingViewModel(repo: s.training, crash: s.crash)
                ..bind(auth.user!.uid),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              AdminTrainingViewModel(repo: s.training, crash: s.crash)..start(),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              PracticeHistoryViewModel(store: s.practice, crash: s.crash)
                ..load(auth.user!.uid),
        ),
      ],
      child: MaterialApp(home: page),
    ),
  );
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  return auth;
}

void main() {
  testWidgets('Lịch sử tự luyện giữ tên và size, ẩn mã món', (tester) async {
    await _pump(tester, const PracticeHistoryPage(), admin: false);
    final history = tester
        .element(find.byType(PracticeHistoryPage))
        .read<PracticeHistoryViewModel>();
    await history.add(
      const SelfPracticeRecord(
        id: 'private-record',
        recipeCode: 'CF-AMERICANON',
        recipeName: 'Cà phê Americano',
        size: 'Khổng lồ',
        durationSeconds: 45,
        targetSeconds: 60,
        notes: '',
        practicedAt: '08/11/2026',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Cà phê Americano'), findsOneWidget);
    expect(find.text('Khổng lồ'), findsOneWidget);
    expect(find.textContaining('CF-AMERICANON'), findsNothing);
    expect(history.records.single.recipeCode, 'CF-AMERICANON');
  });

  testWidgets(
    'Feedback attachment card matches input width and splits actions evenly',
    (tester) async {
      await _pump(tester, const CreateFeedbackPage(), admin: false);
      final inputWidth = tester.getSize(find.byType(TextField)).width;
      final gallery = find.byKey(AppKeys.pickFromGallery);
      final camera = find.byKey(AppKeys.pickFromCamera);
      await tester.ensureVisible(gallery);
      await tester.pumpAndSettle();
      final card = find
          .ancestor(
            of: find.text('Ảnh đính kèm (tùy chọn, tối đa 5MB)'),
            matching: find.byType(Container),
          )
          .first;
      expect(tester.getSize(card).width, inputWidth);
      expect(tester.getSize(gallery).width, tester.getSize(camera).width);
      expect(tester.getTopLeft(gallery).dy, tester.getTopLeft(camera).dy);
    },
  );

  testWidgets('Account password action opens working form', (tester) async {
    await _pump(tester, const AccountProfilePage(), admin: false);
    final action = find.text('Đổi mật khẩu tài khoản');
    await tester.ensureVisible(action);
    await tester.tap(action);
    await tester.pumpAndSettle();
    expect(find.byType(ChangePasswordPage), findsOneWidget);
    expect(find.text('Mật khẩu hiện tại'), findsOneWidget);
  });

  testWidgets('Learning progress action only contains an accessible icon', (
    tester,
  ) async {
    await _pump(tester, const MyLearningPage(), admin: false);
    final action = find.byTooltip('Tiến độ cá nhân');
    expect(action, findsOneWidget);
    expect(
      find.descendant(of: action, matching: find.byType(Text)),
      findsNothing,
    );
    expect(tester.getSize(action).height, greaterThanOrEqualTo(48));
  });

  testWidgets('Admin account hides personal progress and practice history', (
    tester,
  ) async {
    final auth = await _pump(tester, const AccountProfilePage());
    expect(auth.isAdmin, isTrue);
    expect(auth.hasPersonalLearning, isFalse);
    expect(find.text('Tiến độ đào tạo cá nhân'), findsNothing);
    expect(find.text('Lịch sử tự luyện với Timer'), findsNothing);
    expect(find.text('Bảng theo dõi đào tạo chi nhánh'), findsOneWidget);
    expect(find.text('Sổ tay SOP'), findsOneWidget);
  });

  testWidgets('Barista account keeps personal progress and practice history', (
    tester,
  ) async {
    await _pump(tester, const AccountProfilePage(), admin: false);
    expect(find.text('Tiến độ đào tạo cá nhân'), findsOneWidget);
    expect(find.text('Lịch sử tự luyện với Timer'), findsOneWidget);
    expect(find.text('Sổ tay SOP'), findsOneWidget);
    expect(find.textContaining('CỬA HÀNG CÔNG TÁC'), findsNothing);
    expect(find.textContaining('Cửa hàng công tác'), findsNothing);
    await tester.tap(find.text('Sổ tay SOP'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(SopBookPage), findsOneWidget);
  });

  for (final admin in [true, false]) {
    testWidgets('Lookup personal-practice FAB follows role (admin: $admin)', (
      tester,
    ) async {
      await _pump(tester, const CounterRecipeLookupPage(), admin: admin);
      expect(find.text('Trà Sữa Oolong'), findsOneWidget);
      expect(find.text('RC-OOL-02'), findsNothing);
      expect(find.text('RC-CFE-01'), findsNothing);
      expect(find.text('Thư viện SOP'), findsNothing);
      expect(find.text('Tra cứu độc lập'), findsNothing);
      if (!admin) {
        final fab = find.byKey(AppKeys.selfPracticeFab);
        expect(tester.widget<FloatingActionButton>(fab).isExtended, isFalse);
        expect(
          tester.widget<FloatingActionButton>(fab).tooltip,
          'Tự luyện quầy bar',
        );
        expect(
          find.descendant(of: fab, matching: find.byType(Text)),
          findsNothing,
        );
        expect(
          find.descendant(of: fab, matching: find.byIcon(Icons.timer_outlined)),
          findsOneWidget,
        );
        expect(tester.getSize(fab), const Size(56, 56));
      }
      expect(
        find.byKey(AppKeys.selfPracticeFab),
        admin ? findsNothing : findsOneWidget,
      );
    });
  }

  final personalPages = <String, Widget Function()>{
    'SelfPracticeTimer': () => const SelfPracticeTimerPage(),
    'PersonalProgress': () => const PersonalProgressPage(),
    'PracticeHistory': () => const PracticeHistoryPage(),
    'MyLearning': () => const MyLearningPage(),
    'Quiz': () => const QuizExamPage(),
    'LearningTask': () => LearningTaskDetailPage(task: testTask()),
  };
  for (final entry in personalPages.entries) {
    testWidgets('Admin direct route ${entry.key} returns to root', (
      tester,
    ) async {
      await _pump(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context)
                  .push(MaterialPageRoute<void>(builder: (_) => entry.value())),
              child: const Text('Trang gốc'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Trang gốc'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Trang gốc'), findsOneWidget);
      expect(
        find.text('Tài khoản Admin không có mục học và tự luyện cá nhân.'),
        findsOneWidget,
      );
      final rootContext = tester.element(find.text('Trang gốc'));
      expect(Navigator.of(rootContext).canPop(), isFalse);
    });
  }

  testWidgets(
    'Evaluation results button uses eye, 48dp, tooltip and semantics',
    (tester) async {
      await _pump(tester, const PracticalEvaluationPage());
      final button = find.byKey(const Key('eval_toggle_admin'));
      expect(button, findsOneWidget);
      expect(tester.widget<IconButton>(button).tooltip, 'Xem kết quả');
      expect(
        find.descendant(
          of: button,
          matching: find.byIcon(Icons.visibility_outlined),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: button, matching: find.byType(Text)),
        findsNothing,
      );
      expect(tester.getSize(button).width, greaterThanOrEqualTo(48));
      expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
      expect(
        find.ancestor(
          of: button,
          matching: find.byWidgetPredicate(
            (w) =>
                w is Semantics &&
                w.properties.label == 'Xem kết quả' &&
                w.properties.button == true,
          ),
        ),
        findsOneWidget,
      );
      await tester.tap(button);
      await tester.pump();
      expect(tester.widget<IconButton>(button).tooltip, 'Chấm tại quầy');
    },
  );

  testWidgets('Feedback action uses rate_review and still opens send form', (
    tester,
  ) async {
    await _pump(tester, const MyFeedbackListPage(), admin: false);
    final send = find.byTooltip('Gửi phản hồi');
    expect(
      find.descendant(of: send, matching: find.byType(Text)),
      findsNothing,
    );
    expect(
      find.descendant(
        of: send,
        matching: find.byIcon(Icons.rate_review_rounded),
      ),
      findsOneWidget,
    );
    expect(tester.getSize(send).height, greaterThanOrEqualTo(48));
    await tester.ensureVisible(send);
    await tester.tap(send);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(CreateFeedbackPage), findsOneWidget);
    expect(
      tester
          .widget<ElevatedButton>(find.byKey(AppKeys.feedbackSubmit))
          .onPressed,
      isNull,
    );
    expect(find.text('Chọn món cần phản hồi'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('feedback_recipe_picker')));
    await tester.pumpAndSettle();
    final search = find.byType(TextField).last;
    await tester.enterText(search, 'ca phe muoi');
    await tester.pump();
    expect(find.text('Cà Phê Muối'), findsOneWidget);
    expect(find.text('Trà Sữa Oolong'), findsNothing);
    expect(find.textContaining('RC-CFE'), findsNothing);
    await tester.tap(find.text('Cà Phê Muối'));
    await tester.pumpAndSettle();
    expect(find.text('Cà Phê Muối'), findsOneWidget);
    expect(
      tester
          .widget<ElevatedButton>(find.byKey(AppKeys.feedbackSubmit))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('Recipe context can change without retaining the original step', (
    tester,
  ) async {
    await _pump(
      tester,
      const CreateFeedbackPage(
        initialRecipeCode: 'RC-OOL-02',
        initialRecipeName: 'Trà Sữa Oolong',
        initialStepNumber: 1,
        initialStepTitle: 'Ủ trà',
      ),
      admin: false,
    );
    expect(find.text('Trà Sữa Oolong'), findsOneWidget);
    expect(find.textContaining('Bước 1'), findsOneWidget);
    expect(
      tester
          .widget<ElevatedButton>(find.byKey(AppKeys.feedbackSubmit))
          .onPressed,
      isNotNull,
    );
    await tester.tap(find.byKey(const ValueKey('feedback_recipe_picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cà Phê Muối'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Bước 1'), findsNothing);
    expect(find.text('Cà Phê Muối'), findsOneWidget);
  });

  testWidgets('Lookup dish names appear once and published chips are absent', (
    tester,
  ) async {
    await _pump(tester, const CounterRecipeLookupPage(), admin: false);
    expect(find.textContaining('Ban hành'), findsNothing);
    expect(find.text('Trà Sữa Oolong'), findsOneWidget);
    expect(find.text('Cà Phê Muối'), findsOneWidget);
  });
}
