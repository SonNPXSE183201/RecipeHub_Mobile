import 'package:flutter/material.dart';
import '../../core/theme/nomad_kit.dart';
import '../../core/widgets/screen_frame.dart';
import '../../core/utils/navigation.dart';
import 'recipe_review_page.dart';

class PdfDraftPreviewPage extends StatelessWidget {
  const PdfDraftPreviewPage({
    super.key,
    this.recipeName = 'Matcha Latte Mây',
    this.version = 'v3',
    this.code = 'RC-MATCHA-01',
  });

  final String recipeName;
  final String version;
  final String code;

  @override
  Widget build(BuildContext context) => ScreenFrame(
        title: 'Xem trước PDF công thức',
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Watermark Warning Banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: NomadKit.warningLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFDE047)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.warning_amber_rounded, color: NomadKit.warning, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tài liệu này thuộc bản nháp chưa khóa. Dấu Watermark BẢN NHÁP sẽ được tự động đóng chìm bảo vệ an toàn pha chế.',
                      style: TextStyle(fontSize: 12, color: NomadKit.warning, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // SIMULATED PDF A4 PAGE WITH WATERMARK OVERLAY
            Container(
              height: 400,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: NomadKit.border),
                boxShadow: const [
                  BoxShadow(color: Color(0x10000000), blurRadius: 16, offset: Offset(0, 4)),
                ],
              ),
              child: Stack(
                children: [
                  // Document Content
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('NOMAD R&D LAB · SOP SHEET', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: NomadKit.sandDark)),
                            Text('$code · $version', style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: NomadKit.secondary)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(recipeName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: NomadKit.ink)),
                        const SizedBox(height: 6),
                        const Text('Định lượng 500 ml · Thời gian chuẩn bị: 60s', style: TextStyle(fontSize: 12, color: NomadKit.secondary)),
                        const Divider(height: 24),
                        const Text('1. Bột Matcha Uji: 5g hòa tan 40ml nước 75°C', style: TextStyle(fontSize: 12, height: 1.5, color: NomadKit.ink)),
                        const Text('2. Sữa tươi thanh trùng Barista: 150ml', style: TextStyle(fontSize: 12, height: 1.5, color: NomadKit.ink)),
                        const Text('3. Siro đường mía: 15ml', style: TextStyle(fontSize: 12, height: 1.5, color: NomadKit.ink)),
                        const Text('4. Kem sữa muối biển: 60ml phủ mặt ly', style: TextStyle(fontSize: 12, height: 1.5, color: NomadKit.ink)),
                        const Spacer(),
                        const Center(child: Text('Trang 1 / 1 · Bản nháp lưu hành nội bộ R&D', style: TextStyle(fontSize: 10, color: NomadKit.secondary))),
                      ],
                    ),
                  ),

                  // Diagonal Draft Watermark Overlay
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Center(
                        child: Transform.rotate(
                          angle: -0.45,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0x40CA8A04), width: 3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'BẢN NHÁP · DRAFT ONLY',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Color(0x50CA8A04),
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Actions
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: NomadKit.sand,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✓ Đã tải bản PDF nháp kèm Watermark về máy!')),
                  );
                },
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text('Tải bản PDF nháp', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: NomadKit.forest,
                  side: const BorderSide(color: NomadKit.forest),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => go(context, const RecipeReviewPage()),
                icon: const Icon(Icons.verified_outlined, size: 16),
                label: const Text('Tiến hành Kiểm tra & Chốt v2', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      );
}
