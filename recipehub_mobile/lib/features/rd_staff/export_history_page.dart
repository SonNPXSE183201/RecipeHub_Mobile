import 'package:flutter/material.dart';
import '../../core/theme/nomad_kit.dart';
import '../../core/widgets/screen_frame.dart';
import '../../core/utils/navigation.dart';
import 'batch_export_page.dart';

class ExportHistoryPage extends StatefulWidget {
  const ExportHistoryPage({super.key});

  @override
  State<ExportHistoryPage> createState() => _ExportHistoryPageState();
}

class _ExportHistoryPageState extends State<ExportHistoryPage> {
  final List<Map<String, dynamic>> _history = [
    {
      'title': 'RecipeHub_SOP_MasterBook_2026.pdf',
      'recipes': '3 món: Cold Brew Cam Quế, Ô Long Sen Vàng, Matcha Latte Mây',
      'date': '18/10/2026 · 09:15',
      'size': '2.4 MB',
      'type': 'Bộ SOP Tổng hợp',
      'isBatch': true,
    },
    {
      'title': 'SOP_ColdBrew_CamQue_v2.pdf',
      'recipes': '1 món: Cold Brew Cam Quế (v2 - Đã duyệt)',
      'date': '17/10/2026 · 14:30',
      'size': '850 KB',
      'type': 'SOP Đơn lẻ',
      'isBatch': false,
    },
    {
      'title': 'SOP_OLong_SenVang_v1.pdf',
      'recipes': '1 món: Ô Long Sen Vàng (v1 - Đã duyệt)',
      'date': '15/10/2026 · 10:20',
      'size': '790 KB',
      'type': 'SOP Đơn lẻ',
      'isBatch': false,
    },
  ];

  @override
  Widget build(BuildContext context) => ScreenFrame(
        title: 'Lịch sử xuất bản PDF',
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('KHO TÀI LIỆU SOP ĐÃ XUẤT BẢN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: NomadKit.sandDark, letterSpacing: 0.8)),
            const SizedBox(height: 4),
            const Text('Quản lý các ấn bản PDF SOP đã ban hành cho 45 chi nhánh.', style: TextStyle(fontSize: 13, color: NomadKit.secondary)),
            const SizedBox(height: 16),

            ..._history.map(
              (item) => Container(
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
                            color: item['isBatch'] ? NomadKit.sandLight : NomadKit.oceanLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            item['type'],
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: item['isBatch'] ? NomadKit.sandDark : NomadKit.ocean),
                          ),
                        ),
                        Text(item['size'], style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: NomadKit.secondary)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(item['title'], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: NomadKit.ink)),
                    const SizedBox(height: 4),
                    Text(item['recipes'], style: const TextStyle(fontSize: 12, color: NomadKit.secondary)),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(item['date'], style: const TextStyle(fontSize: 11, color: NomadKit.secondary)),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.share_outlined, size: 18, color: NomadKit.sandDark),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Đang chia sẻ tệp ${item['title']}...')),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.download_rounded, size: 20, color: NomadKit.sandDark),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Đang tải lại tệp ${item['title']}...')),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: NomadKit.sand,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => go(context, const BatchExportPage()),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Đóng gói bộ PDF mới', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      );
}
