import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/nomad_kit.dart';
import '../../core/models/app_models.dart';
import '../../core/models/session_models.dart';
import '../../core/navigation/app_keys.dart';
import '../../core/viewmodels/auth_viewmodel.dart';
import '../../core/viewmodels/practice_history_viewmodel.dart';
import '../../core/viewmodels/storage_viewmodel.dart';
import '../../core/widgets/personal_learning_blocked.dart';
import '../../core/widgets/redesign_widgets.dart';
import '../../core/widgets/app_toast.dart';

class PracticeHistoryPage extends StatelessWidget {
  const PracticeHistoryPage({super.key});

  Future<void> _exportReport(
    BuildContext context,
    StorageViewModel storage,
    List<SelfPracticeRecord> records,
  ) async {
    final label = context.read<AuthViewModel>().displayName;
    final result = await storage.exportPracticeReport(
      records: records,
      traineeLabel: label,
    );
    if (!context.mounted || ModalRoute.of(context)?.isCurrent == false) return;
    final messenger = ToastMessenger.of(context);
    final saved = storage.savedFile;
    final saveError = storage.saveError;
    final String message;
    SnackBarAction? action;
    final success = saved != null || (result != null && saveError == null);
    if (saved != null) {
      message =
          'Đã lưu: ${saved.displayPath}'
          '${result == null ? '\nChưa tải được lên Cloud Storage. Vui lòng xuất lại để thử.' : ''}';
      action = SnackBarAction(
        label: 'Mở',
        textColor: Colors.white,
        onPressed: () async {
          final opened = await storage.openSavedFile(saved);
          if (!opened && context.mounted) {
            messenger.showSnackBar(
              const SnackBar(
                content: Text('Không tìm thấy ứng dụng đọc PDF trên máy.'),
              ),
            );
          }
        },
      );
    } else if (saveError != null || result == null) {
      message = saveError ?? storage.reportError ?? 'Xuất báo cáo thất bại.';
      action = SnackBarAction(
        label: 'Thử lại',
        textColor: Colors.white,
        onPressed: () {
          if (context.mounted) _exportReport(context, storage, records);
        },
      );
    } else {
      message = 'Đã xuất báo cáo PDF và lưu lên Cloud Storage.';
    }
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message, key: success ? AppKeys.reportUrl : null),
        backgroundColor: success ? NomadKit.forest : NomadKit.error,
        action: action,
        // Flutter 3.47 mặc định giữ SnackBar có action cho tới khi người dùng đóng.
        persist: false,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messenger = ToastMessenger.of(context);
    return PopScope<void>(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) messenger.clearSnackBars();
      },
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (!context.watch<AuthViewModel>().hasPersonalLearning) {
      return const PersonalLearningBlocked();
    }
    final practice = context.watch<PracticeHistoryViewModel>();
    final records = practice.records;
    final totalSessions = practice.totalSessions;
    final avgSeconds = practice.averageSeconds;
    final within = practice.withinTolerancePercent;

    return RhFlowScaffold(
      title: 'Lịch sử tự luyện',
      trailing: Builder(
        builder: (ctx) {
          final st = ctx.watch<StorageViewModel>();
          return IconButton(
            key: AppKeys.exportReport,
            tooltip: 'Xuất báo cáo PDF',
            icon: st.reportStatus == UploadStatus.uploading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: NomadKit.sandDark,
                    ),
                  )
                : const Icon(
                    Icons.picture_as_pdf_outlined,
                    color: NomadKit.sandDark,
                  ),
            onPressed:
                st.reportStatus == UploadStatus.uploading || records.isEmpty
                ? null
                : () => _exportReport(ctx, st, records),
          );
        },
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
        children: [
          Text(
            'Lịch sử tự luyện',
            style: NomadKit.title.copyWith(fontSize: 24),
          ),
          const SizedBox(height: 8),
          const Text('Các lần luyện tập cá nhân đã lưu', style: NomadKit.label),
          const SizedBox(height: 16),
          Row(
            children: [
              _Stat(value: '$totalSessions', label: 'Lần tự luyện'),
              _Stat(value: _clock(avgSeconds), label: 'Thời gian TB'),
              _Stat(
                valueKey: const Key('practice_within_percent'),
                value: within == null ? '—' : '$within%',
                label: 'Đạt thời gian chuẩn',
              ),
            ],
          ),
          const SizedBox(height: 14),
          const RhNotice(
            icon: Icons.lock_clock_outlined,
            message: 'Dữ liệu tự luyện mang tính chất riêng tư. RecipeHub không xếp hạng thi đua tốc độ giữa các nhân viên.',
          ),
          const SizedBox(height: 16),
          if (records.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  'Chưa có lần tự luyện nào được lưu.',
                  style: TextStyle(color: NomadKit.secondary),
                ),
              ),
            )
          else
            for (final rec in records)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                decoration: BoxDecoration(
                  color: NomadKit.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: NomadKit.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${rec.recipeName} · ${_clock(rec.durationSeconds)}',
                      style: NomadKit.subtitle,
                    ),
                    const SizedBox(height: 8),
                    Text(rec.practicedAt, style: NomadKit.label),
                    Text(
                      rec.size,
                      style: NomadKit.label.copyWith(
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    Text(
                      'Ghi chú: ${rec.notes}',
                      style: NomadKit.label.copyWith(
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  static String _clock(int seconds) =>
      '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, this.valueKey});

  final String value;
  final String label;
  final Key? valueKey;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(
          value,
          key: valueKey,
          style: NomadKit.title.copyWith(color: NomadKit.sandDark),
        ),
        const SizedBox(height: 2),
        Text(label, textAlign: TextAlign.center, style: NomadKit.caption),
      ],
    ),
  );
}
