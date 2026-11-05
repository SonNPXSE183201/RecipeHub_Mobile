import 'package:flutter/material.dart';
import '../../core/theme/nomad_kit.dart';
import '../../core/models/app_models.dart';
import '../../core/services/mock_data_service.dart';
import 'create_feedback_page.dart';

class MyFeedbackListPage extends StatefulWidget {
  const MyFeedbackListPage({super.key});

  @override
  State<MyFeedbackListPage> createState() => _MyFeedbackListPageState();
}

class _MyFeedbackListPageState extends State<MyFeedbackListPage> {
  String _selectedFilter = 'Tất cả';

  final List<String> _filters = ['Tất cả', 'Đã giải quyết', 'Đang xử lý', 'Mới'];

  @override
  Widget build(BuildContext context) {
    final feedbacks = MockDataService.instance.feedbacks;

    final filtered = feedbacks.where((fb) {
      if (_selectedFilter == 'Tất cả') return true;
      if (_selectedFilter == 'Đã giải quyết') return fb.status == FeedbackStatus.resolved;
      if (_selectedFilter == 'Đang xử lý') return fb.status == FeedbackStatus.inProgress;
      if (_selectedFilter == 'Mới') return fb.status == FeedbackStatus.newFeedback;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: NomadKit.canvas,
      body: SafeArea(
        child: Column(
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
                        'Phản hồi của tôi',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: NomadKit.ink),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: NomadKit.sand,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CreateFeedbackPage()),
                          );
                          if (mounted) setState(() {});
                        },
                        icon: Image.asset(
                          'assets/icons/icon_feedback_pencil.png',
                          width: 18,
                          height: 18,
                          filterQuality: FilterQuality.medium,
                          errorBuilder: (ctx, err, stack) => const Icon(Icons.add_rounded, size: 18),
                        ),
                        label: const Text('Gửi phản hồi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Trao đổi trực tiếp với Admin về các vấn đề pha chế và SOP.',
                    style: TextStyle(fontSize: 13, color: NomadKit.secondary),
                  ),
                  const SizedBox(height: 12),

                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _filters.map((f) {
                        final isSelected = _selectedFilter == f;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(
                              f,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? Colors.white : NomadKit.ink,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: NomadKit.sandDark,
                            backgroundColor: NomadKit.surface,
                            side: BorderSide(color: isSelected ? NomadKit.sandDark : NomadKit.border),
                            showCheckmark: false,
                            onSelected: (val) {
                              if (val) setState(() => _selectedFilter = f);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: NomadKit.border),

            // Feedback List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.forum_outlined, size: 48, color: NomadKit.secondary.withOpacity(0.4)),
                          const SizedBox(height: 12),
                          const Text('Chưa có phản hồi nào trong mục này', style: TextStyle(fontSize: 14, color: NomadKit.secondary)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: filtered.length,
                      itemBuilder: (context, idx) {
                        final fb = filtered[idx];
                        return _buildFeedbackCard(fb);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackCard(FeedbackItemModel fb) {
    String statusText;
    Color statusBg;
    Color statusColor;

    switch (fb.status) {
      case FeedbackStatus.resolved:
        statusText = 'Đã giải quyết';
        statusBg = NomadKit.forestLight;
        statusColor = NomadKit.forest;
        break;
      case FeedbackStatus.inProgress:
        statusText = 'Đang xử lý';
        statusBg = NomadKit.sandLight;
        statusColor = NomadKit.sandDark;
        break;
      case FeedbackStatus.waitingInfo:
        statusText = 'Chờ bổ sung';
        statusBg = NomadKit.warningLight;
        statusColor = NomadKit.warning;
        break;
      case FeedbackStatus.newFeedback:
      default:
        statusText = 'Mới gửi';
        statusBg = NomadKit.oceanLight;
        statusColor = NomadKit.ocean;
        break;
    }

    String typeLabel = fb.type == FeedbackType.issue
        ? 'Báo vấn đề'
        : (fb.type == FeedbackType.inquiry ? 'Hỏi cách làm' : 'Đề xuất');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: NomadKit.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: NomadKit.border),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top: Type + Target + Status Chip
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: NomadKit.canvas,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: NomadKit.border),
                  ),
                  child: Text(
                    typeLabel,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: NomadKit.secondary),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${fb.targetName} (${fb.targetCode} · ${fb.version})',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: NomadKit.ink),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    statusText,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: statusColor),
                  ),
                ),
              ],
            ),
            if (fb.stepNote != null) ...[
              const SizedBox(height: 4),
              Text(
                'Ngữ cảnh: ${fb.stepNote}',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: NomadKit.ocean),
              ),
            ],
            const SizedBox(height: 10),

            // Sender Content Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: NomadKit.canvas,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Bạn (${fb.senderName})',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: NomadKit.ink),
                      ),
                      Text(fb.createdAt, style: const TextStyle(fontSize: 10, color: NomadKit.secondary)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    fb.content,
                    style: const TextStyle(fontSize: 13, color: NomadKit.ink, height: 1.35),
                  ),
                ],
              ),
            ),

            // Replies Thread from Admin
            if (fb.replies.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...fb.replies.map((reply) {
                return Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: NomadKit.forestLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: NomadKit.forest.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.verified_user_rounded, size: 14, color: NomadKit.forest),
                              const SizedBox(width: 4),
                              Text(
                                reply.senderName,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: NomadKit.forest),
                              ),
                            ],
                          ),
                          Text(reply.time, style: const TextStyle(fontSize: 10, color: NomadKit.secondary)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        reply.message,
                        style: const TextStyle(fontSize: 12, color: NomadKit.ink, height: 1.35),
                      ),
                    ],
                  ),
                );
              }),
            ] else ...[
              const SizedBox(height: 8),
              const Text(
                '⏳ Đang chờ Admin phụ trách đào tạo tiếp nhận và phản hồi.',
                style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: NomadKit.secondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
