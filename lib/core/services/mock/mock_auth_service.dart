import 'dart:async';

import '../../models/session_models.dart';
import '../interfaces/i_auth_service.dart';

/// Auth giả lập cho test / offline demo. Không gọi mạng.
class MockAuthService implements IAuthService {
  MockAuthService({this.nextGoogleFailure, AppUser? initialUser}) : _user = initialUser;

  /// Đặt trước lỗi cho lần `signInWithGoogle()` kế tiếp (vd cancelled) – dùng trong TC.
  AuthFailure? nextGoogleFailure;

  AppUser? _user;
  final StreamController<AppUser?> _controller = StreamController<AppUser?>.broadcast();
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
