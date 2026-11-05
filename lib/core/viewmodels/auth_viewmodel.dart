import 'dart:async';

import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../models/app_models.dart';
import '../models/session_models.dart';
import '../services/interfaces/i_analytics_service.dart';
import '../services/interfaces/i_auth_service.dart';
import '../services/interfaces/i_crash_reporter.dart';

enum AuthStatus { unknown, unauthenticated, authenticated }

/// Quản lý phiên đăng nhập + phân quyền 2 vai trò (Barista Viewer / Store Admin).
class AuthViewModel extends ChangeNotifier {
  AuthViewModel({
    required this._auth,
    required this._analytics,
    required this._crash,
  });

  final IAuthService _auth;
  final IAnalyticsService _analytics;
  final ICrashReporter _crash;

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
  String get storeBranch => AppConfig.storeBranch;

  String get displayName {
    if (_user == null) return '';
    if (_user!.isGuest) return 'Barista khách';
    final n = _user!.displayName;
    return (n == null || n.isEmpty) ? 'Barista RecipeHub' : n;
  }

  String get roleLabel => _role == UserRole.admin ? 'Store Admin' : 'Barista';

  /// Lắng nghe authStateChanges – điều hướng Splash → Login/Shell.
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
      _user = null;
      _status = AuthStatus.unauthenticated;
      _role = UserRole.viewer;
    } else {
      _user = user;
      _role = user.isGuest ? UserRole.viewer : _selectedRole;
      _sessionStart ??= DateTime.now();
      _status = AuthStatus.authenticated;
    }
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
      if (f.code != AuthFailureCode.cancelled) {
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
      await _crash.recordError(f, s, reason: 'auth_guest');
      return false;
    } finally {
      _guestBusy = false;
      _notify();
    }
  }

  Future<void> _onSignedIn(AppUser user, String method) async {
    _user = user;
    _role = user.isGuest ? UserRole.viewer : _selectedRole;
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
    _role = role;
    _selectedRole = role;
    _notify();
    await _analytics.setUserProperty('user_role', roleCode);
    await _crash.setCustomKey('user_role', roleCode);
    return true;
  }

  Future<void> signOut() async {
    final minutes = _sessionStart == null ? 0 : DateTime.now().difference(_sessionStart!).inMinutes;
    await _analytics.logLogout(role: roleCode, sessionMinutes: minutes);
    try {
      await _auth.signOut();
    } catch (e, s) {
      await _crash.recordError(e, s, reason: 'auth_sign_out');
    }
    await _analytics.setUserId(null);
    await _crash.setUserIdentifier(null);
    _user = null;
    _role = UserRole.viewer;
    _selectedRole = UserRole.viewer;
    _sessionStart = null;
    _status = AuthStatus.unauthenticated;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _sub?.cancel();
    super.dispose();
  }
}
