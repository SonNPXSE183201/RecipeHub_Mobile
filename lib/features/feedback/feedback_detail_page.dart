import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/di/app_services.dart';
import '../../core/models/app_models.dart';
import '../../core/theme/nomad_kit.dart';
import '../../core/viewmodels/auth_viewmodel.dart';
import '../../core/viewmodels/feedback_viewmodel.dart';
import 'feedback_widgets.dart';

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

  Future<void> _send(FeedbackDetailViewModel vm) async {
    final ok = await vm.sendReply(_replyCtrl.text, newStatus: _statusOnSend);
    if (!mounted) return;
    if (ok) {
      _replyCtrl.clear();
      setState(() => _statusOnSend = null);
      FocusScope.of(context).unfocus();
    } else if (vm.actionError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
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
    ScaffoldMessenger.of(context).showSnackBar(
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
      MaterialPageRoute(
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
        backgroundColor: NomadKit.canvas,
        foregroundColor: NomadKit.ink,
        elevation: 0,
        title: const Text(
          'Chi tiết phản hồi',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
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
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: NomadKit.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: NomadKit.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  FeedbackTypeTag(fb.typeLabel),
                  const Spacer(),
                  FeedbackStatusChip(fb.status),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                fb.targetName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: NomadKit.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                [fb.version].where((e) => e.isNotEmpty).join(' · '),
                style: const TextStyle(
                  fontSize: 13,
                  color: NomadKit.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (fb.stepNote != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.format_list_numbered_rounded,
                      size: 16,
                      color: NomadKit.ocean,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        fb.stepNote!,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: NomadKit.ocean,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const Divider(height: 24, color: NomadKit.border),
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
              const SizedBox(height: 12),
              Text(
                fb.content,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: NomadKit.ink,
                ),
              ),
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
        ),
        const SizedBox(height: 20),
        Text(
          vm.replies.isEmpty ? 'Trao đổi' : 'Trao đổi (${vm.replies.length})',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: NomadKit.ink,
          ),
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
        ...vm.replies.map((r) => _bubble(r, mine: r.authorUid == vm.myUid)),
      ],
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

  Widget _bubble(FeedbackReplyModel r, {required bool mine}) {
    final bg = r.isAdmin ? NomadKit.forestLight : NomadKit.sandLight;
    final fg = r.isAdmin ? NomadKit.forest : NomadKit.sandDark;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: fg.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  r.isAdmin
                      ? Icons.verified_user_rounded
                      : Icons.person_rounded,
                  size: 14,
                  color: fg,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    r.senderName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: fg,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              r.message,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
                color: NomadKit.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              r.time,
              style: const TextStyle(fontSize: 12, color: NomadKit.secondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _composer(FeedbackDetailViewModel vm, FeedbackItemModel fb) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      decoration: const BoxDecoration(
        color: NomadKit.surface,
        border: Border(top: BorderSide(color: NomadKit.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (vm.isAdmin)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const Text(
                    'Khi gửi, chuyển sang: ',
                    style: TextStyle(fontSize: 13, color: NomadKit.secondary),
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
                    hintText: vm.isAdmin
                        ? 'Trả lời Barista…'
                        : 'Bổ sung thông tin cho Admin…',
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
