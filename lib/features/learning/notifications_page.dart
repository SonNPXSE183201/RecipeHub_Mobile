import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/nomad_kit.dart';
import '../../core/models/session_models.dart';
import '../../core/navigation/app_keys.dart';
import '../../core/viewmodels/notification_viewmodel.dart';
import '../../core/widgets/redesign_widgets.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  String _selectedFilter = 'Tất cả';

  final List<String> _filters = ['Tất cả', 'Việc học', 'Phiên bản', 'Phản hồi'];

  static String _ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'Vừa xong';
    if (d.inMinutes < 60) return '${d.inMinutes} phút trước';
    if (d.inHours < 24) return '${d.inHours} giờ trước';
    if (d.inDays == 1) return 'Hôm qua';
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
    final all = vm.items;
    final unread = all.where((n) => !n.isRead).length;

    final filtered = all.where((n) {
      final type = _typeOf(n.kind);
      switch (_selectedFilter) {
        case 'Việc học':
          return type == 'task_assigned';
        case 'Phiên bản':
          return type == 'version_update';
        case 'Phản hồi':
          return type == 'feedback_reply';
        default:
          return true;
      }
    }).toList();

    return RhFlowScaffold(
      title: 'Thông báo',
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Cập nhật dành cho bạn',
            style: NomadKit.title.copyWith(fontSize: 23),
          ),
          const SizedBox(height: 10),
          Text(
            unread > 0
                ? '$unread thông báo chưa đọc · Từ quản lý cửa hàng'
                : 'Bạn đã đọc hết thông báo',
            style: NomadKit.caption.copyWith(color: NomadKit.ink),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              key: AppKeys.markAllRead,
              onPressed: unread > 0 ? () => vm.markAllRead() : null,
              style: OutlinedButton.styleFrom(
                foregroundColor: NomadKit.ink,
                backgroundColor: NomadKit.surface,
                side: const BorderSide(color: NomadKit.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Đánh dấu tất cả đã đọc',
                style: NomadKit.label.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final f in _filters)
                  Padding(
                    padding: const EdgeInsets.only(right: 22),
                    child: InkWell(
                      onTap: () => setState(() => _selectedFilter = f),
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 40),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: _selectedFilter == f
                                  ? NomadKit.sandDark
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                        child: Text(
                          f,
                          style: NomadKit.label.copyWith(
                            fontWeight: FontWeight.w600,
                            color: _selectedFilter == f
                                ? NomadKit.sandDark
                                : NomadKit.ink,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Column(
                children: [
                  const RhSvgIcon(
                    'assets/redesign/clipboard.svg',
                    size: 32,
                    color: NomadKit.secondary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Không có thông báo nào',
                    style: NomadKit.body.copyWith(color: NomadKit.secondary),
                  ),
                ],
              ),
            )
          else
            for (final n in filtered)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _NotificationRow(
                  key: Key('notification_tile_${n.id}'),
                  notification: n,
                  kindLabel: switch (_typeOf(n.kind)) {
                    'version_update' => 'ĐỔI PHIÊN BẢN',
                    'feedback_reply' => 'PHẢN HỒI',
                    _ => 'VIỆC HỌC',
                  },
                  icon: switch (_typeOf(n.kind)) {
                    'version_update' => Icons.sync_rounded,
                    'feedback_reply' => Icons.chat_bubble_outline_rounded,
                    _ => Icons.school_outlined,
                  },
                  time: _ago(n.receivedAt),
                  onTap: () => vm.open(n),
                ),
              ),
        ],
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({
    super.key,
    required this.notification,
    required this.kindLabel,
    required this.icon,
    required this.time,
    required this.onTap,
  });

  final AppNotification notification;
  final String kindLabel;
  final IconData icon;
  final String time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isRead = notification.isRead;
    return Material(
      color: isRead ? NomadKit.surface : NomadKit.sandLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: NomadKit.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 22, color: NomadKit.sandDark),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$kindLabel · $time',
                      style: NomadKit.caption.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: NomadKit.ink,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              Text(
                notification.title,
                style: NomadKit.section.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                notification.body,
                style: NomadKit.caption.copyWith(color: NomadKit.ink),
              ),
              const SizedBox(height: 7),
              Text(
                isRead ? 'Đã đọc' : 'Chưa đọc',
                style: NomadKit.caption.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: NomadKit.sandDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
