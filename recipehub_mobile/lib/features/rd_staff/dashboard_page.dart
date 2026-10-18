import 'package:flutter/material.dart';
import '../../core/theme/nomad_kit.dart';
import '../../core/utils/navigation.dart';
import 'main_nav_shell.dart';
import 'recipe_detail_page.dart';
import 'recipe_editor_page.dart';
import 'batch_export_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting Header with Avatar
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: NomadKit.sand,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.coffee_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Chào buổi sáng,', style: TextStyle(fontSize: 12, color: NomadKit.secondary)),
                  Text('Minh Anh · R&D', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: NomadKit.ink)),
                ],
              ),
              const Spacer(),
              Stack(
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.notifications_none_rounded, color: NomadKit.ink, size: 24),
                  ),
                  Positioned(
                    top: 10,
                    right: 12,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: Color(0xFFCA8A04), shape: BoxShape.circle),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Overline, Headline & Subtitle
          const Text(
            'KHÔNG GIAN R&D',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: NomadKit.sandDark, letterSpacing: 0.8),
          ),
          const SizedBox(height: 4),
          const Text(
            'Hôm nay mình tạo gì?',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: NomadKit.ink),
          ),
          const SizedBox(height: 4),
          const Text(
            'Theo dõi bản nháp, duyệt công thức và phát hành SOP.',
            style: TextStyle(fontSize: 13, color: NomadKit.secondary),
          ),
          const SizedBox(height: 20),

          // Two Metric Cards Side by Side
          Row(
            children: [
              Expanded(
                child: _metricCard(
                  icon: Icons.edit_outlined,
                  iconBg: NomadKit.sandLight,
                  iconColor: NomadKit.sandDark,
                  count: '04',
                  label: 'Bản nháp',
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _metricCard(
                  icon: Icons.check_rounded,
                  iconBg: NomadKit.forestLight,
                  iconColor: NomadKit.forest,
                  count: '28',
                  label: 'Đã duyệt',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Quick Actions: Thao tác nhanh
          const Text('Thao tác nhanh', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: NomadKit.ink)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _quickActionCard(
                  icon: Icons.add_rounded,
                  label: 'Công thức mới',
                  onTap: () => go(context, const RecipeEditorPage()),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _quickActionCard(
                  icon: Icons.auto_awesome_rounded,
                  label: 'AI hỗ trợ',
                  onTap: () => go(context, const RecipeDetailPage(initialTabIndex: 2)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _quickActionCard(
                  icon: Icons.menu_book_outlined,
                  label: 'Tài liệu SOP',
                  onTap: () => go(context, const BatchExportPage()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Recent Updates Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Cập nhật gần đây', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: NomadKit.ink)),
              TextButton(
                onPressed: () {
                  final shellState = context.findAncestorStateOfType<MainNavShellState>();
                  shellState?.switchTab(1);
                },
                child: const Text('Xem tất cả', style: TextStyle(fontSize: 12, color: NomadKit.ocean, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Recipe Card 1: Matcha Latte Mây (Draft)
          _recentCard(
            context: context,
            title: 'Matcha Latte Mây',
            code: 'RC-MATCHA-01 · Trà sữa',
            version: 'v3',
            isDraft: true,
            onTap: () => go(context, const RecipeDetailPage(initialTabIndex: 0)),
          ),
          const SizedBox(height: 12),

          // Recipe Card 2: Cold Brew Cam Quế (Approved)
          _recentCard(
            context: context,
            title: 'Cold Brew Cam Quế',
            code: 'RC-COLD-02 · Cà phê',
            version: 'v2',
            isDraft: false,
            onTap: () => go(context, const RecipeDetailPage(title: 'Cold Brew Cam Quế', code: 'RC-COLD-02', version: 'v2', isDraft: false)),
          ),
        ],
      ),
    );
  }

  Widget _metricCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String count,
    required String label,
  }) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: NomadKit.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: NomadKit.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(height: 14),
            Text(count, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: NomadKit.ink)),
            Text(label, style: const TextStyle(fontSize: 13, color: NomadKit.secondary)),
          ],
        ),
      );

  Widget _quickActionCard({required IconData icon, required String label, required VoidCallback onTap}) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: NomadKit.sandLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: NomadKit.border.withValues(alpha: 0.5)),
          ),
          child: Column(
            children: [
              Icon(icon, color: NomadKit.sandDark, size: 22),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: NomadKit.ink),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );

  Widget _recentCard({
    required BuildContext context,
    required String title,
    required String code,
    required String version,
    required bool isDraft,
    required VoidCallback onTap,
  }) {
    final badgeColor = isDraft ? NomadKit.warningLight : NomadKit.forestLight;
    final badgeTextColor = isDraft ? NomadKit.warning : NomadKit.forest;
    final badgeLabel = isDraft ? 'Bản nháp' : 'Đã duyệt';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
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
              decoration: BoxDecoration(
                color: NomadKit.sandLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.coffee_rounded, color: NomadKit.sandDark, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(12)),
                        child: Text(
                          badgeLabel,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: badgeTextColor),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(version, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: NomadKit.secondary)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: NomadKit.ink)),
                  Text(code, style: const TextStyle(fontSize: 12, color: NomadKit.secondary)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: NomadKit.secondary),
          ],
        ),
      ),
    );
  }
}
