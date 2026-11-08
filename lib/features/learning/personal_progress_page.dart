import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/nomad_kit.dart';
import '../../core/models/app_models.dart';
import '../../core/viewmodels/auth_viewmodel.dart';
import '../../core/viewmodels/training_viewmodel.dart';
import '../../core/widgets/load_state_view.dart';
import '../../core/utils/navigation.dart';
import '../../core/widgets/personal_learning_blocked.dart';
import '../practice/quiz_exam_page.dart';
import '../practice/practical_evaluation_page.dart';

class PersonalProgressPage extends StatelessWidget {
  const PersonalProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    final training = context.watch<TrainingViewModel>();
    final auth = context.watch<AuthViewModel>();
    if (!auth.hasPersonalLearning) return const PersonalLearningBlocked();
    final tasks = training.tasks;
    final evaluations = training.myEvaluations;
    final attempts = training.attempts;
    final loading =
        (training.taskState == LoadState.loading && tasks.isEmpty) ||
        training.progressState == LoadState.loading ||
        training.attemptsState == LoadState.loading;
    final failed =
        (training.taskState == LoadState.error && tasks.isEmpty) ||
        training.progressState == LoadState.error ||
        training.attemptsState == LoadState.error;

    final completedCount = tasks
        .where((t) => t.status == TaskStatus.completed)
        .length;
    final inProgressCount = tasks
        .where((t) => t.status == TaskStatus.inProgress)
        .length;
    final total = tasks.length;
    final readingPercent = (training.readingProgress * 100).round();
    final quizPercent = (training.quizAverage * 100).round();
    final hasQuiz = attempts.any((a) => a.hasScore);

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
          'Tiến độ đào tạo cá nhân',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: NomadKit.ink,
          ),
        ),
      ),
      body: SafeArea(
        child: failed
            ? LoadStateView.error(
                message: training.error ?? 'Không tải được tiến độ đào tạo.',
                onRetry: training.retry,
              )
            : loading
            ? const LoadStateView.loading()
            : ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                children: [
                  // Student Profile Card
                  Container(
                    padding: const EdgeInsets.all(16),
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
                    child: Row(
                      children: [
                        Image.asset(
                          'assets/illustrations/mastery_badge_2k.png',
                          width: 48,
                          height: 48,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.medium,
                          errorBuilder: (ctx, err, stack) => const Center(
                            child: Icon(
                              Icons.school_rounded,
                              color: NomadKit.sandDark,
                              size: 28,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                auth.displayName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: NomadKit.ink,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Vai trò: ${auth.roleLabel} · Chi nhánh: ${auth.storeBranch}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: NomadKit.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tier 1: Tiếp nhận nội dung (Đọc/Xem)
                  _tierCard(
                    tierNumber: 'TẦNG 1',
                    title: 'Tiếp nhận nội dung (Đọc/Xem)',
                    statusBadge: '$readingPercent% Hoàn thành',
                    statusColor: readingPercent >= 80
                        ? NomadKit.forest
                        : NomadKit.warning,
                    bgColor: readingPercent >= 80
                        ? NomadKit.forestLight
                        : NomadKit.warningLight,
                    iconAsset: 'assets/icons/icon_recipe_book.png',
                    icon: Icons.auto_stories_rounded,
                    description:
                        'Đã hoàn thành $completedCount/$total nội dung chuẩn ($inProgressCount đang học). Tự xác nhận đọc & xem video mốc.',
                  ),
                  const SizedBox(height: 12),

                  // Tier 2: Hiểu kiến thức (Quiz)
                  _tierCard(
                    tierNumber: 'TẦNG 2',
                    title: 'Kiểm tra kiến thức (Quiz)',
                    statusBadge: hasQuiz
                        ? 'Trung bình $quizPercent%'
                        : 'Chưa làm quiz',
                    statusColor: NomadKit.ocean,
                    bgColor: NomadKit.oceanLight,
                    iconAsset: 'assets/icons/icon_quiz_exam.png',
                    icon: Icons.quiz_rounded,
                    description: attempts.isEmpty
                        ? 'Bạn chưa nộp bài quiz nào.'
                        : 'Đã nộp ${attempts.length} lượt làm bài trắc nghiệm.',
                    actionLabel: attempts.isEmpty
                        ? 'Làm bài Quiz'
                        : 'Làm lại bài Quiz',
                    onAction: () => go(context, const QuizExamPage()),
                  ),
                  const SizedBox(height: 12),

                  // Tier 3: Kỹ năng thực hành (Practical Evaluation)
                  _tierCard(
                    tierNumber: 'TẦNG 3',
                    title: 'Kỹ năng thực hành tại quầy',
                    statusBadge:
                        evaluations.isNotEmpty && evaluations.first.isPassed
                        ? 'Đạt tiêu chuẩn'
                        : 'Chờ đánh giá',
                    statusColor:
                        evaluations.isNotEmpty && evaluations.first.isPassed
                        ? NomadKit.forest
                        : NomadKit.sandDark,
                    bgColor:
                        evaluations.isNotEmpty && evaluations.first.isPassed
                        ? NomadKit.forestLight
                        : NomadKit.sandLight,
                    iconAsset: 'assets/icons/icon_evaluation_rubric.png',
                    icon: Icons.checklist_rounded,
                    description: evaluations.isNotEmpty
                        ? 'Được đánh giá bởi ${evaluations.first.evaluatorName} ngày ${evaluations.first.evaluatedDate}. Tiêu chí quan sát đã xác nhận.'
                        : 'Chưa có lượt đánh giá thực hành mới từ Admin.',
                    actionLabel: 'Xem checklist đánh giá',
                    onAction: () =>
                        go(context, const PracticalEvaluationPage()),
                  ),
                  const SizedBox(height: 24),

                  if (attempts.isNotEmpty) ...[
                    const Text(
                      'LỊCH SỬ LÀM BÀI QUIZ',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: NomadKit.sandDark,
                        letterSpacing: 0.7,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...attempts.map(
                      (a) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: NomadKit.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: NomadKit.border),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    a.quizTitle,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: NomadKit.ink,
                                    ),
                                  ),
                                  Text(
                                    'Lần ${a.attemptNo}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: NomadKit.secondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              a.hasScore ? '${a.score}/${a.total}' : 'Đã nộp',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: NomadKit.ocean,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Version History Training Records
                  const Text(
                    'LỊCH SỬ TIẾN ĐỘ THEO PHIÊN BẢN',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: NomadKit.sandDark,
                      letterSpacing: 0.7,
                    ),
                  ),
                  const SizedBox(height: 10),

                  ...tasks.map((task) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: NomadKit.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: NomadKit.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: task.status == TaskStatus.completed
                                  ? NomadKit.forest
                                  : (task.status == TaskStatus.inProgress
                                        ? NomadKit.sand
                                        : NomadKit.secondary),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  task.title,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: NomadKit.ink,
                                  ),
                                ),
                                Text(
                                  'Bản ${task.version}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: NomadKit.secondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${(task.progress * 100).toInt()}%',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: NomadKit.sandDark,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
                ],
              ),
      ),
    );
  }

  Widget _tierCard({
    required String tierNumber,
    required String title,
    required String statusBadge,
    required Color statusColor,
    required Color bgColor,
    required String iconAsset,
    required IconData icon,
    required String description,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NomadKit.surface,
        borderRadius: BorderRadius.circular(18),
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
              Image.asset(
                iconAsset,
                width: 34,
                height: 34,
                filterQuality: FilterQuality.medium,
                errorBuilder: (ctx, err, stack) =>
                    Icon(icon, color: statusColor, size: 24),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tierNumber,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: NomadKit.ink,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  statusBadge,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: const TextStyle(
              fontSize: 12,
              color: NomadKit.secondary,
              height: 1.35,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  foregroundColor: statusColor,
                ),
                onPressed: onAction,
                icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                label: Text(
                  actionLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
