import 'package:flutter/material.dart';

import '../../core/models/app_models.dart';
import '../../core/theme/nomad_kit.dart';
import '../../core/widgets/redesign_widgets.dart';

/// Màu chip theo trạng thái (cùng quy ước với web Admin).
({Color bg, Color fg}) feedbackStatusColors(FeedbackStatus s) => switch (s) {
  FeedbackStatus.newFeedback => (bg: NomadKit.oceanLight, fg: NomadKit.ocean),
  FeedbackStatus.inProgress => (bg: NomadKit.sandLight, fg: NomadKit.sandDark),
  FeedbackStatus.waitingInfo => (
    bg: NomadKit.warningLight,
    fg: NomadKit.warning,
  ),
  FeedbackStatus.resolved => (bg: NomadKit.forestLight, fg: NomadKit.forest),
  FeedbackStatus.closed => (
    bg: const Color(0xFFF5F5F4),
    fg: NomadKit.secondary,
  ),
};

class FeedbackStatusChip extends StatelessWidget {
  const FeedbackStatusChip(this.status, {super.key});
  final FeedbackStatus status;

  @override
  Widget build(BuildContext context) {
    final c = feedbackStatusColors(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        feedbackStatusLabel(status),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: c.fg,
        ),
      ),
    );
  }
}

class FeedbackTypeTag extends StatelessWidget {
  const FeedbackTypeTag(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: NomadKit.canvas,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: NomadKit.border),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: NomadKit.secondary,
        ),
      ),
    );
  }
}

/// Ảnh từ Storage có trạng thái tải / lỗi.
class FeedbackNetworkImage extends StatelessWidget {
  const FeedbackNetworkImage(
    this.url, {
    super.key,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
  });
  final String url;
  final double? height;
  final double? width;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      height: height,
      width: width,
      fit: fit,
      loadingBuilder: (ctx, child, progress) => progress == null
          ? child
          : SizedBox(
              height: height,
              width: width,
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: NomadKit.sand,
                ),
              ),
            ),
      errorBuilder: (ctx, err, st) => Container(
        height: height,
        width: width,
        color: NomadKit.sandLight,
        alignment: Alignment.center,
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.broken_image_rounded, color: NomadKit.secondary),
            SizedBox(height: 4),
            Text(
              'Không tải được ảnh',
              style: TextStyle(fontSize: 12, color: NomadKit.secondary),
            ),
          ],
        ),
      ),
    );
  }
}

/// Thẻ phản hồi trong danh sách (Figma: nội dung 2 dòng, ngữ cảnh, trạng thái có icon).
class FeedbackCard extends StatelessWidget {
  const FeedbackCard({
    super.key,
    required this.item,
    required this.onTap,
    this.showSender = false,
  });
  final FeedbackItemModel item;
  final VoidCallback onTap;
  final bool showSender;

  @override
  Widget build(BuildContext context) {
    final fb = item;
    final isNew = fb.status == FeedbackStatus.newFeedback;
    final done =
        fb.status == FeedbackStatus.resolved ||
        fb.status == FeedbackStatus.closed;
    final statusColor = done ? NomadKit.forest : NomadKit.sandDark;
    final step = fb.stepNote?.split(':').first.trim();
    final contextLine = [
      if (showSender)
        fb.storeBranch.isEmpty
            ? fb.senderName
            : '${fb.senderName} · ${fb.storeBranch}',
      fb.targetName,
      if (step != null && step.isNotEmpty) step,
    ].join(' · ');
    return Semantics(
      button: true,
      label:
          'Phản hồi ${fb.typeLabel} về ${fb.targetName}, ${feedbackStatusLabel(fb.status)}',
      child: Container(
        decoration: BoxDecoration(
          color: isNew && showSender
              ? NomadKit.sandLight.withValues(alpha: 0.35)
              : Colors.transparent,
          border: const Border(bottom: BorderSide(color: NomadKit.border)),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fb.content,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: NomadKit.body.copyWith(
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                            height: 25 / 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          contextLine,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: NomadKit.caption,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            RhSvgIcon(
                              done
                                  ? 'assets/redesign/circle_check.svg'
                                  : 'assets/redesign/clock.svg',
                              size: 14,
                              color: statusColor,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                feedbackStatusLabel(fb.status),
                                overflow: TextOverflow.ellipsis,
                                style: NomadKit.caption.copyWith(
                                  color: statusColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            if (fb.hasAttachment) ...[
                              const SizedBox(width: 10),
                              const Icon(
                                Icons.image_outlined,
                                size: 14,
                                color: NomadKit.secondary,
                              ),
                            ],
                            if (fb.replyCount > 0) ...[
                              const SizedBox(width: 10),
                              const Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 14,
                                color: NomadKit.secondary,
                              ),
                              const SizedBox(width: 3),
                              Text('${fb.replyCount}', style: NomadKit.caption),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const RhChevron(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Trạng thái rỗng / lỗi có nút hành động.
class FeedbackMessageState extends StatelessWidget {
  const FeedbackMessageState({
    super.key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 48,
              color: NomadKit.secondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: NomadKit.secondary),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(actionLabel!),
                style: OutlinedButton.styleFrom(
                  foregroundColor: NomadKit.sandDark,
                  minimumSize: const Size(48, 48),
                  side: const BorderSide(color: NomadKit.sand),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
