import 'package:flutter/material.dart';
import '../../core/theme/nomad_kit.dart';
import '../../core/widgets/screen_frame.dart';

class IngredientEditPage extends StatefulWidget {
  const IngredientEditPage({
    super.key,
    required this.name,
    required this.code,
    this.isDiscontinued = false,
  });

  final String name, code;
  final bool isDiscontinued;

  @override
  State<IngredientEditPage> createState() => _IngredientEditPageState();
}

class _IngredientEditPageState extends State<IngredientEditPage> {
  late bool _deactivated;

  @override
  void initState() {
    super.initState();
    _deactivated = widget.isDiscontinued;
  }

  @override
  Widget build(BuildContext context) => ScreenFrame(
        title: 'Chỉnh sửa nguyên liệu',
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Warning Banner if used in recipes
            Container(
              padding: const EdgeInsets.all(14),
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
                      Icon(Icons.warning_amber_rounded, color: NomadKit.warning, size: 18),
                      SizedBox(width: 8),
                      Text('Ràng buộc dữ liệu công thức', style: TextStyle(fontWeight: FontWeight.w800, color: NomadKit.warning, fontSize: 13)),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Nguyên liệu này đang được dùng trong 3 công thức đang hoạt động. Không thể xóa cứng để bảo vệ tính toàn vẹn của lịch sử R&D.',
                    style: TextStyle(fontSize: 12, color: NomadKit.warning, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            _inputField('Tên nguyên liệu', widget.name),
            const SizedBox(height: 12),
            _inputField('Mã SKU', widget.code),
            const SizedBox(height: 12),
            _inputField('Đơn vị đo', 'g'),
            const SizedBox(height: 12),
            _inputField('Ngưỡng tồn kho an toàn', '1000'),
            const SizedBox(height: 16),

            // Deactivate Switch
            Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: Material(
                color: NomadKit.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: NomadKit.border),
                ),
                child: SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  activeTrackColor: NomadKit.sand,
                  title: const Text('Ngừng sử dụng (Deactivate)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: NomadKit.ink)),
                  subtitle: const Text('Ẩn khỏi danh sách tạo công thức mới nhưng giữ nguyên dữ liệu công thức cũ.', style: TextStyle(fontSize: 11, color: NomadKit.secondary)),
                  value: _deactivated,
                  onChanged: (v) => setState(() => _deactivated = v),
                ),
              ),
            ),
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
                    const SnackBar(content: Text('Đã cập nhật thông tin nguyên liệu thành công!')),
                  );
                  Navigator.pop(context);
                },
                child: const Text('Lưu thay đổi', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
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
