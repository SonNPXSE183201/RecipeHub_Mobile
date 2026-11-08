import '../../models/session_models.dart';

/// Firebase Authentication boundary (Google Sign-In + Guest/Anonymous).
abstract class IAuthService {
  /// Phát `AppUser` khi đăng nhập, `null` khi đăng xuất (authStateChanges).
  Stream<AppUser?> authStateChanges();

  AppUser? get currentUser;

  /// Đăng nhập Google → Firebase credential.
  /// Throws [AuthFailure] (cancelled / network / configuration / unknown).
  Future<AppUser> signInWithGoogle();

  /// Đăng nhập email + mật khẩu (tài khoản do Admin cấp trên web).
  /// Throws [AuthFailure] (invalidCredentials / tooManyRequests / network / disabled / passwordDisabled).
  Future<AppUser> signInWithEmail(String email, String password);

  /// Gửi thư đặt lại mật khẩu. Không tiết lộ email có tồn tại hay không
  /// (user-not-found được nuốt). Throws [AuthFailure] khi mạng/giới hạn lỗi.
  Future<void> sendPasswordReset(String email);

  /// Xác thực lại mật khẩu hiện tại trước khi cập nhật mật khẩu email.
  Future<void> changePassword(String currentPassword, String newPassword);

  /// Tiếp tục với vai trò Khách (Firebase Anonymous Auth).
  Future<AppUser> signInAsGuest();

  /// Đăng xuất Firebase + Google, xóa phiên cục bộ.
  Future<void> signOut();
}
