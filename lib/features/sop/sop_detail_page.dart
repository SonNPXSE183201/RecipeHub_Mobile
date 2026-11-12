import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/app_models.dart';
import '../../core/theme/nomad_kit.dart';
import '../../core/utils/navigation.dart';
import '../../core/viewmodels/recipe_viewmodel.dart';
import '../../core/widgets/redesign_widgets.dart';
import '../feedback/create_feedback_page.dart';
import '../lookup/recipe_detail_size_page.dart';

class SopDetailPage extends StatelessWidget {
  const SopDetailPage({super.key, required this.sop});

  final SopItem sop;

  void _feedback(BuildContext context, [SopStepItem? step]) => go(
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
    return RhFlowScaffold(
      title: 'Quy trình SOP',
      bottomAction: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.bookmark_border_rounded, size: 18),
              label: const Text('Lưu'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: RhPrimaryButton(
              label: 'Góp ý SOP',
              icon: Icons.chat_bubble_outline_rounded,
              onPressed: () => _feedback(context),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'QUY TRÌNH VẬN HÀNH · ${sop.category.toUpperCase()}',
              style: NomadKit.caption.copyWith(
                color: NomadKit.sandDark,
                fontWeight: FontWeight.w600,
                letterSpacing: .6,
              ),
            ),
            const SizedBox(height: 8),
            Text(sop.title, style: NomadKit.title.copyWith(fontSize: 26)),
            const SizedBox(height: 10),
            Text(sop.summary, style: NomadKit.body),
            const SizedBox(height: 18),
            RhNotice(
              icon: Icons.verified_outlined,
              title: 'Tiêu chuẩn đang áp dụng',
              message:
                  'Phiên bản ${sop.version} · Ban hành ${sop.publishedDate}',
            ),
            const SizedBox(height: 26),
            Text('Các bước thực hiện', style: NomadKit.section),
            const SizedBox(height: 8),
            ...sop.steps.map(
              (step) => _SopStep(
                step: step,
                onFeedback: () => _feedback(context, step),
              ),
            ),
            const SizedBox(height: 22),
            const Divider(color: NomadKit.border),
            const SizedBox(height: 18),
            Text('Thông tin quy trình', style: NomadKit.section),
            const SizedBox(height: 12),
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
    padding: const EdgeInsets.symmetric(vertical: 16),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: NomadKit.lineSoft)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: NomadKit.sandLight,
            shape: BoxShape.circle,
          ),
          child: Text(
            '${step.stepNumber}',
            style: NomadKit.label.copyWith(color: NomadKit.sandDark),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                step.title,
                style: NomadKit.label.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(step.content, style: NomadKit.body),
              if (step.note case final note?) ...[
                const SizedBox(height: 10),
                RhNotice(message: note, title: 'Lưu ý'),
              ],
            ],
          ),
        ),
        IconButton(
          tooltip: 'Góp ý bước này',
          onPressed: onFeedback,
          icon: const Icon(
            Icons.chat_bubble_outline_rounded,
            size: 18,
            color: NomadKit.secondary,
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
