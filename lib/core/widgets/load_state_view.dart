import 'package:flutter/material.dart';

import '../theme/nomad_kit.dart';

/// Khối trạng thái dùng chung: đang tải / trống / lỗi (có nút "Thử lại").
class LoadStateView extends StatelessWidget {
  const LoadStateView.loading({super.key, this.message = 'Đang tải dữ liệu...'})
    : icon = null,
      onRetry = null;

  const LoadStateView.empty({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
  }) : onRetry = null;

  const LoadStateView.error({
    super.key,
    required this.message,
    required this.onRetry,
  }) : icon = Icons.cloud_off_rounded;

  final String message;
  final IconData? icon;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon == null)
              const CircularProgressIndicator(color: NomadKit.sandDark)
            else
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: NomadKit.sandLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 28, color: NomadKit.sandDark),
              ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: NomadKit.body.copyWith(fontWeight: FontWeight.w500),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 14),
              SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Thử lại'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
