import 'package:flutter/material.dart';
import '../../core/theme/nomad_kit.dart';
import '../../core/widgets/screen_frame.dart';

class IngredientCreatePage extends StatelessWidget {
  const IngredientCreatePage({super.key});

  @override
  Widget build(BuildContext context) => ScreenFrame(
        title: 'Thêm nguyên liệu mới',
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _inputField('Tên nguyên liệu', 'Hạt Sen Huế ngâm đường'),
            const SizedBox(height: 14),
            _inputField('Mã SKU', 'ING-LOTUS-01'),
            const SizedBox(height: 14),
            _inputField('Đơn vị đo chuẩn', 'g (gram)'),
            const SizedBox(height: 14),
            _inputField('Ngưỡng tồn kho tối thiểu', '500'),
            const SizedBox(height: 14),
            _inputField('Nhà cung cấp / Xuất xứ', 'Đặc sản Huế - Đóng hộp 500g'),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: NomadKit.sand,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã thêm nguyên liệu mới vào danh mục chuỗi thành công!')),
                  );
                  Navigator.pop(context);
                },
                child: const Text('Lưu vào danh mục', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      );

  Widget _inputField(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: NomadKit.ink)),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: NomadKit.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: NomadKit.border),
            ),
            child: TextField(
              controller: TextEditingController(text: value),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              style: const TextStyle(fontSize: 14, color: NomadKit.ink),
            ),
          ),
        ],
      );
}
