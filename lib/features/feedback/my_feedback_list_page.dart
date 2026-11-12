import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/di/app_services.dart';
import '../../core/theme/nomad_kit.dart';
import '../../core/viewmodels/auth_viewmodel.dart';
import '../../core/viewmodels/feedback_viewmodel.dart';
import '../../core/widgets/redesign_widgets.dart';
import '../../core/utils/navigation.dart';
import '../learning/notifications_page.dart';
import 'create_feedback_page.dart';
import 'feedback_detail_page.dart';
import 'feedback_widgets.dart';
import '../../core/widgets/rh_motion.dart';

/// M-12 Phản hồi: Barista xem phản hồi của mình, Admin xem mọi phản hồi. Real-time từ Firestore.
class MyFeedbackListPage extends StatelessWidget {
  const MyFeedbackListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppServices>();
    return ChangeNotifierProvider(
      create: (_) => FeedbackListViewModel(repo: s.feedback, crash: s.crash),
      child: const _FeedbackListView(),
    );
  }
}

class _FeedbackListView extends StatelessWidget {
  const _FeedbackListView();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final vm = context.watch<FeedbackListViewModel>();
    final uid = auth.user?.uid;
    if (uid != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => vm.bind(uid: uid, isAdmin: auth.isAdmin),
      );
    }
    final isAdmin = auth.isAdmin;

    return Scaffold(
      backgroundColor: NomadKit.canvas,
      body: SafeArea(
        child: Column(
          children: [
            const RhPageHeader(title: 'Phản hồi', trailing: _BellButton()),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 44,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${vm.countFor(FeedbackFilter.all)} phản hồi',
                            style: NomadKit.label.copyWith(
                              color: NomadKit.secondary,
                            ),
                          ),
                        ),
                        if (!isAdmin)
                          Semantics(
                            label: 'Gửi phản hồi',
                            button: true,
                            child: OutlinedButton.icon(
                              onPressed: () => Navigator.push(
                                context,
                                RhPageRoute(
                                  builder: (_) => const CreateFeedbackPage(),
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(48, 44),
                                backgroundColor: NomadKit.surface,
                                foregroundColor: NomadKit.ink,
                                side: const BorderSide(color: NomadKit.border),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              icon: const RhSvgIcon(
                                'assets/redesign/image_plus.svg',
                                size: 16,
                              ),
                              label: Text(
                                'Tạo phản hồi',
                                style: NomadKit.label,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: FeedbackFilter.values.map((f) {
                        final selected = vm.filter == f;
                        final count = vm.countFor(f);
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(
                              count > 0 ? '${f.label} · $count' : f.label,
                              style: NomadKit.label.copyWith(
                                color: selected ? Colors.white : NomadKit.ink,
                              ),
                            ),
                            selected: selected,
                            selectedColor: NomadKit.sandDark,
                            backgroundColor: NomadKit.surface,
                            side: BorderSide(
                              color: selected
                                  ? NomadKit.sandDark
                                  : NomadKit.border,
                            ),
                            showCheckmark: false,
                            onSelected: (v) {
                              if (v) vm.setFilter(f);
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
            Expanded(child: _body(context, vm, isAdmin)),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context, FeedbackListViewModel vm, bool isAdmin) {
    return switch (vm.state) {
      FeedbackListLoading() => const Center(
        child: CircularProgressIndicator(color: NomadKit.sand),
      ),
      FeedbackListError(:final message) => FeedbackMessageState(
        icon: Icons.cloud_off_rounded,
        message: message,
        actionLabel: 'Thử lại',
        onAction: vm.retry,
      ),
      FeedbackListData() when vm.visible.isEmpty => FeedbackMessageState(
        icon: Icons.forum_outlined,
        message: vm.filter == FeedbackFilter.all
            ? (isAdmin
                  ? 'Chưa có Barista nào gửi phản hồi.'
                  : 'Bạn chưa gửi phản hồi nào.')
            : 'Không có phản hồi trong mục này.',
      ),
      FeedbackListData() => ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        itemCount: vm.visible.length + 1,
        itemBuilder: (context, i) {
          if (i == 0) {
            return RhSectionHeading(
              title: isAdmin ? 'Cần xử lý' : 'Phản hồi của bạn',
              trailing: '${vm.visible.length} phản hồi',
            );
          }
          final fb = vm.visible[i - 1];
          return FeedbackCard(
            item: fb,
            showSender: isAdmin,
            onTap: () => Navigator.push(
              context,
              RhPageRoute(
                builder: (_) => FeedbackDetailPage(feedbackId: fb.id),
              ),
            ),
          );
        },
      ),
    };
  }
}

class _BellButton extends StatelessWidget {
  const _BellButton();

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Thông báo',
    onPressed: () => go(context, const NotificationsPage()),
    style: IconButton.styleFrom(backgroundColor: NomadKit.sandLight),
    icon: const Icon(
      Icons.notifications_none_rounded,
      color: NomadKit.sandDark,
    ),
  );
}
