import '../../core/viewmodels/auth_viewmodel.dart';
import '../../core/widgets/personal_learning_blocked.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/nomad_kit.dart';
import '../../core/models/app_models.dart';
import '../../core/viewmodels/notification_viewmodel.dart';
import '../../core/viewmodels/training_viewmodel.dart';
import '../../core/widgets/load_state_view.dart';
import '../../core/widgets/redesign_widgets.dart';
import '../../core/utils/navigation.dart';
import 'learning_task_detail_page.dart';
import 'notifications_page.dart';
import 'personal_progress_page.dart';
import '../practice/quiz_exam_page.dart';
import '../practice/practical_evaluation_page.dart';
import '../../core/widgets/rh_motion.dart';

class MyLearningPage extends StatefulWidget {
  const MyLearningPage({super.key});

  @override
  State<MyLearningPage> createState() => _MyLearningPageState();
}

class _MyLearningPageState extends State<MyLearningPage>
    with SingleTickerProviderStateMixin {
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
    if (!context.watch<AuthViewModel>().hasPersonalLearning) {
      return const PersonalLearningBlocked();
    }
    final training = context.watch<TrainingViewModel>();
    final tasks = training.tasks;

    final notStartedTasks = tasks
        .where((t) => t.status == TaskStatus.notStarted)
        .toList();
    final inProgressTasks = tasks
        .where((t) => t.status == TaskStatus.inProgress)
        .toList();
    final completedTasks = tasks
        .where((t) => t.status == TaskStatus.completed)
        .toList();

    final unread = context.watch<NotificationViewModel>().unreadCount;
    return Scaffold(
      backgroundColor: NomadKit.canvas,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RhPageHeader(
              title: 'Việc học',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Semantics(
                    label: 'Tiến độ cá nhân',
                    button: true,
                    child: IconButton(
                      tooltip: 'Tiến độ cá nhân',
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                      color: NomadKit.sandDark,
                      onPressed: () =>
                          go(context, const PersonalProgressPage()),
                      icon: const Icon(Icons.insights_rounded),
                    ),
                  ),
                  _BellButton(
                    hasUnread: unread > 0,
                    onTap: () => go(context, const NotificationsPage()),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Việc học của tôi',
                    style: NomadKit.title.copyWith(fontSize: 25),
                  ),
                  const SizedBox(height: 14),
                  _DarkButton(
                    label: 'Làm bài Quiz',
                    onTap: () => go(context, const QuizExamPage()),
                  ),
                  const SizedBox(height: 12),
                  _DarkButton(
                    label: 'Kết quả thực hành',
                    onTap: () => go(context, const PracticalEvaluationPage()),
                  ),
                  const SizedBox(height: 8),
                  TabBar(
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    dividerColor: NomadKit.border,
                    controller: _tabController,
                    indicatorColor: NomadKit.sandDark,
                    indicatorWeight: 2,
                    indicatorSize: TabBarIndicatorSize.label,
                    labelColor: NomadKit.sandDark,
                    unselectedLabelColor: NomadKit.secondary,
                    labelPadding: const EdgeInsets.only(right: 18),
                    labelStyle: NomadKit.label.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: NomadKit.label,
                    tabs: [
                      Tab(text: 'Đang học (${inProgressTasks.length})'),
                      Tab(text: 'Chưa học (${notStartedTasks.length})'),
                      Tab(text: 'Hoàn thành (${completedTasks.length})'),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child:
                  (training.taskState == LoadState.error && tasks.isEmpty) ||
                      training.progressState == LoadState.error
                  ? LoadStateView.error(
                      message: training.error ?? 'Không tải được nhiệm vụ học.',
                      onRetry: training.retry,
                    )
                  : (training.taskState == LoadState.loading &&
                            tasks.isEmpty) ||
                        training.progressState == LoadState.loading
                  ? const LoadStateView.loading()
                  : TabBarView(
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
            Icon(
              Icons.assignment_turned_in_outlined,
              size: 48,
              color: NomadKit.secondary.withOpacity(0.4),
            ),
            const SizedBox(height: 12),
            const Text(
              'Không có nhiệm vụ nào trong danh mục này',
              style: TextStyle(fontSize: 14, color: NomadKit.secondary),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: list.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, idx) {
        final task = list[idx];
        Future<void> open() async {
          await Navigator.push(
            context,
            RhPageRoute(
              builder: (_) => LearningTaskDetailPage(task: task),
            ),
          );
          if (mounted) setState(() {});
        }

        final statusLabel = task.status == TaskStatus.completed
            ? 'Hoàn thành'
            : task.status == TaskStatus.inProgress
            ? 'Đang học'
            : 'Chưa học';
        final flag = task.isOverdue
            ? 'Quá hạn'
            : task.isRelearnRequired
            ? 'Cần học lại'
            : null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Material(
              color: NomadKit.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: NomadKit.border),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: open,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: NomadKit.section.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${task.type} · $statusLabel · Người giao: ${task.assignedBy}',
                        style: NomadKit.label.copyWith(
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      Text(
                        'Hạn hoàn thành: ${task.dueDate}${flag == null ? '' : ' · $flag'}',
                        style: NomadKit.label.copyWith(
                          fontWeight: FontWeight.w400,
                          color: task.isOverdue ? NomadKit.error : NomadKit.ink,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
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
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${(task.progress * 100).toInt()}%',
                            style: NomadKit.label,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (task.status == TaskStatus.inProgress) ...[
              const SizedBox(height: 12),
              _DarkButton(label: 'Mở nhiệm vụ học', onTap: open),
            ],
          ],
        );
      },
    );
  }
}

class _DarkButton extends StatelessWidget {
  const _DarkButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: NomadKit.sandDark,
    borderRadius: BorderRadius.circular(12),
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 48),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(14),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: NomadKit.label.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ),
  );
}

class _BellButton extends StatelessWidget {
  const _BellButton({required this.hasUnread, required this.onTap});

  final bool hasUnread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Thông báo',
    child: InkResponse(
      onTap: onTap,
      radius: 24,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: NomadKit.sandLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  size: 22,
                  color: NomadKit.sandDark,
                ),
              ),
              if (hasUnread)
                Positioned(
                  right: 1,
                  top: 1,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: NomadKit.sandDark,
                      shape: BoxShape.circle,
                      border: Border.all(color: NomadKit.canvas, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
