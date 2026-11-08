import 'package:flutter/material.dart';
import '../../core/theme/nomad_kit.dart';
import '../../core/models/app_models.dart';
import '../../core/services/mock_data_service.dart';
import '../../core/utils/navigation.dart';
import '../lookup/step_video_guide_page.dart';
import '../sop/sop_detail_page.dart';

class LearningTaskDetailPage extends StatefulWidget {
  const LearningTaskDetailPage({super.key, required this.task});

  final LearningTaskItem task;

  @override
  State<LearningTaskDetailPage> createState() => _LearningTaskDetailPageState();
}

class _LearningTaskDetailPageState extends State<LearningTaskDetailPage> {
  late List<bool> _sectionCompleted;

  @override
  void initState() {
    super.initState();
    _sectionCompleted = List.generate(
      widget.task.sections.length,
      (idx) => (widget.task.progress >= ((idx + 1) / widget.task.sections.length)),
    );
  }

  void _toggleSection(int idx) {
    setState(() {
      _sectionCompleted[idx] = !_sectionCompleted[idx];
      final completedCount = _sectionCompleted.where((c) => c).length;
      widget.task.progress = completedCount / widget.task.sections.length;
      if (widget.task.progress >= 1.0) {
        widget.task.status = TaskStatus.completed;
      } else if (widget.task.progress > 0) {
        widget.task.status = TaskStatus.inProgress;
      } else {
        widget.task.status = TaskStatus.notStarted;
      }
    });
  }

  void _markAllCompleted() {
    setState(() {
      for (int i = 0; i < _sectionCompleted.length; i++) {
        _sectionCompleted[i] = true;
      }
      widget.task.progress = 1.0;
      widget.task.status = TaskStatus.completed;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã xác nhận hoàn thành nội dung đọc/xem. Kết quả thực hành cần được Admin đánh giá riêng.'),
        backgroundColor: NomadKit.forest,
      ),
    );
  }

  void _openRelatedContent() {
    if (widget.task.type == 'Công thức') {
      final recipe = MockDataService.instance.recipes.firstWhere(
        (r) => r.code == widget.task.targetCode,
        orElse: () => MockDataService.instance.recipes.first,
      );
      go(context, StepVideoGuidePage(recipe: recipe, initialStepNumber: 1));
    } else {
      final sop = MockDataService.instance.sops.firstWhere(
        (s) => s.code == widget.task.targetCode,
        orElse: () => MockDataService.instance.sops.first,
      );
      go(context, SopDetailPage(sop: sop));
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;

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
          'Chi tiết nhiệm vụ học',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: NomadKit.ink),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                          BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 2)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: NomadKit.secondary),
                              ),
                              const Spacer(),
                              if (task.isOverdue)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEE2E2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text('Quá hạn', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: NomadKit.error)),
                                )
                              else if (task.isRelearnRequired)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: NomadKit.warningLight,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text('Cần học lại', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: NomadKit.warning)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          Text(
                            task.title,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: NomadKit.ink),
                          ),
                          const SizedBox(height: 8),

                          Text('Người giao: ${task.assignedBy}', style: const TextStyle(fontSize: 12, color: NomadKit.secondary)),
                          Text('Ngày giao: ${task.assignedDate}', style: const TextStyle(fontSize: 12, color: NomadKit.secondary)),
                          Text(
                            'Hạn chót: ${task.dueDate}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: task.isOverdue ? NomadKit.error : NomadKit.secondary,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Progress Slider Bar
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Tiến độ đọc/xem:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: NomadKit.ink)),
                              Text(
                                '${(task.progress * 100).toInt()}%',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: NomadKit.sandDark),
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
                                task.progress >= 1.0 ? NomadKit.forest : NomadKit.sand,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Rule Alert Banner (BR-01)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: NomadKit.forestLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: NomadKit.forest.withOpacity(0.2)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.verified_rounded, size: 20, color: NomadKit.forest),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Nguyên tắc đào tạo chuẩn: Đọc & xem video là bằng chứng tiếp nhận nội dung. Kỹ năng thực hành tại quầy bar sẽ do Admin quan sát và đánh giá checklist riêng.',
                              style: TextStyle(fontSize: 12, color: NomadKit.forest.withOpacity(0.95), height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Sections Checklist
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'CÁC PHẦN CẦN HOÀN THÀNH',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: NomadKit.sandDark, letterSpacing: 0.7),
                        ),
                        Text(
                          '${_sectionCompleted.where((c) => c).length}/${task.sections.length} mục',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: NomadKit.secondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    ...List.generate(task.sections.length, (idx) {
                      final isDone = _sectionCompleted[idx];
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
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            title: Text(
                              task.sections[idx],
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isDone ? NomadKit.secondary : NomadKit.ink,
                                decoration: isDone ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            subtitle: Text(
                              isDone ? 'Đã hoàn thành phần này' : 'Chưa hoàn tất',
                              style: TextStyle(fontSize: 11, color: isDone ? NomadKit.forest : NomadKit.secondary),
                            ),
                            value: isDone,
                            onChanged: (_) => _toggleSection(idx),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 10),

                    // Linked Material Summary Card
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _openRelatedContent,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: NomadKit.sandLight,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: NomadKit.sand.withOpacity(0.35)),
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
                                    '${task.targetCode} · Phiên bản ${task.version}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: NomadKit.ink,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, size: 20, color: NomadKit.sandDark),
                          ],
                        ),
                      ),
                    ),
                  ],
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
                          backgroundColor: NomadKit.forestLight.withOpacity(0.45),
                          side: const BorderSide(color: NomadKit.forest, width: 1.2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        onPressed: _markAllCompleted,
                        icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                        label: const Text(
                          'Hoàn thành',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          elevation: 0,
                        ),
                        onPressed: _openRelatedContent,
                        icon: const Icon(Icons.play_circle_fill_rounded, size: 19),
                        label: const Text(
                          'Mở học ngay',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
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
