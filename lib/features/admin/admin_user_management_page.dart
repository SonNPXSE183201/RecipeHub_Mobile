import 'package:flutter/material.dart';
import '../../core/theme/nomad_kit.dart';
import '../../core/widgets/screen_frame.dart';

class AdminUserManagementPage extends StatefulWidget {
  const AdminUserManagementPage({super.key});

  @override
  State<AdminUserManagementPage> createState() => _AdminUserManagementPageState();
}

class _AdminUserManagementPageState extends State<AdminUserManagementPage> {
  int _selectedFilter = 0; // 0: Tất cả, 1: R&D, 2: Barista, 3: Admin

  final List<Map<String, dynamic>> _users = [
    {
      'name': 'Minh Anh',
      'email': 'rnd@recipehub.vn',
      'role': 'R&D Lead (Chuyên viên)',
      'branch': 'Trung tâm Nghiên cứu R&D',
      'roleType': 1,
      'active': true,
      'perms': ['Tạo mới', 'Chốt v2', 'Xuất PDF', 'Prompt AI'],
    },
    {
      'name': 'Trần Quốc Tuấn',
      'email': 'tuan.barista@recipehub.vn',
      'role': 'Barista Ca sáng',
      'branch': 'Chi nhánh Landmark 81',
      'roleType': 2,
      'active': true,
      'perms': ['Chỉ đọc (Viewer)', 'Checklist SOP'],
    },
    {
      'name': 'Lê Hoàng Nam',
      'email': 'nam.operations@recipehub.vn',
      'role': 'Quản lý Vận hành Chuỗi',
      'branch': 'Toàn hệ thống (45 CH)',
      'roleType': 3,
      'active': true,
      'perms': ['Phân quyền', 'Audit Logs', 'Cấu hình Gemini'],
    },
    {
      'name': 'Đỗ Thị Mai',
      'email': 'mai.barista@recipehub.vn',
      'role': 'Barista Ca chiều',
      'branch': 'Chi nhánh Cầu Giấy, HN',
      'roleType': 2,
      'active': true,
      'perms': ['Chỉ đọc (Viewer)', 'Checklist SOP'],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _users.where((u) {
      if (_selectedFilter == 0) return true;
      return u['roleType'] == _selectedFilter;
    }).toList();

    return ScreenFrame(
      title: 'Phân quyền tài khoản',
      showLogo: true,
      action: IconButton(
        tooltip: 'Thêm nhân sự mới',
        icon: const Icon(Icons.person_add_alt_1_rounded, color: NomadKit.sandDark),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mở form tạo tài khoản nhân sự mới cho chi nhánh.')),
          );
        },
      ),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('DANH SÁCH NHÂN SỰ & QUYỀN TRUY CẬP', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: NomadKit.sandDark, letterSpacing: 0.8)),
          const SizedBox(height: 4),
          const Text('Quản lý 48 tài khoản trên 45 chi nhánh toàn quốc.', style: TextStyle(fontSize: 13, color: NomadKit.secondary)),
          const SizedBox(height: 14),

          // Role Filter Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _roleTab('Tất cả (4)', 0),
                const SizedBox(width: 8),
                _roleTab('R&D Team (1)', 1),
                const SizedBox(width: 8),
                _roleTab('Baristas (2)', 2),
                const SizedBox(width: 8),
                _roleTab('Admin (1)', 3),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Users List
          ...filtered.map(
            (user) => Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: NomadKit.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: NomadKit.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: user['active'] ? NomadKit.sandLight : const Color(0xFFFEE2E2),
                        child: Text(
                          user['name'][0],
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: user['active'] ? NomadKit.sandDark : const Color(0xFFDC2626),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user['name'], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: NomadKit.ink)),
                            Text('${user['role']} · ${user['branch']}', style: const TextStyle(fontSize: 12, color: NomadKit.secondary)),
                          ],
                        ),
                      ),
                      Switch(
                        activeTrackColor: NomadKit.sand,
                        value: user['active'],
                        onChanged: (val) {
                          setState(() => user['active'] = val);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${val ? "Đã kích hoạt" : "Đã tạm khóa"} tài khoản ${user["name"]}')),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: (user['perms'] as List<String>)
                        .map(
                          (p) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: NomadKit.canvas, borderRadius: BorderRadius.circular(8)),
                            child: Text(p, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: NomadKit.secondary)),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _roleTab(String label, int index) {
    final isSelected = _selectedFilter == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? NomadKit.sand : NomadKit.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? NomadKit.sand : NomadKit.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : NomadKit.secondary,
          ),
        ),
      ),
    );
  }
}
