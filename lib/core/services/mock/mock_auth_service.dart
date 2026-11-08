import 'dart:async';

import '../../models/session_models.dart';
import '../interfaces/i_auth_service.dart';

/// Auth giả lập cho test / offline demo. Không gọi mạng.
class MockAuthService implements IAuthService {
  MockAuthService({this.nextGoogleFailure, AppUser? initialUser})
    : _user = initialUser;

  /// Đặt trước lỗi cho lần `signInWithGoogle()` kế tiếp (vd cancelled) – dùng trong TC.
  AuthFailure? nextGoogleFailure;

  /// Lỗi đặt trước cho lần đăng nhập email / gửi thư đặt lại kế tiếp.
  AuthFailure? nextEmailFailure;
  AuthFailure? nextResetFailure;
  AuthFailure? nextPasswordFailure;
  int passwordChangeCount = 0;
  String _password = validPassword;

  /// Tài khoản mock hợp lệ cho đăng nhập email.
  static const String validEmail = 'barista@recipehub.vn';
  static const String validPassword = '123456';
  final List<String> resetRequests = [];
  int emailSignInCount = 0;

  AppUser? _user;
  final StreamController<AppUser?> _controller =
      StreamController<AppUser?>.broadcast();
  int signOutCount = 0;

  @override
  Stream<AppUser?> authStateChanges() async* {
    yield _user;
    yield* _controller.stream;
  }

  @override
  AppUser? get currentUser => _user;

  @override
  Future<AppUser> signInWithGoogle() async {
    final failure = nextGoogleFailure;
    if (failure != null) {
      nextGoogleFailure = null;
      throw failure;
    }
    _user = const AppUser(
      uid: 'mock-google-uid-001',
      method: AuthMethod.google,
      displayName: 'Nguyễn Văn Tuấn',
      email: 'tuan.barista@recipehub.vn',
    );
    _controller.add(_user);
    return _user!;
  }

  @override
  Future<AppUser> signInWithEmail(String email, String password) async {
    emailSignInCount++;
    final failure = nextEmailFailure;
    if (failure != null) {
      nextEmailFailure = null;
      throw failure;
    }
    if (email.trim().toLowerCase() != validEmail || password != _password) {
      throw const AuthFailure(AuthFailureCode.invalidCredentials);
    }
    _user = const AppUser(
      uid: 'mock-email-uid-001',
      method: AuthMethod.password,
      displayName: 'Barista RecipeHub',
      email: validEmail,
    );
    _controller.add(_user);
    return _user!;
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    final failure = nextResetFailure;
    if (failure != null) {
      nextResetFailure = null;
      throw failure;
    }
    resetRequests.add(email.trim());
  }

  @override
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    passwordChangeCount++;
    if (_user == null) {
      throw const AuthFailure(AuthFailureCode.requiresRecentLogin);
    }
    if (_user!.method != AuthMethod.password) {
      throw const AuthFailure(AuthFailureCode.passwordNotApplicable);
    }
    final failure = nextPasswordFailure;
    nextPasswordFailure = null;
    if (failure != null) throw failure;
    if (currentPassword != _password) {
      throw const AuthFailure(AuthFailureCode.invalidCredentials);
    }
    if (newPassword.length < 8) {
      throw const AuthFailure(AuthFailureCode.weakPassword);
    }
    _password = newPassword;
  }

  @override
  Future<AppUser> signInAsGuest() async {
    _user = const AppUser(uid: 'mock-guest-uid-001', method: AuthMethod.guest);
    _controller.add(_user);
    return _user!;
  }

  @override
  Future<void> signOut() async {
    signOutCount++;
    _user = null;
    _controller.add(null);
  }
}
