import 'package:flutter/material.dart';
import '../../core/theme/nomad_kit.dart';
import '../../core/utils/navigation.dart';
import '../barista/viewer_home_page.dart';
import '../barista/booklet_reader_page.dart';
import '../barista/barista_viewer_page.dart';
import '../admin/admin_console_page.dart';
import '../system/error_recovery_page.dart';
import 'batch_export_page.dart';
import 'export_history_page.dart';
import 'pdf_draft_preview_page.dart';
import '../auth/login_page.dart';

class AccountSettingsPage extends StatelessWidget {
  const AccountSettingsPage({super.key});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('CÁ NHÂN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: NomadKit.sandDark, letterSpacing: 0.8)),
            const SizedBox(height: 2),
            const Text('Tài khoản', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: NomadKit.ink)),
            const SizedBox(height: 16),

            // User Profile Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: NomadKit.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: NomadKit.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(color: NomadKit.sand, borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.person_rounded, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Minh Anh', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: NomadKit.ink)),
                        Text('rnd@recipehub.vn · R&D Specialist', style: TextStyle(fontSize: 12, color: NomadKit.secondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text('Chế độ làm việc & Phân hệ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: NomadKit.ink)),
            const SizedBox(height: 8),

            _menuItem(
              title: 'Trang chủ Store Barista (Viewer Flow)',
              subtitle: 'Giao diện tại quầy chi nhánh Landmark 81',
              icon: Icons.storefront_rounded,
              onTap: () => go(context, const ViewerHomePage()),
            ),
            _menuItem(
              title: 'Lật đọc Sổ tay SOP (Booklet Reader)',
              subtitle: 'Sách điện tử 8 trang lật trang 3D mượt mà',
              icon: Icons.auto_stories_rounded,
              onTap: () => go(context, const BookletReaderPage()),
            ),
            _menuItem(
              title: 'Chế độ Barista Viewer tốc độ cao',
              subtitle: 'Giao diện chỉ đọc, chữ to có checklist chống lóa tại quầy bar',
              icon: Icons.coffee_rounded,
              onTap: () => go(context, const BaristaViewerPage()),
            ),
            _menuItem(
              title: 'Bảng điều khiển Quản trị (Admin Flow)',
              subtitle: 'Phân quyền tài khoản, cấu hình Gemini AI & Nhật ký kiểm toán',
              icon: Icons.admin_panel_settings_outlined,
              onTap: () => go(context, const AdminConsolePage()),
            ),
            _menuItem(
              title: 'Đóng gói SOP Master Book',
              subtitle: 'Chọn nhiều công thức để xuất 1 bộ PDF chuẩn chuỗi',
              icon: Icons.picture_as_pdf_outlined,
              onTap: () => go(context, const BatchExportPage()),
            ),
            _menuItem(
              title: 'Lịch sử xuất bản PDF',
              subtitle: 'Quản lý, tải lại và xem lại các tài liệu SOP đã đóng gói',
              icon: Icons.history_edu_rounded,
              onTap: () => go(context, const ExportHistoryPage()),
            ),
            _menuItem(
              title: 'Xem trước tài liệu nháp Watermark',
              subtitle: 'Kiểm tra dấu chìm BẢN NHÁP cho công thức chưa chốt',
              icon: Icons.waterfall_chart,
              onTap: () => go(context, const PdfDraftPreviewPage()),
            ),
            _menuItem(
              title: 'Chẩn đoán kết nối & Phục hồi nháp ngoại tuyến',
              subtitle: 'Kiểm tra tính năng lưu trữ đệm và khôi phục khi mất mạng',
              icon: Icons.cloud_off_rounded,
              onTap: () => go(context, const ErrorRecoveryPage()),
            ),
            const SizedBox(height: 16),

            // Logout Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFDC2626),
                  side: const BorderSide(color: Color(0xFFFCA5A5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                ),
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Đăng xuất tài khoản', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              ),
            ),
          ],
        ),
      );

  Widget _menuItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) =>
      Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Material(
          color: NomadKit.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: NomadKit.border),
          ),
          child: ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: NomadKit.sandLight, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: NomadKit.sandDark, size: 20),
            ),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: NomadKit.ink)),
            subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: NomadKit.secondary)),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: NomadKit.secondary),
            onTap: onTap,
          ),
        ),
      );
}
