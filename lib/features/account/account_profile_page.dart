import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/nomad_kit.dart';
import '../../core/models/app_models.dart';
import '../../core/services/mock_data_service.dart';
import '../../core/utils/navigation.dart';
import '../../core/di/app_services.dart';
import '../../core/navigation/app_keys.dart';
import '../../core/viewmodels/auth_viewmodel.dart';
import '../../core/viewmodels/notification_viewmodel.dart';
import '../learning/personal_progress_page.dart';
import '../practice/practice_history_page.dart';
import '../practice/practical_evaluation_page.dart';
import '../admin_training/admin_store_training_page.dart';

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
        title: const Text('Đăng xuất tài khoản?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: NomadKit.ink)),
        content: const Text('Bạn sẽ quay về màn hình đăng nhập quầy bar.', style: TextStyle(fontSize: 13, color: NomadKit.secondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(fontWeight: FontWeight.w700, color: NomadKit.secondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: NomadKit.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              // AuthGate chuyển về Login khi authStateChanges phát null.
              context.read<AuthViewModel>().signOut();
            },
            child: const Text('Đăng xuất', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  /// Ẩn: nhấn giữ tiêu đề "CÀI ĐẶT ỨNG DỤNG" (chỉ Admin) → kiểm thử Crashlytics.
  void _crashDemo() {
    final crash = context.read<AppServices>().crash;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kiểm thử Crashlytics'),
        content: const Text('Chỉ dùng khi demo Lab 3. "Gây crash" sẽ đóng ứng dụng.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          TextButton(
            key: AppKeys.recordNonFatal,
            onPressed: () async {
              Navigator.pop(ctx);
              await crash.recordError(StateError('demo_non_fatal'), StackTrace.current, reason: 'manual_demo');
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã ghi lỗi non-fatal.')));
            },
            child: const Text('Ghi non-fatal'),
          ),
          TextButton(
            key: AppKeys.testCrash,
            onPressed: () {
              Navigator.pop(ctx);
              crash.testCrash();
            },
            child: const Text('Gây crash', style: TextStyle(color: NomadKit.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRoleAdmin = MockDataService.instance.currentRole == UserRole.admin;

    return Scaffold(
      backgroundColor: NomadKit.canvas,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('HỒ SƠ CÁ NHÂN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: NomadKit.sandDark, letterSpacing: 0.8)),
              const SizedBox(height: 2),
              const Text('Tài khoản & Phân quyền', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: NomadKit.ink)),
              const SizedBox(height: 16),

              // Profile Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: NomadKit.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: NomadKit.border),
                  boxShadow: const [
                    BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 2)),
                  ],
                ),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/icons/icon_user_profile.png',
                      width: 48,
                      height: 48,
                      filterQuality: FilterQuality.medium,
                      errorBuilder: (ctx, err, stack) => Icon(
                        isRoleAdmin ? Icons.admin_panel_settings_rounded : Icons.person_rounded,
                        color: NomadKit.sand,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                MockDataService.instance.currentUserName,
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: NomadKit.ink),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isRoleAdmin ? NomadKit.sandLight : NomadKit.forestLight,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isRoleAdmin ? 'ADMIN' : 'VIEWER',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: isRoleAdmin ? NomadKit.sandDark : NomadKit.forest,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(MockDataService.instance.currentUserEmail, style: const TextStyle(fontSize: 12, color: NomadKit.secondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Store Branch Scope Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: NomadKit.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: NomadKit.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Image.asset(
                          'assets/icons/icon_store_branch.png',
                          width: 20,
                          height: 20,
                          filterQuality: FilterQuality.medium,
                          errorBuilder: (ctx, err, stack) => const Icon(Icons.storefront_rounded, size: 18, color: NomadKit.forest),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isRoleAdmin ? 'PHẠM VI QUẢN LÝ CỬA HÀNG' : 'CỬA HÀNG CÔNG TÁC HIỆN TẠI',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: NomadKit.sandDark, letterSpacing: 0.6),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isRoleAdmin
                          ? MockDataService.instance.adminStoreScope
                          : MockDataService.instance.currentStoreBranch,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: NomadKit.ink),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isRoleAdmin
                          ? 'Được phân công quản lý tiêu chuẩn và tiến độ đào tạo các chi nhánh trên.'
                          : 'Quy tắc FR-02: Lịch sử học và tiến độ đào tạo vẫn được giữ nguyên khi chuyển cửa hàng.',
                      style: const TextStyle(fontSize: 11, color: NomadKit.secondary, height: 1.3),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Menu Items
              const Text('HỒ SƠ ĐÀO TẠO & KẾT QUẢ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: NomadKit.sandDark, letterSpacing: 0.7)),
              const SizedBox(height: 8),

              _menuTile(
                title: 'Tiến độ đào tạo cá nhân',
                subtitle: 'Thống kê 3 tầng: Đọc/Xem, Quiz và Thực hành',
                icon: Icons.insights_rounded,
                color: NomadKit.forest,
                onTap: () => go(context, const PersonalProgressPage()),
              ),
              _menuTile(
                title: 'Kết quả đánh giá thực hành tại quầy',
                subtitle: 'Checklist quan sát, lỗi ghi nhận và kế hoạch ôn tập',
                icon: Icons.checklist_rounded,
                color: NomadKit.ocean,
                onTap: () => go(context, const PracticalEvaluationPage()),
              ),
              _menuTile(
                title: 'Lịch sử tự luyện với Timer',
                subtitle: 'Các lần bấm giờ thao tác cá nhân, không xếp hạng đua',
                icon: Icons.history_rounded,
                color: NomadKit.sandDark,
                onTap: () => go(context, const PracticeHistoryPage()),
              ),

              if (isRoleAdmin) ...[
                const SizedBox(height: 14),
                const Text('PHÂN HỆ ADMIN QUẢN LÝ ĐÀO TẠO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: NomadKit.sandDark, letterSpacing: 0.7)),
                const SizedBox(height: 8),

                _menuTile(
                  title: 'Bảng theo dõi đào tạo chi nhánh',
                  subtitle: 'Xem tiến độ nhân viên, danh sách quá hạn & chấm tại quầy',
                  icon: Icons.group_work_outlined,
                  color: NomadKit.sandDark,
                  onTap: () => go(context, const AdminStoreTrainingPage()),
                ),
              ],

              const SizedBox(height: 14),
              GestureDetector(
                onLongPress: isRoleAdmin ? _crashDemo : null,
                child: const Text('CÀI ĐẶT ỨNG DỤNG', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: NomadKit.sandDark, letterSpacing: 0.7)),
              ),
              const SizedBox(height: 8),

              _menuTile(
                title: 'Đổi mật khẩu tài khoản',
                subtitle: 'Bảo mật tài khoản quầy bar',
                icon: Icons.lock_outline_rounded,
                color: NomadKit.secondary,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tính năng đổi mật khẩu đang mở kết nối bảo mật.')),
                  );
                },
              ),
              _menuTile(
                title: 'Thông báo & Âm thanh quầy bar',
                subtitle: 'Bật chuông thông báo khi có công thức cập nhật phiên bản',
                icon: Icons.notifications_none_rounded,
                color: NomadKit.secondary,
                onTap: () async {
                  final p = await context.read<NotificationViewModel>().requestPermission();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(p.name == 'granted' ? 'Đã bật thông báo.' : 'Thông báo đang tắt. Bật lại trong Cài đặt hệ thống.'),
                  ));
                },
              ),

              const SizedBox(height: 24),

              // Logout Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: NomadKit.error,
                    side: const BorderSide(color: NomadKit.error),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  key: AppKeys.logout,
                  onPressed: _handleLogout,
                  icon: const Icon(Icons.logout_rounded, size: 20),
                  label: const Text('Đăng xuất khỏi quầy bar', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: NomadKit.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NomadKit.border),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 20),
          ),
          title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: NomadKit.ink)),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: NomadKit.secondary)),
          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: NomadKit.secondary),
          onTap: onTap,
        ),
      ),
    );
  }
}
