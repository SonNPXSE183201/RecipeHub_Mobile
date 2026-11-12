import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/di/app_services.dart';
import '../../core/models/app_models.dart';
import '../../core/theme/nomad_kit.dart';
import '../../core/viewmodels/auth_viewmodel.dart';
import '../../core/viewmodels/feedback_viewmodel.dart';
import '../../core/widgets/redesign_widgets.dart';
import 'feedback_widgets.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/rh_motion.dart';

/// Chi tiết phản hồi: thông tin đầy đủ, ảnh đính kèm (phóng to), luồng trả lời real-time.
/// Admin trả lời và đổi trạng thái; Barista trả lời bổ sung.
class FeedbackDetailPage extends StatelessWidget {
  const FeedbackDetailPage({super.key, required this.feedbackId});
  final String feedbackId;

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppServices>();
    final auth = context.read<AuthViewModel>();
    return ChangeNotifierProvider(
      create: (_) => FeedbackDetailViewModel(
        repo: s.feedback,
        crash: s.crash,
        feedbackId: feedbackId,
        myUid: auth.user?.uid ?? '',
        myName: auth.isAdmin ? '${auth.displayName} (Admin)' : auth.displayName,
        isAdmin: auth.isAdmin,
      ),
      child: const _DetailView(),
    );
  }
}

class _DetailView extends StatefulWidget {
  const _DetailView();
  @override
  State<_DetailView> createState() => _DetailViewState();
}

class _DetailViewState extends State<_DetailView> {
  final _replyCtrl = TextEditingController();
  FeedbackStatus? _statusOnSend;

  @override
  void dispose() {
    _replyCtrl.dispose();
    super.dispose();
  }

  Future<void> _send(
    FeedbackDetailViewModel vm, {
    FeedbackStatus? status,
  }) async {
    if (_replyCtrl.text.trim().isEmpty && vm.isAdmin) {
      ToastMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập nội dung xử lý.'),
          backgroundColor: NomadKit.error,
        ),
      );
      return;
    }
    final ok = await vm.sendReply(
      _replyCtrl.text,
      newStatus: status ?? _statusOnSend,
    );
    if (!mounted) return;
    if (ok) {
      _replyCtrl.clear();
      setState(() => _statusOnSend = null);
      FocusScope.of(context).unfocus();
    } else if (vm.actionError != null) {
      ToastMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vm.actionError!),
          backgroundColor: NomadKit.error,
        ),
      );
    }
  }

  Future<void> _changeStatus(
    FeedbackDetailViewModel vm,
    FeedbackStatus s,
  ) async {
    final ok = await vm.changeStatus(s);
    if (!mounted) return;
    ToastMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Đã chuyển sang "${feedbackStatusLabel(s)}".'
              : (vm.actionError ?? 'Đổi trạng thái thất bại.'),
        ),
        backgroundColor: ok ? NomadKit.forest : NomadKit.error,
      ),
    );
  }

  void _openImage(String url) {
    Navigator.push(
      context,
      RhPageRoute(
        fullscreenDialog: true,
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: const Text('Ảnh đính kèm', style: TextStyle(fontSize: 16)),
          ),
          body: InteractiveViewer(
            maxScale: 5,
            child: Center(
              child: FeedbackNetworkImage(url, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FeedbackDetailViewModel>();
    final fb = vm.item;
    return Scaffold(
      backgroundColor: NomadKit.canvas,
      appBar: AppBar(
        toolbarHeight: 64,
        backgroundColor: NomadKit.canvas,
        foregroundColor: NomadKit.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const Border(bottom: BorderSide(color: NomadKit.border)),
        title: Text(
          'Chi tiết phản hồi',
          style: NomadKit.label.copyWith(color: NomadKit.secondary),
        ),
        actions: [
          if (vm.isAdmin && fb != null)
            PopupMenuButton<FeedbackStatus>(
              tooltip: 'Đổi trạng thái',
              icon: const Icon(Icons.swap_horiz_rounded),
              onSelected: (s) => _changeStatus(vm, s),
              itemBuilder: (_) => FeedbackStatus.values
                  .where((s) => s != fb.status)
                  .map(
                    (s) => PopupMenuItem(
                      value: s,
                      child: Text(feedbackStatusLabel(s)),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
      body: SafeArea(
        child: vm.loading
            ? const Center(
                child: CircularProgressIndicator(color: NomadKit.sand),
              )
            : vm.error != null
            ? FeedbackMessageState(
                icon: Icons.cloud_off_rounded,
                message: vm.error!,
                actionLabel: 'Thử lại',
                onAction: vm.retry,
              )
            : (vm.notFound || fb == null)
            ? const FeedbackMessageState(
                icon: Icons.search_off_rounded,
                message: 'Phản hồi không còn tồn tại.',
              )
            : Column(
                children: [
                  Expanded(child: _content(vm, fb)),
                  _composer(vm, fb),
                ],
              ),
      ),
    );
  }

  Widget _content(FeedbackDetailViewModel vm, FeedbackItemModel fb) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${feedbackStatusLabel(fb.status)} · ${fb.typeLabel}',
              style: NomadKit.caption.copyWith(
                color: NomadKit.sandDark,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(fb.targetName, style: NomadKit.title.copyWith(fontSize: 26)),
            const SizedBox(height: 6),
            Text(
              [
                if (fb.stepNote != null)
                  'Liên quan ${fb.stepNote!.split(':').first.trim().toLowerCase()}',
                fb.version,
              ].where((e) => e.isNotEmpty).join(' · '),
              style: NomadKit.caption,
            ),
            const Divider(height: 30, color: NomadKit.border),
            _infoRow(
              Icons.person_rounded,
              'Người gửi',
              fb.senderRole.isEmpty
                  ? fb.senderName
                  : '${fb.senderName} · ${fb.senderRole}',
            ),
            if (fb.storeBranch.isNotEmpty)
              _infoRow(Icons.storefront_rounded, 'Chi nhánh', fb.storeBranch),
            _infoRow(Icons.schedule_rounded, 'Gửi lúc', fb.createdAt),
            const SizedBox(height: 18),
            Text('Nội dung góp ý', style: NomadKit.section),
            const SizedBox(height: 8),
            Text(fb.content, style: NomadKit.body),
            if (fb.hasAttachment) ...[
              const SizedBox(height: 14),
              Semantics(
                button: true,
                label: 'Xem ảnh đính kèm cỡ lớn',
                child: GestureDetector(
                  onTap: () => _openImage(fb.attachmentUrl!),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: FeedbackNetworkImage(
                          fb.attachmentUrl!,
                          height: 220,
                          width: double.infinity,
                        ),
                      ),
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.zoom_out_map_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Phóng to',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 28),
        Text(
          vm.replies.isEmpty ? 'Trao đổi' : 'Trao đổi (${vm.replies.length})',
          style: NomadKit.section,
        ),
        const SizedBox(height: 8),
        if (vm.replies.isEmpty)
          Text(
            vm.isAdmin
                ? 'Chưa có trả lời. Hãy phản hồi Barista bên dưới.'
                : 'Đang chờ Admin tiếp nhận và trả lời.',
            style: const TextStyle(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: NomadKit.secondary,
            ),
          ),
        ...vm.replies.map(
          (r) => Padding(
            padding: const EdgeInsets.only(top: 10),
            child: RhNotice(
              icon: r.isAdmin
                  ? Icons.verified_user_outlined
                  : Icons.person_outline_rounded,
              title: '${r.senderName} · ${r.time}',
              message: r.message,
            ),
          ),
        ),
        if (vm.isAdmin) ...[const SizedBox(height: 20), _replyCard()],
      ],
    );
  }

  /// Card "Nội dung xử lý" của quản lý (Figma 109:466).
  Widget _replyCard() {
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
          Text.rich(
            TextSpan(
              style: NomadKit.label.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              children: const [
                TextSpan(text: 'Nội dung xử lý '),
                TextSpan(
                  text: '*',
                  style: TextStyle(color: NomadKit.error),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _replyCtrl,
            minLines: 4,
            maxLines: 6,
            maxLength: 2000,
            style: NomadKit.body.copyWith(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Ghi hướng xử lý và điều cần thông báo cho barista…',
              hintStyle: NomadKit.caption.copyWith(fontSize: 13),
              counterText: '',
              filled: true,
              fillColor: NomadKit.canvas,
              contentPadding: const EdgeInsets.all(13),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: NomadKit.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: NomadKit.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: NomadKit.sand, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: NomadKit.secondary),
        const SizedBox(width: 6),
        SizedBox(
          width: 76,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: NomadKit.secondary),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: NomadKit.ink,
            ),
          ),
        ),
      ],
    ),
  );

  /// Thanh hành động của Admin: chọn trạng thái khi gửi + nút xác nhận.
  Widget _adminActions(FeedbackDetailViewModel vm) {
    final confirmsResolved =
        _statusOnSend == null || _statusOnSend == FeedbackStatus.resolved;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: const BoxDecoration(
        color: NomadKit.surface,
        border: Border(top: BorderSide(color: NomadKit.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Text(
                  'Khi gửi, chuyển sang: ',
                  style: NomadKit.caption.copyWith(fontSize: 13),
                ),
                for (final s in [
                  FeedbackStatus.inProgress,
                  FeedbackStatus.waitingInfo,
                  FeedbackStatus.resolved,
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(
                        feedbackStatusLabel(s),
                        style: const TextStyle(fontSize: 12),
                      ),
                      selected: _statusOnSend == s,
                      showCheckmark: false,
                      selectedColor: feedbackStatusColors(s).bg,
                      side: BorderSide(
                        color: _statusOnSend == s
                            ? feedbackStatusColors(s).fg
                            : NomadKit.border,
                      ),
                      onSelected: (v) =>
                          setState(() => _statusOnSend = v ? s : null),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: vm.sending
                  ? null
                  : () => _send(
                      vm,
                      status: _statusOnSend ?? FeedbackStatus.resolved,
                    ),
              style: FilledButton.styleFrom(
                backgroundColor: NomadKit.sandDark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: vm.sending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      confirmsResolved ? 'Xác nhận đã xử lý' : 'Gửi trả lời',
                      style: NomadKit.label.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _composer(FeedbackDetailViewModel vm, FeedbackItemModel fb) {
    if (vm.isAdmin) return _adminActions(vm);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      decoration: const BoxDecoration(
        color: NomadKit.surface,
        border: Border(top: BorderSide(color: NomadKit.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _replyCtrl,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: 2000,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    hintText: 'Bổ sung thông tin cho Admin…',
                    counterText: '',
                    filled: true,
                    fillColor: NomadKit.canvas,
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: NomadKit.border),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'Gửi trả lời',
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                onPressed: vm.sending ? null : () => _send(vm),
                icon: vm.sending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: NomadKit.sand,
                        ),
                      )
                    : const Icon(Icons.send_rounded, color: NomadKit.sandDark),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
