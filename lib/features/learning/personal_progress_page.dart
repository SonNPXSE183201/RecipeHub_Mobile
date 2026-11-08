import 'package:flutter/material.dart';
import '../../core/theme/nomad_kit.dart';
import '../../core/models/app_models.dart';
import '../../core/services/mock_data_service.dart';
import '../../core/utils/navigation.dart';
import '../practice/quiz_exam_page.dart';
import '../practice/practical_evaluation_page.dart';

class PersonalProgressPage extends StatelessWidget {
  const PersonalProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tasks = MockDataService.instance.tasks;
    final evaluations = MockDataService.instance.evaluations;

    final completedCount = tasks.where((t) => t.status == TaskStatus.completed).length;
    final inProgressCount = tasks.where((t) => t.status == TaskStatus.inProgress).length;
    final total = tasks.length;
    final readingPercent = total > 0 ? (completedCount / total * 100).toInt() : 0;

    return Scaffold(
      backgroundColor: NomadKit.canvas,
      appBar: AppBar(
        backgroundColor: NomadKit.canvas,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: NomadKit.ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Tiến độ đào tạo cá nhân',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: NomadKit.ink),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [
            // Student Profile Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: NomadKit.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: NomadKit.border),
                boxShadow: const [
                  BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 2)),
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
                      child: Icon(Icons.school_rounded, color: NomadKit.sandDark, size: 28),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          MockDataService.instance.currentUserName,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: NomadKit.ink),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Vai trò: Barista · Chi nhánh: ${MockDataService.instance.currentStoreBranch}',
                          style: const TextStyle(fontSize: 11, color: NomadKit.secondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Mandatory 3-Tier Evaluation Architecture (BR-01)
            const Text(
              '3 TẦNG KẾT QUẢ ĐÀO TẠO ĐỘC LẬP (BR-01)',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: NomadKit.sandDark, letterSpacing: 0.7),
            ),
            const SizedBox(height: 4),
            const Text(
              'Tiếp nhận nội dung ≠ Đạt kiến thức lý thuyết ≠ Đạt kỹ năng thực hành.',
              style: TextStyle(fontSize: 12, color: NomadKit.secondary),
            ),
            const SizedBox(height: 12),

            // Tier 1: Tiếp nhận nội dung (Đọc/Xem)
            _tierCard(
              tierNumber: 'TẦNG 1',
              title: 'Tiếp nhận nội dung (Đọc/Xem)',
              statusBadge: '$readingPercent% Hoàn thành',
              statusColor: readingPercent >= 80 ? NomadKit.forest : NomadKit.warning,
              bgColor: readingPercent >= 80 ? NomadKit.forestLight : NomadKit.warningLight,
              iconAsset: 'assets/icons/icon_recipe_book.png',
              icon: Icons.auto_stories_rounded,
              description: 'Đã hoàn thành $completedCount/$total nội dung chuẩn ($inProgressCount đang học). Tự xác nhận đọc & xem video mốc.',
            ),
            const SizedBox(height: 12),

            // Tier 2: Hiểu kiến thức (Quiz)
            _tierCard(
              tierNumber: 'TẦNG 2',
              title: 'Kiểm tra kiến thức (Quiz)',
              statusBadge: '9/10 Điểm · Đạt',
              statusColor: NomadKit.ocean,
              bgColor: NomadKit.oceanLight,
              iconAsset: 'assets/icons/icon_quiz_exam.png',
              icon: Icons.quiz_rounded,
              description: 'Đã vượt qua bộ câu hỏi trắc nghiệm kiểm tra định lượng và nhiệt độ chuẩn.',
              actionLabel: 'Làm lại bài Quiz',
              onAction: () => go(context, const QuizExamPage()),
            ),
            const SizedBox(height: 12),

            // Tier 3: Kỹ năng thực hành (Practical Evaluation)
            _tierCard(
              tierNumber: 'TẦNG 3',
              title: 'Kỹ năng thực hành tại quầy',
              statusBadge: evaluations.isNotEmpty && evaluations.first.isPassed ? 'Đạt tiêu chuẩn' : 'Chờ đánh giá',
              statusColor: evaluations.isNotEmpty && evaluations.first.isPassed ? NomadKit.forest : NomadKit.sandDark,
              bgColor: evaluations.isNotEmpty && evaluations.first.isPassed ? NomadKit.forestLight : NomadKit.sandLight,
              iconAsset: 'assets/icons/icon_evaluation_rubric.png',
              icon: Icons.checklist_rounded,
              description: evaluations.isNotEmpty
                  ? 'Được đánh giá bởi ${evaluations.first.evaluatorName} ngày ${evaluations.first.evaluatedDate}. Tiêu chí quan sát đã xác nhận.'
                  : 'Chưa có lượt đánh giá thực hành mới từ Admin.',
              actionLabel: 'Xem checklist đánh giá',
              onAction: () => go(context, const PracticalEvaluationPage()),
            ),
            const SizedBox(height: 24),

            // Version History Training Records
            const Text(
              'LỊCH SỬ TIẾN ĐỘ THEO PHIÊN BẢN',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: NomadKit.sandDark, letterSpacing: 0.7),
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
                            : (task.status == TaskStatus.inProgress ? NomadKit.sand : NomadKit.secondary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: NomadKit.ink),
                          ),
                          Text(
                            'Mã: ${task.targetCode} · Bản ${task.version}',
                            style: const TextStyle(fontSize: 11, color: NomadKit.secondary),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${(task.progress * 100).toInt()}%',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: NomadKit.sandDark),
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
          BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 2)),
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
                errorBuilder: (ctx, err, stack) => Icon(icon, color: statusColor, size: 24),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tierNumber,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: statusColor, letterSpacing: 0.5),
                    ),
                    Text(
                      title,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: NomadKit.ink),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
                child: Text(
                  statusBadge,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(description, style: const TextStyle(fontSize: 12, color: NomadKit.secondary, height: 1.35)),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  foregroundColor: statusColor,
                ),
                onPressed: onAction,
                icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                label: Text(actionLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
