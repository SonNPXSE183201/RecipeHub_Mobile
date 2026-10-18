import 'package:flutter/material.dart';
import '../../core/theme/nomad_kit.dart';
import '../../core/widgets/screen_frame.dart';

class AdminAuditLogsPage extends StatefulWidget {
  const AdminAuditLogsPage({super.key});

  @override
  State<AdminAuditLogsPage> createState() => _AdminAuditLogsPageState();
}

class _AdminAuditLogsPageState extends State<AdminAuditLogsPage> {
  int _selectedFilter = 0; // 0: Tất cả, 1: Chốt v2, 2: Xuất PDF, 3: Cấu hình

  final List<Map<String, dynamic>> _logs = [
    {
      'time': '18/10/2026 09:30:15',
      'user': 'Minh Anh (R&D Lead)',
      'action': 'CHỐT PHIÊN BẢN (Lock v2)',
      'target': 'Matcha Latte Mây (RC-MATCHA-01)',
      'hash': 'SHA-256: 7f8a3c8e9d2...14b',
      'ip': '192.168.1.42 · Pixel 5 Mobile',
      'type': 1,
    },
    {
      'time': '17/10/2026 16:45:20',
      'user': 'Minh Anh (R&D Lead)',
      'action': 'XUẤT PDF MASTER BOOK',
      'target': 'RecipeHub_SOP_MasterBook_2026.pdf (3 công thức)',
      'hash': 'SHA-256: 4b2e8f1a7c0...99d',
      'ip': '192.168.1.42 · Pixel 5 Mobile',
      'type': 2,
    },
    {
      'time': '16/10/2026 14:10:05',
      'user': 'Lê Hoàng Nam (Admin)',
      'action': 'CẬP NHẬT CẤU HÌNH AI',
      'target': 'Model: Gemini 1.5 Pro · Ping Latency: 138ms',
      'hash': 'SHA-256: e8b2a19c4d3...55f',
      'ip': '10.0.0.12 · Admin Console Web/App',
      'type': 3,
    },
    {
      'time': '15/10/2026 11:22:40',
      'user': 'Trần Quốc Tuấn (Barista L81)',
      'action': 'TẢI FILE SOP VỀ MÁY POS',
      'target': 'Cold Brew Cam Quế v2 (Chính thức)',
      'hash': 'SHA-256: 9a3d7b1e2c8...77a',
      'ip': '172.16.4.10 · POS Chi nhánh L81',
      'type': 2,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _logs.where((l) {
      if (_selectedFilter == 0) return true;
      return l['type'] == _selectedFilter;
    }).toList();

    return ScreenFrame(
      title: 'Nhật ký kiểm toán',
      showLogo: true,
      action: IconButton(
        tooltip: 'Xuất báo cáo kiểm toán',
        icon: const Icon(Icons.download_rounded, color: NomadKit.sandDark),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xuất file Audit_Report_Oct2026.csv bảo mật toàn hệ thống.')),
          );
        },
      ),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('LƯU VẾT BẤT BIẾN TOÀN CHUỖI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: NomadKit.sandDark, letterSpacing: 0.8)),
          const SizedBox(height: 4),
          const Text('Mọi thao tác chốt công thức, xuất bản và phân quyền đều được băm SHA-256 đối soát.', style: TextStyle(fontSize: 13, color: NomadKit.secondary)),
          const SizedBox(height: 14),

          // Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _pill('Tất cả (4)', 0),
                const SizedBox(width: 8),
                _pill('Chốt v2 (1)', 1),
                const SizedBox(width: 8),
                _pill('Xuất PDF (2)', 2),
                const SizedBox(width: 8),
                _pill('Cấu hình AI (1)', 3),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Log Entries
          ...filtered.map(
            (log) => Container(
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: log['type'] == 1
                              ? NomadKit.forestLight
                              : log['type'] == 2
                                  ? NomadKit.sandLight
                                  : NomadKit.oceanLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          log['action'],
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: log['type'] == 1
                                ? NomadKit.forest
                                : log['type'] == 2
                                    ? NomadKit.sandDark
                                    : NomadKit.ocean,
                          ),
                        ),
                      ),
                      Text(log['time'], style: const TextStyle(fontSize: 11, color: NomadKit.secondary)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(log['target'], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: NomadKit.ink)),
                  const SizedBox(height: 4),
                  Text('Thực hiện bởi: ${log['user']}', style: const TextStyle(fontSize: 12, color: NomadKit.secondary)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: NomadKit.canvas, borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        const Icon(Icons.fingerprint_rounded, size: 14, color: NomadKit.secondary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(log['hash'], style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: NomadKit.secondary)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(String label, int index) {
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
