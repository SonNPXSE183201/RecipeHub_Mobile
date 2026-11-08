import 'dart:async';

import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../models/app_models.dart';
import '../models/session_models.dart';
import '../services/interfaces/i_analytics_service.dart';
import '../services/interfaces/i_auth_service.dart';
import '../services/interfaces/i_crash_reporter.dart';
import '../services/interfaces/i_incident_reporter.dart';
import '../services/interfaces/i_user_profile_service.dart';

enum AuthStatus { unknown, unauthenticated, authenticated }

/// Quản lý phiên đăng nhập + phân quyền 2 vai trò (Barista Viewer / Store Admin).
///
/// Vai trò thật do server cấp (custom claim `role`, đọc qua [IUserProfileService]); người dùng chỉ
/// được chọn "xem như Barista" khi là Admin, không tự nâng quyền. Admin khóa tài khoản → đăng xuất ngay.
class AuthViewModel extends ChangeNotifier {
  AuthViewModel({
    required this._auth,
    required this._analytics,
    required this._crash,
    this._profile,
    this._incidents,
  });

  final IAuthService _auth;
  final IAnalyticsService _analytics;
  final ICrashReporter _crash;
  final IUserProfileService? _profile;
  final IIncidentReporter? _incidents;
  StreamSubscription<ProfileState>? _profileSub;
  final List<Future<void> Function()> _beforeSignOut = [];
  UserRole _serverRole = UserRole.viewer;
  String? _syncedUid;
  Future<void>? _syncFuture;
  bool _signingOut = false;
  int? _claimsVersion;

  /// Thời gian tối đa chờ mỗi hook trước khi đăng xuất (offline: Firestore không bao giờ xác nhận).
  static const Duration hookTimeout = Duration(seconds: 3);
  String? _notice;

  StreamSubscription<AppUser?>? _sub;
  AuthStatus _status = AuthStatus.unknown;
  AppUser? _user;
  UserRole _role = UserRole.viewer;
  UserRole _selectedRole = UserRole.viewer;
  bool _googleBusy = false;
  bool _guestBusy = false;
  String? _errorMessage;
  AuthFailureCode? _lastFailure;
  DateTime? _sessionStart;
  bool _disposed = false;

  AuthStatus get status => _status;
  AppUser? get user => _user;
  UserRole get role => _role;
  UserRole get selectedRole => _selectedRole;
  bool get isAdmin => _role == UserRole.admin;
  bool get isGuest => _user?.isGuest ?? false;
  bool get isGoogleBusy => _googleBusy;
  bool get isGuestBusy => _guestBusy;
  bool get isBusy => _googleBusy || _guestBusy;
  String? get errorMessage => _errorMessage;
  AuthFailureCode? get lastFailure => _lastFailure;
  String get roleCode => _role == UserRole.admin ? 'admin' : 'viewer';

  /// Vai trò server cấp (claim). Khác [role] khi Admin đang "xem như Barista".
  UserRole get serverRole => _serverRole;

  /// Thông báo nhẹ (không phải lỗi), ví dụ chọn Admin nhưng tài khoản chưa được cấp quyền.
  String? get notice => _notice;

  /// Việc cần làm khi còn đăng nhập, ngay trước khi đăng xuất (vd. xóa FCM token trên server).
  void addBeforeSignOut(Future<void> Function() hook) => _beforeSignOut.add(hook);

  void clearNotice() {
    _notice = null;
    _notify();
  }
  String get storeBranch => AppConfig.storeBranch;

  String get displayName {
    if (_user == null) return '';
    if (_user!.isGuest) return 'Barista khách';
    final n = _user!.displayName;
    return (n == null || n.isEmpty) ? 'Barista RecipeHub' : n;
  }

  String get roleLabel => _role == UserRole.admin ? 'Store Admin' : 'Barista';

  /// Lắng nghe authStateChanges – điều hướng Splash → Login/Shell.
  /// Người dùng hủy hoặc mất mạng là tình huống dự kiến (đã báo bằng thông điệp) — không ghi Crashlytics.
  static bool _isUnexpected(AuthFailure f) =>
      f.code != AuthFailureCode.cancelled && f.code != AuthFailureCode.network;

  void start() {
    _sub ??= _auth.authStateChanges().listen(
      _onAuthState,
      onError: (Object e, StackTrace s) {
        _crash.recordError(e, s, reason: 'auth_state_stream');
        _status = AuthStatus.unauthenticated;
        _notify();
      },
    );
  }

  void _onAuthState(AppUser? user) {
    if (user == null) {
      // SDK tự đăng xuất (token bị thu hồi khi Admin khóa, user bị xóa…): dọn phiên như signOut.
      _clearSession();
      _status = AuthStatus.unauthenticated;
      _notify();
      return;
    }
    if (_user?.uid != user.uid) _clearSession();
    _user = user;
    _sessionStart ??= DateTime.now();
    _incidents?.setUser(uid: user.uid, email: user.email);
    unawaited(_tagCrashReports(user));
    if (_profile == null) {
      _role = user.isGuest ? UserRole.viewer : _selectedRole;
      _status = AuthStatus.authenticated;
      _notify();
      return;
    }
    // Chưa vào màn chính cho tới khi server xác nhận vai trò + chưa bị khóa.
    if (_status != AuthStatus.authenticated) _status = AuthStatus.unknown;
    _notify();
    unawaited(_ensureSynced(user).then((_) {
      if (_user?.uid != user.uid || _signingOut) return;
      _status = AuthStatus.authenticated;
      _notify();
    }));
  }

  /// Crashlytics gắn uid + custom key cả khi phiên được khôi phục (mở lại app), không chỉ lúc đăng nhập.
  Future<void> _tagCrashReports(AppUser user) async {
    try {
      await _crash.setUserIdentifier(user.uid);
      await _crash.setCustomKey('store_code', AppConfig.storeCode);
      await _crash.setCustomKey('auth_mode', user.isGuest ? 'guest' : 'google');
    } catch (_) {}
  }

  /// Một lần đồng bộ cho mỗi uid; mọi nơi (authStateChanges, signInWithGoogle) chờ CÙNG Future.
  Future<void> _ensureSynced(AppUser user) {
    if (_syncedUid == user.uid && _syncFuture != null) return _syncFuture!;
    _syncedUid = user.uid;
    return _syncFuture = _syncProfile(user);
  }

  /// Lấy vai trò + trạng thái khóa từ server, rồi nghe thay đổi.
  Future<void> _syncProfile(AppUser user) async {
    final profile = _profile;
    if (profile == null) return;
    ProfileState state;
    try {
      state = await profile.sync();
    } catch (e, s) {
      // Function lỗi / mất mạng: dùng claim đang có trong token.
      await _crash.recordError(e, s, reason: 'profile_sync');
      var role = 'viewer';
      try {
        role = await profile.currentRole();
      } catch (_) {}
      state = ProfileState(role: role, disabled: false);
    }
    if (_user?.uid != user.uid) return;
    if (state.disabled) {
      await _forceSignOutDisabled();
      return;
    }
    _applyServerRole(state.role == 'admin' ? UserRole.admin : UserRole.viewer, fromLogin: true);
    await _profileSub?.cancel();
    _profileSub = profile.watch(user.uid).listen(
      (s) => _onProfileChanged(s).catchError((Object e, StackTrace st) {
        _crash.recordError(e, st, reason: 'profile_changed');
      }),
      onError: (Object e, StackTrace s) {
        _crash.recordError(e, s, reason: 'profile_watch');
      },
    );
  }

  Future<void> _onProfileChanged(ProfileState s) async {
    if (_signingOut || _user == null) return;
    if (s.disabled) {
      await _forceSignOutDisabled();
      return;
    }
    final changed = s.claimsVersion != null && _claimsVersion != null && s.claimsVersion != _claimsVersion;
    _claimsVersion = s.claimsVersion ?? _claimsVersion;
    if (changed) {
      String role;
      try {
        role = await _profile!.currentRole(forceRefresh: true);
      } catch (e, st) {
        // Offline / token bị thu hồi: dùng vai trò Firestore vừa nhận.
        await _crash.recordError(e, st, reason: 'profile_refresh_token');
        role = s.role;
      }
      _applyServerRole(role == 'admin' ? UserRole.admin : UserRole.viewer, fromLogin: false);
    }
  }

  void _applyServerRole(UserRole serverRole, {required bool fromLogin}) {
    _serverRole = serverRole;
    if (serverRole == UserRole.admin) {
      // Vai trò theo server; Admin có thể tự chuyển sang xem như Barista ở màn Tài khoản.
      _role = UserRole.admin;
    } else {
      if (fromLogin && _selectedRole == UserRole.admin) {
        _notice = 'Tài khoản chưa được cấp quyền Admin – đang dùng vai trò Barista.';
      }
      _role = UserRole.viewer;
    }
    _notify();
    unawaited(_analytics.setUserProperty('user_role', roleCode));
    unawaited(_crash.setCustomKey('user_role', roleCode));
  }

  Future<void> _forceSignOutDisabled() async {
    if (_signingOut) return;
    await signOut();
    _lastFailure = AuthFailureCode.disabled;
    _errorMessage = const AuthFailure(AuthFailureCode.disabled).userMessage;
    _notice = _errorMessage; // AuthGate hiện SnackBar ở màn đăng nhập
    _notify();
  }

  void selectRole(UserRole role) {
    _selectedRole = role;
    _notify();
  }

  void clearError() {
    _errorMessage = null;
    _lastFailure = null;
    _notify();
  }

  Future<bool> signInWithGoogle() async {
    if (isBusy) return false;
    _googleBusy = true;
    _errorMessage = null;
    _lastFailure = null;
    _notify();
    try {
      final user = await _auth.signInWithGoogle();
      await _onSignedIn(user, 'google');
      return true;
    } on AuthFailure catch (f, s) {
      _lastFailure = f.code;
      _errorMessage = f.userMessage;
      if (_isUnexpected(f)) {
        await _crash.recordError(f, s, reason: 'auth_google');
      }
      return false;
    } catch (e, s) {
      _lastFailure = AuthFailureCode.unknown;
      _errorMessage = const AuthFailure(AuthFailureCode.unknown).userMessage;
      await _crash.recordError(e, s, reason: 'auth_google_unexpected');
      return false;
    } finally {
      _googleBusy = false;
      _notify();
    }
  }

  Future<bool> continueAsGuest() async {
    if (isBusy) return false;
    _guestBusy = true;
    _errorMessage = null;
    _notify();
    try {
      final user = await _auth.signInAsGuest();
      await _onSignedIn(user, 'guest');
      return true;
    } on AuthFailure catch (f, s) {
      _lastFailure = f.code;
      _errorMessage = f.userMessage;
      if (_isUnexpected(f)) await _crash.recordError(f, s, reason: 'auth_guest');
      return false;
    } finally {
      _guestBusy = false;
      _notify();
    }
  }

  Future<void> _onSignedIn(AppUser user, String method) async {
    _user = user;
    _role = _profile == null ? (user.isGuest ? UserRole.viewer : _selectedRole) : _serverRole;
    _incidents?.setUser(uid: user.uid, email: user.email);
    await _ensureSynced(user);
    if (_user?.uid != user.uid) return; // bị khóa → đã đăng xuất trong lúc đồng bộ
    _status = AuthStatus.authenticated;
    _sessionStart = DateTime.now();
    _notify();
    await _analytics.setUserId(user.uid);
    await _analytics.setUserProperty('user_role', roleCode);
    await _analytics.setUserProperty('auth_mode', method);
    await _analytics.setUserProperty('store_code', AppConfig.storeCode);
    await _analytics.logLogin(method: method, role: roleCode);
    await _crash.setUserIdentifier(user.uid);
    await _crash.setCustomKey('user_role', roleCode);
    await _crash.setCustomKey('store_code', AppConfig.storeCode);
    await _crash.setCustomKey('auth_mode', method);
  }

  /// Đổi vai trò trong phiên (demo 2 role). Khách không được làm Admin.
  Future<bool> switchRole(UserRole role) async {
    if (role == UserRole.admin && isGuest) {
      _errorMessage = 'Tài khoản khách chỉ có quyền Barista. Đăng nhập Google để dùng vai trò Admin.';
      _notify();
      return false;
    }
    if (role == UserRole.admin && _profile != null && _serverRole != UserRole.admin) {
      _errorMessage = 'Tài khoản chưa được Admin cấp quyền quản lý.';
      _notify();
      return false;
    }
    _role = role;
    _selectedRole = role;
    _notify();
    await _analytics.setUserProperty('user_role', roleCode);
    await _crash.setCustomKey('user_role', roleCode);
    return true;
  }

  Future<void> signOut() async {
    if (_signingOut) return; // bấm đúp / snapshot "bị khóa" tới 2 lần
    _signingOut = true;
    try {
      final minutes = _sessionStart == null ? 0 : DateTime.now().difference(_sessionStart!).inMinutes;
      await _analytics.logLogout(role: roleCode, sessionMinutes: minutes);
      for (final hook in List.of(_beforeSignOut)) {
        try {
          await hook().timeout(hookTimeout);
        } catch (e, s) {
          await _crash.recordError(e, s, reason: 'before_sign_out');
        }
      }
      _clearSession();
      try {
        await _auth.signOut();
      } catch (e, s) {
        await _crash.recordError(e, s, reason: 'auth_sign_out');
      }
      await _analytics.setUserId(null);
      await _crash.setUserIdentifier(null);
      _selectedRole = UserRole.viewer;
      _status = AuthStatus.unauthenticated;
      _notify();
    } finally {
      _signingOut = false;
    }
  }

  void _clearSession() {
    _profileSub?.cancel();
    _profileSub = null;
    _syncedUid = null;
    _syncFuture = null;
    _claimsVersion = null;
    _serverRole = UserRole.viewer;
    _incidents?.setUser();
    _user = null;
    _role = UserRole.viewer;
    _sessionStart = null;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _sub?.cancel();
    _profileSub?.cancel();
    super.dispose();
  }
}
