import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:recipehub_mobile/core/models/app_models.dart';
import 'package:recipehub_mobile/core/services/mock/mock_auth_service.dart';
import 'package:recipehub_mobile/core/services/mock/mock_analytics_service.dart';
import 'package:recipehub_mobile/core/services/mock/mock_crash_reporter.dart';
import 'package:recipehub_mobile/core/services/recipe_mapper.dart';
import 'package:recipehub_mobile/core/viewmodels/auth_viewmodel.dart';
import 'package:recipehub_mobile/features/auth/login_page.dart';

import 'support/fake_recipe_source.dart';

void main() {
  testWidgets('M-01: LoginPage hiển thị form đăng nhập + Google', (tester) async {
    final vm = AuthViewModel(
      auth: MockAuthService(),
      analytics: MockAnalyticsService(),
      crash: MockCrashReporter(),
    );
    await tester.pumpWidget(
      ChangeNotifierProvider.value(value: vm, child: const MaterialApp(home: LoginPage())),
    );
    expect(find.text('Tiếp tục với Google'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
  });

  test('RecipeMapper: category suy từ tên, 1 size chuẩn, bước có mốc thời gian', () {
    final item = RecipeMapper.fromDetail(FakeRecipeSource.detail('r9', 'RC-X', 'Cold Brew Cam'));
    expect(item.category, 'Cà phê & Cold Brew');
    expect(item.sizes.single.ingredients.single.unit, 'g');
    expect(item.steps.single.videoEndSeconds, 480);
    expect(item.standardTime, '480 giây');
    expect(item, isA<RecipeItem>());
  });
}
