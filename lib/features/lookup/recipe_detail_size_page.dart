import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/nomad_kit.dart';
import '../../core/di/app_services.dart';
import '../../core/models/app_models.dart';
import '../../core/utils/navigation.dart';
import '../../core/utils/video_time.dart';
import 'step_video_guide_page.dart';
import '../practice/self_practice_timer_page.dart';
import '../feedback/create_feedback_page.dart';
import '../sop/sop_detail_page.dart';
import '../../core/viewmodels/training_viewmodel.dart';
import '../../core/viewmodels/recipe_bookmark_viewmodel.dart';
import '../../core/services/interfaces/i_recipe_bookmark_store.dart';
import '../../core/services/recipe_bookmark_store.dart';

class RecipeDetailSizePage extends StatefulWidget {
  const RecipeDetailSizePage({
    super.key,
    required this.recipe,
    this.initialSizeCode,
    this.source = 'lookup',
    this.bookmarkStore,
    this.bookmarkUid,
  });

  /// Nơi lưu món đã đánh dấu; mặc định lưu trên máy theo người dùng.
  final IRecipeBookmarkStore? bookmarkStore;
  final String? bookmarkUid;

  final RecipeItem recipe;
  final String? initialSizeCode;

  /// Nơi mở màn: `lookup` (danh sách tra cứu) hoặc `notification` (chạm thông báo / deep link).
  final String source;

  @override
  State<RecipeDetailSizePage> createState() => _RecipeDetailSizePageState();
}

class _RecipeDetailSizePageState extends State<RecipeDetailSizePage> {
  late int _selectedSizeIndex;
  late final RecipeBookmarkViewModel _bookmarks;

  @override
  void initState() {
    super.initState();
    String? uid = widget.bookmarkUid;
    if (uid == null) {
      try {
        uid = context.read<TrainingViewModel>().uid;
      } catch (_) {
        uid = null;
      }
    }
    _bookmarks = RecipeBookmarkViewModel(
      store: widget.bookmarkStore ?? const PrefsRecipeBookmarkStore(),
      uid: uid,
    )..load();
    if (widget.initialSizeCode != null) {
      final idx = widget.recipe.sizes.indexWhere(
        (s) => s.sizeCode == widget.initialSizeCode,
      );
      _selectedSizeIndex = idx >= 0 ? idx : 0;
    } else {
      // Default to M or first
      final idx = widget.recipe.sizes.indexWhere((s) => s.sizeCode == 'M');
      _selectedSizeIndex = idx >= 0 ? idx : 0;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppServices>().analytics.logViewRecipe(
        recipeCode: widget.recipe.code,
        category: widget.recipe.category,
        size: widget.recipe.sizes[_selectedSizeIndex].sizeCode,
        source: widget.source,
      );
    });
  }

  @override
  void dispose() {
    _bookmarks.dispose();
    super.dispose();
  }

  Future<void> _toggleBookmark() async {
    final messenger = ScaffoldMessenger.of(context);
    final saved = await _bookmarks.toggle(widget.recipe.code);
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(switch (saved) {
          true => 'Đã lưu công thức.',
          false => 'Đã bỏ lưu công thức.',
          null => 'Không lưu được. Vui lòng thử lại.',
        }),
      ),
    );
  }

  void _openFeedback(RecipeStepItem? step) {
    final recipe = widget.recipe;
    go(
      context,
      CreateFeedbackPage(
        initialRecipeCode: recipe.code,
        initialRecipeName: recipe.name,
        initialVersion: recipe.version,
        initialStepNumber: step?.stepNumber,
        initialStepTitle: step?.title,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;
    final currentSize = recipe.sizes[_selectedSizeIndex];

    return Scaffold(
      backgroundColor: NomadKit.canvas,
      appBar: AppBar(
        backgroundColor: NomadKit.canvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 64,
        shape: const Border(bottom: BorderSide(color: NomadKit.border)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Công thức',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: NomadKit.secondary,
          ),
        ),
        actions: [
          ListenableBuilder(
            listenable: _bookmarks,
            builder: (context, _) {
              final saved = _bookmarks.isBookmarked(recipe.code);
              return IconButton(
                tooltip: saved ? 'Bỏ lưu công thức' : 'Lưu công thức',
                onPressed: _bookmarks.loaded ? _toggleBookmark : null,
                icon: Icon(
                  saved
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  color: saved ? NomadKit.sandDark : NomadKit.secondary,
                ),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
          decoration: const BoxDecoration(
            color: NomadKit.canvas,
            border: Border(top: BorderSide(color: NomadKit.border)),
          ),
          child: SizedBox(
            height: 52,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: NomadKit.sandDark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => _openFeedback(null),
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
              label: const Text(
                'Góp ý công thức',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Version & Metadata Badge Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: NomadKit.forestLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${recipe.status} · ${recipe.version}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: NomadKit.forest,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Ban hành: ${recipe.publishedDate}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontSize: 12,
                        color: NomadKit.secondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Newer Version Alert Banner (if applicable)
              if (recipe.hasNewerVersion && recipe.newerVersionNotice != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: NomadKit.warningLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: NomadKit.warning.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: NomadKit.warning,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Đã có phiên bản cập nhật',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: NomadKit.warning,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              recipe.newerVersionNotice!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: NomadKit.ink,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              Text(
                recipe.category,
                style: NomadKit.caption.copyWith(
                  fontWeight: FontWeight.w500,
                  color: NomadKit.sandDark,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                recipe.name,
                style: NomadKit.title.copyWith(fontSize: 26, height: 34 / 26),
              ),
              const SizedBox(height: 6),
              Text(
                recipe.description,
                style: const TextStyle(
                  fontSize: 13,
                  color: NomadKit.secondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Người ban hành: ${recipe.publisher}',
                style: const TextStyle(
                  fontSize: 11,
                  color: NomadKit.secondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 20),

              // Standard Serving Yield Note (Không dùng Size) — ẩn khi chưa có quy cách
              if (currentSize.servingNotes.trim().isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: NomadKit.sandLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/icons/icon_beaker_ratio.png',
                        width: 22,
                        height: 22,
                        filterQuality: FilterQuality.medium,
                        errorBuilder: (ctx, err, stack) => const Icon(
                          Icons.local_cafe_outlined,
                          size: 18,
                          color: NomadKit.sandDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Quy cách phục vụ chuẩn: ${currentSize.servingNotes}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: NomadKit.sandDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              if (recipe.sizes.length > 1) ...[
                Row(
                  children: [
                    for (var i = 0; i < recipe.sizes.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(recipe.sizes[i].sizeCode),
                          selected: i == _selectedSizeIndex,
                          showCheckmark: false,
                          selectedColor: NomadKit.sandDark,
                          backgroundColor: NomadKit.canvas,
                          side: BorderSide(
                            color: i == _selectedSizeIndex
                                ? NomadKit.sandDark
                                : NomadKit.border,
                          ),
                          labelStyle: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: i == _selectedSizeIndex
                                ? Colors.white
                                : NomadKit.ink,
                          ),
                          onSelected: (_) =>
                              setState(() => _selectedSizeIndex = i),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // Ingredients Portion Table
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Nguyên liệu', style: NomadKit.section),
                  Text(
                    '${currentSize.ingredients.length} thành phần',
                    style: const TextStyle(
                      fontSize: 12,
                      color: NomadKit.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Container(
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: NomadKit.lineSoft)),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: currentSize.ingredients.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1, color: NomadKit.border),
                  itemBuilder: (context, idx) {
                    final ing = currentSize.ingredients[idx];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ing.name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: NomadKit.ink,
                                  ),
                                ),
                                if (ing.note != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    ing.note!,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: NomadKit.secondary,
                                    ),
                                  ),
                                ],
                                if (ing.warning != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    '⚠ ${ing.warning!}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: NomadKit.error,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          // Exact Amount & Unit
                          Text(
                            '${ing.amount.toString().replaceAll('.0', '')} ${ing.unit}',
                            style: const TextStyle(
                              fontSize: 19,
                              height: 28 / 19,
                              fontWeight: FontWeight.w600,
                              color: NomadKit.sandDark,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Steps & Video Timeline Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Pha chế', style: NomadKit.section),
                  GestureDetector(
                    onTap: () => go(
                      context,
                      StepVideoGuidePage(recipe: recipe, initialStepNumber: 1),
                    ),
                    child: Row(
                      children: [
                        Image.asset(
                          'assets/icons/icon_video_guide.png',
                          width: 20,
                          height: 20,
                          filterQuality: FilterQuality.medium,
                          errorBuilder: (ctx, err, stack) => const Icon(
                            Icons.play_circle_fill_rounded,
                            size: 16,
                            color: NomadKit.sand,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Xem video chuẩn',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: NomadKit.sandDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              ...recipe.steps.map((st) {
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: NomadKit.lineSoft),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: NomadKit.sandLight,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${st.stepNumber}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: NomadKit.sandDark,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  st.title,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: NomadKit.ink,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  st.instruction,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: NomadKit.ink,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 48,
                            height: 48,
                            child: IconButton(
                              icon: const Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 18,
                                color: NomadKit.secondary,
                              ),
                              tooltip: 'Góp ý bước ${st.stepNumber}',
                              onPressed: () => _openFeedback(st),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Step Metadata & Video Jump Link
                      Row(
                        children: [
                          // Mốc video chỉ hiện khi món có video thật.
                          if (recipe.videoUrl.isNotEmpty)
                            InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () {
                                go(
                                  context,
                                  StepVideoGuidePage(
                                    recipe: recipe,
                                    initialStepNumber: st.stepNumber,
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: NomadKit.oceanLight,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: NomadKit.ocean.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.play_arrow_rounded,
                                      size: 14,
                                      color: NomadKit.ocean,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Mốc video: ${formatVideoTime(Duration(seconds: st.videoStartSeconds))}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: NomadKit.ocean,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          const Spacer(),

                          if (st.temperature != null) ...[
                            const Icon(
                              Icons.thermostat_rounded,
                              size: 14,
                              color: NomadKit.secondary,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              st.temperature!,
                              style: const TextStyle(
                                fontSize: 11,
                                color: NomadKit.secondary,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (st.durationText != null) ...[
                            const Icon(
                              Icons.timer_outlined,
                              size: 14,
                              color: NomadKit.secondary,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              st.durationText!,
                              style: const TextStyle(
                                fontSize: 11,
                                color: NomadKit.secondary,
                              ),
                            ),
                          ],
                        ],
                      ),

                      // Linked SOP Chip (if any)
                      if (st.linkedSopId != null) ...[
                        const SizedBox(height: 10),
                        InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            final sop = context
                                .read<TrainingViewModel>()
                                .sopByCode(st.linkedSopId ?? '');
                            if (sop == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'SOP liên kết chưa có trong thư viện.',
                                  ),
                                ),
                              );
                              return;
                            }
                            go(context, SopDetailPage(sop: sop));
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: NomadKit.sandLight,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: NomadKit.border),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.menu_book_rounded,
                                  size: 16,
                                  color: NomadKit.sandDark,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    st.linkedSopTitle ??
                                        'Mở hướng dẫn kỹ thuật SOP',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: NomadKit.sandDark,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 11,
                                  color: NomadKit.sandDark,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }),
              const SizedBox(height: 20),

              // Bottom Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        side: const BorderSide(color: NomadKit.sandDark),
                        foregroundColor: NomadKit.sandDark,
                      ),
                      onPressed: () {
                        go(
                          context,
                          SelfPracticeTimerPage(
                            initialRecipe: recipe,
                            initialSizeCode: currentSize.sizeCode,
                          ),
                        );
                      },
                      icon: const Icon(Icons.timer_outlined, size: 18),
                      label: const Text(
                        'Tự luyện món này',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: NomadKit.sand,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        go(
                          context,
                          StepVideoGuidePage(
                            recipe: recipe,
                            initialStepNumber: 1,
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.play_circle_fill_rounded,
                        size: 18,
                      ),
                      label: const Text(
                        'Xem video chuẩn',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
