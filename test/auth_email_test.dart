import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:recipehub_mobile/core/models/session_models.dart';
import 'package:recipehub_mobile/core/navigation/app_keys.dart';
import 'package:recipehub_mobile/core/services/firebase/firebase_auth_service.dart';
import 'package:recipehub_mobile/core/services/mock/mock_analytics_service.dart';
import 'package:recipehub_mobile/core/services/mock/mock_auth_service.dart';
import 'package:recipehub_mobile/core/services/mock/mock_crash_reporter.dart';
import 'package:recipehub_mobile/core/services/mock/mock_user_profile_service.dart';
import 'package:recipehub_mobile/core/viewmodels/auth_viewmodel.dart';
import 'package:recipehub_mobile/features/auth/login_page.dart';

class _FailingFirebaseAuth extends MockFirebaseAuth {
  _FailingFirebaseAuth(this.code);
  final String code;

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async => throw FirebaseAuthException(code: code);

  @override
  Future<void> sendPasswordResetEmail({
    required String email,
    ActionCodeSettings? actionCodeSettings,
  }) async => throw FirebaseAuthException(code: code);
}

class _HeldAuth extends MockAuthService {
  final emailGate = Completer<void>();
  final googleGate = Completer<void>();
  final resetGate = Completer<void>();
  int googleCalls = 0;

  @override
  Future<AppUser> signInWithEmail(String email, String password) async {
    await emailGate.future;
    return super.signInWithEmail(email, password);
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    googleCalls++;
    await googleGate.future;
    return super.signInWithGoogle();
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    await resetGate.future;
    return super.sendPasswordReset(email);
  }
}

AuthViewModel _vm(
  MockAuthService auth, {
  MockAnalyticsService? analytics,
  MockUserProfileService? profile,
}) => AuthViewModel(
  auth: auth,
  analytics: analytics ?? MockAnalyticsService(),
  crash: MockCrashReporter(),
  profile: profile,
);

Future<void> _page(WidgetTester tester, AuthViewModel vm) async {
  tester.view.physicalSize = const Size(430, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: vm,
      child: const MaterialApp(home: LoginPage()),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final code in [
    'invalid-credential',
    'wrong-password',
    'user-not-found',
    'invalid-email',
  ]) {
    test('Firebase $code maps to neutral credential error', () async {
      final service = FirebaseAuthService(auth: _FailingFirebaseAuth(code));
      await expectLater(
        service.signInWithEmail('a@b.vn', 'wrong'),
        throwsA(
          isA<AuthFailure>().having(
            (e) => e.userMessage,
            'message',
            'Email hoặc mật khẩu không đúng.',
          ),
        ),
      );
    });
  }

  for (final code in ['user-not-found', 'invalid-email']) {
    test('Firebase password reset hides $code', () async {
      final service = FirebaseAuthService(auth: _FailingFirebaseAuth(code));
      await service.sendPasswordReset('a@b.vn');
    });
  }

  test('Email login syncs profile and logs password without email', () async {
    final analytics = MockAnalyticsService();
    final profile = MockUserProfileService(role: 'admin');
    final vm = _vm(MockAuthService(), analytics: analytics, profile: profile);
    addTearDown(vm.dispose);
    expect(
      await vm.signInWithEmail(
        MockAuthService.validEmail,
        MockAuthService.validPassword,
      ),
      isTrue,
    );
    expect(profile.syncCalls, 1);
    expect(vm.isAdmin, isTrue);
    expect(vm.status, AuthStatus.authenticated);
    final login = analytics.loggedEvents.singleWhere((e) => e.name == 'login');
    expect(login.parameters['method'], 'password');
    expect(login.parameters.containsKey('email'), isFalse);
  });

  for (final code in [
    AuthFailureCode.invalidCredentials,
    AuthFailureCode.tooManyRequests,
    AuthFailureCode.network,
    AuthFailureCode.disabled,
    AuthFailureCode.passwordDisabled,
  ]) {
    test('Email failure $code has localized message', () async {
      final service = MockAuthService()..nextEmailFailure = AuthFailure(code);
      final vm = _vm(service);
      addTearDown(vm.dispose);
      expect(await vm.signInWithEmail('a@b.vn', 'bad'), isFalse);
      expect(vm.errorMessage, AuthFailure(code).userMessage);
      expect(vm.isBusy, isFalse);
    });
  }

  test(
    'Password reset excludes all login flows and clears previous error',
    () async {
      final service = _HeldAuth();
      final vm = _vm(service);
      addTearDown(vm.dispose);
      final reset = vm.sendPasswordReset(' someone@recipehub.vn ');
      expect(vm.isResetBusy, isTrue);
      expect(await vm.signInWithGoogle(), isFalse);
      expect(await vm.signInWithEmail('a@b.vn', 'x'), isFalse);
      expect(await vm.continueAsGuest(), isFalse);
      service.resetGate.complete();
      expect(await reset, isTrue);
      expect(service.resetRequests, ['someone@recipehub.vn']);
      expect(vm.isBusy, isFalse);
    },
  );

  testWidgets(
    'Email button alone loads, Google and guest disabled, Enter submits',
    (tester) async {
      final service = _HeldAuth();
      final vm = _vm(service);
      addTearDown(vm.dispose);
      await _page(tester, vm);
      await tester.enterText(
        find.byKey(AppKeys.loginEmail),
        MockAuthService.validEmail,
      );
      await tester.enterText(
        find.byKey(AppKeys.loginPassword),
        MockAuthService.validPassword,
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(vm.isEmailBusy, isTrue);
      expect(vm.isGoogleBusy, isFalse);
      expect(
        tester
            .widget<OutlinedButton>(find.byKey(AppKeys.googleSignIn))
            .onPressed,
        isNull,
      );
      expect(
        tester.widget<TextButton>(find.byKey(AppKeys.guestSignIn)).onPressed,
        isNull,
      );
      expect(
        find.descendant(
          of: find.byKey(AppKeys.loginSubmit),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(AppKeys.googleSignIn),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsNothing,
      );
      expect(service.googleCalls, 0);
      service.emailGate.complete();
      await tester.pumpAndSettle();
    },
  );

  testWidgets('Google alone loads and excludes password login', (tester) async {
    final service = _HeldAuth();
    final vm = _vm(service);
    addTearDown(vm.dispose);
    await _page(tester, vm);
    await tester.ensureVisible(find.byKey(AppKeys.googleSignIn));
    await tester.tap(find.byKey(AppKeys.googleSignIn));
    await tester.pump();
    expect(vm.isGoogleBusy, isTrue);
    expect(vm.isEmailBusy, isFalse);
    expect(
      tester.widget<ElevatedButton>(find.byKey(AppKeys.loginSubmit)).onPressed,
      isNull,
    );
    expect(
      find.descendant(
        of: find.byKey(AppKeys.loginSubmit),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsNothing,
    );
    service.googleGate.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('Password error appears in Vietnamese', (tester) async {
    final vm = _vm(MockAuthService());
    addTearDown(vm.dispose);
    await _page(tester, vm);
    await tester.enterText(
      find.byKey(AppKeys.loginEmail),
      MockAuthService.validEmail,
    );
    await tester.enterText(find.byKey(AppKeys.loginPassword), 'wrong');
    await tester.ensureVisible(find.byKey(AppKeys.loginSubmit));
    await tester.tap(find.byKey(AppKeys.loginSubmit));
    await tester.pumpAndSettle();
    expect(find.text('Email hoặc mật khẩu không đúng.'), findsOneWidget);
  });

  for (final fails in [false, true]) {
    testWidgets('Forgot password keeps neutral message (failure: $fails)', (
      tester,
    ) async {
      final service = MockAuthService();
      if (fails) {
        service.nextResetFailure = const AuthFailure(AuthFailureCode.network);
      }
      final vm = _vm(service);
      addTearDown(vm.dispose);
      await _page(tester, vm);
      await tester.ensureVisible(find.byKey(AppKeys.loginForgot));
      await tester.tap(find.byKey(AppKeys.loginForgot));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(AppKeys.forgotEmail),
        'someone@recipehub.vn',
      );
      await tester.tap(find.byKey(AppKeys.forgotSubmit));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Nếu email đã được cấp tài khoản, bạn sẽ nhận thư đặt lại mật khẩu.',
        ),
        findsWidgets,
      );
      if (!fails) expect(service.resetRequests, ['someone@recipehub.vn']);
    });
  }
}
