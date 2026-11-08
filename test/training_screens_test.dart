// Màn đào tạo dùng dữ liệu thật (repository), có trạng thái loading/empty và luồng nộp quiz.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:recipehub_mobile/core/di/app_services.dart';
import 'package:recipehub_mobile/core/services/mock/mock_training_repository.dart';
import 'package:recipehub_mobile/core/viewmodels/app_config_viewmodel.dart';
import 'package:recipehub_mobile/core/viewmodels/auth_viewmodel.dart';
import 'package:recipehub_mobile/core/viewmodels/recipe_viewmodel.dart';
import 'package:recipehub_mobile/core/viewmodels/training_viewmodel.dart';
import 'package:recipehub_mobile/features/learning/learning_task_detail_page.dart';
import 'package:recipehub_mobile/features/learning/my_learning_page.dart';
import 'package:recipehub_mobile/features/learning/personal_progress_page.dart';
import 'package:recipehub_mobile/features/practice/quiz_exam_page.dart';
import 'package:recipehub_mobile/features/sop/sop_catalog_page.dart';

import 'support/fake_recipe_source.dart';
import 'support/training_fixtures.dart';

Future<void> _pump(
  WidgetTester tester,
  MockTrainingRepository repo,
  Widget page,
) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.625;
  addTearDown(tester.view.reset);
  final s = AppServices.mock(recipes: FakeRecipeSource(), training: repo);
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
          create: (_) =>
              RecipeViewModel(source: s.recipes, crash: s.crash)..load(),
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
