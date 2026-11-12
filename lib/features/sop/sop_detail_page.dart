import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/app_models.dart';
import '../../core/theme/nomad_kit.dart';
import '../../core/utils/navigation.dart';
import '../../core/viewmodels/recipe_viewmodel.dart';
import '../../core/widgets/rh_motion.dart';
import '../../core/widgets/redesign_widgets.dart';
import '../feedback/create_feedback_page.dart';
import '../lookup/recipe_detail_size_page.dart';

/// Chi tiết SOP theo Figma "SOP Detail / Quy trình SOP" (node 22:164).
class SopDetailPage extends StatefulWidget {
  const SopDetailPage({super.key, required this.sop});

  final SopItem sop;

  @override
  State<SopDetailPage> createState() => _SopDetailPageState();
}

class _SopDetailPageState extends State<SopDetailPage> {
  bool _metaOpen = false;

  SopItem get sop => widget.sop;

  void _feedback([SopStepItem? step]) => go(
    context,
    CreateFeedbackPage(
      initialSopCode: sop.code,
      initialSopTitle: sop.title,
      initialVersion: sop.version,
      initialStepNumber: step?.stepNumber,
      initialStepTitle: step?.title,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final recipes = context.read<RecipeViewModel>().items;
    final linked = sop.linkedRecipeCodes
        .map(
          (code) => recipes.where((recipe) => recipe.code == code).firstOrNull,
        )
        .whereType<RecipeItem>()
        .toList();
    final stepCount = '${sop.steps.length} bước';

    return RhFlowScaffold(
      title: 'Quy trình SOP',
      bottomAction: SizedBox(
        height: 52,
        width: double.infinity,
        child: PressScale(
          child: FilledButton.icon(
            onPressed: _feedback,
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
            label: const Text('Góp ý SOP'),
            style: FilledButton.styleFrom(
              backgroundColor: NomadKit.sandDark,
              foregroundColor: Colors.white,
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Document Heading
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 22),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: NomadKit.border)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quy trình vận hành',
                    style: NomadKit.caption.copyWith(
                      color: NomadKit.sandDark,
                      fontWeight: FontWeight.w500,
                      height: 19 / 12,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 3, bottom: 14),
                    child: Text(
                      sop.title,
                      style: NomadKit.title.copyWith(
                        fontSize: 26,
                        height: 34 / 26,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    stepCount,
                    style: NomadKit.label.copyWith(
                      fontWeight: FontWeight.w400,
                      color: NomadKit.secondary,
                    ),
                  ),
                ],
              ),
            ),
            // Section Heading
            Padding(
              padding: const EdgeInsets.only(top: 22, bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Thực hiện',
                    style: NomadKit.section.copyWith(fontSize: 17),
                  ),
                  Text(
                    stepCount,
                    style: NomadKit.label.copyWith(
                      fontWeight: FontWeight.w400,
                      color: NomadKit.secondary,
                    ),
                  ),
                ],
              ),
            ),
            ...sop.steps.map(
              (step) => _SopStep(step: step, onFeedback: () => _feedback(step)),
            ),
            const SizedBox(height: 24),
            // Metadata (thu gọn mặc định, như Figma "Thông tin tài liệu  +")
            InkWell(
              onTap: () => setState(() => _metaOpen = !_metaOpen),
              child: Container(
                constraints: const BoxConstraints(minHeight: 60),
                padding: const EdgeInsets.only(top: 12),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: NomadKit.border)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Thông tin tài liệu',
                      style: NomadKit.label.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _metaOpen ? '−' : '+',
                      style: NomadKit.body.copyWith(
                        fontSize: 20,
                        color: NomadKit.sandDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_metaOpen) ...[
              if (sop.summary.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(sop.summary, style: NomadKit.body),
                const SizedBox(height: 12),
              ],
              _Meta(label: 'Phân loại', value: sop.category),
              _Meta(label: 'Phiên bản', value: sop.version),
              _Meta(label: 'Ngày ban hành', value: sop.publishedDate),
              if (linked.isNotEmpty) ...[
                const SizedBox(height: 18),
                Text('Công thức liên quan', style: NomadKit.section),
                const SizedBox(height: 8),
                ...linked.map(
                  (recipe) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    minLeadingWidth: 28,
                    leading: const Icon(
                      Icons.local_cafe_outlined,
                      color: NomadKit.sandDark,
                    ),
                    title: Text(recipe.name, style: NomadKit.label),
                    trailing: const RhChevron(),
                    onTap: () => go(
                      context,
                      RecipeDetailSizePage(recipe: recipe, source: 'sop'),
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _SopStep extends StatelessWidget {
  const _SopStep({required this.step, required this.onFeedback});
  final SopStepItem step;
  final VoidCallback onFeedback;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 20),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: NomadKit.lineSoft)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: NomadKit.sandLight,
            shape: BoxShape.circle,
          ),
          child: Text(
            '${step.stepNumber}',
            style: NomadKit.label.copyWith(
              color: NomadKit.sandDark,
              fontWeight: FontWeight.w600,
              height: 16 / 13,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      step.title,
                      style: NomadKit.body.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 23 / 15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PressScale(
                    child: IconButton(
                      tooltip: 'Góp ý bước này',
                      onPressed: onFeedback,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: 32,
                        height: 23,
                      ),
                      icon: const Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 16,
                        color: NomadKit.secondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                step.content,
                style: NomadKit.body.copyWith(height: 28 / 15),
              ),
              if (step.note case final note?) ...[
                const SizedBox(height: 10),
                RhNotice(message: note, title: 'Lưu ý'),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

class _Meta extends StatelessWidget {
  const _Meta({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Expanded(child: Text(label, style: NomadKit.caption)),
        Expanded(
          child: Text(value, textAlign: TextAlign.end, style: NomadKit.label),
        ),
      ],
    ),
  );
}
