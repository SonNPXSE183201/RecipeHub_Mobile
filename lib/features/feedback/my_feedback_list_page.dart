import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/di/app_services.dart';
import '../../core/theme/nomad_kit.dart';
import '../../core/viewmodels/auth_viewmodel.dart';
import '../../core/viewmodels/feedback_viewmodel.dart';
import 'create_feedback_page.dart';
import 'feedback_detail_page.dart';
import 'feedback_widgets.dart';

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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          isAdmin ? 'Phản hồi từ Barista' : 'Phản hồi của tôi',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: NomadKit.ink,
                          ),
                        ),
                      ),
                      if (!isAdmin)
                        Semantics(
                          label: 'Gửi phản hồi',
                          button: true,
                          child: IconButton(
                            tooltip: 'Gửi phản hồi',
                            constraints: const BoxConstraints(
                              minWidth: 48,
                              minHeight: 48,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: NomadKit.sand,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CreateFeedbackPage(),
                              ),
                            ),
                            icon: const Icon(Icons.rate_review_rounded),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
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
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
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
        padding: const EdgeInsets.all(20),
        itemCount: vm.visible.length,
        itemBuilder: (context, i) {
          final fb = vm.visible[i];
          return FeedbackCard(
            item: fb,
            showSender: isAdmin,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FeedbackDetailPage(feedbackId: fb.id),
              ),
            ),
          );
        },
      ),
    };
  }
}
