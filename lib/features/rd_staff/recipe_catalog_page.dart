import 'package:flutter/material.dart';
import '../../core/theme/nomad_kit.dart';
import '../../core/utils/navigation.dart';
import 'recipe_detail_page.dart';
import 'recipe_editor_page.dart';

class RecipeCatalogPage extends StatefulWidget {
  const RecipeCatalogPage({super.key});

  @override
  State<RecipeCatalogPage> createState() => _RecipeCatalogPageState();
}

class _RecipeCatalogPageState extends State<RecipeCatalogPage> {
  int _filterIndex = 0; // 0: Tất cả, 1: Bản nháp, 2: Đã duyệt

  final List<Map<String, dynamic>> _allRecipes = [
    {
      'title': 'Matcha Latte Mây',
      'code': 'RC-MATCHA-01',
      'category': 'Trà sữa',
      'version': 'v3',
      'isDraft': true,
      'portions': '500 ml',
      'ingredients': '4 thành phần',
    },
    {
      'title': 'Cold Brew Cam Quế',
      'code': 'RC-COLD-02',
      'category': 'Cà phê',
      'version': 'v2',
      'isDraft': false,
      'portions': '350 ml',
      'ingredients': '4 thành phần',
    },
    {
      'title': 'Ô Long Sen Vàng',
      'code': 'RC-OOL-01',
      'category': 'Trà sữa',
      'version': 'v1',
      'isDraft': false,
      'portions': '500 ml',
      'ingredients': '5 thành phần',
    },
    {
      'title': 'Trà Đào Cam Sả',
      'code': 'RC-PEACH-02',
      'category': 'Trà trái cây',
      'version': 'v2',
      'isDraft': false,
      'portions': '500 ml',
      'ingredients': '4 thành phần',
    },
    {
      'title': 'Cà Phê Muối Biển',
      'code': 'RC-SALT-03',
      'category': 'Cà phê',
      'version': 'v1',
      'isDraft': true,
      'portions': '300 ml',
      'ingredients': '3 thành phần',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filteredRecipes = _allRecipes.where((r) {
      if (_filterIndex == 1) return r['isDraft'] == true;
      if (_filterIndex == 2) return r['isDraft'] == false;
      return true;
    }).toList();

    return Material(
      color: NomadKit.canvas,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          const Text(
            'THƯ VIỆN',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: NomadKit.sandDark, letterSpacing: 0.8),
          ),
          const SizedBox(height: 4),
          const Text(
            'Công thức',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: NomadKit.ink),
          ),
          const SizedBox(height: 4),
          const Text(
            'Một bản nháp hoạt động cho mỗi công thức.',
            style: TextStyle(fontSize: 13, color: NomadKit.secondary),
          ),
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
                hintText: 'Tìm kiếm theo tên hoặc mã công thức...',
                hintStyle: TextStyle(fontSize: 13, color: NomadKit.secondary),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Filter Segment Tabs
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: NomadKit.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: NomadKit.border),
            ),
            child: Row(
              children: [
                _filterTab('Tất cả (5)', 0),
                _filterTab('Bản nháp (2)', 1),
                _filterTab('Đã duyệt (3)', 2),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Recipe Cards List
          ...filteredRecipes.map((r) => _recipeCard(r)),

          const SizedBox(height: 16),

          // Add New Recipe Floating Banner
          InkWell(
            onTap: () => go(context, const RecipeEditorPage()),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: NomadKit.sandLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: NomadKit.sandDark.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.add_circle_outline_rounded, color: NomadKit.sandDark, size: 18),
                  SizedBox(width: 8),
                  Text('Tạo công thức mới', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: NomadKit.sandDark)),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _filterTab(String label, int index) {
    final isSelected = _filterIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _filterIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? NomadKit.sand : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? Colors.white : NomadKit.secondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _recipeCard(Map<String, dynamic> r) {
    final bool isDraft = r['isDraft'];
    final badgeColor = isDraft ? NomadKit.warningLight : NomadKit.forestLight;
    final badgeTextColor = isDraft ? NomadKit.warning : NomadKit.forest;
    final badgeLabel = isDraft ? 'Bản nháp' : 'Đã duyệt';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Material(
        color: NomadKit.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: NomadKit.border),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => go(
            context,
            RecipeDetailPage(
              title: r['title'],
              code: r['code'],
              version: r['version'],
              isDraft: isDraft,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(12)),
                          child: Text(badgeLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: badgeTextColor)),
                        ),
                        const SizedBox(width: 8),
                        Text(r['version'], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: NomadKit.secondary)),
                      ],
                    ),
                    Text(r['code'], style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: NomadKit.secondary)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(r['title'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: NomadKit.ink)),
                const SizedBox(height: 4),
                Text('${r['category']} · ${r['portions']} · ${r['ingredients']}', style: const TextStyle(fontSize: 12, color: NomadKit.secondary)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
