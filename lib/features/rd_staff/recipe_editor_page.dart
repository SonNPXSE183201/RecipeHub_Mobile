import 'package:flutter/material.dart';
import '../../core/theme/nomad_kit.dart';
import '../../core/widgets/screen_frame.dart';
import '../../core/utils/navigation.dart';
import 'recipe_review_page.dart';

class RecipeEditorPage extends StatefulWidget {
  const RecipeEditorPage({super.key});

  @override
  State<RecipeEditorPage> createState() => _RecipeEditorPageState();
}

class _RecipeEditorPageState extends State<RecipeEditorPage> {
  final _nameCtrl = TextEditingController(text: 'Trà Sữa Oolong Lài Kem Phô Mai');
  final _codeCtrl = TextEditingController(text: 'RC-OOL-03');
  final _portionCtrl = TextEditingController(text: '500 ml (Size L)');

  final List<Map<String, String>> _ingredients = [
    {'name': 'Cốt trà Ô Long Lài ủ lạnh', 'amount': '120 ml'},
    {'name': 'Sữa tươi thanh trùng DalatMilk', 'amount': '80 ml'},
    {'name': 'Siro đường mía organic', 'amount': '20 ml'},
    {'name': 'Lớp kem phô mai Macchiato', 'amount': '50 ml'},
  ];

  @override
  Widget build(BuildContext context) {
    return ScreenFrame(
      title: 'Tạo công thức mới',
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Gemini AI Assistant Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: NomadKit.oceanLight,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFBAE6FD)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.auto_awesome_rounded, color: NomadKit.ocean, size: 20),
                    SizedBox(width: 8),
                    Text('Trợ lý Gemini AI', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: NomadKit.ocean)),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Nhập ý tưởng món mới, Gemini sẽ tự động gợi ý định lượng thành phần và các bước chuẩn bị.',
                  style: TextStyle(fontSize: 12, color: NomadKit.ocean, height: 1.4),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 36,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: NomadKit.ocean,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Gemini AI đã cân bằng tỷ lệ đường & béo tối ưu cho 500ml.')),
                      );
                    },
                    icon: const Icon(Icons.bolt_rounded, size: 16),
                    label: const Text('Tối ưu tỷ lệ thành phần', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _inputField('Tên công thức', _nameCtrl),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _inputField('Mã SKU', _codeCtrl)),
              const SizedBox(width: 12),
              Expanded(child: _inputField('Định lượng ly', _portionCtrl)),
            ],
          ),
          const SizedBox(height: 20),

          // Ingredients List Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Thành phần & Định lượng', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: NomadKit.ink)),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _ingredients.add({'name': 'Thành phần mới', 'amount': '10 g'});
                  });
                },
                icon: const Icon(Icons.add_rounded, size: 16, color: NomadKit.sandDark),
                label: const Text('Thêm', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: NomadKit.sandDark)),
              ),
            ],
          ),
          const SizedBox(height: 6),

          ..._ingredients.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: NomadKit.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: NomadKit.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(item['name']!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: NomadKit.ink)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: NomadKit.sandLight, borderRadius: BorderRadius.circular(8)),
                    child: Text(item['amount']!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: NomadKit.sandDark)),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      setState(() {
                        if (_ingredients.length > 1) {
                          _ingredients.removeAt(idx);
                        }
                      });
                    },
                    child: const Icon(Icons.remove_circle_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 28),

          // Save & Review Button
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
              onPressed: () => go(context, const RecipeReviewPage()),
              child: const Text('Tiếp tục xem lại & Khóa v2', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputField(String label, TextEditingController ctrl) => Column(
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
              controller: ctrl,
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
