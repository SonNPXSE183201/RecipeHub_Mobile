import 'package:flutter/material.dart';
import '../../core/theme/nomad_kit.dart';
import '../../core/models/app_models.dart';
import '../../core/services/mock_data_service.dart';
import '../../core/utils/navigation.dart';
import 'learning_task_detail_page.dart';
import 'personal_progress_page.dart';
import '../practice/quiz_exam_page.dart';
import '../practice/practical_evaluation_page.dart';

class MyLearningPage extends StatefulWidget {
  const MyLearningPage({super.key});

  @override
  State<MyLearningPage> createState() => _MyLearningPageState();
}

class _MyLearningPageState extends State<MyLearningPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tasks = MockDataService.instance.tasks;

    final notStartedTasks = tasks.where((t) => t.status == TaskStatus.notStarted).toList();
    final inProgressTasks = tasks.where((t) => t.status == TaskStatus.inProgress).toList();
    final completedTasks = tasks.where((t) => t.status == TaskStatus.completed).toList();

    return Scaffold(
      backgroundColor: NomadKit.canvas,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Việc học của tôi',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: NomadKit.ink),
                      ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          side: const BorderSide(color: NomadKit.sandDark),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          foregroundColor: NomadKit.sandDark,
                        ),
                        onPressed: () => go(context, const PersonalProgressPage()),
                        icon: const Icon(Icons.insights_rounded, size: 16),
                        label: const Text('Tiến độ cá nhân', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Nội dung chuẩn và SOP được phân công theo từng phiên bản.',
                    style: TextStyle(fontSize: 13, color: NomadKit.secondary),
                  ),
                  const SizedBox(height: 14),

                  // Quick links to Extension modules (Quiz, Practical Results)
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => go(context, const QuizExamPage()),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: NomadKit.sandLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: NomadKit.border),
                            ),
                            child: Row(
                              children: [
                                Image.asset(
                                  'assets/icons/icon_quiz_exam.png',
                                  width: 22,
                                  height: 22,
                                  filterQuality: FilterQuality.medium,
                                  errorBuilder: (ctx, err, stack) => const Icon(Icons.quiz_outlined, size: 18, color: NomadKit.sandDark),
                                ),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text('Làm bài Quiz', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: NomadKit.sandDark)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => go(context, const PracticalEvaluationPage()),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: NomadKit.forestLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: NomadKit.forest.withOpacity(0.2)),
                            ),
                            child: Row(
                              children: [
                                Image.asset(
                                  'assets/icons/icon_evaluation_rubric.png',
                                  width: 22,
                                  height: 22,
                                  filterQuality: FilterQuality.medium,
                                  errorBuilder: (ctx, err, stack) => const Icon(Icons.checklist_rounded, size: 18, color: NomadKit.forest),
                                ),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text('Kết quả thực hành', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: NomadKit.forest)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 3 Tabs
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: NomadKit.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: NomadKit.border),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicatorColor: NomadKit.sand,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        color: NomadKit.sand,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: NomadKit.secondary,
                      labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      tabs: [
                        Tab(text: 'Đang học (${inProgressTasks.length})'),
                        Tab(text: 'Chưa học (${notStartedTasks.length})'),
                        Tab(text: 'Hoàn thành (${completedTasks.length})'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: NomadKit.border),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTaskList(inProgressTasks),
                  _buildTaskList(notStartedTasks),
                  _buildTaskList(completedTasks),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskList(List<LearningTaskItem> list) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_turned_in_outlined, size: 48, color: NomadKit.secondary.withOpacity(0.4)),
            const SizedBox(height: 12),
            const Text('Không có nhiệm vụ nào trong danh mục này', style: TextStyle(fontSize: 14, color: NomadKit.secondary)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: list.length,
      itemBuilder: (context, idx) {
        final task = list[idx];
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: NomadKit.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: NomadKit.border),
            boxShadow: const [
              BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 2)),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => LearningTaskDetailPage(task: task)),
                );
                if (mounted) setState(() {});
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top: Tag + Code & Badges
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: task.type == 'Công thức' ? NomadKit.sandLight : NomadKit.oceanLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${task.type}: ${task.targetCode}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'monospace',
                              color: task.type == 'Công thức' ? NomadKit.sandDark : NomadKit.ocean,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          task.version,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: NomadKit.secondary),
                        ),
                        const Spacer(),

                        if (task.isOverdue)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('Quá hạn', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: NomadKit.error)),
                          )
                        else if (task.isRelearnRequired)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: NomadKit.warningLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('Cần học lại', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: NomadKit.warning)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Title
                    Text(
                      task.title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: NomadKit.ink),
                    ),
                    const SizedBox(height: 6),

                    Text(
                      'Người giao: ${task.assignedBy}',
                      style: const TextStyle(fontSize: 12, color: NomadKit.secondary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Hạn hoàn thành: ${task.dueDate}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: task.isOverdue ? NomadKit.error : NomadKit.secondary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Progress Bar
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: task.progress,
                              minHeight: 6,
                              backgroundColor: NomadKit.canvas,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                task.progress >= 1.0 ? NomadKit.forest : NomadKit.sand,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${(task.progress * 100).toInt()}%',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: NomadKit.ink),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

