import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../models/session_models.dart';
import '../interfaces/i_auth_service.dart';

/// Firebase Authentication + Google Sign-In (google_sign_in v7 API).
///
/// Web Client ID (client_type 3) được plugin đọc từ `google-services.json`
/// (resource `default_web_client_id`). Có thể override bằng
/// `--dart-define=GOOGLE_SERVER_CLIENT_ID=xxx.apps.googleusercontent.com`.
class FirebaseAuthService implements IAuthService {
  FirebaseAuthService({FirebaseAuth? auth, GoogleSignIn? googleSignIn})
    : _auth = auth ?? FirebaseAuth.instance,
      _google = googleSignIn ?? GoogleSignIn.instance;

  static const String _serverClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );

  final FirebaseAuth _auth;
  final GoogleSignIn _google;
  Future<void>? _googleInit;

  Future<void> _ensureGoogleInitialized() {
    return _googleInit ??= _google.initialize(
      serverClientId: _serverClientId.isEmpty ? null : _serverClientId,
    );
  }

  static AppUser? _map(User? user) {
    if (user == null) return null;
    return AppUser(
      uid: user.uid,
      method: user.isAnonymous
          ? AuthMethod.guest
          : (user.providerData.any((p) => p.providerId == 'google.com')
                ? AuthMethod.google
                : AuthMethod.password),
      displayName: user.displayName,
      email: user.email,
      photoUrl: user.photoURL,
    );
  }

  @override
  Stream<AppUser?> authStateChanges() => _auth.authStateChanges().map(_map);

  @override
  AppUser? get currentUser => _map(_auth.currentUser);

  @override
  Future<AppUser> signInWithGoogle() async {
    try {
      await _ensureGoogleInitialized();
      final GoogleSignInAccount account = await _google.authenticate();
      final String? idToken = account.authentication.idToken;
      if (idToken == null) {
        throw const AuthFailure(
          AuthFailureCode.configuration,
          'Google idToken is null',
        );
      }
      final credential = GoogleAuthProvider.credential(idToken: idToken);
      final result = await _auth.signInWithCredential(credential);
      return _map(result.user)!;
    } on GoogleSignInException catch (e) {
      final codeName = e.code.name;
      if (e.code == GoogleSignInExceptionCode.canceled ||
          codeName == 'interrupted') {
        throw AuthFailure(AuthFailureCode.cancelled, e.description);
      }
      if (codeName.contains('onfiguration')) {
        throw AuthFailure(AuthFailureCode.configuration, e.description);
      }
      throw AuthFailure(AuthFailureCode.unknown, '$codeName: ${e.description}');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'network-request-failed') {
        throw AuthFailure(AuthFailureCode.network, e.message);
      }
      if (e.code == 'user-disabled') {
        throw AuthFailure(AuthFailureCode.disabled, e.message);
      }
      throw AuthFailure(AuthFailureCode.unknown, '${e.code}: ${e.message}');
    } on AuthFailure {
      rethrow;
    } catch (e) {
      debugPrint('[Auth] Google sign-in error: $e');
      throw AuthFailure(AuthFailureCode.unknown, e.toString());
    }
  }

  static AuthFailure _emailFailure(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
      case 'invalid-email':
        return AuthFailure(AuthFailureCode.invalidCredentials, e.code);
      case 'too-many-requests':
        return AuthFailure(AuthFailureCode.tooManyRequests, e.code);
      case 'network-request-failed':
        return AuthFailure(AuthFailureCode.network, e.message);
      case 'user-disabled':
        return AuthFailure(AuthFailureCode.disabled, e.message);
      case 'operation-not-allowed':
        return AuthFailure(AuthFailureCode.passwordDisabled, e.message);
      case 'weak-password':
        return AuthFailure(AuthFailureCode.weakPassword, e.message);
      case 'requires-recent-login':
        return AuthFailure(AuthFailureCode.requiresRecentLogin, e.message);
      default:
        return AuthFailure(AuthFailureCode.unknown, '${e.code}: ${e.message}');
    }
  }

  @override
  Future<AppUser> signInWithEmail(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return _map(result.user)!;
    } on FirebaseAuthException catch (e) {
      throw _emailFailure(e);
    }
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      // Mẫu email của project bị khóa chỉnh sửa → dùng bản dịch tiếng Việt có sẵn của Firebase.
      try {
        await _auth.setLanguageCode('vi');
      } catch (_) {}
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      // Không lộ email có tài khoản hay không.
      if (e.code == 'user-not-found' || e.code == 'invalid-email') return;
      throw _emailFailure(e);
    }
  }

  @override
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthFailure(AuthFailureCode.requiresRecentLogin);
    }
    if (user.isAnonymous ||
        !user.providerData.any((p) => p.providerId == 'password') ||
        user.email == null) {
      throw const AuthFailure(AuthFailureCode.passwordNotApplicable);
    }
    if (newPassword.length < 8) {
      throw const AuthFailure(AuthFailureCode.weakPassword);
    }
    try {
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(
          email: user.email!,
          password: currentPassword,
        ),
      );
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _emailFailure(e);
    }
  }

  @override
  Future<AppUser> signInAsGuest() async {
    try {
      final result = await _auth.signInAnonymously();
      return _map(result.user)!;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'network-request-failed') {
        throw AuthFailure(AuthFailureCode.network, e.message);
      }
      if (e.code == 'user-disabled') {
        throw AuthFailure(AuthFailureCode.disabled, e.message);
      }
      if (e.code == 'operation-not-allowed' ||
          e.code == 'admin-restricted-operation') {
        throw AuthFailure(
          AuthFailureCode.configuration,
          'Bật Anonymous provider trong Firebase Console',
        );
      }
      throw AuthFailure(AuthFailureCode.unknown, '${e.code}: ${e.message}');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      if (_googleInit != null) await _google.signOut();
    } catch (e) {
      debugPrint('[Auth] Google signOut ignored: $e');
    }
    await _auth.signOut();
  }
}
