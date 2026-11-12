import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/nomad_kit.dart';
import '../../core/models/app_models.dart';
import '../../core/viewmodels/auth_viewmodel.dart';
import '../../core/viewmodels/training_viewmodel.dart';
import '../../core/widgets/load_state_view.dart';
import '../../core/utils/navigation.dart';
import '../../core/widgets/personal_learning_blocked.dart';
import '../../core/widgets/redesign_widgets.dart';
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
    final practicalPassed =
        evaluations.isNotEmpty && evaluations.first.isPassed;

    return RhFlowScaffold(
      title: 'Tiến độ đào tạo cá nhân',
      body: failed
          ? LoadStateView.error(
              message: training.error ?? 'Không tải được tiến độ đào tạo.',
              onRetry: training.retry,
            )
          : loading
          ? const LoadStateView.loading()
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              children: [
                Row(
                  children: [
                    RhAvatar(initials: rhInitials(auth.displayName), size: 44),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(auth.displayName, style: NomadKit.subtitle),
                          Text(
                            'Vai trò: ${auth.roleLabel} · Chi nhánh: ${auth.storeBranch}',
                            style: NomadKit.caption,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
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
                  description:
                      'Đã hoàn thành $completedCount/$total nội dung chuẩn ($inProgressCount đang học). Tự xác nhận đọc & xem video mốc.',
                ),
                const SizedBox(height: 12),
                _tierCard(
                  tierNumber: 'TẦNG 2',
                  title: 'Kiểm tra kiến thức (Quiz)',
                  statusBadge: hasQuiz
                      ? 'Trung bình $quizPercent%'
                      : 'Chưa làm quiz',
                  statusColor: NomadKit.sandDark,
                  bgColor: NomadKit.sandLight,
                  description: attempts.isEmpty
                      ? 'Bạn chưa nộp bài quiz nào.'
                      : 'Đã nộp ${attempts.length} lượt làm bài trắc nghiệm.',
                  actionLabel: attempts.isEmpty
                      ? 'Làm bài Quiz'
                      : 'Làm lại bài Quiz',
                  onAction: () => go(context, const QuizExamPage()),
                ),
                const SizedBox(height: 12),
                _tierCard(
                  tierNumber: 'TẦNG 3',
                  title: 'Kỹ năng thực hành tại quầy',
                  statusBadge: practicalPassed
                      ? 'Đạt tiêu chuẩn'
                      : 'Chờ đánh giá',
                  statusColor: practicalPassed
                      ? NomadKit.forest
                      : NomadKit.sandDark,
                  bgColor: practicalPassed
                      ? NomadKit.forestLight
                      : NomadKit.sandLight,
                  description: evaluations.isNotEmpty
                      ? 'Được đánh giá bởi ${evaluations.first.evaluatorName} ngày ${evaluations.first.evaluatedDate}. Tiêu chí quan sát đã xác nhận.'
                      : 'Chưa có lượt đánh giá thực hành mới từ Admin.',
                  actionLabel: 'Xem checklist đánh giá',
                  onAction: () => go(context, const PracticalEvaluationPage()),
                ),
                if (attempts.isNotEmpty) ...[
                  const RhSectionHeading(title: 'Lịch sử làm bài quiz'),
                  const SizedBox(height: 6),
                  for (final a in attempts)
                    _historyRow(
                      title: a.quizTitle,
                      subtitle: 'Lần ${a.attemptNo}',
                      trailing: a.hasScore ? '${a.score}/${a.total}' : 'Đã nộp',
                    ),
                ],
                const RhSectionHeading(title: 'Lịch sử tiến độ theo phiên bản'),
                const SizedBox(height: 6),
                for (final task in tasks)
                  _historyRow(
                    title: task.title,
                    subtitle: 'Bản ${task.version}',
                    trailing: '${(task.progress * 100).toInt()}%',
                    dot: task.status == TaskStatus.completed
                        ? NomadKit.forest
                        : (task.status == TaskStatus.inProgress
                              ? NomadKit.sand
                              : NomadKit.secondary),
                  ),
              ],
            ),
    );
  }

  Widget _historyRow({
    required String title,
    required String subtitle,
    required String trailing,
    Color? dot,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: NomadKit.border)),
      ),
      child: Row(
        children: [
          if (dot != null) ...[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(shape: BoxShape.circle, color: dot),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: NomadKit.label),
                Text(subtitle, style: NomadKit.caption),
              ],
            ),
          ),
          Text(
            trailing,
            style: NomadKit.label.copyWith(
              fontWeight: FontWeight.w600,
              color: NomadKit.sandDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tierCard({
    required String tierNumber,
    required String title,
    required String statusBadge,
    required Color statusColor,
    required Color bgColor,
    required String description,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NomadKit.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NomadKit.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tierNumber,
                      style: NomadKit.caption.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                    Text(
                      title,
                      style: NomadKit.label.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusBadge,
                  style: NomadKit.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(description, style: NomadKit.caption),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: NomadKit.sandDark,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                onPressed: onAction,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      actionLabel,
                      style: NomadKit.label.copyWith(
                        fontWeight: FontWeight.w600,
                        color: NomadKit.sandDark,
                      ),
                    ),
                    const RhChevron(color: NomadKit.sandDark),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
