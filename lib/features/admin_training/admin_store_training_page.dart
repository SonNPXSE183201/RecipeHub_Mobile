import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/app_models.dart';
import '../../core/theme/nomad_kit.dart';
import '../../core/utils/navigation.dart';
import '../../core/viewmodels/auth_viewmodel.dart';
import '../../core/viewmodels/training_viewmodel.dart';
import '../../core/widgets/app_dropdown.dart';
import '../../core/widgets/redesign_widgets.dart';
import '../practice/practical_evaluation_page.dart';

class AdminStoreTrainingPage extends StatefulWidget {
  const AdminStoreTrainingPage({super.key});

  @override
  State<AdminStoreTrainingPage> createState() => _AdminStoreTrainingPageState();
}

class _AdminStoreTrainingPageState extends State<AdminStoreTrainingPage> {
  static const String _all = 'Tất cả chi nhánh';
  String _selectedStore = _all;

  String _practicalLabel(PracticalEvaluationRecord? e) => e == null
      ? 'Chưa đánh giá'
      : (e.isPassed ? 'Đạt tiêu chuẩn' : 'Chưa đạt');

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminTrainingViewModel>();
    final auth = context.watch<AuthViewModel>();
    final branches = <String>{
      for (final m in vm.staff)
        if (m.storeBranch != null && m.storeBranch!.isNotEmpty) m.storeBranch!,
      if (auth.storeBranch.isNotEmpty) auth.storeBranch,
    }.toList()..sort();
    final options = [_all, ...branches];
    final store = options.contains(_selectedStore) ? _selectedStore : _all;
    final shown = vm.summaries
        .where((x) => store == _all || x.member.storeBranch == store)
        .toList();
    final totalOverdue = shown.fold<int>(
      0,
      (a, x) => a + x.overdueTasks.length,
    );
    final avg = shown.isEmpty
        ? 0
        : (shown.fold<int>(0, (a, x) => a + x.readingPercent) / shown.length)
              .round();
    final pending = shown.where((x) => x.latestEvaluation == null).length;
    final evaluated = shown.length - pending;
    return Scaffold(
      backgroundColor: NomadKit.canvas,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            RhPageHeader(
              title: 'Đào tạo',
              trailing: IconButton(
                tooltip: 'Chấm thực hành tại quầy',
                icon: const Icon(
                  Icons.checklist_rtl_rounded,
                  size: 24,
                  color: NomadKit.sandDark,
                ),
                onPressed: () => go(context, const PracticalEvaluationPage()),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CHI NHÁNH PHỤ TRÁCH QUẢN LÝ',
                    style: NomadKit.caption.copyWith(
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.4,
                    ),
                  ),
                  AppDropdown<String>(
                    value: store,
                    items: options
                        .map(
                          (s) => DropdownMenuItem(
                            value: s,
                            child: Text(
                              s,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _selectedStore = v ?? store),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 20,
                    runSpacing: 4,
                    children: [
                      _metric('$pending', 'Chờ chấm'),
                      _metric('$evaluated', 'Đã đánh giá'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${shown.length} nhân sự · Tiến độ TB $avg% · $totalOverdue bài quá hạn',
                    style: NomadKit.caption,
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: NomadKit.border),
                  const RhSectionHeading(title: 'Cần xử lý'),
                ],
              ),
            ),
            if (vm.state == LoadState.loading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (vm.state == LoadState.error)
              _notice(
                icon: Icons.cloud_off_rounded,
                text: vm.error ?? 'Không tải được dữ liệu giám sát.',
                action: TextButton.icon(
                  onPressed: vm.retry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Thử lại'),
                ),
              )
            else if (shown.isEmpty)
              _notice(
                icon: Icons.groups_outlined,
                text: 'Chưa có Barista nào được cấp tài khoản',
              ),
            ...shown.map((st) {
              final percent = st.readingPercent;
              final eval = st.latestEvaluation;
              final name = st.member.displayName.isEmpty
                  ? 'Chưa cập nhật'
                  : st.member.displayName;
              final role = st.member.title ?? 'Barista';
              final done = eval != null;
              final statusColor = !done
                  ? NomadKit.sandDark
                  : (eval.isPassed ? NomadKit.forest : NomadKit.error);
              return InkWell(
                onTap: () => go(context, const PracticalEvaluationPage()),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: NomadKit.border)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RhAvatar(initials: rhInitials(name), size: 40),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: NomadKit.body.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              role,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: NomadKit.caption,
                            ),
                            Text('$percent% đã học', style: NomadKit.caption),
                            if (st.overdueTasks.isNotEmpty)
                              Text(
                                'Quá hạn: ${st.overdueTasks.first.title}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: NomadKit.caption.copyWith(
                                  color: NomadKit.error,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  done
                                      ? (eval.isPassed
                                            ? Icons.check_circle_outline_rounded
                                            : Icons.error_outline_rounded)
                                      : Icons.schedule_rounded,
                                  size: 14,
                                  color: statusColor,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'Thực hành: ${_practicalLabel(eval)}',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: NomadKit.caption.copyWith(
                                      color: statusColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Row(
                          children: [
                            Text(
                              done ? 'Xem' : 'Chấm',
                              style: NomadKit.label.copyWith(
                                color: NomadKit.sandDark,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const RhChevron(color: NomadKit.sandDark),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _notice({
    required IconData icon,
    required String text,
    Widget? action,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
    child: Column(
      children: [
        Icon(icon, size: 36, color: NomadKit.secondary),
        const SizedBox(height: 8),
        Text(
          text,
          textAlign: TextAlign.center,
          style: NomadKit.label.copyWith(
            color: NomadKit.secondary,
            fontWeight: FontWeight.w400,
          ),
        ),
        ?action,
      ],
    ),
  );

  Widget _metric(String val, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.baseline,
    textBaseline: TextBaseline.alphabetic,
    children: [
      Text(val, style: NomadKit.title.copyWith(color: NomadKit.sandDark)),
      const SizedBox(width: 6),
      Text(label, style: NomadKit.caption),
    ],
  );
}
