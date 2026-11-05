import 'package:flutter/material.dart';
import '../../core/theme/nomad_kit.dart';
import '../../core/utils/navigation.dart';
import '../practice/practical_evaluation_page.dart';

class AdminStoreTrainingPage extends StatefulWidget {
  const AdminStoreTrainingPage({super.key});

  @override
  State<AdminStoreTrainingPage> createState() => _AdminStoreTrainingPageState();
}

class _AdminStoreTrainingPageState extends State<AdminStoreTrainingPage> {
  String _selectedStore = 'Landmark 81';

  final List<Map<String, dynamic>> _staffList = [
    {
      'name': 'Nguyễn Văn Tuấn',
      'role': 'Barista chính ca sáng',
      'readingPercent': 85,
      'hasOverdue': true,
      'hasRelearn': true,
      'practicalStatus': 'Đạt tiêu chuẩn',
      'overdueTask': 'SOP-CLEAN-01: Vệ sinh máy Espresso',
    },
    {
      'name': 'Lê Thị Lan',
      'role': 'Barista phụ ca chiều',
      'readingPercent': 100,
      'hasOverdue': false,
      'hasRelearn': false,
      'practicalStatus': 'Đạt tiêu chuẩn',
      'overdueTask': null,
    },
    {
      'name': 'Phạm Hoàng Nam',
      'role': 'Nhân viên thử việc',
      'readingPercent': 30,
      'hasOverdue': true,
      'hasRelearn': false,
      'practicalStatus': 'Chưa đánh giá',
      'overdueTask': 'RC-CB-01: Cold Brew Cam Quế v2.0',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NomadKit.canvas,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('GIÁM SÁT CHI NHÁNH', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: NomadKit.sandDark, letterSpacing: 0.8)),
                    SizedBox(height: 2),
                    Text('Theo dõi đào tạo', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: NomadKit.ink)),
                  ],
                ),
                IconButton(
                  tooltip: 'Chấm thực hành tại quầy',
                  icon: const Icon(Icons.checklist_rtl_rounded, size: 26, color: NomadKit.sandDark),
                  onPressed: () => go(context, const PracticalEvaluationPage()),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Store Scope Selector (Single clean card without nested card border)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: NomadKit.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: NomadKit.border),
                boxShadow: const [
                  BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Image.asset(
                        'assets/icons/icon_store_branch.png',
                        width: 22,
                        height: 22,
                        filterQuality: FilterQuality.medium,
                        errorBuilder: (ctx, err, stack) => const Icon(Icons.storefront_rounded, size: 20, color: NomadKit.sandDark),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'CHI NHÁNH PHỤ TRÁCH QUẢN LÝ',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: NomadKit.sandDark, letterSpacing: 0.6),
                            ),
                            const SizedBox(height: 2),
                            DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedStore,
                                isDense: true,
                                isExpanded: true,
                                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: NomadKit.sandDark, size: 22),
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: NomadKit.ink, fontFamily: 'Inter'),
                                items: ['Landmark 81', 'Bitexco Q1', 'Thảo Điền Q2']
                                    .map((s) => DropdownMenuItem(
                                          value: s,
                                          child: Text(s, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: NomadKit.ink)),
                                        ))
                                    .toList(),
                                onChanged: (v) => setState(() => _selectedStore = v ?? _selectedStore),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1, thickness: 1, color: NomadKit.border),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _metricBox('3', 'Nhân sự'),
                      Container(width: 1, height: 26, color: NomadKit.border),
                      _metricBox('72%', 'Tiến độ TB'),
                      Container(width: 1, height: 26, color: NomadKit.border),
                      _metricBox('2', 'Bài quá hạn', isWarning: true),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Quick Action: Chấm thực hành tại quầy
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: NomadKit.sandLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: NomadKit.border),
              ),
              child: Row(
                children: [
                  Image.asset(
                    'assets/icons/icon_evaluation_rubric.png',
                    width: 28,
                    height: 28,
                    filterQuality: FilterQuality.medium,
                    errorBuilder: (ctx, err, stack) => const Icon(Icons.checklist_rounded, size: 24, color: NomadKit.sandDark),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Đánh giá thực hành tại quầy', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: NomadKit.ink)),
                        Text('Quan sát thao tác của Barista và tick tiêu chí chuẩn.', style: TextStyle(fontSize: 11, color: NomadKit.secondary)),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: NomadKit.sandDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    onPressed: () => go(context, const PracticalEvaluationPage()),
                    child: const Text('Chấm ngay', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Staff Training List
            const Text(
              'TIẾN ĐỘ TỪNG NHÂN SỰ TẠI CỬA HÀNG (FR-13)',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: NomadKit.sandDark, letterSpacing: 0.7),
            ),
            const SizedBox(height: 10),

            ..._staffList.map((st) {
              final int percent = st['readingPercent'] as int;
              final bool hasOverdue = st['hasOverdue'] as bool;
              final bool hasRelearn = st['hasRelearn'] as bool;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
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
                        Image.asset(
                          'assets/icons/icon_user_profile.png',
                          width: 36,
                          height: 36,
                          filterQuality: FilterQuality.medium,
                          errorBuilder: (ctx, err, stack) => const Icon(Icons.person_rounded, size: 24, color: NomadKit.sandDark),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(st['name'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: NomadKit.ink)),
                              Text(st['role'] as String, style: const TextStyle(fontSize: 11, color: NomadKit.secondary)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: percent >= 80 ? NomadKit.forestLight : NomadKit.warningLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$percent% đã học',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: percent >= 80 ? NomadKit.forest : NomadKit.warning,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Overdue / Relearn plain text notes (no background box)
                    if (hasOverdue && st['overdueTask'] != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          'Quá hạn: ${st['overdueTask']}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: NomadKit.error,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                    if (hasRelearn)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Text(
                          'Cần học lại: Trà Ô Long Sen Vàng cập nhật v2.1',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: NomadKit.warning,
                          ),
                        ),
                      ),

                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Thực hành: ${st['practicalStatus']}', style: const TextStyle(fontSize: 11.5, color: NomadKit.secondary)),
                        TextButton(
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 28),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () => go(context, const PracticalEvaluationPage()),
                          child: const Text('Chấm điểm', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: NomadKit.sandDark)),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _metricBox(String val, String label, {bool isWarning = false}) {
    return Column(
      children: [
        Text(
          val,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: isWarning ? NomadKit.error : NomadKit.ink,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: NomadKit.secondary)),
      ],
    );
  }
}
