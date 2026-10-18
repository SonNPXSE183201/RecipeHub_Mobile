import 'package:flutter/material.dart';
import '../../core/theme/nomad_kit.dart';
import '../../core/widgets/recipe_hub_logo.dart';
import '../../core/widgets/screen_frame.dart';
import '../../core/utils/navigation.dart';
import '../barista/viewer_home_page.dart';
import '../rd_staff/main_nav_shell.dart';
import 'admin_user_management_page.dart';
import 'admin_ai_config_page.dart';
import 'admin_audit_logs_page.dart';

class AdminConsolePage extends StatelessWidget {
  const AdminConsolePage({super.key});

  @override
  Widget build(BuildContext context) => ScreenFrame(
        title: 'Bảng điều khiển Quản trị',
        showLogo: true,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Admin Top Summary Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: NomadKit.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: NomadKit.border),
                boxShadow: const [
                  BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 3)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const RecipeHubLogo(size: 38, iconSize: 20, radius: 12),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('HỆ THỐNG QUẢN TRỊ CHUỖI', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: NomadKit.sandDark, letterSpacing: 0.6)),
                            Text('Nomad Coffee & Tea Hub', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: NomadKit.ink)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: NomadKit.forestLight, borderRadius: BorderRadius.circular(10)),
                        child: const Text('ONLINE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: NomadKit.forest)),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _adminMetric('45', 'Chi nhánh'),
                      Container(width: 1, height: 28, color: NomadKit.border),
                      _adminMetric('48', 'Nhân sự'),
                      Container(width: 1, height: 28, color: NomadKit.border),
                      _adminMetric('98.5%', 'Tuân thủ SOP'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text('DANH MỤC QUẢN TRỊ VẬN HÀNH', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: NomadKit.sandDark, letterSpacing: 0.8)),
            const SizedBox(height: 10),

            _adminTile(
              context: context,
              title: 'Phân quyền tài khoản người dùng',
              subtitle: 'Minh Anh (R&D Lead) · Tuấn (Barista) · 45 Chi nhánh',
              badge: '48 TÀI KHOẢN',
              icon: Icons.manage_accounts_outlined,
              color: NomadKit.sand,
              onTap: () => go(context, const AdminUserManagementPage()),
            ),
            _adminTile(
              context: context,
              title: 'Cấu hình Gemini AI',
              subtitle: 'Gemini 1.5 Pro · API Status: Active · Kiểm tra kết nối',
              badge: 'AI ACTIVE',
              icon: Icons.psychology_outlined,
              color: NomadKit.ocean,
              onTap: () => go(context, const AdminAiConfigPage()),
            ),
            _adminTile(
              context: context,
              title: 'Nhật ký kiểm toán SHA-256',
              subtitle: 'Lưu vết bất biến mọi lần chốt công thức & xuất PDF chuỗi',
              badge: 'AUDIT LOGS',
              icon: Icons.verified_user_outlined,
              color: NomadKit.forest,
              onTap: () => go(context, const AdminAuditLogsPage()),
            ),

            const SizedBox(height: 24),
            const Text('ĐIỀU HƯỚNG VAI TRÒ VẬN HÀNH', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: NomadKit.sandDark, letterSpacing: 0.8)),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: NomadKit.forest,
                      side: const BorderSide(color: NomadKit.forestLight),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => go(context, const ViewerHomePage()),
                    icon: const Icon(Icons.storefront_rounded, size: 16),
                    label: const Text('Store Viewer', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: NomadKit.sandDark,
                      side: const BorderSide(color: NomadKit.border),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => go(context, const MainNavShell(initialTab: 0)),
                    icon: const Icon(Icons.science_outlined, size: 16),
                    label: const Text('R&D Studio', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _adminMetric(String value, String label) => Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: NomadKit.ink)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: NomadKit.secondary)),
        ],
      );

  Widget _adminTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String badge,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) =>
      Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: Material(
          color: NomadKit.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: NomadKit.border),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                              child: Text(badge, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: color)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: NomadKit.ink)),
                        const SizedBox(height: 2),
                        Text(subtitle, style: const TextStyle(fontSize: 11, color: NomadKit.secondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: NomadKit.secondary),
                ],
              ),
            ),
          ),
        ),
      );
}
