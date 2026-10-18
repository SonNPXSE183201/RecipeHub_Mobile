import 'package:flutter/material.dart';
import '../../core/theme/nomad_kit.dart';
import '../../core/widgets/screen_frame.dart';
import '../../core/utils/navigation.dart';
import 'export_history_page.dart';

class PdfCoverPreviewPage extends StatelessWidget {
  const PdfCoverPreviewPage({super.key, this.recipeCount = 3});
  final int recipeCount;

  @override
  Widget build(BuildContext context) => ScreenFrame(
        title: 'Xem trước PDF SOP Master Book',
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // PDF COVER PREVIEW CARD
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: NomadKit.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: NomadKit.border),
                boxShadow: const [
                  BoxShadow(color: Color(0x0C000000), blurRadius: 16, offset: Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: NomadKit.sandLight, borderRadius: BorderRadius.circular(8)),
                    child: const Text('R&D MASTER BOOK · BAN HÀNH 2026', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: NomadKit.sandDark)),
                  ),
                  const SizedBox(height: 16),
                  const Text('SỔ TAY QUY TRÌNH PHA CHẾ CHUẨN', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: NomadKit.ink, height: 1.25)),
                  const SizedBox(height: 6),
                  const Text('Chuỗi Cà Phê & Trà Nomad · Phiên Bản Ban Hành Toàn Hệ Thống', style: TextStyle(fontSize: 12, color: NomadKit.secondary)),
                  const Divider(height: 32),

                  // Standard Table of Contents
                  const Text('MỤC LỤC TÀI LIỆU (TOC)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: NomadKit.sandDark, letterSpacing: 0.6)),
                  const SizedBox(height: 12),
                  _tocRow('Trang 01', 'Quy định an toàn & Vệ sinh quầy bar'),
                  _tocRow('Trang 02', 'Cold Brew Cam Quế (v2 - Đã duyệt)'),
                  _tocRow('Trang 03', 'Ô Long Sen Vàng (v1 - Đã duyệt)'),
                  _tocRow('Trang 04', 'Matcha Latte Mây (v3 - Bản nháp [Watermark])'),
                  _tocRow('Trang 05', 'Bảng quy chuẩn bảo quản & Hạn sử dụng nguyên liệu'),

                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: NomadKit.canvas, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: const [
                        Icon(Icons.verified_outlined, size: 16, color: NomadKit.forest),
                        SizedBox(width: 8),
                        Expanded(child: Text('Tài liệu đã được mã hóa bản quyền số chuỗi Nomad Hub.', style: TextStyle(fontSize: 11, color: NomadKit.forest, fontWeight: FontWeight.w600))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Download / Action Buttons
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
                    const SnackBar(content: Text('✓ Đã tải tệp PDF SOP Master Book về máy thành công!')),
                  );
                },
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text('Tải file PDF về máy', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: NomadKit.sandDark,
                  side: const BorderSide(color: NomadKit.sand),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => go(context, const ExportHistoryPage()),
                icon: const Icon(Icons.history_edu_rounded, size: 16),
                label: const Text('Mở Lịch sử xuất bản PDF', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      );

  Widget _tocRow(String page, String title) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Text(page, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: NomadKit.sandDark)),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 13, color: NomadKit.ink, fontWeight: FontWeight.w500))),
          ],
        ),
      );
}
