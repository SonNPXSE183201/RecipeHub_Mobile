import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/nomad_kit.dart';
import '../../core/models/app_models.dart';
import '../../core/models/session_models.dart';
import '../../core/navigation/app_keys.dart';
import '../../core/services/recipe_bookmark_store.dart';
import '../../core/viewmodels/auth_viewmodel.dart';
import '../../core/viewmodels/recipe_bookmark_viewmodel.dart';
import '../../core/widgets/load_state_view.dart';
import '../../core/widgets/redesign_widgets.dart';
import '../../core/viewmodels/app_config_viewmodel.dart';
import '../../core/viewmodels/recipe_viewmodel.dart';
import '../../core/utils/navigation.dart';
import 'recipe_detail_size_page.dart';
import '../practice/self_practice_timer_page.dart';
import '../learning/notifications_page.dart';
import '../../core/viewmodels/training_viewmodel.dart';
import '../sop/sop_detail_page.dart';
import '../sop_book/sop_book_page.dart';
import '../../core/widgets/recipe_thumb.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/rh_motion.dart';

class CounterRecipeLookupPage extends StatefulWidget {
  const CounterRecipeLookupPage({super.key});

  @override
  State<CounterRecipeLookupPage> createState() =>
      _CounterRecipeLookupPageState();
}

class _CounterRecipeLookupPageState extends State<CounterRecipeLookupPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedCategory = 'Tất cả';
  bool _sopMode = false;
  Timer? _debounce;
  String _remoteQuery = '';
  List<RecipeItem> _remote = const [];
  static const _savedLabel = 'Đã lưu';
  RecipeBookmarkViewModel? _bookmarks;

  @override
  void initState() {
    super.initState();
    String? uid;
    try {
      uid = context.read<TrainingViewModel>().uid;
    } catch (_) {
      uid = null;
    }
    _bookmarks =
        RecipeBookmarkViewModel(
          store: const PrefsRecipeBookmarkStore(),
          uid: uid,
        )..addListener(() {
          if (mounted) setState(() {});
        });
    _bookmarks!.load();
  }

  bool _matchesCategory(RecipeItem r) =>
      _selectedCategory == 'Tất cả' ||
      (_selectedCategory == _savedLabel
          ? (_bookmarks?.isBookmarked(r.code) ?? false)
          : r.category == _selectedCategory);

  @override
  void dispose() {
    _bookmarks?.dispose();
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Sau 400ms ngừng gõ: hỏi server để tìm cả món ngoài danh sách đã tải.
  void _onQueryChanged() {
    setState(() {});
    _debounce?.cancel();
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) {
      setState(() => _remote = const []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      final found = await context.read<RecipeViewModel>().searchAll(q);
      if (!mounted || _searchCtrl.text.trim() != q) return;
      setState(() {
        _remoteQuery = q;
        _remote = found;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Danh sách lấy từ RecipeViewModel (watch) để tự cập nhật khi tải lại ngầm;
    // Remote Config `max_lookup_results` giới hạn số công thức hiển thị.
    final recipeVm = context.watch<RecipeViewModel>();
    // Remote Config `max_lookup_results` chỉ giới hạn danh sách mặc định; tìm kiếm / lọc nhóm quét toàn bộ món.
    final maxResults = context.watch<AppConfigViewModel>().maxLookupResults;
    final allRecipes = recipeVm.items;
    final categories = [
      'Tất cả',
      _savedLabel,
      ...{for (final r in allRecipes) r.category}.where((c) => c.isNotEmpty),
    ];
    if (!categories.contains(_selectedCategory)) _selectedCategory = 'Tất cả';
    // Không phân biệt dấu: "bac xiu" tìm được "Bạc Xỉu".
    final query = _searchCtrl.text.trim();
    final browsing = query.isEmpty && _selectedCategory == 'Tất cả';

    final filtered = (browsing ? allRecipes.take(maxResults) : allRecipes)
        .where((r) {
          final matchesCategory = _matchesCategory(r);
          final matchesQuery = RecipeViewModel.matchesQuery(r, query);
          return matchesCategory && matchesQuery;
        })
        .toList();
    if (query.isNotEmpty && _remoteQuery == _searchCtrl.text.trim()) {
      final shown = {for (final r in filtered) r.code};
      filtered.addAll(
        _remote.where((r) => !shown.contains(r.code) && _matchesCategory(r)),
      );
    }

    final content = allRecipes.isEmpty && recipeVm.state == ViewState.error
        ? LoadStateView.error(
            message: recipeVm.error ?? 'Không tải được danh sách công thức.',
            onRetry: recipeVm.load,
          )
        : allRecipes.isEmpty && recipeVm.state == ViewState.empty
        ? const LoadStateView.empty(
            message: 'Chưa có công thức nào được ban hành.',
            icon: Icons.local_cafe_outlined,
          )
        : allRecipes.isEmpty
        ? const LoadStateView.loading()
        : filtered.isEmpty
        ? const LoadStateView.empty(
            message: 'Không tìm thấy công thức phù hợp.',
            icon: Icons.search_off_rounded,
          )
        : ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: filtered.length,
            itemBuilder: (context, idx) =>
                _buildRecipeCard(context, filtered[idx]),
          );

    final training = context.watch<TrainingViewModel>();
    final sops = training.sops
        .where(
          (s) =>
              query.isEmpty ||
              s.title.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
    final sopContent =
        training.sopState == LoadState.error && training.sops.isEmpty
        ? LoadStateView.error(
            message: training.error ?? 'Không tải được quy trình SOP.',
            onRetry: training.retry,
          )
        : training.sops.isEmpty && training.sopState == LoadState.loading
        ? const LoadStateView.loading()
        : training.sops.isEmpty
        ? const LoadStateView.empty(message: 'Chưa có SOP nào được ban hành.')
        : sops.isEmpty
        ? const LoadStateView.empty(
            message: 'Không tìm thấy quy trình phù hợp.',
          )
        : ListView.separated(
            padding: const EdgeInsets.only(bottom: 20),
            itemCount: sops.length,
            separatorBuilder: (_, _) => const SizedBox(height: 2),
            itemBuilder: (context, i) => _sopTile(context, sops[i], i + 1),
          );

    return Scaffold(
      backgroundColor: NomadKit.canvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            RhBrandHeader(
              trailing: IconButton(
                key: AppKeys.notificationBell,
                tooltip: 'Thông báo',
                onPressed: () => go(context, const NotificationsPage()),
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: NomadKit.sandDark,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Column(
                  children: [
                    Container(
                      height: 54,
                      decoration: BoxDecoration(
                        color: NomadKit.sandLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        key: AppKeys.recipeSearch,
                        controller: _searchCtrl,
                        onChanged: (_) => _onQueryChanged(),
                        style: NomadKit.body.copyWith(fontSize: 16),
                        decoration: InputDecoration(
                          hintText: _sopMode
                              ? 'Tìm quy trình...'
                              : 'Tìm công thức...',
                          hintStyle: NomadKit.body.copyWith(
                            fontSize: 16,
                            color: NomadKit.secondary,
                          ),
                          prefixIcon: const Padding(
                            padding: EdgeInsets.all(16.5),
                            child: RhSvgIcon(
                              'assets/redesign/search.svg',
                              size: 21,
                            ),
                          ),
                          suffixIcon: _searchCtrl.text.isEmpty
                              ? null
                              : IconButton(
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    _onQueryChanged();
                                  },
                                  icon: const Icon(Icons.close, size: 18),
                                ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 52,
                      child: LayoutBuilder(
                        builder: (context, box) {
                          final tabW = (box.maxWidth - 20) / 2;
                          return Stack(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _documentTab(
                                      'Công thức',
                                      !_sopMode,
                                      () => setState(() => _sopMode = false),
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: _documentTab(
                                      'SOP',
                                      _sopMode,
                                      () => setState(() => _sopMode = true),
                                    ),
                                  ),
                                ],
                              ),
                              // Gạch chân trượt giữa 2 tab (prototype: 180ms)
                              AnimatedPositioned(
                                duration: RhMotion.reduced(context)
                                    ? Duration.zero
                                    : RhMotion.tab,
                                curve: Curves.easeInOut,
                                left: _sopMode ? tabW + 20 : 0,
                                bottom: 0,
                                width: tabW,
                                height: 3,
                                child: IgnorePointer(
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: NomadKit.sandDark,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    if (!_sopMode)
                      SizedBox(
                        height: 62,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.only(top: 14, bottom: 8),
                          itemCount: categories.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (_, index) {
                            final cat = categories[index];
                            final selected = cat == _selectedCategory;
                            return ChoiceChip(
                              label: Text(cat),
                              selected: selected,
                              onSelected: (_) =>
                                  setState(() => _selectedCategory = cat),
                              showCheckmark: false,
                              selectedColor: NomadKit.sandDark,
                              backgroundColor: NomadKit.canvas,
                              labelStyle: NomadKit.label.copyWith(
                                color: selected
                                    ? Colors.white
                                    : NomadKit.secondary,
                              ),
                              side: BorderSide(
                                color: selected
                                    ? NomadKit.sandDark
                                    : NomadKit.border,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            );
                          },
                        ),
                      ),
                    if (_sopMode)
                      _bookRows(
                        recipeCount: allRecipes.length,
                        sopCount: training.sops.length,
                      ),
                    RhSectionHeading(
                      title: _sopMode
                          ? 'Quy trình tại quầy'
                          : 'Công thức đồ uống',
                      trailing: _sopMode
                          ? '${sops.length} quy trình'
                          : '${filtered.length} món',
                    ),
                    Expanded(child: _sopMode ? sopContent : content),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: !context.watch<AuthViewModel>().hasPersonalLearning
          ? null
          : Semantics(
              label: 'Tự luyện quầy bar',
              button: true,
              child: FloatingActionButton(
                key: AppKeys.selfPracticeFab,
                tooltip: 'Tự luyện quầy bar',
                shape: const CircleBorder(),
                backgroundColor: NomadKit.sand,
                foregroundColor: Colors.white,
                onPressed: () => go(context, const SelfPracticeTimerPage()),
                child: const Icon(Icons.timer_outlined),
              ),
            ),
    );
  }

  Widget _bookRows({required int recipeCount, required int sopCount}) {
    void open() => go(context, const SopBookPage());
    return Column(
      children: [
        InkWell(
          onTap: open,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 70),
            child: Row(
              children: [
                const RhSvgIcon('assets/redesign/book.svg', size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sổ tay công thức & SOP', style: NomadKit.subtitle),
                      Text(
                        '$recipeCount công thức · $sopCount SOP',
                        style: NomadKit.caption,
                      ),
                    ],
                  ),
                ),
                const RhChevron(),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        InkWell(
          onTap: open,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Row(
              children: [
                const SizedBox(width: 36),
                Expanded(
                  child: Text(
                    'Mục lục, tìm kiếm & PDF',
                    style: NomadKit.caption.copyWith(
                      color: NomadKit.ink,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const RhChevron(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _sopTile(BuildContext context, SopItem sop, int index) => PressScale(
    child: Material(
    color: NomadKit.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: const BorderSide(color: NomadKit.border),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => go(context, SopDetailPage(sop: sop)),
      child: SizedBox(
        height: 78,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              SizedBox(
                width: 44,
                child: Text(
                  index.toString().padLeft(2, '0'),
                  style: NomadKit.caption.copyWith(color: NomadKit.sandDark),
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sop.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: NomadKit.label.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text('${sop.steps.length} bước', style: NomadKit.caption),
                  ],
                ),
              ),
              const RhChevron(),
            ],
          ),
        ),
      ),
    ),
    ),
  );

  Widget _documentTab(String label, bool selected, VoidCallback? onTap) =>
      PressScale(
       child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: Center(
                child: Text(
                  label,
                  style: NomadKit.body.copyWith(
                    fontSize: 16,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected ? NomadKit.sandDark : NomadKit.secondary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 3),
          ],
        ),
       ),
      );

  Widget _buildRecipeCard(BuildContext context, RecipeItem recipe) {
    return Container(
      constraints: const BoxConstraints(minHeight: 110),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: NomadKit.lineSoft)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: AppKeys.recipeCard(recipe.id),
          onTap: () async {
            await Navigator.push(
              context,
              RhPageRoute(
                builder: (_) => RecipeDetailSizePage(recipe: recipe),
              ),
            );
            if (mounted) _bookmarks?.load();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                RecipeThumb(imageUrl: recipe.imageUrl),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipe.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: NomadKit.subtitle.copyWith(
                          fontSize: 16,
                          height: 23 / 16,
                        ),
                      ),
                      Text(recipe.category, style: NomadKit.caption),
                      Text(
                        '${recipe.standardTime} · ${recipe.steps.length} bước',
                        style: NomadKit.caption,
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 48,
                  height: 48,
                  child: IconButton(
                    tooltip: 'Lưu công thức',
                    onPressed: () async {
                      final messenger = ToastMessenger.of(context);
                      final saved = await _bookmarks?.toggle(recipe.code);
                      if (!mounted || saved == null) return;
                      messenger
                        ..clearSnackBars()
                        ..showSnackBar(
                          SnackBar(
                            content: Text(
                              saved
                                  ? 'Đã lưu ${recipe.name}'
                                  : 'Đã bỏ lưu ${recipe.name}',
                            ),
                          ),
                        );
                    },
                    icon: SvgPicture.asset(
                      'assets/redesign/bookmark.svg',
                      width: 19,
                      height: 19,
                      colorFilter:
                          (_bookmarks?.isBookmarked(recipe.code) ?? false)
                          ? const ColorFilter.mode(
                              NomadKit.sandDark,
                              BlendMode.srcIn,
                            )
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
