import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/nomad_kit.dart';
import '../../core/di/app_services.dart';
import '../../core/models/app_models.dart';
import '../../core/utils/navigation.dart';
import 'step_video_guide_page.dart';
import '../practice/self_practice_timer_page.dart';
import '../feedback/create_feedback_page.dart';
import '../sop/sop_detail_page.dart';
import '../../core/services/mock_data_service.dart';

class RecipeDetailSizePage extends StatefulWidget {
  const RecipeDetailSizePage({
    super.key,
    required this.recipe,
    this.initialSizeCode,
  });

  final RecipeItem recipe;
  final String? initialSizeCode;

  @override
  State<RecipeDetailSizePage> createState() => _RecipeDetailSizePageState();
}

class _RecipeDetailSizePageState extends State<RecipeDetailSizePage> {
  late int _selectedSizeIndex;

  @override
  void initState() {
    super.initState();
    if (widget.initialSizeCode != null) {
      final idx = widget.recipe.sizes.indexWhere((s) => s.sizeCode == widget.initialSizeCode);
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
            source: 'lookup',
          );
    });
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: NomadKit.ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          recipe.name,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: NomadKit.ink),
        ),
        actions: [
          IconButton(
            tooltip: 'Gửi phản hồi món này',
            icon: Image.asset(
              'assets/icons/icon_feedback_pencil.png',
              width: 22,
              height: 22,
              filterQuality: FilterQuality.medium,
              errorBuilder: (ctx, err, stack) => const Icon(Icons.feedback_outlined, size: 20, color: NomadKit.sandDark),
            ),
            onPressed: () {
              go(
                context,
                CreateFeedbackPage(
                  initialRecipeCode: recipe.code,
                  initialRecipeName: recipe.name,
                  initialVersion: recipe.version,
                ),
              );
            },
          ),
        ],
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
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: NomadKit.forestLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${recipe.status} · ${recipe.version}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: NomadKit.forest),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: NomadKit.sandLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          recipe.code,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, fontFamily: 'monospace', color: NomadKit.sandDark),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Ban hành: ${recipe.publishedDate}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: const TextStyle(fontSize: 12, color: NomadKit.secondary),
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
                    border: Border.all(color: NomadKit.warning.withOpacity(0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline_rounded, color: NomadKit.warning, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Đã có phiên bản cập nhật',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: NomadKit.warning),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              recipe.newerVersionNotice!,
                              style: const TextStyle(fontSize: 12, color: NomadKit.ink, height: 1.3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              // Title & Description
              Text(
                recipe.name,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: NomadKit.ink),
              ),
              const SizedBox(height: 6),
              Text(
                recipe.description,
                style: const TextStyle(fontSize: 13, color: NomadKit.secondary, height: 1.4),
              ),
              const SizedBox(height: 8),
              Text(
                'Người ban hành: ${recipe.publisher}',
                style: const TextStyle(fontSize: 11, color: NomadKit.secondary, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 20),

              // Standard Serving Yield Note (Không dùng Size)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                      errorBuilder: (ctx, err, stack) => const Icon(Icons.local_cafe_outlined, size: 18, color: NomadKit.sandDark),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Quy cách phục vụ chuẩn: ${currentSize.servingNotes}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: NomadKit.sandDark),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Ingredients Portion Table
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'ĐỊNH LƯỢNG NGUYÊN LIỆU',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: NomadKit.sandDark, letterSpacing: 0.7),
                  ),
                  Text(
                    '${currentSize.ingredients.length} thành phần',
                    style: const TextStyle(fontSize: 12, color: NomadKit.secondary),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Container(
                decoration: BoxDecoration(
                  color: NomadKit.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: NomadKit.border),
                  boxShadow: const [
                    BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 2)),
                  ],
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: currentSize.ingredients.length,
                  separatorBuilder: (context, index) => const Divider(height: 1, color: NomadKit.border),
                  itemBuilder: (context, idx) {
                    final ing = currentSize.ingredients[idx];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: NomadKit.canvas,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                '${idx + 1}',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: NomadKit.secondary),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ing.name,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: NomadKit.ink),
                                ),
                                if (ing.note != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    ing.note!,
                                    style: const TextStyle(fontSize: 11, color: NomadKit.secondary),
                                  ),
                                ],
                                if (ing.warning != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    '⚠ ${ing.warning!}',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: NomadKit.error),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          // Exact Amount & Unit
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: NomadKit.sandLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${ing.amount.toString().replaceAll('.0', '')} ${ing.unit}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: NomadKit.sandDark,
                              ),
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
                  const Text(
                    'CÁC BƯỚC PHA CHẾ & MỐC VIDEO',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: NomadKit.sandDark, letterSpacing: 0.7),
                  ),
                  GestureDetector(
                    onTap: () => go(context, StepVideoGuidePage(recipe: recipe, initialStepNumber: 1)),
                    child: Row(
                      children: [
                        Image.asset(
                          'assets/icons/icon_video_guide.png',
                          width: 20,
                          height: 20,
                          filterQuality: FilterQuality.medium,
                          errorBuilder: (ctx, err, stack) => const Icon(Icons.play_circle_fill_rounded, size: 16, color: NomadKit.sand),
                        ),
                        const SizedBox(width: 4),
                        const Text('Xem video chuẩn', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: NomadKit.sandDark)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              ...recipe.steps.map((st) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: NomadKit.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: NomadKit.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: NomadKit.sand,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Bước ${st.stepNumber}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  st.title,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: NomadKit.ink),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  st.instruction,
                                  style: const TextStyle(fontSize: 13, color: NomadKit.ink, height: 1.35),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Step Metadata & Video Jump Link
                      Row(
                        children: [
                          // Video timestamp button
                          InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () {
                              go(context, StepVideoGuidePage(recipe: recipe, initialStepNumber: st.stepNumber));
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: NomadKit.oceanLight,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: NomadKit.ocean.withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.play_arrow_rounded, size: 14, color: NomadKit.ocean),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Mốc video: 00:${st.videoStartSeconds.toString().padLeft(2, '0')}',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: NomadKit.ocean),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Spacer(),

                          if (st.temperature != null) ...[
                            const Icon(Icons.thermostat_rounded, size: 14, color: NomadKit.secondary),
                            const SizedBox(width: 2),
                            Text(st.temperature!, style: const TextStyle(fontSize: 11, color: NomadKit.secondary)),
                            const SizedBox(width: 8),
                          ],
                          if (st.durationText != null) ...[
                            const Icon(Icons.timer_outlined, size: 14, color: NomadKit.secondary),
                            const SizedBox(width: 2),
                            Text(st.durationText!, style: const TextStyle(fontSize: 11, color: NomadKit.secondary)),
                          ],
                        ],
                      ),

                      // Linked SOP Chip (if any)
                      if (st.linkedSopId != null) ...[
                        const SizedBox(height: 10),
                        InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            final sop = MockDataService.instance.sops.firstWhere(
                              (s) => s.id == st.linkedSopId,
                              orElse: () => MockDataService.instance.sops.first,
                            );
                            go(context, SopDetailPage(sop: sop));
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: NomadKit.sandLight,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: NomadKit.border),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.menu_book_rounded, size: 16, color: NomadKit.sandDark),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    st.linkedSopTitle ?? 'Mở hướng dẫn kỹ thuật SOP',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: NomadKit.sandDark),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios_rounded, size: 11, color: NomadKit.sandDark),
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                      label: const Text('Tự luyện món này', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: NomadKit.sand,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        go(context, StepVideoGuidePage(recipe: recipe, initialStepNumber: 1));
                      },
                      icon: const Icon(Icons.play_circle_fill_rounded, size: 18),
                      label: const Text('Xem video chuẩn', style: TextStyle(fontWeight: FontWeight.w800)),
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
