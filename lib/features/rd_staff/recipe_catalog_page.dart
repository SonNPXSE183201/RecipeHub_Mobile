import 'package:flutter/material.dart';
import '../../core/theme/nomad_kit.dart';
import '../../core/utils/navigation.dart';
import '../../core/services/recipe_service.dart';
import '../../core/models/recipe_models.dart';
import 'recipe_detail_page.dart';
import 'recipe_editor_page.dart';

class RecipeCatalogPage extends StatefulWidget {
  const RecipeCatalogPage({super.key});

  @override
  State<RecipeCatalogPage> createState() => _RecipeCatalogPageState();
}

class _RecipeCatalogPageState extends State<RecipeCatalogPage> {
  int _filterIndex = 0; // 0: Tất cả, 1: Bản nháp, 2: Đã duyệt
  String _searchQuery = '';
  bool _isLoading = false;
  List<RecipeSummaryResponse> _recipes = [];

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    setState(() => _isLoading = true);
    try {
      final paged = await RecipeService.instance.searchRecipes(
        query: _searchQuery.isNotEmpty ? _searchQuery : null,
      );
      if (mounted) {
        setState(() {
          _recipes = paged.items;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredRecipes = _recipes.where((r) {
      final isDraft = r.versionStatus.toLowerCase() == 'draft';
      if (_filterIndex == 1) return isDraft;
      if (_filterIndex == 2) return !isDraft;
      return true;
    }).toList();

    final draftCount = _recipes.where((r) => r.versionStatus.toLowerCase() == 'draft').length;
    final approvedCount = _recipes.length - draftCount;

    return Material(
      color: NomadKit.canvas,
      child: RefreshIndicator(
        color: NomadKit.sand,
        onRefresh: _loadRecipes,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'THƯ VIỆN',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: NomadKit.sandDark,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Công thức',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: NomadKit.ink),
                  ),
                  if (_isLoading)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: NomadKit.sand),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Một bản nháp hoạt động cho mỗi công thức (Đồng bộ YARP Gateway :5000).',
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
                child: TextField(
                  onChanged: (val) {
                    _searchQuery = val;
                    _loadRecipes();
                  },
                  decoration: const InputDecoration(
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
                    _filterTab('Tất cả (${_recipes.length})', 0),
                    _filterTab('Bản nháp ($draftCount)', 1),
                    _filterTab('Đã duyệt ($approvedCount)', 2),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Recipe Cards List
              if (filteredRecipes.isEmpty && !_isLoading)
                Container(
                  padding: const EdgeInsets.all(32),
                  alignment: Alignment.center,
                  child: Column(
                    children: const [
                      Icon(Icons.coffee_maker_outlined, size: 48, color: NomadKit.sandDark),
                      SizedBox(height: 12),
                      Text(
                        'No matching formulas found.',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: NomadKit.ink),
                      ),
                    ],
                  ),
                )
              else
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
                      Text(
                        'Tạo công thức mới',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: NomadKit.sandDark),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
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

  Widget _recipeCard(RecipeSummaryResponse r) {
    final bool isDraft = r.versionStatus.toLowerCase() == 'draft';
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
              title: r.name,
              code: r.code,
              version: 'v${r.versionNumber}',
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
                          child: Text(
                            badgeLabel,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: badgeTextColor),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'v${r.versionNumber}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: NomadKit.secondary),
                        ),
                      ],
                    ),
                    Text(
                      r.code,
                      style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: NomadKit.secondary),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  r.name,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: NomadKit.ink),
                ),
                const SizedBox(height: 4),
                Text(
                  'Trạng thái: ${r.state} · Cập nhật: ${r.updatedAt.hour}:${r.updatedAt.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 12, color: NomadKit.secondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
