import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipehub_mobile/app.dart';
import 'package:recipehub_mobile/core/di/app_services.dart';
import 'package:recipehub_mobile/core/models/app_models.dart';
import 'package:recipehub_mobile/core/models/session_models.dart';
import 'package:recipehub_mobile/core/services/mock/mock_auth_service.dart';
import 'package:recipehub_mobile/features/practice/self_practice_timer_page.dart';
import 'package:recipehub_mobile/features/shell/main_app_shell.dart';

import 'support/fake_recipe_source.dart';

void main() {
  testWidgets(
    '360px: long ingredient keeps quantity visible without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(360, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final services = AppServices.mock(
        recipes: FakeRecipeSource(),
        auth: MockAuthService(
          initialUser: const AppUser(uid: 'u', method: AuthMethod.google),
        ),
      );
      await tester.pumpWidget(RecipeHubApp(services: services));
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(MainAppShell));
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const SelfPracticeTimerPage(
            initialRecipe: RecipeItem(
              id: 'r1',
              code: 'PRIVATE-CODE',
              name: 'Món có tên rất dài để kiểm tra giao diện',
              category: 'Cà phê',
              version: 'v1',
              status: 'Ban hành',
              publishedDate: '',
              publisher: '',
              description: '',
              standardTime: '28 giây',
              standardTemp: '',
              videoUrl: '',
              steps: [],
              sizes: [
                RecipeSizeOption(
                  sizeCode: 'M',
                  label: 'Định lượng chuẩn',
                  servingNotes: '',
                  ingredients: [
                    IngredientPortion(
                      name: 'Cà phê bột Espresso 1 (70% Arabica Brazil + 30% Robusta Việt Nam)',
                      amount: 18,
                      unit: 'g',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Xem lại công thức'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('18 g'));
      expect(tester.getRect(find.text('18 g')).right, lessThanOrEqualTo(360));
      expect(find.text('PRIVATE-CODE'), findsNothing);
    },
  );
}
