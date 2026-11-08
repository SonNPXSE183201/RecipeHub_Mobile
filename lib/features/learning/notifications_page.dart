import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/nomad_kit.dart';
import '../../core/models/session_models.dart';
import '../../core/navigation/app_keys.dart';
import '../../core/viewmodels/notification_viewmodel.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  String _selectedFilter = 'Tất cả';

  final List<String> _filters = ['Tất cả', 'Việc học', 'Đổi phiên bản', 'Phản hồi'];

  static String _ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'Vừa xong';
    if (d.inMinutes < 60) return '${d.inMinutes} phút trước';
    if (d.inHours < 24) return '${d.inHours} giờ trước';
    return '${d.inDays} ngày trước';
  }

  static String _typeOf(NotificationKind k) {
    switch (k) {
      case NotificationKind.versionUpdate:
        return 'version_update';
      case NotificationKind.feedbackReply:
        return 'feedback_reply';
      default:
        return 'task_assigned';
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<NotificationViewModel>();
    final notifs = vm.items
        .map((n) => <String, dynamic>{
              'n': n,
              'id': n.id,
              'title': n.title,
              'body': n.body,
              'time': _ago(n.receivedAt),
              'isRead': n.isRead,
              'type': _typeOf(n.kind),
            })
        .toList();

    final filtered = notifs.where((n) {
      if (_selectedFilter == 'Tất cả') return true;
      if (_selectedFilter == 'Việc học') return n['type'] == 'task_assigned';
      if (_selectedFilter == 'Đổi phiên bản') return n['type'] == 'version_update';
      if (_selectedFilter == 'Phản hồi') return n['type'] == 'feedback_reply';
      return true;
    }).toList();

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
          'Thông báo & Thay đổi',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: NomadKit.ink),
        ),
        actions: [
          TextButton(
            key: AppKeys.markAllRead,
            onPressed: () => vm.markAllRead(),
            child: const Text('Đã đọc tất cả', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: NomadKit.sandDark)),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter Chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: SingleChildScrollView(
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
                        selectedColor: NomadKit.sand,
                        backgroundColor: NomadKit.surface,
                        side: BorderSide(color: isSelected ? NomadKit.sand : NomadKit.border),
                        showCheckmark: false,
                        onSelected: (val) {
                          if (val) setState(() => _selectedFilter = f);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const Divider(height: 1, color: NomadKit.border),

            // Notification List
            Expanded(
              child: filtered.isEmpty
                  ? const Center(
                      child: Text('Không có thông báo nào', style: TextStyle(fontSize: 14, color: NomadKit.secondary)),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: filtered.length,
                      itemBuilder: (context, idx) {
                        final item = filtered[idx];
                        final bool isRead = item['isRead'] as bool;
                        final String type = item['type'] as String;

                        IconData icon;
                        Color iconColor;
                        Color iconBg;

                        if (type == 'version_update') {
                          icon = Icons.update_rounded;
                          iconColor = NomadKit.warning;
                          iconBg = NomadKit.warningLight;
                        } else if (type == 'feedback_reply') {
                          icon = Icons.forum_rounded;
                          iconColor = NomadKit.forest;
                          iconBg = NomadKit.forestLight;
                        } else {
                          icon = Icons.school_rounded;
                          iconColor = NomadKit.ocean;
                          iconBg = NomadKit.oceanLight;
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: isRead ? NomadKit.surface : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isRead ? NomadKit.border : NomadKit.sand.withOpacity(0.5),
                              width: isRead ? 1 : 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isRead ? const Color(0x04000000) : const Color(0x0C000000),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
                              child: Icon(icon, color: iconColor, size: 20),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item['title'] as String,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isRead ? FontWeight.w700 : FontWeight.w900,
                                      color: NomadKit.ink,
                                    ),
                                  ),
                                ),
                                if (!isRead)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: NomadKit.sand,
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  item['body'] as String,
                                  style: const TextStyle(fontSize: 12, color: NomadKit.ink, height: 1.3),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  item['time'] as String,
                                  style: const TextStyle(fontSize: 11, color: NomadKit.secondary),
                                ),
                              ],
                            ),
                            key: Key('notification_tile_${item['id']}'),
                            onTap: () => vm.open(item['n'] as AppNotification),
                          ),
                        ),
                      );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
