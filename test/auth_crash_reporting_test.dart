import 'package:flutter_test/flutter_test.dart';
import 'package:recipehub_mobile/core/models/session_models.dart';
import 'package:recipehub_mobile/core/services/mock/mock_analytics_service.dart';
import 'package:recipehub_mobile/core/services/mock/mock_auth_service.dart';
import 'package:recipehub_mobile/core/services/mock/mock_crash_reporter.dart';
import 'package:recipehub_mobile/core/viewmodels/auth_viewmodel.dart';

class _FailingAuthService extends MockAuthService {
  _FailingAuthService(this.error);

  final Object error;

  @override
  Future<AppUser> signInWithGoogle() async => throw error;

  @override
  Future<AppUser> signInWithEmail(String email, String password) async =>
      throw error;

  @override
  Future<void> sendPasswordReset(String email) async => throw error;

  @override
  Future<AppUser> signInAsGuest() async => throw error;
}

void main() {
  final flows = <String, Future<bool> Function(AuthViewModel)>{
    'Google': (vm) => vm.signInWithGoogle(),
    'email': (vm) => vm.signInWithEmail('barista@example.vn', 'wrong'),
    'password reset': (vm) => vm.sendPasswordReset('barista@example.vn'),
    'guest': (vm) => vm.continueAsGuest(),
  };
  const expectedFailures = [
    AuthFailureCode.cancelled,
    AuthFailureCode.network,
    AuthFailureCode.disabled,
    AuthFailureCode.invalidCredentials,
    AuthFailureCode.tooManyRequests,
    AuthFailureCode.passwordDisabled,
    AuthFailureCode.weakPassword,
    AuthFailureCode.requiresRecentLogin,
    AuthFailureCode.passwordNotApplicable,
  ];

  for (final flow in flows.entries) {
    group('${flow.key} Crashlytics', () {
      late MockCrashReporter crash;

      AuthViewModel createViewModel(Object error) {
        final vm = AuthViewModel(
          auth: _FailingAuthService(error),
          analytics: MockAnalyticsService(),
          crash: crash,
        );
        addTearDown(vm.dispose);
        return vm;
      }

      setUp(() => crash = MockCrashReporter());

      for (final code in expectedFailures) {
        test('does not report expected $code', () async {
          final failure = AuthFailure(code);
          final vm = createViewModel(failure);

          expect(await flow.value(vm), isFalse);

          expect(crash.recordedErrors, isEmpty);
          expect(vm.errorMessage, failure.userMessage);
          expect(vm.isBusy, isFalse);
        });
      }

      for (final code in [
        AuthFailureCode.configuration,
        AuthFailureCode.unknown,
      ]) {
        test('reports unexpected $code once', () async {
          final failure = AuthFailure(code);
          final vm = createViewModel(failure);

          expect(await flow.value(vm), isFalse);

          expect(crash.recordedErrors, [same(failure)]);
          expect(vm.errorMessage, failure.userMessage);
          expect(vm.isBusy, isFalse);
        });
      }
    });
  }

  // Guest sign-in only handles normalized AuthFailure exceptions.
  for (final name in ['Google', 'email', 'password reset']) {
    test('$name reports an unnormalized exception once', () async {
      final error = StateError('Unexpected authentication error');
      final crash = MockCrashReporter();
      final vm = AuthViewModel(
        auth: _FailingAuthService(error),
        analytics: MockAnalyticsService(),
        crash: crash,
      );
      addTearDown(vm.dispose);

      expect(await flows[name]!(vm), isFalse);

      expect(crash.recordedErrors, [same(error)]);
      expect(
        vm.errorMessage,
        const AuthFailure(AuthFailureCode.unknown).userMessage,
      );
      expect(vm.isBusy, isFalse);
    });
  }
}
