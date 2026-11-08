import 'package:flutter/material.dart';

import '../../core/models/app_models.dart';
import '../../core/theme/nomad_kit.dart';

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

/// Thẻ phản hồi trong danh sách.
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
    return Semantics(
      button: true,
      label:
          'Phản hồi ${fb.typeLabel} về ${fb.targetName}, ${feedbackStatusLabel(fb.status)}',
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: NomadKit.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isNew && showSender
                ? NomadKit.ocean.withValues(alpha: 0.5)
                : NomadKit.border,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      FeedbackTypeTag(fb.typeLabel),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          fb.version.isEmpty
                              ? fb.targetName
                              : '${fb.targetName} · ${fb.version}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: NomadKit.ink,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      FeedbackStatusChip(fb.status),
                    ],
                  ),
                  if (showSender) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.person_rounded,
                          size: 16,
                          color: NomadKit.secondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            fb.storeBranch.isEmpty
                                ? fb.senderName
                                : '${fb.senderName} · ${fb.storeBranch}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: NomadKit.ink,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (fb.stepNote != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Ngữ cảnh: ${fb.stepNote}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: NomadKit.ocean,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          fb.content,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            color: NomadKit.ink,
                            height: 1.4,
                          ),
                        ),
                      ),
                      if (fb.hasAttachment) ...[
                        const SizedBox(width: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: FeedbackNetworkImage(
                            fb.attachmentUrl!,
                            width: 64,
                            height: 64,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        size: 14,
                        color: NomadKit.secondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        fb.createdAt,
                        style: const TextStyle(
                          fontSize: 12,
                          color: NomadKit.secondary,
                        ),
                      ),
                      const Spacer(),
                      if (fb.hasAttachment) ...[
                        const Icon(
                          Icons.image_rounded,
                          size: 16,
                          color: NomadKit.secondary,
                        ),
                        const SizedBox(width: 10),
                      ],
                      const Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 16,
                        color: NomadKit.secondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        fb.replyCount == 0
                            ? 'Chưa trả lời'
                            : '${fb.replyCount} trả lời',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: NomadKit.secondary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: NomadKit.secondary,
                      ),
                    ],
                  ),
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
