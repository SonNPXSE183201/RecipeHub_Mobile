import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:recipehub_mobile/app.dart';
import 'package:recipehub_mobile/core/di/app_services.dart';
import 'package:recipehub_mobile/core/models/app_models.dart';
import 'package:recipehub_mobile/core/models/session_models.dart';
import 'package:recipehub_mobile/core/services/mock/mock_notification_service.dart';
import 'package:recipehub_mobile/core/services/mock/mock_auth_service.dart';
import 'package:recipehub_mobile/core/services/mock/mock_training_repository.dart';
import 'package:recipehub_mobile/core/viewmodels/auth_viewmodel.dart';
import 'package:recipehub_mobile/core/viewmodels/training_viewmodel.dart';
import 'package:recipehub_mobile/features/auth/login_page.dart';
import 'package:recipehub_mobile/features/shell/main_app_shell.dart';

import 'support/fake_recipe_source.dart';
import 'support/training_fixtures.dart';

void main() {
  setUpAll(() async {
    final fonts = FontLoader('Inter')
      ..addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf'));
    await fonts.load();
  });
  for (final width in [360.0, 412.0]) {
    for (final scale in [1.0, 1.3]) {
      testWidgets(
        'Viewer/Admin shell ${width.toInt()}px scale $scale with long labels',
        (tester) async {
          tester.view.physicalSize = Size(width, 760);
          tester.view.devicePixelRatio = 1;
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.view.reset);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          final s = AppServices.mock(
            recipes: FakeRecipeSource(),
            notifications: MockNotificationService(
              permission: NotificationPermission.granted,
            ),
            training: MockTrainingRepository(tasks: [testTask()]),
            auth: MockAuthService(
              initialUser: const AppUser(
                uid: 'layout',
                method: AuthMethod.google,
                displayName: 'Nguyễn Thị Minh Anh phụ trách pha chế tại quầy',
                email: 'long.test.account@example.com',
              ),
            ),
          );
          await tester.pumpWidget(RecipeHubApp(services: s));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          for (final tab in ['Việc học', 'Phản hồi', 'Tài khoản', 'Tra cứu']) {
            await tester.tap(find.text(tab).last);
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull, reason: tab);
          }
          final ctx = tester.element(find.byType(MainAppShell));
          await ctx.read<AuthViewModel>().switchRole(UserRole.admin);
          // This test uses a local role fixture; it does not create server admin claims.
          ctx.read<AdminTrainingViewModel>().start();
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          for (final tab in ['Đào tạo', 'Tài khoản', 'Tra cứu']) {
            await tester.tap(find.text(tab).last);
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull, reason: 'Admin $tab');
          }
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
    }
    testWidgets('Login ${width.toInt()}px keyboard and validation', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        RecipeHubApp(services: AppServices.mock(recipes: FakeRecipeSource())),
      );
      await tester.pumpAndSettle();
      expect(find.byType(LoginPage), findsOneWidget);
      expect(tester.takeException(), isNull);
      final email = find.byType(TextFormField).first;
      await tester.tap(email);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
