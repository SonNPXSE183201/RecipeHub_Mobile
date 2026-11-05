import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/nomad_kit.dart';
import '../../core/models/app_models.dart';
import '../../core/navigation/app_keys.dart';
import '../../core/services/mock_data_service.dart';
import '../../core/viewmodels/app_config_viewmodel.dart';
import '../../core/viewmodels/recipe_viewmodel.dart';
import '../../core/utils/navigation.dart';
import '../sop/sop_catalog_page.dart';
import 'recipe_detail_size_page.dart';
import '../practice/self_practice_timer_page.dart';

class CounterRecipeLookupPage extends StatefulWidget {
  const CounterRecipeLookupPage({super.key});

  @override
  State<CounterRecipeLookupPage> createState() => _CounterRecipeLookupPageState();
}

class _CounterRecipeLookupPageState extends State<CounterRecipeLookupPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedCategory = 'Tất cả';

  final List<String> _categories = ['Tất cả', 'Cà phê & Cold Brew', 'Trà Sữa & Kem Mây', 'Trà Trái Cây'];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Danh sách lấy từ RecipeViewModel (watch) để tự cập nhật khi tải lại ngầm;
    // Remote Config `max_lookup_results` giới hạn số công thức hiển thị.
    final allRecipes = context
        .watch<RecipeViewModel>()
        .items
        .take(context.watch<AppConfigViewModel>().maxLookupResults)
        .toList();
    final query = _searchCtrl.text.trim().toLowerCase();

    final filtered = allRecipes.where((r) {
      final matchesCategory = _selectedCategory == 'Tất cả' || r.category == _selectedCategory;
      final matchesQuery =
          query.isEmpty || r.name.toLowerCase().contains(query) || r.code.toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();

    return Scaffold(
      backgroundColor: NomadKit.canvas,
      body: SafeArea(
        child: Column(
          children: [
            // Top Section: Store Info & Search
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              color: NomadKit.canvas,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Store & Shift Badge
                  Row(
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: NomadKit.forestLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                'assets/icons/icon_store_branch.png',
                                width: 18,
                                height: 18,
                                filterQuality: FilterQuality.medium,
                                errorBuilder: (ctx, err, stack) =>
                                    const Icon(Icons.storefront_rounded, size: 14, color: NomadKit.forest),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  MockDataService.instance.currentStoreBranch,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: NomadKit.forest,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Independent lookup rule badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: NomadKit.sandLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: NomadKit.border),
                        ),
                        child: const Text(
                          'Tra cứu độc lập',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: NomadKit.sandDark),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Headline
                  const Text(
                    'Tra cứu tại quầy',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: NomadKit.ink,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Tra cứu đúng công thức và định lượng tiêu chuẩn, không bị chặn bởi tiến độ học.',
                    style: TextStyle(fontSize: 12, color: NomadKit.secondary),
                  ),
                  const SizedBox(height: 14),

                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: NomadKit.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: NomadKit.border),
                      boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 2))],
                    ),
                    child: TextField(
                      key: AppKeys.recipeSearch,
                      controller: _searchCtrl,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(fontSize: 14, color: NomadKit.ink),
                      decoration: InputDecoration(
                        hintText: 'Tìm theo tên món hoặc mã món (vd: Cold Brew, RC-CB-01)...',
                        hintStyle: const TextStyle(fontSize: 13, color: NomadKit.secondary),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(11),
                          child: Image.asset(
                            'assets/icons/icon_search.png',
                            width: 22,
                            height: 22,
                            filterQuality: FilterQuality.medium,
                            errorBuilder: (ctx, err, stack) =>
                                const Icon(Icons.search_rounded, color: NomadKit.sand, size: 22),
                          ),
                        ),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18, color: NomadKit.secondary),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Categories & SOP Shortcut Row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // Quick SOP button
                        ActionChip(
                          avatar: Image.asset(
                            'assets/icons/icon_sop_protocol.png',
                            width: 20,
                            height: 20,
                            filterQuality: FilterQuality.medium,
                            errorBuilder: (ctx, err, stack) =>
                                const Icon(Icons.menu_book_rounded, size: 16, color: NomadKit.ocean),
                          ),
                          label: const Text(
                            'Thư viện SOP',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: NomadKit.ocean),
                          ),
                          backgroundColor: NomadKit.oceanLight,
                          side: BorderSide(color: NomadKit.ocean.withOpacity(0.3)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          onPressed: () => go(context, const SopCatalogPage()),
                        ),
                        const SizedBox(width: 8),

                        ..._categories.map((cat) {
                          final isSelected = _selectedCategory == cat;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(
                                cat,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected ? Colors.white : NomadKit.ink,
                                ),
                              ),
                              selected: isSelected,
                              selectedColor: NomadKit.sandDark,
                              backgroundColor: NomadKit.surface,
                              side: BorderSide(color: isSelected ? NomadKit.sandDark : NomadKit.border),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              showCheckmark: false,
                              onSelected: (val) {
                                if (val) setState(() => _selectedCategory = cat);
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: NomadKit.border),

            // Recipe List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/illustrations/empty_search_2k.png',
                            width: 140,
                            height: 140,
                            fit: BoxFit.contain,
                            errorBuilder: (ctx, err, stack) =>
                                const Icon(Icons.search_off_rounded, size: 80, color: NomadKit.secondary),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Không tìm thấy công thức phù hợp',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: NomadKit.ink),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Thử đổi từ khóa hoặc bộ lọc danh mục.',
                            style: TextStyle(fontSize: 13, color: NomadKit.secondary),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
                      itemCount: filtered.length,
                      itemBuilder: (context, idx) {
                        final recipe = filtered[idx];
                        return _buildRecipeCard(context, recipe);
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: NomadKit.sand,
        foregroundColor: Colors.white,
        elevation: 3,
        icon: Image.asset(
          'assets/icons/icon_timer_brew.png',
          width: 22,
          height: 22,
          filterQuality: FilterQuality.medium,
          errorBuilder: (ctx, err, stack) => const Icon(Icons.timer_outlined, size: 20),
        ),
        label: const Text('Tự luyện quầy bar', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        onPressed: () => go(context, const SelfPracticeTimerPage()),
      ),
    );
  }

  Widget _buildRecipeCard(BuildContext context, RecipeItem recipe) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: NomadKit.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: NomadKit.border),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 3))],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          key: AppKeys.recipeCard(recipe.id),
          onTap: () => go(context, RecipeDetailSizePage(recipe: recipe)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Code + Status Chip + Version
                Row(
                  children: [
                    Image.asset(
                      'assets/icons/icon_recipe_book.png',
                      width: 22,
                      height: 22,
                      filterQuality: FilterQuality.medium,
                      errorBuilder: (ctx, err, stack) =>
                          const Icon(Icons.receipt_long_rounded, size: 20, color: NomadKit.sandDark),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: NomadKit.sandLight, borderRadius: BorderRadius.circular(8)),
                      child: Text(
                        recipe.code,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'monospace',
                          color: NomadKit.sandDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: NomadKit.forestLight, borderRadius: BorderRadius.circular(8)),
                      child: Text(
                        '${recipe.status} · ${recipe.version}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: NomadKit.forest),
                      ),
                    ),
                    const Spacer(),
                    if (recipe.hasNewerVersion)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: NomadKit.warningLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: NomadKit.warning.withOpacity(0.3)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.fiber_new_rounded, size: 14, color: NomadKit.warning),
                            SizedBox(width: 4),
                            Text(
                              'Có bản mới',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: NomadKit.warning),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Title & Description
                Text(
                  recipe.name,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: NomadKit.ink),
                ),
                const SizedBox(height: 4),
                Text(
                  recipe.description,
                  style: const TextStyle(fontSize: 13, color: NomadKit.secondary, height: 1.35),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 14),

                // Category & Metrics Bar (Không dùng Size)
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: NomadKit.canvas,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: NomadKit.border),
                              ),
                              child: Text(
                                recipe.category,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: NomadKit.ink),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: NomadKit.canvas,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: NomadKit.border),
                            ),
                            child: Text(
                              '${recipe.steps.length} bước chuẩn',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: NomadKit.secondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Time & Temp Icons
                    Row(
                      children: [
                        const Icon(Icons.timer_outlined, size: 15, color: NomadKit.secondary),
                        const SizedBox(width: 4),
                        Text(
                          recipe.standardTime,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: NomadKit.secondary),
                        ),
                        const SizedBox(width: 10),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: NomadKit.secondary),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
