import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/nomad_kit.dart';
import '../../core/utils/navigation.dart';
import '../../core/di/app_services.dart';
import '../../core/navigation/app_keys.dart';
import '../../core/models/incident_report.dart';
import '../../core/viewmodels/app_config_viewmodel.dart';
import '../../core/viewmodels/auth_viewmodel.dart';
import '../../core/viewmodels/notification_viewmodel.dart';
import '../../core/widgets/redesign_widgets.dart';
import '../learning/personal_progress_page.dart';
import '../practice/practice_history_page.dart';
import '../practice/practical_evaluation_page.dart';
import '../admin_training/admin_store_training_page.dart';
import '../learning/notifications_page.dart';
import '../sop_book/sop_book_page.dart';
import 'change_password_page.dart';
import 'experience_settings_page.dart';

class AccountProfilePage extends StatefulWidget {
  const AccountProfilePage({super.key});

  @override
  State<AccountProfilePage> createState() => _AccountProfilePageState();
}

class _AccountProfilePageState extends State<AccountProfilePage> {
  void _handleLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NomadKit.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Đăng xuất tài khoản?',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: NomadKit.ink,
          ),
        ),
        content: const Text(
          'Bạn sẽ quay về màn hình đăng nhập quầy bar.',
          style: TextStyle(fontSize: 14, color: NomadKit.secondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Hủy',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: NomadKit.secondary,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: NomadKit.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              // AuthGate chuyển về Login khi authStateChanges phát null.
              context.read<AuthViewModel>().signOut();
            },
            child: const Text(
              'Đăng xuất',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  /// Kiểm thử sự cố (Lab 3): ghi sự cố lên Firestore để web Admin thấy ngay, đồng thời gửi Crashlytics.
  /// Hiện khi Remote Config `show_crash_demo = true`.
  void _crashDemo() {
    final services = context.read<AppServices>();
    final crash = services.crash;
    final incidents = services.incidents;
    final analytics = services.analytics;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kiểm thử sự cố'),
        content: const Text(
          'Sự cố được gửi tới web Admin ngay và tới Crashlytics. "Gây crash" sẽ đóng ứng dụng.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          TextButton(
            key: AppKeys.recordNonFatal,
            onPressed: () async {
              Navigator.pop(ctx);
              final error = StateError(
                'demo_non_fatal: kiểm thử lỗi không làm dừng app',
              );
              final stack = StackTrace.current;
              await analytics.logTriggerTestCrash(kind: 'non_fatal');
              await crash.recordError(error, stack, reason: 'manual_demo');
              final sent = await incidents.report(
                IncidentReport.fromError(
                  error,
                  stack,
                  kind: IncidentKind.nonFatal,
                  source: IncidentSource.nonFatalReport,
                  screen: 'account',
                ),
              );
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    sent
                        ? 'Đã gửi lỗi non-fatal tới Admin và Crashlytics.'
                        : 'Đã ghi Crashlytics; chưa gửi được tới Admin.',
                  ),
                ),
              );
            },
            child: const Text('Ghi non-fatal'),
          ),
          TextButton(
            key: AppKeys.testCrash,
            onPressed: () async {
              Navigator.pop(ctx);
              final error = StateError('demo_fatal: nút Gây crash');
              await analytics.logTriggerTestCrash(kind: 'fatal');
              // Ghi Firestore TRƯỚC khi crash để web Admin thấy ngay; Crashlytics gửi báo cáo ở lần mở sau.
              await incidents.report(
                IncidentReport.fromError(
                  error,
                  StackTrace.current,
                  kind: IncidentKind.fatal,
                  source: IncidentSource.demoButton,
                  screen: 'account',
                ),
              );
              await incidents.markCrashAlreadyReported();
              crash.testCrash();
            },
            child: const Text(
              'Gây crash',
              style: TextStyle(color: NomadKit.error),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final isRoleAdmin = auth.isAdmin;
    final email = (auth.user?.email ?? '').isEmpty
        ? 'Chưa cập nhật'
        : auth.user!.email!;

    return Scaffold(
      backgroundColor: NomadKit.canvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            RhPageHeader(
              title: 'Tài khoản',
              trailing: IconButton(
                key: AppKeys.notificationBell,
                tooltip: 'Thông báo',
                onPressed: () => go(context, const NotificationsPage()),
                style: IconButton.styleFrom(
                  backgroundColor: NomadKit.sandLight,
                ),
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: NomadKit.sandDark,
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _menuTile(
                      title:
                          '${auth.displayName} · ${isRoleAdmin ? 'ADMIN' : 'VIEWER'}',
                      subtitle:
                          '${isRoleAdmin ? 'Quản lý cửa hàng' : 'Nhân viên pha chế'} · $email',
                      icon: Icons.people_outline_rounded,
                    ),
                    _menuTile(
                      title: 'Sổ tay SOP',
                      subtitle: 'Công thức và hướng dẫn thao tác tại quầy',
                      icon: Icons.menu_book_outlined,
                      onTap: () => go(context, const SopBookPage()),
                    ),
                    _group('Hồ sơ đào tạo & kết quả'),
                    if (auth.hasPersonalLearning)
                      _menuTile(
                        title: 'Tiến độ đào tạo cá nhân',
                        subtitle: 'Việc học, quiz và kết quả thực hành của bạn',
                        icon: Icons.trending_up_rounded,
                        onTap: () => go(context, const PersonalProgressPage()),
                      ),
                    _menuTile(
                      title: 'Kết quả đánh giá thực hành',
                      subtitle: 'Checklist quan sát và kế hoạch ôn tập',
                      icon: Icons.assignment_turned_in_outlined,
                      onTap: () => go(context, const PracticalEvaluationPage()),
                    ),
                    if (auth.hasPersonalLearning)
                      _menuTile(
                        title: 'Lịch sử tự luyện với Timer',
                        subtitle: 'Các phiên bấm giờ thao tác cá nhân',
                        icon: Icons.history_rounded,
                        onTap: () => go(context, const PracticeHistoryPage()),
                      ),
                    if (isRoleAdmin)
                      _menuTile(
                        title: 'Đào tạo chi nhánh',
                        subtitle: 'Tiến độ nhân viên và đánh giá tại quầy',
                        icon: Icons.people_outline_rounded,
                        onTap: () =>
                            go(context, const AdminStoreTrainingPage()),
                      ),
                    _group('Cài đặt ứng dụng'),
                    _menuTile(
                      title: 'Đổi mật khẩu',
                      subtitle: 'Bảo mật tài khoản quầy bar',
                      icon: Icons.lock_outline_rounded,
                      onTap: () => go(context, const ChangePasswordPage()),
                    ),
                    _menuTile(
                      title: 'Cài đặt trải nghiệm',
                      subtitle: 'Khả năng tiếp cận, chữ và chuyển động',
                      icon: Icons.tune_rounded,
                      onTap: () => go(context, const ExperienceSettingsPage()),
                    ),
                    _menuTile(
                      title: 'Thông báo & Âm thanh',
                      subtitle: 'Thông báo khi công thức cập nhật phiên bản',
                      icon: Icons.notifications_none_rounded,
                      onTap: () async {
                        final p = await context
                            .read<NotificationViewModel>()
                            .requestPermission();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              p.name == 'granted' ? 'Đã bật thông báo.' : 'Thông báo đang tắt. Bật lại trong Cài đặt hệ thống.',
                            ),
                          ),
                        );
                      },
                    ),
                    if (context.watch<AppConfigViewModel>().showCrashDemo)
                      KeyedSubtree(
                        key: AppKeys.crashDemoTile,
                        child: _menuTile(
                          title: 'Kiểm thử sự cố',
                          subtitle: 'Công cụ kiểm thử dành cho bản demo',
                          icon: Icons.bug_report_outlined,
                          onTap: _crashDemo,
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: NomadKit.surface,
                          foregroundColor: NomadKit.sandDark,
                          side: const BorderSide(color: NomadKit.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        key: AppKeys.logout,
                        onPressed: _handleLogout,
                        child: Text(
                          'Đăng xuất khỏi quầy bar',
                          style: NomadKit.label.copyWith(
                            color: NomadKit.sandDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _group(String label) => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 8),
    child: Text(
      label.toUpperCase(),
      style: NomadKit.caption.copyWith(
        color: NomadKit.sandDark,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      ),
    ),
  );

  Widget _menuTile({
    required String title,
    required String subtitle,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: NomadKit.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: NomadKit.border),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 72),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(icon, color: NomadKit.sandDark, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: NomadKit.body.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(subtitle, style: NomadKit.caption),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
