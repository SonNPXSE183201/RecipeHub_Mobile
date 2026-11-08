import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../interfaces/i_user_profile_service.dart';

/// Gọi callable Cloud Function (tách ra để test thay bằng bản giả).
typedef ProfileCallable = Future<Map<String, dynamic>> Function(String name);

/// Vai trò lấy từ custom claim trong ID token (do Function `ensureProfile` / `setUserRole` đặt).
class FirebaseUserProfileService implements IUserProfileService {
  FirebaseUserProfileService({FirebaseAuth? auth, FirebaseFirestore? firestore, ProfileCallable? call})
    : _auth = auth ?? FirebaseAuth.instance,
      _db = firestore ?? FirebaseFirestore.instance,
      _call = call ?? _defaultCall;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final ProfileCallable _call;

  static Future<Map<String, dynamic>> _defaultCall(String name) async {
    final res = await FirebaseFunctions.instanceFor(region: 'asia-southeast1').httpsCallable(name).call<Object?>();
    final d = res.data;
    return d is Map ? Map<String, dynamic>.from(d) : <String, dynamic>{};
  }

  @override
  Future<ProfileState> sync() async {
    final data = await _call('ensureProfile');
    final role = await currentRole(forceRefresh: data['refreshToken'] == true);
    return ProfileState(role: role, disabled: data['disabled'] == true);
  }

  @override
  Future<String> currentRole({bool forceRefresh = false}) async {
    final user = _auth.currentUser;
    if (user == null) return 'viewer';
    final token = await user.getIdTokenResult(forceRefresh);
    return token.claims?['role'] == 'admin' ? 'admin' : 'viewer';
  }

  /// Bỏ qua snapshot lấy từ cache offline: cache có thể còn `disabled=true` cũ sau khi Admin đã mở khóa,
  /// làm app tự đăng xuất nhầm. Chỉ tin dữ liệu đã xác nhận từ server.
  @override
  Stream<ProfileState> watch(String uid) => _db
      .doc('users/$uid')
      .snapshots(includeMetadataChanges: true)
      .where((s) => s.exists && !s.metadata.isFromCache)
      .map((s) {
        final d = s.data()!;
        final ts = d['claimsUpdatedAt'];
        return ProfileState(
          role: d['role'] == 'admin' ? 'admin' : 'viewer',
          disabled: d['disabled'] == true,
          claimsVersion: ts is Timestamp ? ts.millisecondsSinceEpoch : null,
        );
      });
}
