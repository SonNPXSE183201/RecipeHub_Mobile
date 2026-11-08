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
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
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
    messenger.showSnackBar(
      SnackBar(
        content: Text(message, key: success ? AppKeys.reportUrl : null),
        backgroundColor: success ? NomadKit.forest : NomadKit.error,
        action: action,
        duration: const Duration(seconds: 8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!context.watch<AuthViewModel>().hasPersonalLearning) {
      return const PersonalLearningBlocked();
    }
    final practice = context.watch<PracticeHistoryViewModel>();
    final records = practice.records;
    final totalSessions = practice.totalSessions;
    final avgSeconds = practice.averageSeconds;
    final within = practice.withinTolerancePercent;

    return Scaffold(
      backgroundColor: NomadKit.canvas,
      appBar: AppBar(
        backgroundColor: NomadKit.canvas,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: NomadKit.ink,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Lịch sử tự luyện cá nhân',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: NomadKit.ink,
          ),
        ),
        actions: [
          Builder(
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
                        color: NomadKit.ink,
                      ),
                onPressed:
                    st.reportStatus == UploadStatus.uploading || records.isEmpty
                    ? null
                    : () => _exportReport(ctx, st, records),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Summary Banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: NomadKit.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: NomadKit.border),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x06000000),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            '$totalSessions',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: NomadKit.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Lần tự luyện',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: NomadKit.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 32, color: NomadKit.border),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            '${avgSeconds}s',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: NomadKit.sandDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Thời gian TB',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: NomadKit.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 32, color: NomadKit.border),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            within == null ? '—' : '$within%',
                            key: const Key('practice_within_percent'),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: NomadKit.forest,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Đạt thời gian chuẩn',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: NomadKit.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Policy Rule: No speed leaderboards (BR-09)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: NomadKit.sandLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: const [
                    Icon(
                      Icons.lock_clock_outlined,
                      size: 18,
                      color: NomadKit.sandDark,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Dữ liệu tự luyện mang tính chất riêng tư. RecipeHub không xếp hạng thi đua tốc độ giữa các nhân viên.',
                        style: TextStyle(
                          fontSize: 14,
                          color: NomadKit.sandDark,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: NomadKit.border),

            // Records List
            Expanded(
              child: records.isEmpty
                  ? const Center(
                      child: Text(
                        'Chưa có lần tự luyện nào được lưu.',
                        style: TextStyle(color: NomadKit.secondary),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: records.length,
                      itemBuilder: (context, idx) {
                        final rec = records[idx];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      rec.recipeName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: NomadKit.ink,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: NomadKit.oceanLight,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${rec.durationSeconds} giây',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: NomadKit.ocean,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      rec.size,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: NomadKit.secondary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    rec.practicedAt,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: NomadKit.secondary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: NomadKit.canvas,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Image.asset(
                                      'assets/icons/icon_feedback_pencil.png',
                                      width: 16,
                                      height: 16,
                                      filterQuality: FilterQuality.medium,
                                      errorBuilder: (ctx, err, stack) =>
                                          const Icon(
                                            Icons.edit_note_rounded,
                                            size: 16,
                                            color: NomadKit.sandDark,
                                          ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Ghi chú: ${rec.notes}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: NomadKit.ink,
                                          height: 1.3,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
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
