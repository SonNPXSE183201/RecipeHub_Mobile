/// Hồ sơ người dùng phía server: vai trò (custom claim do Cloud Functions đặt) và trạng thái khóa.
abstract class IUserProfileService {
  /// Gọi callable `ensureProfile` (tạo hồ sơ nếu thiếu, đồng bộ claim), làm mới ID token khi cần,
  /// rồi trả vai trò đọc từ claim.
  Future<ProfileState> sync();

  /// Đọc lại vai trò từ ID token (forceRefresh = lấy token mới có claim mới).
  Future<String> currentRole({bool forceRefresh = false});

  /// Nghe `users/{uid}`: bị khóa, hoặc vai trò vừa đổi (claimsUpdatedAt).
  Stream<ProfileState> watch(String uid);
}

class ProfileState {
  const ProfileState({required this.role, required this.disabled, this.claimsVersion});

  /// 'viewer' | 'admin'.
  final String role;
  final bool disabled;

  /// Thời điểm claim đổi gần nhất (millis) – đổi giá trị nghĩa là cần làm mới token.
  final int? claimsVersion;

  bool get isAdmin => role == 'admin';
}
