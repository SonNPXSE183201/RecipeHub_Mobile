import 'package:flutter/material.dart';
import '../../core/theme/nomad_kit.dart';
import '../../core/utils/navigation.dart';
import 'ingredient_create_page.dart';
import 'ingredient_edit_page.dart';

class IngredientsCatalogPage extends StatelessWidget {
  const IngredientsCatalogPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> ingredients = [
      {'name': 'Bột Matcha Uji Ceremonial', 'code': 'ING-001', 'unit': 'g', 'threshold': '500g', 'category': 'Bột trà', 'status': 'Hoạt động'},
      {'name': 'Cốt trà Ô Long Lài', 'code': 'ING-002', 'unit': 'ml', 'threshold': '2000ml', 'category': 'Cốt trà', 'status': 'Hoạt động'},
      {'name': 'Sữa tươi thanh trùng DalatMilk', 'code': 'ING-003', 'unit': 'ml', 'threshold': '5000ml', 'category': 'Sữa', 'status': 'Hoạt động'},
      {'name': 'Siro Đào Pomona', 'code': 'ING-004', 'unit': 'ml', 'threshold': '1000ml', 'category': 'Siro', 'status': 'Ngừng dùng'},
      {'name': 'Kem béo thực vật Rich', 'code': 'ING-005', 'unit': 'ml', 'threshold': '1500ml', 'category': 'Sữa', 'status': 'Hoạt động'},
    ];

    return Material(
      color: NomadKit.canvas,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('KHO NGUYÊN LIỆU', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: NomadKit.sandDark, letterSpacing: 0.8)),
          const SizedBox(height: 4),
          const Text('Nguyên liệu chuẩn', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: NomadKit.ink)),
          const SizedBox(height: 4),
          const Text('Chuẩn hóa đơn vị đo gram (g) và mililit (ml) toàn hệ thống.', style: TextStyle(fontSize: 13, color: NomadKit.secondary)),
          const SizedBox(height: 16),

          // Search Field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: NomadKit.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: NomadKit.border),
            ),
            child: const TextField(
              decoration: InputDecoration(
                icon: Icon(Icons.search_rounded, color: NomadKit.secondary, size: 20),
                hintText: 'Tìm kiếm nguyên liệu theo tên, SKU...',
                hintStyle: TextStyle(fontSize: 13, color: NomadKit.secondary),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Ingredients List
          ...ingredients.map(
            (ing) => Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: Material(
                color: NomadKit.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: NomadKit.border),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => go(
                    context,
                    IngredientEditPage(
                      name: ing['name'],
                      code: ing['code'],
                      isDiscontinued: ing['status'] == 'Ngừng dùng',
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: ing['status'] == 'Ngừng dùng' ? NomadKit.warningLight : NomadKit.sandLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            ing['unit'] == 'ml' ? Icons.water_drop_outlined : Icons.scale_outlined,
                            color: ing['status'] == 'Ngừng dùng' ? NomadKit.warning : NomadKit.sandDark,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(ing['name'], style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: NomadKit.ink)),
                              const SizedBox(height: 2),
                              Text('${ing['code']} · ${ing['category']} · Tồn an toàn: ${ing['threshold']}', style: const TextStyle(fontSize: 12, color: NomadKit.secondary)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: ing['status'] == 'Ngừng dùng' ? const Color(0xFFFEE2E2) : NomadKit.forestLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            ing['status'],
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: ing['status'] == 'Ngừng dùng' ? const Color(0xFFDC2626) : NomadKit.forest,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Add New Ingredient Button
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
              onPressed: () => go(context, const IngredientCreatePage()),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Thêm nguyên liệu mới', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    ),
  );
}
}
