import 'package:flutter/material.dart';
import '../../core/theme/nomad_kit.dart';
import '../../core/models/app_models.dart';
import '../../core/utils/navigation.dart';
import '../feedback/create_feedback_page.dart';
import '../lookup/recipe_detail_size_page.dart';
import '../../core/services/mock_data_service.dart';

class SopDetailPage extends StatelessWidget {
  const SopDetailPage({super.key, required this.sop});

  final SopItem sop;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NomadKit.canvas,
      appBar: AppBar(
        backgroundColor: NomadKit.canvas,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: NomadKit.ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          sop.code,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: NomadKit.ink),
        ),
        actions: [
          IconButton(
            tooltip: 'Gửi phản hồi SOP này',
            icon: const Icon(Icons.feedback_outlined, size: 20, color: NomadKit.sandDark),
            onPressed: () {
              go(
                context,
                CreateFeedbackPage(
                  initialSopCode: sop.code,
                  initialSopTitle: sop.title,
                  initialVersion: sop.version,
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
              // Meta Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: NomadKit.oceanLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      sop.code,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'monospace',
                        color: NomadKit.ocean,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: NomadKit.forestLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Ban hành · ${sop.version}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: NomadKit.forest),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Ngày: ${sop.publishedDate}',
                    style: const TextStyle(fontSize: 12, color: NomadKit.secondary),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Title & Category
              Text(
                sop.title,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: NomadKit.ink),
              ),
              const SizedBox(height: 4),
              Text(
                'Phân loại: ${sop.category}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: NomadKit.secondary),
              ),
              const SizedBox(height: 14),

              // Summary Box
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: NomadKit.sandLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: NomadKit.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 20, color: NomadKit.sandDark),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        sop.summary,
                        style: const TextStyle(fontSize: 13, color: NomadKit.ink, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Steps
              const Text(
                'CÁC BƯỚC THỰC HIỆN TIÊU CHUẨN',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: NomadKit.sandDark, letterSpacing: 0.7),
              ),
              const SizedBox(height: 10),

              ...sop.steps.map((st) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: NomadKit.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: NomadKit.border),
                    boxShadow: const [
                      BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: NomadKit.oceanLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Icon(st.icon ?? Icons.check_circle_outline_rounded, color: NomadKit.ocean, size: 20),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bước ${st.stepNumber}: ${st.title}',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: NomadKit.ink),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              st.content,
                              style: const TextStyle(fontSize: 13, color: NomadKit.ink, height: 1.4),
                            ),
                            if (st.note != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Image.asset(
                                      'assets/icons/icon_alert_triangle.png',
                                      width: 16,
                                      height: 16,
                                      filterQuality: FilterQuality.medium,
                                      errorBuilder: (ctx, err, stack) => const Icon(Icons.warning_amber_rounded, size: 15, color: Color(0xFF92400E)),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Lưu ý: ${st.note!}',
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF92400E), height: 1.3),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),

              // Referenced Recipes Section
              const Text(
                'CÔNG THỨC ÁP DỤNG QUY TRÌNH NÀY',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: NomadKit.sandDark, letterSpacing: 0.7),
              ),
              const SizedBox(height: 8),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: sop.linkedRecipeCodes.map((code) {
                  final recipe = MockDataService.instance.recipes.firstWhere(
                    (r) => r.code == code,
                    orElse: () => MockDataService.instance.recipes.first,
                  );
                  return ActionChip(
                    avatar: Image.asset(
                      'assets/icons/icon_recipe_book.png',
                      width: 18,
                      height: 18,
                      filterQuality: FilterQuality.medium,
                      errorBuilder: (ctx, err, stack) => const Icon(Icons.coffee_rounded, size: 16, color: NomadKit.sandDark),
                    ),
                    label: Text('${recipe.name} (${recipe.code})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: NomadKit.ink)),
                    backgroundColor: NomadKit.surface,
                    side: const BorderSide(color: NomadKit.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onPressed: () => go(context, RecipeDetailSizePage(recipe: recipe)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Bottom Button: Feedback on SOP
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: NomadKit.sandDark),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    foregroundColor: NomadKit.sandDark,
                  ),
                  onPressed: () {
                    go(
                      context,
                      CreateFeedbackPage(
                        initialSopCode: sop.code,
                        initialSopTitle: sop.title,
                        initialVersion: sop.version,
                      ),
                    );
                  },
                  icon: const Icon(Icons.feedback_outlined, size: 18),
                  label: const Text('Gửi phản hồi cho SOP này', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

