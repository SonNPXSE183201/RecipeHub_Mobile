import '../../core/widgets/app_dropdown.dart';
import '../../core/widgets/redesign_widgets.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/viewmodels/auth_viewmodel.dart';
import '../../core/theme/nomad_kit.dart';
import '../../core/models/app_models.dart';
import '../../core/models/training_models.dart';
import '../../core/viewmodels/recipe_viewmodel.dart';
import '../../core/viewmodels/training_viewmodel.dart';
import '../../core/widgets/app_toast.dart';

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
    final messenger = ToastMessenger.of(context);
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
    if (err == null && mounted) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(
            Icons.verified_rounded,
            color: NomadKit.forest,
            size: 42,
          ),
          title: const Text('Đã đánh giá'),
          content: Text(
            'Kết quả của ${staff.displayName} đã được ghi nhận và đồng bộ.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hoàn tất'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final admin = context.watch<AdminTrainingViewModel>();
    final training = context.watch<TrainingViewModel>();
    final evaluations = auth.isAdmin
        ? admin.evaluations
        : training.myEvaluations;
    final formReady =
        _isAdminMode &&
        admin.state == LoadState.ready &&
        admin.staff.isNotEmpty;

    return RhFlowScaffold(
      title: _isAdminMode ? 'Chấm thực hành' : 'Kết quả đánh giá thực hành',
      // Chế độ chấm tại quầy chỉ dành cho Admin (Barista chỉ xem kết quả).
      trailing: auth.isAdmin
          ? Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Semantics(
                button: true,
                label: _isAdminMode ? 'Xem kết quả' : 'Chấm tại quầy',
                child: IconButton(
                  key: const Key('eval_toggle_admin'),
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
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
            )
          : null,
      bottomAction: formReady
          ? SizedBox(
              height: 52,
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: NomadKit.sandDark,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: NomadKit.border,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _saving ? null : () => _saveEvaluation(admin, auth),
                icon: const Icon(Icons.check_rounded, size: 20),
                label: const Text(
                  'Lưu đánh giá thực hành',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: _isAdminMode
            ? _buildAdminScoringForm(admin, auth)
            : _buildResults(evaluations, auth.isAdmin ? admin : null, training),
      ),
    );
  }

  Widget _stateBox(String message, {VoidCallback? onRetry}) => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: NomadKit.label.copyWith(
              color: NomadKit.secondary,
              fontWeight: FontWeight.w400,
            ),
          ),
          if (onRetry != null)
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
            ),
        ],
      ),
    ),
  );

  Widget _card({String? label, required Widget child, Color? borderColor}) =>
      Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: NomadKit.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor ?? NomadKit.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (label != null) ...[
              Text(
                label,
                style: NomadKit.label.copyWith(
                  fontWeight: FontWeight.w600,
                  color: NomadKit.sandDark,
                ),
              ),
              const SizedBox(height: 8),
            ],
            child,
          ],
        ),
      );

  Widget _crucialBadge() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: NomadKit.warningLight,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      'Bắt buộc',
      style: NomadKit.caption.copyWith(
        fontWeight: FontWeight.w600,
        color: NomadKit.warning,
      ),
    ),
  );

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
      return _stateBox(
        failed
            ? (admin?.error ??
                  training.error ??
                  'Không tải được kết quả đánh giá.')
            : 'Chưa có dữ liệu đánh giá thực hành.',
        onRetry: failed ? (admin != null ? admin.retry : training.retry) : null,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Kết quả thực hành', style: NomadKit.title),
        const SizedBox(height: 16),
        for (final e in list) ...[
          _buildResultCard(e, showTrainee: admin != null),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildResultCard(
    PracticalEvaluationRecord eval, {
    bool showTrainee = false,
  }) {
    final color = eval.isPassed ? NomadKit.forest : NomadKit.error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _card(
          borderColor: color,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                eval.isPassed
                    ? Icons.verified_outlined
                    : Icons.report_problem_outlined,
                color: color,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eval.isPassed
                          ? 'Đạt tiêu chuẩn thực hành'
                          : 'Cần luyện lại',
                      style: NomadKit.label.copyWith(
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${showTrainee ? '${eval.traineeName} · ' : ''}Món: ${eval.recipeName} · ${eval.version}',
                      style: NomadKit.label,
                    ),
                    Text(
                      'Người đánh giá: ${eval.evaluatorName} · Ngày: ${eval.evaluatedDate}',
                      style: NomadKit.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        _card(
          label: 'Nhận xét của Admin quản lý',
          child: Text(
            eval.overallComment,
            style: NomadKit.label.copyWith(fontWeight: FontWeight.w400),
          ),
        ),
        _card(
          label: 'Kế hoạch ôn tập / luyện lại',
          child: Text(
            eval.relearnPlan,
            style: NomadKit.label.copyWith(fontWeight: FontWeight.w400),
          ),
        ),
        _card(
          label: 'Tiêu chí quan sát tại quầy',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final c in eval.criteria)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        c.isPassed
                            ? Icons.check_circle_outline_rounded
                            : Icons.cancel_outlined,
                        color: c.isPassed ? NomadKit.forest : NomadKit.error,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(c.name, style: NomadKit.label),
                                ),
                                if (c.isCrucial) _crucialBadge(),
                              ],
                            ),
                            Text(
                              c.standardRequirement,
                              style: NomadKit.caption,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: NomadKit.label.copyWith(
      color: NomadKit.secondary,
      fontWeight: FontWeight.w400,
    ),
    isDense: true,
    filled: true,
    fillColor: NomadKit.surface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: NomadKit.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: NomadKit.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: NomadKit.sandDark),
    ),
    contentPadding: const EdgeInsets.all(12),
  );

  Widget _resultChoice(String label, bool value, Color activeColor) {
    final selected = _isPassedResult == value;
    return Expanded(
      child: ChoiceChip(
        label: SizedBox(
          width: double.infinity,
          child: Text(label, textAlign: TextAlign.center),
        ),
        selected: selected,
        showCheckmark: false,
        selectedColor: activeColor,
        backgroundColor: NomadKit.surface,
        labelStyle: NomadKit.label.copyWith(
          fontWeight: FontWeight.w600,
          color: selected ? Colors.white : NomadKit.ink,
        ),
        side: const BorderSide(color: NomadKit.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onSelected: (_) => setState(() => _isPassedResult = value),
      ),
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
      return _stateBox(
        vm.error ?? 'Không tải được dữ liệu giám sát.',
        onRetry: vm.retry,
      );
    }
    if (staff.isEmpty) {
      return _stateBox('Chưa có Barista nào được cấp tài khoản');
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
    final itemStyle = NomadKit.label.copyWith(fontWeight: FontWeight.w400);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chấm thực hành tại quầy',
          style: NomadKit.title.copyWith(color: NomadKit.sandDark),
        ),
        const SizedBox(height: 4),
        Text(
          'Quan sát trực tiếp thao tác của Barista tại quầy bar và đánh giá checklist theo tiêu chuẩn phiên bản hiện hành.',
          style: NomadKit.caption,
        ),
        const SizedBox(height: 16),
        _card(
          label: 'Barista *',
          child: AppDropdown<StaffMember>(
            value: _selectedStaff,
            items: staff
                .map(
                  (t) => DropdownMenuItem(
                    value: t,
                    child: Text(
                      t.displayName.isEmpty ? 'Chưa cập nhật' : t.displayName,
                      overflow: TextOverflow.ellipsis,
                      style: itemStyle,
                    ),
                  ),
                )
                .toList(),
            onChanged: (v) =>
                setState(() => _selectedStaff = v ?? _selectedStaff),
          ),
        ),
        _card(
          label: 'Công thức *',
          child: AppDropdown<RecipeItem>(
            value: _selectedRecipe,
            items: recipes
                .map(
                  (r) => DropdownMenuItem(
                    value: r,
                    child: Text(
                      '${r.name} · ${r.version}',
                      overflow: TextOverflow.ellipsis,
                      style: itemStyle,
                    ),
                  ),
                )
                .toList(),
            onChanged: (v) =>
                setState(() => _pickRecipe(v ?? _selectedRecipe, vm)),
          ),
        ),
        _card(
          label: 'Tiêu chí quan sát *',
          child: _criteria.isEmpty
              ? Text(
                  'Chưa có tiêu chí chấm mẫu cho món này.',
                  style: NomadKit.caption,
                )
              : Column(
                  children: [
                    for (final c in _criteria)
                      Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(c.name, style: itemStyle),
                                      ),
                                      if (c.isCrucial) ...[
                                        const SizedBox(width: 6),
                                        _crucialBadge(),
                                      ],
                                    ],
                                  ),
                                  Text(
                                    c.standardRequirement,
                                    style: NomadKit.caption,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Switch(
                            value: c.isPassed,
                            activeThumbColor: NomadKit.forest,
                            onChanged: (val) {
                              setState(() {
                                c.isPassed = val;
                                // Tiêu chí bắt buộc không đạt → kết luận không đạt.
                                if (!val && c.isCrucial) {
                                  _isPassedResult = false;
                                }
                              });
                            },
                          ),
                        ],
                      ),
                  ],
                ),
        ),
        _card(
          label: 'Kết quả *',
          child: Row(
            children: [
              _resultChoice('Đạt yêu cầu', true, NomadKit.forest),
              const SizedBox(width: 12),
              _resultChoice('Cần luyện lại', false, NomadKit.error),
            ],
          ),
        ),
        _card(
          label: 'Nhận xét',
          child: TextField(
            controller: _commentCtrl,
            maxLines: 2,
            style: itemStyle,
            decoration: _inputDecoration(
              'Thao tác đã tốt và điểm cần cải thiện...',
            ),
          ),
        ),
        _card(
          label: 'Kế hoạch ôn tập',
          child: TextField(
            controller: _planCtrl,
            maxLines: 2,
            style: itemStyle,
            decoration: _inputDecoration('Nội dung nhân viên cần luyện lại...'),
          ),
        ),
      ],
    );
  }
}
