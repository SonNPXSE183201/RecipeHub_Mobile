// Màn đào tạo dùng dữ liệu thật (repository), có trạng thái loading/empty và luồng nộp quiz.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:recipehub_mobile/core/di/app_services.dart';
import 'package:recipehub_mobile/core/models/app_models.dart';
import 'package:recipehub_mobile/core/models/recipe_models.dart';
import 'package:recipehub_mobile/core/services/mock/mock_training_repository.dart';
import 'package:recipehub_mobile/core/viewmodels/app_config_viewmodel.dart';
import 'package:recipehub_mobile/core/viewmodels/auth_viewmodel.dart';
import 'package:recipehub_mobile/core/viewmodels/recipe_viewmodel.dart';
import 'package:recipehub_mobile/core/viewmodels/training_viewmodel.dart';
import 'package:recipehub_mobile/features/learning/learning_task_detail_page.dart';
import 'package:recipehub_mobile/features/learning/my_learning_page.dart';
import 'package:recipehub_mobile/features/learning/personal_progress_page.dart';
import 'package:recipehub_mobile/features/lookup/step_video_guide_page.dart';
import 'package:recipehub_mobile/features/practice/quiz_exam_page.dart';
import 'package:recipehub_mobile/features/sop/sop_catalog_page.dart';

import 'support/fake_recipe_source.dart';
import 'support/training_fixtures.dart';

Future<void> _pump(
  WidgetTester tester,
  MockTrainingRepository repo,
  Widget page, {
  FakeRecipeSource? recipes,
  int recipeLimit = 50,
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.625;
  addTearDown(tester.view.reset);
  final s = AppServices.mock(
    recipes: recipes ?? FakeRecipeSource(),
    training: repo,
  );
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<AppServices>.value(value: s),
        ChangeNotifierProvider(
          create: (_) => AuthViewModel(
            auth: s.auth,
            analytics: s.analytics,
            crash: s.crash,
          )..start(),
        ),
        ChangeNotifierProvider(
          create: (_) => AppConfigViewModel(service: s.remoteConfig)..init(),
        ),
        ChangeNotifierProvider(
          lazy: false,
          create: (_) =>
              RecipeViewModel(source: s.recipes, crash: s.crash)
                ..load(limit: recipeLimit),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              TrainingViewModel(repo: s.training, crash: s.crash)..bind('u1'),
        ),
      ],
      child: MaterialApp(home: page),
    ),
  );
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

class _DeferredRecipeSource extends FakeRecipeSource {
  final pending = Completer<RecipeDetailResponse>();
  int remoteReads = 0;

  @override
  Future<RecipeDetailResponse> getRecipe(String id) {
    if (id == 'r2') {
      remoteReads++;
      return pending.future;
    }
    return super.getRecipe(id);
  }
}

LearningTaskItem _recipeTask(String code) => LearningTaskItem(
  id: 'recipe-task',
  title: 'Học công thức',
  type: 'Công thức',
  targetCode: code,
  version: 'v1.0',
  assignedBy: 'Quản lý',
  assignedDate: '01/11/2026',
  dueDate: '10/11/2026',
  status: TaskStatus.notStarted,
  progress: 0,
  sections: const [],
);

/// Font test vẽ mỗi ký tự thành ô 1em nên tràn layout chỉ có trong test: bỏ qua riêng lỗi overflow.
void _ignoreOverflow() {
  final original = FlutterError.onError;
  FlutterError.onError = (d) {
    if (d.exceptionAsString().contains('overflowed')) return;
    original?.call(d);
  };
  addTearDown(() => FlutterError.onError = original);
}

void main() {
  testWidgets('Mở học tải món ngoài giới hạn, loading và không mở lặp', (
    tester,
  ) async {
    _ignoreOverflow();
    final source = _DeferredRecipeSource();
    await _pump(
      tester,
      testTrainingRepo(),
      LearningTaskDetailPage(task: _recipeTask('RC-CFE-01')),
      recipes: source,
      recipeLimit: 1,
    );
    await tester.tap(find.text('Mở học ngay'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(StepVideoGuidePage), findsNothing);
    await tester.tap(find.text('TÀI LIỆU & VIDEO CHUẨN LIÊN KẾT'));
    await tester.pump();
    expect(source.remoteReads, 1);
    source.pending.complete(
      FakeRecipeSource.detail('r2', 'RC-CFE-01', 'Cà Phê Muối'),
    );
    await tester.pumpAndSettle();
    final page = tester.widget<StepVideoGuidePage>(
      find.byType(StepVideoGuidePage),
    );
    expect(page.recipe.code, 'RC-CFE-01');
    expect(page.initialStepNumber, 1);
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNotNull,
    );
  });

  testWidgets('Thẻ tài liệu chỉ báo không có sau tra cứu và cho thử lại', (
    tester,
  ) async {
    _ignoreOverflow();
    final source = FakeRecipeSource();
    await _pump(
      tester,
      testTrainingRepo(),
      LearningTaskDetailPage(task: _recipeTask('KHONG-TON-TAI')),
      recipes: source,
      recipeLimit: 1,
    );
    await tester.tap(find.text('TÀI LIỆU & VIDEO CHUẨN LIÊN KẾT'));
    await tester.pumpAndSettle();
    expect(source.calls, 2);
    expect(
      find.text('Công thức này chưa có trong danh sách đã ban hành.'),
      findsOneWidget,
    );
    expect(find.byType(StepVideoGuidePage), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    ScaffoldMessenger.of(tester.element(find.byType(LearningTaskDetailPage)))
        .removeCurrentSnackBar();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mở học ngay'));
    await tester.pumpAndSettle();
    expect(source.calls, 3);
  });

  testWidgets('Món có sẵn mở từ thẻ tài liệu mà không truy vấn thêm', (
    tester,
  ) async {
    _ignoreOverflow();
    final source = FakeRecipeSource();
    await _pump(
      tester,
      testTrainingRepo(),
      LearningTaskDetailPage(task: _recipeTask('RC-OOL-02')),
      recipes: source,
      recipeLimit: 1,
    );
    await tester.tap(find.text('TÀI LIỆU & VIDEO CHUẨN LIÊN KẾT'));
    await tester.pumpAndSettle();
    expect(source.calls, 1);
    expect(find.byType(StepVideoGuidePage), findsOneWidget);
  });

  testWidgets(
    'Rời trang trong lúc tải không điều hướng hay setState sau dispose',
    (tester) async {
      _ignoreOverflow();
      final source = _DeferredRecipeSource();
      await _pump(
        tester,
        testTrainingRepo(),
        LearningTaskDetailPage(task: _recipeTask('RC-CFE-01')),
        recipes: source,
        recipeLimit: 1,
      );
      await tester.tap(find.text('Mở học ngay'));
      await tester.pump();
      expect(source.remoteReads, 1);
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      source.pending.complete(
        FakeRecipeSource.detail('r2', 'RC-CFE-01', 'Cà Phê Muối'),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(StepVideoGuidePage), findsNothing);
    },
  );

  testWidgets('SOP: lọc theo danh mục thật, mở chi tiết', (tester) async {
    _ignoreOverflow();
    await _pump(tester, testTrainingRepo(), const SopCatalogPage());
    expect(find.text('Vệ sinh máy pha'), findsOneWidget);
    expect(find.text('Kỹ thuật lắc trà'), findsOneWidget);
    final chip = find.widgetWithText(ChoiceChip, 'Kỹ thuật pha chế');
    await tester.ensureVisible(chip);
    await tester.pump();
    await tester.tap(chip);
    await tester.pump();
    expect(find.text('Vệ sinh máy pha'), findsNothing);
    expect(find.text('Kỹ thuật lắc trà'), findsOneWidget);
  });

  testWidgets('SOP: chưa có dữ liệu → empty state', (tester) async {
    _ignoreOverflow();
    await _pump(tester, MockTrainingRepository(), const SopCatalogPage());
    expect(find.text('Chưa có SOP nào được ban hành.'), findsOneWidget);
  });

  testWidgets('Việc học + chi tiết: tick mục lưu tiến độ, có nút Làm quiz', (
    tester,
  ) async {
    _ignoreOverflow();
    final repo = testTrainingRepo();
    await _pump(tester, repo, const MyLearningPage());
    expect(find.text('Chưa học (1)'), findsOneWidget);
    await _pump(tester, repo, LearningTaskDetailPage(task: testTask()));
    expect(find.text('Làm quiz'), findsOneWidget);
    await tester.tap(find.byType(CheckboxListTile).first);
    await tester.pump(const Duration(milliseconds: 200));
    expect(repo.progress['u1']!['task-doc-1']!.completedSections, [0]);
    expect(find.text('1/2 mục'), findsOneWidget);
  });

  testWidgets('Tiến độ cá nhân: dựng được khi chưa có quiz/chấm', (
    tester,
  ) async {
    _ignoreOverflow();
    await _pump(tester, testTrainingRepo(), const PersonalProgressPage());
    expect(find.text('Chưa làm quiz'), findsOneWidget);
  });

  testWidgets('Quiz: chọn bộ đề → nộp → thấy điểm, giải thích', (tester) async {
    _ignoreOverflow();
    await _pump(tester, testTrainingRepo(), const QuizExamPage());
    await tester.tap(find.text('Quiz vệ sinh máy'));
    await tester.pump();
    await tester.tap(find.text('Nộp bài kiểm tra'));
    await tester.pump();
    expect(find.textContaining('trả lời đầy đủ'), findsOneWidget);
    await tester.tap(find.text('30 giây'));
    await tester.tap(find.text('Nóng'));
    await tester.pump();
    await tester.ensureVisible(find.text('Nộp bài kiểm tra'));
    await tester.tap(find.text('Nộp bài kiểm tra'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.textContaining('2 / 2 câu đúng'), findsOneWidget);
    expect(find.text('Xả 30 giây.'), findsOneWidget);
  });

  testWidgets('Quiz: không có bộ đề → empty state', (tester) async {
    _ignoreOverflow();
    await _pump(tester, MockTrainingRepository(), const QuizExamPage());
    expect(find.text('Chưa có bộ đề quiz nào được phát hành.'), findsOneWidget);
  });
}
