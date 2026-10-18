import 'package:flutter/material.dart';
import '../../core/theme/nomad_kit.dart';
import '../../core/widgets/screen_frame.dart';

class RecipeReviewPage extends StatelessWidget {
  const RecipeReviewPage({super.key});

  @override
  Widget build(BuildContext context) => ScreenFrame(
        title: 'Xem lại & Khóa công thức',
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Warning/Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: NomadKit.warningLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFDE047)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Row(
                    children: [
                      Icon(Icons.shield_outlined, color: NomadKit.warning, size: 20),
                      SizedBox(width: 8),
                      Text('Kiểm tra trước khi ban hành v2', style: TextStyle(fontWeight: FontWeight.w800, color: NomadKit.warning, fontSize: 14)),
                    ],
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Sau khi bấm "Chốt & Khóa phiên bản v2", công thức sẽ trở thành bất biến và được áp dụng tới 45 chi nhánh. Mọi chỉnh sửa sau này bắt buộc phải tạo bản nháp v3 mới.',
                    style: TextStyle(fontSize: 12, color: NomadKit.warning, height: 1.45),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Recipe Overview Card
            Container(
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
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: NomadKit.forestLight, borderRadius: BorderRadius.circular(10)),
                        child: const Text('Chuẩn bị khóa: v2.0', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: NomadKit.forest)),
                      ),
                      const Text('RC-OOL-03', style: TextStyle(fontSize: 12, fontFamily: 'monospace', color: NomadKit.secondary)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text('Trà Sữa Oolong Lài Kem Phô Mai', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: NomadKit.ink)),
                  const SizedBox(height: 4),
                  const Text('Định lượng 500 ml · 4 thành phần · 120 cal', style: TextStyle(fontSize: 13, color: NomadKit.secondary)),
                  const Divider(height: 20),
                  _checkItem('Tất cả nguyên liệu đều có sẵn trong kho toàn chuỗi'),
                  _checkItem('Đã kiểm thử cảm quan đạt chuẩn độ ngọt và hậu vị'),
                  _checkItem('Quy trình pha chế tối ưu dưới 60 giây tại quầy bar'),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Confirm Lock Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: NomadKit.forest,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✓ Đã chốt và khóa thành công phiên bản v2! Sẵn sàng xuất bản.')),
                  );
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.lock_rounded, size: 18),
                label: const Text('Chốt & Khóa phiên bản v2', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      );

  Widget _checkItem(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.check_circle_rounded, color: NomadKit.forest, size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: NomadKit.ink, height: 1.3))),
          ],
        ),
      );
}
