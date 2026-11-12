import '../../core/viewmodels/auth_viewmodel.dart';
import '../../core/widgets/personal_learning_blocked.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/nomad_kit.dart';
import '../../core/models/app_models.dart';
import '../../core/utils/navigation.dart';
import '../../core/viewmodels/recipe_viewmodel.dart';
import '../../core/viewmodels/training_viewmodel.dart';
import '../../core/widgets/load_state_view.dart';
import '../../core/widgets/redesign_widgets.dart';
import '../lookup/step_video_guide_page.dart';
import '../practice/quiz_exam_page.dart';
import '../sop/sop_detail_page.dart';

class LearningTaskDetailPage extends StatefulWidget {
  const LearningTaskDetailPage({super.key, required this.task});

  final LearningTaskItem task;

  @override
  State<LearningTaskDetailPage> createState() => _LearningTaskDetailPageState();
}

class _LearningTaskDetailPageState extends State<LearningTaskDetailPage> {
  bool _saving = false;
  bool _openingContent = false;

  void _snack(String msg, {Color color = NomadKit.error}) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  Future<void> _toggleSection(LearningTaskItem task, int idx, bool done) async {
    final err = await context.read<TrainingViewModel>().toggleSection(
      task,
      idx,
      done,
    );
    if (err != null && mounted) _snack(err);
  }

  Future<void> _markAllCompleted(LearningTaskItem task) async {
    if (_saving) return;
    final vm = context.read<TrainingViewModel>();
    setState(() => _saving = true);
    final failure = await vm.completeAll(task);
    if (!mounted) return;
    setState(() => _saving = false);
    if (failure != null) {
      _snack(failure);
    } else {
      _snack(
        'Đã xác nhận hoàn thành nội dung đọc/xem. Kết quả thực hành cần được Admin đánh giá riêng.',
        color: NomadKit.forest,
      );
    }
  }

  Future<void> _openRelatedContent(LearningTaskItem task) async {
    if (_openingContent) return;
    if (task.type == 'Công thức') {
      final recipes = context.read<RecipeViewModel>();
      setState(() => _openingContent = true);
      RecipeItem? recipe;
      try {
        recipe = await recipes.findForDeepLink(task.targetCode);
      } catch (_) {
        if (mounted) _snack('Không tải được công thức. Vui lòng thử lại.');
        return;
      } finally {
        if (mounted) setState(() => _openingContent = false);
      }
      if (!mounted) return;
      if (recipe == null) {
        _snack('Công thức này chưa có trong danh sách đã ban hành.');
        return;
      }
      go(context, StepVideoGuidePage(recipe: recipe, initialStepNumber: 1));
    } else {
      final sop = context.read<TrainingViewModel>().sopByCode(task.targetCode);
      if (sop == null) {
        _snack('SOP này chưa có trong thư viện.');
        return;
      }
      go(context, SopDetailPage(sop: sop));
    }
  }

  Widget _sectionHeading(String title, [String? trailing]) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 12),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: NomadKit.section),
        if (trailing != null)
          Text(
            trailing,
            style: NomadKit.caption.copyWith(color: NomadKit.secondary),
          ),
      ],
    ),
  );

  Widget _recipeLesson(RecipeItem recipe) {
    final ingredients = recipe.sizes.isEmpty
        ? const <IngredientPortion>[]
        : recipe.sizes.first.ingredients;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeading(
          'Nguyên liệu',
          recipe.sizes.isEmpty ? null : recipe.sizes.first.label,
        ),
        if (ingredients.isEmpty)
          const Text('Chưa có định lượng.', style: NomadKit.caption)
        else
          ...ingredients.map(
            (item) => Container(
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: NomadKit.lineSoft)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: Text(item.name, style: NomadKit.body)),
                  Text(
                    item.amount.toString().replaceFirst(RegExp(r'\.0$'), ''),
                    style: NomadKit.section.copyWith(
                      fontSize: 19,
                      color: NomadKit.sandDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item.unit,
                    style: NomadKit.caption.copyWith(color: NomadKit.secondary),
                  ),
                ],
              ),
            ),
          ),
        _sectionHeading('Pha chế', '${recipe.steps.length} bước'),
        ...recipe.steps.map(
          (step) => Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
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
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.title,
                        style: NomadKit.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (step.instruction.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(step.instruction, style: NomadKit.body),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!context.watch<AuthViewModel>().hasPersonalLearning) {
      return const PersonalLearningBlocked();
    }
    final training = context.watch<TrainingViewModel>();
    final task = training.taskById(widget.task.id) ?? widget.task;
    final completed = training.completedSectionsOf(task.id);
    final quiz = training.quizFor(task.targetCode);
    final isRecipe = task.type == 'Công thức';
    final recipe = isRecipe
        ? context
              .watch<RecipeViewModel>()
              .items
              .where((item) => item.code == task.targetCode)
              .firstOrNull
        : null;
    bool done(int idx) => completed.contains(idx);
    final flag = task.isOverdue
        ? 'Quá hạn'
        : task.isRelearnRequired
        ? 'Cần học lại'
        : null;

    return RhFlowScaffold(
      title: 'Bài học',
      bottomAction: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (quiz != null) ...[
            SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: NomadKit.sandDark,
                  side: const BorderSide(color: NomadKit.sandDark),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => go(context, QuizExamPage(quiz: quiz)),
                icon: const Icon(Icons.quiz_outlined, size: 18),
                label: Text(
                  'Làm quiz',
                  style: NomadKit.label.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: 'Hoàn thành',
                  onPressed: _saving ? null : () => _markAllCompleted(task),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  label: _openingContent ? 'Đang tải...' : 'Mở học ngay',
                  loading: _openingContent,
                  onPressed: _openingContent
                      ? null
                      : () => _openRelatedContent(task),
                ),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
        children: [
          if (training.progressState == LoadState.error)
            LoadStateView.error(
              message: training.error ?? 'Không tải được tiến độ.',
              onRetry: training.retry,
            )
          else if (training.progressState == LoadState.loading)
            const LoadStateView.loading(message: 'Đang tải tiến độ...'),
          Container(
            padding: const EdgeInsets.only(bottom: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: NomadKit.border)),
            ),
            child: Text(
              'Bài học · Đọc ${isRecipe ? 'công thức' : 'SOP'}${quiz != null ? ' trước khi làm quiz' : ''}',
              style: NomadKit.caption.copyWith(color: NomadKit.secondary),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.only(bottom: 22),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: NomadKit.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipe?.category ?? task.type,
                  style: NomadKit.caption.copyWith(
                    color: NomadKit.sandDark,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 3, bottom: 14),
                  child: Text(
                    task.title,
                    style: NomadKit.title.copyWith(
                      fontSize: 26,
                      height: 34 / 26,
                    ),
                  ),
                ),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Phiên bản ${task.version}',
                      style: NomadKit.label.copyWith(
                        fontWeight: FontWeight.w400,
                        color: NomadKit.secondary,
                      ),
                    ),
                    Container(width: 1, height: 14, color: NomadKit.border),
                    Text(
                      'Hạn chót: ${task.dueDate}',
                      style: NomadKit.label.copyWith(
                        fontWeight: FontWeight.w400,
                        color: task.isOverdue
                            ? NomadKit.error
                            : NomadKit.secondary,
                      ),
                    ),
                    if (flag != null) ...[
                      Container(width: 1, height: 14, color: NomadKit.border),
                      Text(
                        flag,
                        style: NomadKit.label.copyWith(
                          color: task.isOverdue
                              ? NomadKit.error
                              : NomadKit.warning,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Người giao: ${task.assignedBy} · Ngày giao: ${task.assignedDate}',
                  style: NomadKit.label.copyWith(
                    fontWeight: FontWeight.w400,
                    color: NomadKit.secondary,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Tiến độ đọc/xem', style: NomadKit.label),
                    Text(
                      '${(task.progress * 100).toInt()}%',
                      style: NomadKit.label.copyWith(color: NomadKit.sandDark),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: task.progress,
                    minHeight: 6,
                    backgroundColor: NomadKit.sandLight,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      task.progress >= 1.0
                          ? NomadKit.forest
                          : NomadKit.sandDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (recipe != null) _recipeLesson(recipe),
          _sectionHeading(
            'Các phần cần hoàn thành',
            '${completed.where((i) => i < task.sections.length).length}/${task.sections.length} mục',
          ),
          ...List.generate(task.sections.length, (idx) {
            final isDone = done(idx);
            return Container(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: NomadKit.lineSoft)),
              ),
              child: CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: NomadKit.sandDark,
                title: Text(
                  task.sections[idx].replaceAll(
                    RegExp(r'\bQZ-[A-Z0-9_-]+\b'),
                    'theo nội dung bài học',
                  ),
                  style: NomadKit.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDone ? NomadKit.secondary : NomadKit.ink,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
                subtitle: Text(
                  isDone ? 'Đã hoàn thành phần này' : 'Chưa hoàn tất',
                  style: NomadKit.caption.copyWith(
                    color: isDone ? NomadKit.forest : NomadKit.secondary,
                  ),
                ),
                value: isDone,
                onChanged: (v) => _toggleSection(task, idx, v ?? !isDone),
              ),
            );
          }),
          const SizedBox(height: 24),
          InkWell(
            onTap: _openingContent ? null : () => _openRelatedContent(task),
            child: Container(
              constraints: const BoxConstraints(minHeight: 60),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: NomadKit.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TÀI LIỆU & VIDEO CHUẨN LIÊN KẾT',
                          style: NomadKit.caption.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: NomadKit.sandDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${task.title} · Phiên bản ${task.version}',
                          style: NomadKit.label.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const RhChevron(color: NomadKit.sandDark),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final style = ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.disabled)
            ? NomadKit.border
            : NomadKit.sandDark,
      ),
      foregroundColor: const WidgetStatePropertyAll(Colors.white),
      elevation: const WidgetStatePropertyAll(0),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 16),
      ),
    );
    final text = Text(
      label,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
    );
    return SizedBox(
      height: 52,
      child: loading
          ? ElevatedButton.icon(
              onPressed: onPressed,
              style: style,
              icon: const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              label: text,
            )
          : onPressed == null || label != 'Mở học ngay'
          ? FilledButton(onPressed: onPressed, style: style, child: text)
          : ElevatedButton(onPressed: onPressed, style: style, child: text),
    );
  }
}
