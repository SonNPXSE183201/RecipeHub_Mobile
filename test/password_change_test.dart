import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:recipehub_mobile/core/models/session_models.dart';
import 'package:recipehub_mobile/core/services/mock/mock_analytics_service.dart';
import 'package:recipehub_mobile/core/services/mock/mock_auth_service.dart';
import 'package:recipehub_mobile/core/services/mock/mock_crash_reporter.dart';
import 'package:recipehub_mobile/core/viewmodels/auth_viewmodel.dart';
import 'package:recipehub_mobile/features/account/change_password_page.dart';

AuthViewModel _vm(MockAuthService service) => AuthViewModel(
  auth: service,
  analytics: MockAnalyticsService(),
  crash: MockCrashReporter(),
);

void main() {
  test('Password changes only after current password is verified', () async {
    final service = MockAuthService();
    final vm = _vm(service);
    addTearDown(vm.dispose);
    await vm.signInWithEmail(
      MockAuthService.validEmail,
      MockAuthService.validPassword,
    );
    expect(
      await vm.changePassword(
        MockAuthService.validPassword,
        'new-pass-123',
        'new-pass-123',
      ),
      isTrue,
    );
    expect(vm.errorMessage, isNull);
    expect(vm.isBusy, isFalse);
    expect(service.passwordChangeCount, 1);
    await service.signOut();
    await expectLater(
      service.signInWithEmail(MockAuthService.validEmail, 'new-pass-123'),
      completes,
    );
  });

  test(
    'Wrong current password gives Vietnamese error and keeps old password',
    () async {
      final service = MockAuthService();
      final vm = _vm(service);
      addTearDown(vm.dispose);
      await vm.signInWithEmail(
        MockAuthService.validEmail,
        MockAuthService.validPassword,
      );
      expect(
        await vm.changePassword('wrong', 'new-pass-123', 'new-pass-123'),
        isFalse,
      );
      expect(
        vm.errorMessage,
        'Mật khẩu hiện tại không đúng. Vui lòng thử lại.',
      );
      expect(vm.isBusy, isFalse);
      await expectLater(
        service.signInWithEmail(
          MockAuthService.validEmail,
          MockAuthService.validPassword,
        ),
        completes,
      );
    },
  );

  for (final guest in [false, true]) {
    test(
      'Google/guest cannot change RecipeHub password (guest: $guest)',
      () async {
        final service = MockAuthService();
        final vm = _vm(service);
        addTearDown(vm.dispose);
        if (guest) {
          await vm.continueAsGuest();
        } else {
          await vm.signInWithGoogle();
        }
        expect(
          await vm.changePassword('old', 'new-pass-123', 'new-pass-123'),
          isFalse,
        );
        expect(
          vm.errorMessage,
          'Tài khoản đăng nhập bằng Google không dùng mật khẩu RecipeHub',
        );
        expect(service.passwordChangeCount, 0);
      },
    );
  }

  test('Short or mismatched new password never reaches service', () async {
    final service = MockAuthService();
    final vm = _vm(service);
    addTearDown(vm.dispose);
    await vm.signInWithEmail(
      MockAuthService.validEmail,
      MockAuthService.validPassword,
    );
    expect(await vm.changePassword('123456', 'short', 'short'), isFalse);
    expect(vm.errorMessage, 'Mật khẩu mới phải có ít nhất 8 ký tự.');
    expect(
      await vm.changePassword('123456', 'new-pass-123', 'different'),
      isFalse,
    );
    expect(vm.errorMessage, 'Mật khẩu nhập lại chưa khớp.');
    expect(service.passwordChangeCount, 0);
  });

  for (final code in [
    AuthFailureCode.network,
    AuthFailureCode.weakPassword,
    AuthFailureCode.requiresRecentLogin,
  ]) {
    test('Password failure $code is localized', () async {
      final service = MockAuthService()
        ..nextPasswordFailure = AuthFailure(code);
      final vm = _vm(service);
      addTearDown(vm.dispose);
      await vm.signInWithEmail(
        MockAuthService.validEmail,
        MockAuthService.validPassword,
      );
      expect(
        await vm.changePassword('123456', 'new-pass-123', 'new-pass-123'),
        isFalse,
      );
      expect(vm.errorMessage, AuthFailure(code).userMessage);
      expect(vm.isBusy, isFalse);
    });
  }

  testWidgets('Email password form changes password and sends reset email', (
    tester,
  ) async {
    final service = MockAuthService();
    final vm = _vm(service);
    addTearDown(vm.dispose);
    await vm.signInWithEmail(
      MockAuthService.validEmail,
      MockAuthService.validPassword,
    );
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: vm,
        child: const MaterialApp(home: ChangePasswordPage()),
      ),
    );
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '123456');
    await tester.enterText(fields.at(1), 'new-pass-123');
    await tester.enterText(fields.at(2), 'new-pass-123');
    await tester.ensureVisible(find.byType(ElevatedButton));
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
    expect(find.text('Đã đổi mật khẩu thành công.'), findsOneWidget);
    await tester.ensureVisible(find.text('Gửi email đặt lại mật khẩu'));
    await tester.tap(find.text('Gửi email đặt lại mật khẩu'));
    await tester.pumpAndSettle();
    expect(service.resetRequests, [MockAuthService.validEmail]);
  });
}
