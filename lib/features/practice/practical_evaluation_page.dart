import '../../core/widgets/app_dropdown.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/viewmodels/auth_viewmodel.dart';
import '../../core/theme/nomad_kit.dart';
import '../../core/models/app_models.dart';
import '../../core/models/training_models.dart';
import '../../core/viewmodels/recipe_viewmodel.dart';
import '../../core/viewmodels/training_viewmodel.dart';

class PracticalEvaluationPage extends StatefulWidget {
  const PracticalEvaluationPage({super.key});

  @override
  State<PracticalEvaluationPage> createState() =>
      _PracticalEvaluationPageState();
}

class _PracticalEvaluationPageState extends State<PracticalEvaluationPage> {
  // State for Admin Evaluation Mode
  bool _isAdminMode = false;
  StaffMember? _selectedStaff;
  RecipeItem? _selectedRecipe;
  List<EvaluationCriterion> _criteria = [];
  final TextEditingController _commentCtrl = TextEditingController();
  final TextEditingController _planCtrl = TextEditingController();
  bool _isPassedResult = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _isAdminMode = context.read<AuthViewModel>().isAdmin;
  }

  void _pickRecipe(RecipeItem? r, AdminTrainingViewModel vm) {
    _selectedRecipe = r;
    _criteria = r == null ? [] : vm.criteriaFor(r.code);
    for (final c in _criteria) {
      c.isPassed = true;
    }
    _isPassedResult = true;
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    _planCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveEvaluation(
    AdminTrainingViewModel vm,
    AuthViewModel auth,
  ) async {
    final staff = _selectedStaff;
    final recipe = _selectedRecipe;
    final uid = auth.user?.uid;
    final messenger = ScaffoldMessenger.of(context);
    if (staff == null || recipe == null || uid == null || _criteria.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Chọn Barista, công thức và tiêu chí trước khi lưu.'),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    final err = await vm.saveEvaluation(
      PracticalEvaluationRecord(
        id: 'eval-${DateTime.now().millisecondsSinceEpoch}',
        traineeUid: staff.uid,
        traineeName: staff.displayName,
        storeBranch: staff.storeBranch ?? auth.storeBranch,
        evaluatorName: auth.displayName,
        recipeCode: recipe.code,
        recipeName: recipe.name,
        version: recipe.version,
        evaluatedDate: 'Hôm nay',
        isPassed: _isPassedResult,
        overallComment: _commentCtrl.text.trim(),
        relearnPlan: _planCtrl.text.trim(),
        criteria: _criteria,
      ),
      evaluatorUid: uid,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          err ?? 'Đã lưu kết quả đánh giá thực hành tại quầy thành công.',
        ),
        backgroundColor: err == null ? NomadKit.forest : NomadKit.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final admin = context.watch<AdminTrainingViewModel>();
    final training = context.watch<TrainingViewModel>();
    final evaluations = auth.isAdmin
        ? admin.evaluations
        : training.myEvaluations;

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
        title: Text(
          _isAdminMode
              ? 'Chấm thực hành tại quầy'
              : 'Kết quả đánh giá thực hành',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: NomadKit.ink,
          ),
        ),
        actions: [
          // Chế độ chấm tại quầy chỉ dành cho Admin (Barista chỉ xem kết quả).
          if (context.watch<AuthViewModel>().isAdmin)
            Semantics(
              button: true,
              label: _isAdminMode ? 'Xem kết quả' : 'Chấm tại quầy',
              child: IconButton(
                key: const Key('eval_toggle_admin'),
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                tooltip: _isAdminMode ? 'Xem kết quả' : 'Chấm tại quầy',
                color: NomadKit.sandDark,
                icon: Icon(
                  _isAdminMode
                      ? Icons.visibility_outlined
                      : Icons.edit_note_rounded,
                ),
                onPressed: () => setState(() => _isAdminMode = !_isAdminMode),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: _isAdminMode
              ? _buildAdminScoringForm(admin, auth)
              : _buildResults(
                  evaluations,
                  auth.isAdmin ? admin : null,
                  training,
                ),
        ),
      ),
    );
  }

  // --- Danh sách kết quả: Admin thấy phiếu đã chấm, Barista thấy phiếu của mình ---
  Widget _buildResults(
    List<PracticalEvaluationRecord> list,
    AdminTrainingViewModel? admin,
    TrainingViewModel training,
  ) {
    final failed = admin != null
        ? admin.state == LoadState.error
        : training.evaluationState == LoadState.error;
    final loading = admin != null
        ? admin.state == LoadState.loading
        : training.evaluationState == LoadState.loading;
    if (list.isEmpty) {
      if (loading) {
        return const Padding(
          padding: EdgeInsets.all(40),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              Text(
                failed
                    ? (admin?.error ??
                          training.error ??
                          'Không tải được kết quả đánh giá.')
                    : 'Chưa có dữ liệu đánh giá thực hành.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: NomadKit.secondary),
              ),
              if (failed)
                TextButton.icon(
                  onPressed: admin != null ? admin.retry : training.retry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Thử lại'),
                ),
            ],
          ),
        ),
      );
    }
    return Column(
      children: [
        for (final e in list) ...[
          _buildResultCard(e, showTrainee: admin != null),
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  Widget _buildResultCard(
    PracticalEvaluationRecord eval, {
    bool showTrainee = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Overall Result Badge Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: eval.isPassed
                ? NomadKit.forestLight
                : const Color(0xFFFEE2E2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: eval.isPassed ? NomadKit.forest : NomadKit.error,
            ),
          ),
          child: Row(
            children: [
              Icon(
                eval.isPassed
                    ? Icons.verified_rounded
                    : Icons.report_problem_rounded,
                color: eval.isPassed ? NomadKit.forest : NomadKit.error,
                size: 36,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eval.isPassed
                          ? 'KẾT QUẢ: ĐẠT TIÊU CHUẨN THỰC HÀNH'
                          : 'KẾT QUẢ: CẦN LUYỆN LẠI',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: eval.isPassed ? NomadKit.forest : NomadKit.error,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${showTrainee ? '${eval.traineeName} · ' : ''}Món: ${eval.recipeName} · ${eval.version}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: NomadKit.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Người đánh giá: ${eval.evaluatorName} · Ngày: ${eval.evaluatedDate}',
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
        ),
        const SizedBox(height: 16),

        // Comments & Relearning plan
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
              const Text(
                'NHẬN XÉT CỦA ADMIN QUẢN LÝ',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: NomadKit.sandDark,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                eval.overallComment,
                style: const TextStyle(
                  fontSize: 13,
                  color: NomadKit.ink,
                  height: 1.4,
                ),
              ),
              const Divider(height: 20),
              const Text(
                'KẾ HOẠCH ÔN TẬP / LUYỆN LẠI',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: NomadKit.sandDark,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                eval.relearnPlan,
                style: const TextStyle(
                  fontSize: 13,
                  color: NomadKit.ink,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Observation Checklist Table
        const Text(
          'CHECKLIST TIÊU CHÍ QUAN SÁT TẠI QUẦY',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: NomadKit.sandDark,
            letterSpacing: 0.7,
          ),
        ),
        const SizedBox(height: 10),

        ...eval.criteria.map((c) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: NomadKit.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: NomadKit.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  c.isPassed
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  color: c.isPassed ? NomadKit.forest : NomadKit.error,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              c.name,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: NomadKit.ink,
                              ),
                            ),
                          ),
                          if (c.isCrucial)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: NomadKit.warningLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Bắt buộc',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: NomadKit.warning,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        c.standardRequirement,
                        style: const TextStyle(
                          fontSize: 12,
                          color: NomadKit.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // --- ADMIN VIEW: Giao diện quan sát và chấm thực hành trực tiếp tại quầy ---
  Widget _buildAdminScoringForm(AdminTrainingViewModel vm, AuthViewModel auth) {
    final staff = vm.staff;
    final recipes = context.watch<RecipeViewModel>().items;
    if (vm.state == LoadState.loading) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (vm.state == LoadState.error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              Text(
                vm.error ?? 'Không tải được dữ liệu giám sát.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: NomadKit.secondary),
              ),
              TextButton.icon(
                onPressed: vm.retry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }
    if (staff.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Text(
            'Chưa có Barista nào được cấp tài khoản',
            style: TextStyle(color: NomadKit.secondary),
          ),
        ),
      );
    }
    final current = staff.where((m) => m.uid == _selectedStaff?.uid);
    _selectedStaff = current.isEmpty ? staff.first : current.first;
    if (_selectedRecipe == null && recipes.isNotEmpty) {
      _pickRecipe(recipes.first, vm);
    }
    if (_selectedRecipe != null &&
        _criteria.isEmpty &&
        vm.criteriaTemplates.isNotEmpty) {
      _pickRecipe(_selectedRecipe, vm);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Admin Guide Banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: NomadKit.sandLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: NomadKit.border),
          ),
          child: Row(
            children: const [
              Icon(Icons.edit_note_rounded, color: NomadKit.sandDark, size: 22),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Admin quan sát trực tiếp thao tác của Barista tại quầy bar và đánh giá checklist theo tiêu chuẩn phiên bản hiện hành.',
                  style: TextStyle(
                    fontSize: 12,
                    color: NomadKit.ink,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Select Trainee & Recipe
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
              const Text(
                'CHỌN NHÂN VIÊN ĐÁNH GIÁ',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: NomadKit.sandDark,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 8),

              AppDropdown<StaffMember>(
                value: _selectedStaff,
                items: staff
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Text(
                          t.displayName.isEmpty
                              ? 'Chưa cập nhật'
                              : t.displayName,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: NomadKit.ink,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) =>
                    setState(() => _selectedStaff = v ?? _selectedStaff),
              ),
              const SizedBox(height: 14),

              const Text(
                'CHỌN CÔNG THỨC KIỂM TRA',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: NomadKit.sandDark,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 8),

              AppDropdown<RecipeItem>(
                value: _selectedRecipe,
                items: recipes
                    .map(
                      (r) => DropdownMenuItem(
                        value: r,
                        child: Text(
                          '${r.name} · ${r.version}',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: NomadKit.ink,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) =>
                    setState(() => _pickRecipe(v ?? _selectedRecipe, vm)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Observation Checklist with interactive Switches
        const Text(
          'CHECKLIST TIÊU CHÍ QUAN SÁT (TICK CHỌN)',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: NomadKit.sandDark,
            letterSpacing: 0.7,
          ),
        ),
        const SizedBox(height: 10),

        if (_criteria.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Chưa có tiêu chí chấm mẫu cho món này.',
              style: TextStyle(fontSize: 12, color: NomadKit.secondary),
            ),
          ),
        ..._criteria.map((c) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: NomadKit.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: c.isPassed
                    ? NomadKit.border
                    : NomadKit.error.withOpacity(0.5),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              c.name,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: NomadKit.ink,
                              ),
                            ),
                          ),
                          if (c.isCrucial)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: NomadKit.warningLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Bắt buộc',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: NomadKit.warning,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        c.standardRequirement,
                        style: const TextStyle(
                          fontSize: 11,
                          color: NomadKit.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: c.isPassed,
                  activeThumbColor: NomadKit.forest,
                  onChanged: (val) {
                    setState(() {
                      c.isPassed = val;
                      // If any crucial criteria failed, fail overall
                      if (!val && c.isCrucial) {
                        _isPassedResult = false;
                      }
                    });
                  },
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 16),

        // Overall Result Choice
        const Text(
          'KẾT LUẬN ĐÁNH GIÁ',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: NomadKit.sandDark,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),

        Row(
          children: [
            Expanded(
              child: ChoiceChip(
                label: const Center(
                  child: Text(
                    'Đạt yêu cầu',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                ),
                selected: _isPassedResult,
                selectedColor: NomadKit.forest,
                labelStyle: TextStyle(
                  color: _isPassedResult ? Colors.white : NomadKit.ink,
                ),
                backgroundColor: NomadKit.surface,
                side: const BorderSide(color: NomadKit.border),
                onSelected: (val) => setState(() => _isPassedResult = true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ChoiceChip(
                label: const Center(
                  child: Text(
                    'Cần luyện lại',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                ),
                selected: !_isPassedResult,
                selectedColor: NomadKit.error,
                labelStyle: TextStyle(
                  color: !_isPassedResult ? Colors.white : NomadKit.ink,
                ),
                backgroundColor: NomadKit.surface,
                side: const BorderSide(color: NomadKit.border),
                onSelected: (val) => setState(() => _isPassedResult = false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Admin Comments Input
        const Text(
          'NHẬN XÉT CỦA ADMIN',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: NomadKit.sandDark,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _commentCtrl,
          maxLines: 2,
          style: const TextStyle(fontSize: 13, color: NomadKit.ink),
          decoration: InputDecoration(
            filled: true,
            fillColor: NomadKit.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: NomadKit.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: NomadKit.border),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(height: 12),

        const Text(
          'KẾ HOẠCH ÔN TẬP / LUYỆN LẠI (NẾU CÓ LỖI)',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: NomadKit.sandDark,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _planCtrl,
          maxLines: 2,
          style: const TextStyle(fontSize: 13, color: NomadKit.ink),
          decoration: InputDecoration(
            filled: true,
            fillColor: NomadKit.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: NomadKit.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: NomadKit.border),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(height: 20),

        // Save Evaluation Button (52dp)
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _isPassedResult
                  ? NomadKit.forest
                  : NomadKit.sandDark,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            onPressed: _saving ? null : () => _saveEvaluation(vm, auth),
            icon: const Icon(Icons.check_circle_rounded, size: 20),
            label: const Text(
              'Lưu đánh giá thực hành tại quầy',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
