import '../../core/viewmodels/auth_viewmodel.dart';
import '../../core/widgets/personal_learning_blocked.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/nomad_kit.dart';
import '../../core/models/app_models.dart';
import '../../core/utils/navigation.dart';
import '../../core/viewmodels/recipe_viewmodel.dart';
import '../../core/viewmodels/training_viewmodel.dart';
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

  @override
  Widget build(BuildContext context) {
    if (!context.watch<AuthViewModel>().hasPersonalLearning) {
      return const PersonalLearningBlocked();
    }
    final training = context.watch<TrainingViewModel>();
    final task = training.taskById(widget.task.id) ?? widget.task;
    final completed = training.completedSectionsOf(task.id);
    final quiz = training.quizFor(task.targetCode);
    bool done(int idx) => completed.contains(idx);

    return Scaffold(
      backgroundColor: NomadKit.canvas,
      appBar: AppBar(
        backgroundColor: NomadKit.canvas,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: NomadKit.ink,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Chi tiết nhiệm vụ học',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: NomadKit.ink,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Card
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: NomadKit.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: NomadKit.border),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x06000000),
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: task.type == 'Công thức'
                                      ? NomadKit.sandLight
                                      : NomadKit.oceanLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  task.type,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    fontFamily: 'monospace',
                                    color: task.type == 'Công thức'
                                        ? NomadKit.sandDark
                                        : NomadKit.ocean,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                task.version,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: NomadKit.secondary,
                                ),
                              ),
                              const Spacer(),
                              if (task.isOverdue)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEE2E2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Quá hạn',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: NomadKit.error,
                                    ),
                                  ),
                                )
                              else if (task.isRelearnRequired)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: NomadKit.warningLight,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Cần học lại',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: NomadKit.warning,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          Text(
                            task.title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: NomadKit.ink,
                            ),
                          ),
                          const SizedBox(height: 8),

                          Text(
                            'Người giao: ${task.assignedBy}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: NomadKit.secondary,
                            ),
                          ),
                          Text(
                            'Ngày giao: ${task.assignedDate}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: NomadKit.secondary,
                            ),
                          ),
                          Text(
                            'Hạn chót: ${task.dueDate}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: task.isOverdue
                                  ? NomadKit.error
                                  : NomadKit.secondary,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Progress Slider Bar
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Tiến độ đọc/xem:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: NomadKit.ink,
                                ),
                              ),
                              Text(
                                '${(task.progress * 100).toInt()}%',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: NomadKit.sandDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: task.progress,
                              minHeight: 8,
                              backgroundColor: NomadKit.canvas,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                task.progress >= 1.0
                                    ? NomadKit.forest
                                    : NomadKit.sand,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Sections Checklist
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'CÁC PHẦN CẦN HOÀN THÀNH',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: NomadKit.sandDark,
                            letterSpacing: 0.7,
                          ),
                        ),
                        Text(
                          '${completed.where((i) => i < task.sections.length).length}/${task.sections.length} mục',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: NomadKit.secondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    ...List.generate(task.sections.length, (idx) {
                      final isDone = done(idx);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: NomadKit.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: NomadKit.border),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          child: CheckboxListTile(
                            activeColor: NomadKit.sand,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            title: Text(
                              task.sections[idx],
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isDone
                                    ? NomadKit.secondary
                                    : NomadKit.ink,
                                decoration: isDone
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            subtitle: Text(
                              isDone
                                  ? 'Đã hoàn thành phần này'
                                  : 'Chưa hoàn tất',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDone
                                    ? NomadKit.forest
                                    : NomadKit.secondary,
                              ),
                            ),
                            value: isDone,
                            onChanged: (v) =>
                                _toggleSection(task, idx, v ?? !isDone),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 10),

                    // Linked Material Summary Card
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _openingContent
                          ? null
                          : () => _openRelatedContent(task),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: NomadKit.sandLight,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: NomadKit.sand.withOpacity(0.35),
                          ),
                        ),
                        child: Row(
                          children: [
                            Image.asset(
                              task.type == 'Công thức'
                                  ? 'assets/icons/icon_video_guide.png'
                                  : 'assets/icons/icon_sop_protocol.png',
                              width: 24,
                              height: 24,
                              filterQuality: FilterQuality.medium,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'TÀI LIỆU & VIDEO CHUẨN LIÊN KẾT',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: NomadKit.sandDark,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${task.title} · Phiên bản ${task.version}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: NomadKit.ink,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              size: 20,
                              color: NomadKit.sandDark,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (quiz != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                color: NomadKit.surface,
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: NomadKit.sandDark,
                      side: const BorderSide(color: NomadKit.sandDark),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => go(context, QuizExamPage(quiz: quiz)),
                    icon: const Icon(Icons.quiz_outlined, size: 18),
                    label: const Text(
                      'Làm quiz',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),

            // Bottom Action Bar: Side-by-Side Concise Buttons
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
              decoration: const BoxDecoration(
                color: NomadKit.surface,
                border: Border(top: BorderSide(color: NomadKit.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: NomadKit.forest,
                          backgroundColor: NomadKit.forestLight.withOpacity(
                            0.45,
                          ),
                          side: const BorderSide(
                            color: NomadKit.forest,
                            width: 1.2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        onPressed: _saving
                            ? null
                            : () => _markAllCompleted(task),
                        icon: const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 18,
                        ),
                        label: const Text(
                          'Hoàn thành',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: NomadKit.sand,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          elevation: 0,
                        ),
                        onPressed: _openingContent
                            ? null
                            : () => _openRelatedContent(task),
                        icon: _openingContent
                            ? const SizedBox.square(
                                dimension: 19,
                                child: CircularProgressIndicator(),
                              )
                            : const Icon(
                                Icons.play_circle_fill_rounded,
                                size: 19,
                              ),
                        label: Text(
                          _openingContent ? 'Đang tải...' : 'Mở học ngay',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
