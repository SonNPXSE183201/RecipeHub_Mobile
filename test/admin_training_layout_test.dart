import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:recipehub_mobile/core/di/app_services.dart';
import 'package:recipehub_mobile/core/models/training_models.dart';
import 'package:recipehub_mobile/core/services/mock/mock_training_repository.dart';
import 'package:recipehub_mobile/core/viewmodels/auth_viewmodel.dart';
import 'package:recipehub_mobile/core/viewmodels/training_viewmodel.dart';
import 'package:recipehub_mobile/features/admin_training/admin_store_training_page.dart';

import 'support/fake_recipe_source.dart';

void main() {
  for (final width in [360.0, 412.0]) {
    testWidgets(
      'Admin training fits ${width.toInt()}px with long staff labels',
      (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        const name = 'Nguyễn Thị Minh Anh nhân viên phụ trách pha chế tại quầy';
        final repo = MockTrainingRepository(
          staff: const [
            StaffMember(
              uid: 'staff-layout-test',
              displayName: name,
              email: 'staff@example.com',
              storeBranch: 'Chi nhánh Thành phố Hồ Chí Minh khu vực phía Đông',
              title: 'Barista phụ trách tiêu chuẩn pha chế và đào tạo tại quầy',
            ),
          ],
        );
        final services = AppServices.mock(
          recipes: FakeRecipeSource(),
          training: repo,
        );
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider(
                create: (_) => AuthViewModel(
                  auth: services.auth,
                  analytics: services.analytics,
                  crash: services.crash,
                ),
              ),
              ChangeNotifierProvider(
                create: (_) => AdminTrainingViewModel(
                  repo: services.training,
                  crash: services.crash,
                )..start(),
              ),
            ],
            child: const MaterialApp(home: AdminStoreTrainingPage()),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.scrollUntilVisible(find.text(name), 200);
        await tester.pumpAndSettle();
        expect(find.text(name), findsOneWidget);
        expect(find.text('0% đã học'), findsOneWidget);
        expect(find.text('Thực hành: Chưa đánh giá'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
