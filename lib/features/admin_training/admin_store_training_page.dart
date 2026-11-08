import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/app_models.dart';
import '../../core/theme/nomad_kit.dart';
import '../../core/utils/navigation.dart';
import '../../core/viewmodels/auth_viewmodel.dart';
import '../../core/viewmodels/training_viewmodel.dart';
import '../../core/widgets/app_dropdown.dart';
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
    return Scaffold(
      backgroundColor: NomadKit.canvas,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'GIÁM SÁT CHI NHÁNH',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: NomadKit.sandDark,
                          letterSpacing: 0.8,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Theo dõi đào tạo',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: NomadKit.ink,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Chấm thực hành tại quầy',
                  icon: const Icon(
                    Icons.checklist_rtl_rounded,
                    size: 26,
                    color: NomadKit.sandDark,
                  ),
                  onPressed: () => go(context, const PracticalEvaluationPage()),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Store Scope Selector (Single clean card without nested card border)
            Container(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Image.asset(
                        'assets/icons/icon_store_branch.png',
                        width: 22,
                        height: 22,
                        filterQuality: FilterQuality.medium,
                        errorBuilder: (ctx, err, stack) => const Icon(
                          Icons.storefront_rounded,
                          size: 20,
                          color: NomadKit.sandDark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'CHI NHÁNH PHỤ TRÁCH QUẢN LÝ',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: NomadKit.sandDark,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(height: 2),
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
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(
                      height: 1,
                      thickness: 1,
                      color: NomadKit.border,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Expanded(child: _metricBox('${shown.length}', 'Nhân sự')),
                      Container(width: 1, height: 26, color: NomadKit.border),
                      Expanded(child: _metricBox('$avg%', 'Tiến độ TB')),
                      Container(width: 1, height: 26, color: NomadKit.border),
                      Expanded(
                        child: _metricBox(
                          '$totalOverdue',
                          'Bài quá hạn',
                          isWarning: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Quick Action: Chấm thực hành tại quầy
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: NomadKit.sandLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: NomadKit.border),
              ),
              child: Row(
                children: [
                  Image.asset(
                    'assets/icons/icon_evaluation_rubric.png',
                    width: 28,
                    height: 28,
                    filterQuality: FilterQuality.medium,
                    errorBuilder: (ctx, err, stack) => const Icon(
                      Icons.checklist_rounded,
                      size: 24,
                      color: NomadKit.sandDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Đánh giá thực hành tại quầy',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: NomadKit.ink,
                          ),
                        ),
                        Text(
                          'Quan sát thao tác của Barista và tick tiêu chí chuẩn.',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: NomadKit.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: NomadKit.sandDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () =>
                        go(context, const PracticalEvaluationPage()),
                    child: const Text(
                      'Chấm ngay',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Staff Training List
            const Text(
              'TIẾN ĐỘ TỪNG NHÂN SỰ TẠI CỬA HÀNG (FR-13)',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: NomadKit.sandDark,
                letterSpacing: 0.7,
              ),
            ),
            const SizedBox(height: 10),

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
              final int percent = st.readingPercent;
              final bool hasOverdue = st.overdueTasks.isNotEmpty;
              final name = st.member.displayName.isEmpty
                  ? 'Chưa cập nhật'
                  : st.member.displayName;
              final role = st.member.title ?? 'Barista';

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
                      children: [
                        Image.asset(
                          'assets/icons/icon_user_profile.png',
                          width: 36,
                          height: 36,
                          filterQuality: FilterQuality.medium,
                          errorBuilder: (ctx, err, stack) => const Icon(
                            Icons.person_rounded,
                            size: 24,
                            color: NomadKit.sandDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: NomadKit.ink,
                                ),
                              ),
                              Text(
                                role,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: NomadKit.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: percent >= 80
                                ? NomadKit.forestLight
                                : NomadKit.warningLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$percent% đã học',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: percent >= 80
                                  ? NomadKit.forest
                                  : NomadKit.warning,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Overdue / Relearn plain text notes (no background box)
                    if (hasOverdue)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          'Quá hạn: ${st.overdueTasks.first.title}',
                          maxLines: 2,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: NomadKit.error,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Thực hành: ${_practicalLabel(st.latestEvaluation)}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: NomadKit.secondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 28),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () =>
                              go(context, const PracticalEvaluationPage()),
                          child: const Text(
                            'Chấm điểm',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: NomadKit.sandDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 20),
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
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: Column(
      children: [
        Icon(icon, size: 36, color: NomadKit.secondary),
        const SizedBox(height: 8),
        Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: NomadKit.secondary),
        ),
        ?action,
      ],
    ),
  );

  Widget _metricBox(String val, String label, {bool isWarning = false}) {
    return Column(
      children: [
        Text(
          val,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: isWarning ? NomadKit.error : NomadKit.ink,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, color: NomadKit.secondary),
        ),
      ],
    );
  }
}
