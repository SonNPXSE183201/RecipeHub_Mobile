import 'package:flutter/material.dart';
import '../../core/theme/nomad_kit.dart';
import '../../core/widgets/recipe_hub_logo.dart';
import '../../core/utils/navigation.dart';
import 'booklet_reader_page.dart';
import 'barista_viewer_page.dart';
import 'brewing_timer_page.dart';

class ViewerHomePage extends StatefulWidget {
  const ViewerHomePage({super.key});

  @override
  State<ViewerHomePage> createState() => _ViewerHomePageState();
}

class _ViewerHomePageState extends State<ViewerHomePage> {
  int _categoryIndex = 0; // 0: Tất cả, 1: Cold Brew & Cafe, 2: Trà Sữa & Kem, 3: Topping

  final List<Map<String, dynamic>> _menuItems = [
    {
      'title': 'Cold Brew Cam Quế',
      'code': 'RC-CB-01',
      'status': 'Đã duyệt v2',
      'isDraft': false,
      'time': '45s',
      'temp': '4°C ướp lạnh',
      'category': 1,
      'bookPage': 2,
    },
    {
      'title': 'Ô Long Sen Vàng',
      'code': 'RC-OL-01',
      'status': 'Đã duyệt v1',
      'isDraft': false,
      'time': '60s',
      'temp': '85°C ủ trà',
      'category': 2,
      'bookPage': 4,
    },
    {
      'title': 'Matcha Latte Mây',
      'code': 'RC-MATCHA-01',
      'status': 'Bản nháp v3',
      'isDraft': true,
      'time': '80s',
      'temp': '75°C nước ấm',
      'category': 2,
      'bookPage': 6,
    },
    {
      'title': 'Trà Đào Cam Sả',
      'code': 'RC-PEACH-02',
      'status': 'Đã duyệt v2',
      'isDraft': false,
      'time': '50s',
      'temp': 'Đá viên 100g',
      'category': 2,
      'bookPage': 2,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _menuItems.where((item) {
      if (_categoryIndex == 0) return true;
      return item['category'] == _categoryIndex;
    }).toList();

    return Scaffold(
      backgroundColor: NomadKit.canvas,
      appBar: AppBar(
        backgroundColor: NomadKit.canvas,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: NomadKit.ink),
        ),
        title: Row(
          children: const [
            RecipeHubLogo(size: 28, iconSize: 16, radius: 8),
            SizedBox(width: 8),
            Text('Trang chủ Barista Chuỗi', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: NomadKit.ink)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Lật đọc Sổ tay SOP',
            icon: const Icon(Icons.menu_book_rounded, color: NomadKit.forest),
            onPressed: () => go(context, const BookletReaderPage()),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          // Store Branch Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: NomadKit.forestLight,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.storefront_rounded, color: NomadKit.forest, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('CHI NHÁNH LANDMARK 81', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: NomadKit.forest, letterSpacing: 0.6)),
                      Text('Menu Barista Ca Sáng', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: NomadKit.ink)),
                      Text('Đồng bộ phiên bản SOP Master 2026', style: TextStyle(fontSize: 11, color: NomadKit.secondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Big Interactive Booklet Banner
          Material(
            color: NomadKit.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: NomadKit.border),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => go(context, const BookletReaderPage()),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: NomadKit.sandLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: NomadKit.sand.withValues(alpha: 0.4)),
                      ),
                      child: const Center(
                        child: Icon(Icons.auto_stories_rounded, color: NomadKit.sandDark, size: 26),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('SỔ TAY SOP ĐIỆN TỬ 2026', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: NomadKit.sandDark, letterSpacing: 0.6)),
                          SizedBox(height: 2),
                          Text('Lật đọc Sách SOP Chuỗi', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: NomadKit.ink)),
                          Text('Hiệu ứng lật trang 3D · Mục lục 8 trang nhảy nhanh', style: TextStyle(fontSize: 11, color: NomadKit.secondary)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: NomadKit.sandDark),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),

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
                hintText: 'Tìm món theo tên hoặc mã...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Category Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _catPill('Tất cả món (4)', 0),
                const SizedBox(width: 8),
                _catPill('Cold Brew & Cafe (1)', 1),
                const SizedBox(width: 8),
                _catPill('Trà Sữa & Kem (3)', 2),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Menu Items List
          ...filtered.map(
            (item) => Container(
              margin: const EdgeInsets.symmetric(vertical: 5),
              child: Material(
                color: NomadKit.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: const BorderSide(color: NomadKit.border),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => go(context, const BaristaViewerPage()),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: item['isDraft'] ? NomadKit.warningLight : NomadKit.forestLight,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.local_cafe_rounded,
                            color: item['isDraft'] ? NomadKit.warning : NomadKit.forest,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: item['isDraft'] ? NomadKit.warningLight : NomadKit.forestLight,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      item['status'],
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: item['isDraft'] ? NomadKit.warning : NomadKit.forest,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(item['code'], style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: NomadKit.secondary)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(item['title'], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: NomadKit.ink)),
                              const SizedBox(height: 2),
                              Text('Chuẩn bị: ${item['time']} · Nhiệt độ: ${item['temp']}', style: const TextStyle(fontSize: 11, color: NomadKit.secondary)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.timer_outlined, color: NomadKit.sandDark, size: 22),
                          onPressed: () => go(context, const BrewingTimerPage()),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Step by step brewing quick button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: NomadKit.forest,
                side: const BorderSide(color: NomadKit.forest),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => go(context, const BrewingTimerPage()),
              icon: const Icon(Icons.play_circle_outline_rounded, size: 20),
              label: const Text('Bật chế độ Pha chế từng bước & Timer', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _catPill(String title, int idx) {
    final isSel = _categoryIndex == idx;
    return GestureDetector(
      onTap: () => setState(() => _categoryIndex = idx),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSel ? NomadKit.sand : NomadKit.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSel ? NomadKit.sand : NomadKit.border),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
            color: isSel ? Colors.white : NomadKit.secondary,
          ),
        ),
      ),
    );
  }
}
