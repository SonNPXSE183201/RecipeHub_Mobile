import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:recipehub_mobile/core/di/app_services.dart';
import 'package:recipehub_mobile/core/models/app_models.dart';
import 'package:recipehub_mobile/core/navigation/app_keys.dart';
import 'package:recipehub_mobile/core/services/mock/mock_feedback_repository.dart';
import 'package:recipehub_mobile/core/viewmodels/auth_viewmodel.dart';
import 'package:recipehub_mobile/core/viewmodels/storage_viewmodel.dart';
import 'package:recipehub_mobile/features/feedback/create_feedback_page.dart';

import 'support/fake_recipe_source.dart';

class _RecordingFeedbackRepository extends MockFeedbackRepository {
  final submissions = <NewFeedback>[];

  @override
  Future<String> create(NewFeedback feedback) async {
    submissions.add(feedback);
    return super.create(feedback);
  }
}

Future<_RecordingFeedbackRepository> _pumpPage(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1000, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final repo = _RecordingFeedbackRepository();
  final services = AppServices.mock(
    recipes: FakeRecipeSource(),
    feedback: repo,
  );
  final auth = AuthViewModel(
    auth: services.auth,
    analytics: services.analytics,
    crash: services.crash,
  );
  addTearDown(auth.dispose);
  await auth.signInWithGoogle();
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<AppServices>.value(value: services),
        ChangeNotifierProvider<AuthViewModel>.value(value: auth),
        ChangeNotifierProvider(
          create: (_) => StorageViewModel(
            storage: services.storage,
            picker: services.mediaPicker,
            auth: services.auth,
            analytics: services.analytics,
            crash: services.crash,
          ),
        ),
      ],
      child: const MaterialApp(
        home: CreateFeedbackPage(
          initialRecipeCode: 'RC-CFE-01',
          initialRecipeName: 'Cà Phê Muối',
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

Future<void> _submit(WidgetTester tester) async {
  final button = find.byKey(AppKeys.feedbackSubmit);
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Nội dung có bộ đếm và chặn nhập quá 2000 ký tự', (tester) async {
    await _pumpPage(tester);
    final field = find.byType(TextField);
    expect(find.text('0/2000'), findsOneWidget);
    await tester.enterText(field, 'á' * 2001);
    await tester.pump();
    expect(tester.widget<TextField>(field).controller!.text, 'á' * 2000);
    expect(find.text('2000/2000'), findsOneWidget);
  });

  testWidgets('Nội dung quá dài báo lỗi trước khi gửi và cho phép sửa lại', (
    tester,
  ) async {
    final repo = await _pumpPage(tester);
    // Bypass input formatters to verify the independent submit guard.
    tester.widget<TextField>(find.byType(TextField)).controller!.text =
        'á' * 2001;
    await tester.pump();
    await _submit(tester);
    expect(
      find.text('Nội dung phản hồi không được vượt quá 2000 ký tự.'),
      findsOneWidget,
    );
    expect(repo.submissions, isEmpty);
    expect(find.byType(CreateFeedbackPage), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Nhiệt độ hơi cao.');
    await _submit(tester);
    expect(repo.submissions.single.content, 'Nhiệt độ hơi cao.');
  });

  testWidgets('Gửi được nội dung đúng 2000 ký tự sau khi bỏ khoảng trắng', (
    tester,
  ) async {
    final repo = await _pumpPage(tester);
    tester.widget<TextField>(find.byType(TextField)).controller!.text =
        '  ${'ộ' * 2000}  ';
    await tester.pump();
    await _submit(tester);
    expect(repo.submissions.single.content, 'ộ' * 2000);
  });
}
