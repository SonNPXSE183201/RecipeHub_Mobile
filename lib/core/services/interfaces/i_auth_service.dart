import '../../models/session_models.dart';

/// Firebase Authentication boundary (Google Sign-In + Guest/Anonymous).
abstract class IAuthService {
  /// Phát `AppUser` khi đăng nhập, `null` khi đăng xuất (authStateChanges).
  Stream<AppUser?> authStateChanges();

  AppUser? get currentUser;

  /// Đăng nhập Google → Firebase credential.
  /// Throws [AuthFailure] (cancelled / network / configuration / unknown).
  Future<AppUser> signInWithGoogle();

  /// Tiếp tục với vai trò Khách (Firebase Anonymous Auth).
  Future<AppUser> signInAsGuest();

  /// Đăng xuất Firebase + Google, xóa phiên cục bộ.
  Future<void> signOut();
}
