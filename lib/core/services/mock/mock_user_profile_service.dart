import 'dart:async';

import '../interfaces/i_user_profile_service.dart';

/// Bản giả: vai trò cấu hình sẵn, test đẩy trạng thái qua [emit].
class MockUserProfileService implements IUserProfileService {
  MockUserProfileService({this.role = 'viewer'});

  String role;
  bool disabled = false;
  int syncCalls = 0;
  final StreamController<ProfileState> _ctrl = StreamController<ProfileState>.broadcast();

  void emit(ProfileState s) {
    role = s.role;
    disabled = s.disabled;
    _ctrl.add(s);
  }

  @override
  Future<ProfileState> sync() async {
    syncCalls++;
    return ProfileState(role: role, disabled: disabled);
  }

  @override
  Future<String> currentRole({bool forceRefresh = false}) async => role;

  @override
  Stream<ProfileState> watch(String uid) => _ctrl.stream;
}
