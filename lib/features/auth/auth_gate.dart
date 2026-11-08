import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app.dart' show rootNavigatorKey;
import '../../core/config/app_config.dart';
import '../../core/models/session_models.dart';
import '../../core/navigation/app_keys.dart';
import '../../core/navigation/deep_link_router.dart';
import '../../core/services/mock_data_service.dart';
import '../../core/theme/nomad_kit.dart';
import '../../core/viewmodels/app_config_viewmodel.dart';
import '../../core/viewmodels/auth_viewmodel.dart';
import '../../core/viewmodels/notification_viewmodel.dart';
import '../../core/viewmodels/practice_history_viewmodel.dart';
import '../../core/viewmodels/recipe_viewmodel.dart';
import '../../core/viewmodels/storage_viewmodel.dart';
import '../shell/main_app_shell.dart';
import '../system/loading_transition_page.dart';
import 'login_page.dart';

/// Bảo vệ route theo authStateChanges: Loading → Login | (tải công thức) → Shell.
/// Điều phối phiên: nạp dữ liệu khi đăng nhập, dọn state khi đăng xuất,
/// xử lý banner/deep link/primer quyền của FCM.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final AuthViewModel _auth;
  late final NotificationViewModel _notif;
  late final AppConfigViewModel _config;
  AuthStatus _handled = AuthStatus.unknown;
  bool _primerOpen = false;

  @override
  void initState() {
    super.initState();
    _auth = context.read<AuthViewModel>();
    _notif = context.read<NotificationViewModel>();
    _config = context.read<AppConfigViewModel>();
    _auth.addListener(_onAuthChanged);
    _notif.addListener(_onNotificationChanged);
    _config.addListener(_onConfigChanged);
    // Xóa FCM token trên server khi còn quyền ghi (trước khi Firebase Auth đăng xuất).
    _auth.addBeforeSignOut(_notif.unregisterDevice);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onAuthChanged());
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    _notif.removeListener(_onNotificationChanged);
    _config.removeListener(_onConfigChanged);
    super.dispose();
  }

  /// Remote Config cập nhật (real-time): tăng max_lookup_results thì tải thêm công thức.
  void _onConfigChanged() {
    if (!mounted || _auth.status != AuthStatus.authenticated) return;
    context.read<RecipeViewModel>().applyLimit(_config.maxLookupResults);
  }

  void _syncSession() {
    final d = MockDataService.instance;
    d.currentRole = _auth.role;
    d.currentUserName = _auth.displayName;
    d.currentUserEmail = _auth.user?.email ?? '';
    d.currentStoreBranch = AppConfig.storeBranch;
  }

  void _onAuthChanged() {
    if (!mounted) return;
    if (_auth.status == AuthStatus.authenticated) {
      _syncSession();
      unawaited(_notif.updateRole(_auth.roleCode));
    }
    final notice = _auth.notice;
    if (notice != null) {
      _auth.clearNotice();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(notice)));
      });
    }
    final status = _auth.status;
    if (status == _handled) return;
    final previous = _handled;
    _handled = status;
    if (status == AuthStatus.authenticated) {
      context.read<RecipeViewModel>().load(limit: context.read<AppConfigViewModel>().maxLookupResults);
      _notif.start(roleCode: _auth.roleCode, storeCode: AppConfig.storeCode, uid: _auth.user?.uid);
      final uid = _auth.user?.uid;
      if (uid != null) context.read<PracticeHistoryViewModel>().load(uid);
    } else if (status == AuthStatus.unauthenticated && previous == AuthStatus.authenticated) {
      rootNavigatorKey.currentState?.popUntil((r) => r.isFirst);
      MockDataService.instance.recipes = [];
      _notif.reset();
      context.read<StorageViewModel>().reset();
      context.read<PracticeHistoryViewModel>().clear();
    }
  }

  void _onNotificationChanged() {
    if (!mounted) return;
    final banner = _notif.takePendingBanner();
    if (banner != null) {
      ScaffoldMessenger.maybeOf(context)
        ?..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text('${banner.title}\n${banner.body}'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 6),
          // Thông báo khi app đang mở cũng phải mở được nội dung đính kèm (món/SOP/nhiệm vụ).
          action: SnackBarAction(
            key: AppKeys.bannerOpen,
            label: 'Xem',
            onPressed: () => _notif.open(banner),
          ),
        ));
    }
    final link = _notif.takePendingDeepLink();
    if (link != null) {
      final nav = rootNavigatorKey.currentContext;
      if (nav != null) DeepLinkRouter.open(nav, link);
    }
    if (_notif.shouldShowPermissionPrimer && !_primerOpen) {
      _primerOpen = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final ctx = rootNavigatorKey.currentContext;
        if (ctx == null || !mounted) {
          _primerOpen = false;
          return;
        }
        final allow = await showDialog<bool>(
          context: ctx,
          builder: (_) => AlertDialog(
            key: AppKeys.permissionPrimer,
            title: const Text('Bật thông báo?'),
            content: const Text('RecipeHub sẽ báo khi công thức, SOP hoặc nhiệm vụ học được cập nhật.'),
            actions: [
              TextButton(
                key: AppKeys.permissionLater,
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Để sau'),
              ),
              FilledButton(
                key: AppKeys.permissionAllow,
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Cho phép'),
              ),
            ],
          ),
        );
        _primerOpen = false;
        if (!_notif.isStarted) return; // đã đăng xuất trong lúc hộp thoại mở
        if (allow == true) {
          await _notif.requestPermission();
        } else {
          _notif.dismissPermissionPrimer();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    if (auth.status == AuthStatus.unknown) {
      return const LoadingTransitionPage(message: 'Đang khởi động RecipeHub...');
    }
    if (auth.status == AuthStatus.unauthenticated) {
      return const LoginPage(key: ValueKey('gate_login'));
    }
    final recipes = context.watch<RecipeViewModel>();
    switch (recipes.state) {
      case ViewState.idle:
      case ViewState.loading:
        return const LoadingTransitionPage(message: 'Đang tải công thức từ máy chủ...');
      case ViewState.error:
      case ViewState.empty:
        return _RecipeLoadProblem(
          empty: recipes.state == ViewState.empty,
          message: recipes.error,
          onRetry: () => recipes.load(limit: context.read<AppConfigViewModel>().maxLookupResults),
          onSignOut: auth.signOut,
        );
      case ViewState.ready:
        return MainAppShell(key: ValueKey('gate_shell_${auth.roleCode}'));
    }
  }
}

class _RecipeLoadProblem extends StatelessWidget {
  const _RecipeLoadProblem({required this.empty, required this.message, required this.onRetry, required this.onSignOut});

  final bool empty;
  final String? message;
  final VoidCallback onRetry;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: NomadKit.canvas,
        body: SafeArea(
          child: Center(
            child: Padding(
              key: AppKeys.recipeLoadError,
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(empty ? Icons.menu_book_outlined : Icons.cloud_off_rounded, size: 44, color: NomadKit.warning),
                  const SizedBox(height: 16),
                  Text(
                    empty ? 'Chưa có công thức ban hành' : 'Không tải được công thức',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: NomadKit.ink),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    empty
                        ? 'Máy chủ chưa có công thức đã ban hành (published). Nhờ R&D ban hành rồi thử lại.'
                        : (message ?? 'Vui lòng thử lại.'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: NomadKit.secondary, height: 1.4),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    key: AppKeys.recipeRetry,
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Thử lại'),
                  ),
                  TextButton(onPressed: onSignOut, child: const Text('Đăng xuất')),
                ],
              ),
            ),
          ),
        ),
      );
}
