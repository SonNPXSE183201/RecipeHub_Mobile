import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/viewmodels/auth_viewmodel.dart';
import '../../core/theme/nomad_kit.dart';
import '../../core/models/app_models.dart';
import '../../core/services/mock_data_service.dart';

class PracticalEvaluationPage extends StatefulWidget {
  const PracticalEvaluationPage({super.key});

  @override
  State<PracticalEvaluationPage> createState() => _PracticalEvaluationPageState();
}

class _PracticalEvaluationPageState extends State<PracticalEvaluationPage> {
  // State for Admin Evaluation Mode
  bool _isAdminMode = false;
  String _selectedTrainee = 'Nguyễn Văn Tuấn';
  late RecipeItem _selectedRecipe;

  final List<String> _trainees = ['Nguyễn Văn Tuấn', 'Lê Thị Lan', 'Phạm Hoàng Nam'];

  late List<EvaluationCriterion> _criteria;
  final TextEditingController _commentCtrl = TextEditingController();
  final TextEditingController _planCtrl = TextEditingController();
  bool _isPassedResult = true;

  @override
  void initState() {
    super.initState();
    _isAdminMode = MockDataService.instance.currentRole == UserRole.admin;
    _selectedRecipe = MockDataService.instance.recipes.first;

    _criteria = [
      EvaluationCriterion(
        id: 'c1',
        name: 'Đúng định lượng nguyên liệu theo Size',
        standardRequirement: 'Cân đong chính xác không lệch quá ±1g hoặc ±1ml',
        isPassed: true,
        isCrucial: true,
      ),
      EvaluationCriterion(
        id: 'c2',
        name: 'Kiểm soát nhiệt độ nước và đá',
        standardRequirement: 'Cold Brew đúng 4°C, nhiệt độ nước ủ đạt chuẩn',
        isPassed: true,
        isCrucial: true,
      ),
      EvaluationCriterion(
        id: 'c3',
        name: 'Thao tác khuấy và kỹ thuật tạo tầng',
        standardRequirement: 'Rót nhẹ qua thành ly tạo tầng màu rõ ràng, không lẫn lộn',
        isPassed: true,
        isCrucial: false,
      ),
      EvaluationCriterion(
        id: 'c4',
        name: 'Vệ sinh và bảo quản ca đong sau khi pha',
        standardRequirement: 'Xả sạch ca đong dưới vòi sục nước áp lực ngay lập tức',
        isPassed: true,
        isCrucial: true,
      ),
    ];

    _commentCtrl.text = 'Thao tác chuẩn xác, định lượng đúng từng ml, vệ sinh quầy sạch sẽ.';
    _planCtrl.text = 'Tiếp tục duy trì phong độ cho ca phục vụ cao điểm.';
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    _planCtrl.dispose();
    super.dispose();
  }

  void _saveEvaluation() {
    final newEval = PracticalEvaluationRecord(
      id: 'eval-${DateTime.now().millisecondsSinceEpoch}',
      traineeName: _selectedTrainee,
      storeBranch: MockDataService.instance.currentStoreBranch,
      evaluatorName: MockDataService.instance.currentUserName,
      recipeCode: _selectedRecipe.code,
      recipeName: _selectedRecipe.name,
      version: _selectedRecipe.version,
      evaluatedDate: 'Hôm nay',
      isPassed: _isPassedResult,
      overallComment: _commentCtrl.text.trim(),
      relearnPlan: _planCtrl.text.trim(),
      criteria: _criteria,
    );

    MockDataService.instance.saveEvaluation(newEval);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã lưu kết quả đánh giá thực hành tại quầy thành công.'),
        backgroundColor: NomadKit.forest,
      ),
    );

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final evaluations = MockDataService.instance.evaluations;
    final latestEval = evaluations.isNotEmpty ? evaluations.first : null;

    return Scaffold(
      backgroundColor: NomadKit.canvas,
      appBar: AppBar(
        backgroundColor: NomadKit.canvas,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: NomadKit.ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isAdminMode ? 'Chấm thực hành tại quầy' : 'Kết quả đánh giá thực hành',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: NomadKit.ink),
        ),
        actions: [
          // Chế độ chấm tại quầy chỉ dành cho Admin (Barista chỉ xem kết quả).
          if (context.watch<AuthViewModel>().isAdmin)
            TextButton.icon(
              key: const Key('eval_toggle_admin'),
              style: TextButton.styleFrom(
                foregroundColor: NomadKit.sandDark,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              icon: Icon(_isAdminMode ? Icons.visibility_outlined : Icons.edit_note_rounded, size: 16),
              label: Text(
                _isAdminMode ? 'Xem kết quả' : 'Chấm tại quầy',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              onPressed: () => setState(() => _isAdminMode = !_isAdminMode),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: _isAdminMode ? _buildAdminScoringForm() : _buildViewerResultView(latestEval),
        ),
      ),
    );
  }

  // --- VIEWER VIEW: Xem kết quả đánh giá thực hành của mình ---
  Widget _buildViewerResultView(PracticalEvaluationRecord? eval) {
    if (eval == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Text('Chưa có dữ liệu đánh giá thực hành.', style: TextStyle(color: NomadKit.secondary)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Overall Result Badge Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: eval.isPassed ? NomadKit.forestLight : const Color(0xFFFEE2E2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: eval.isPassed ? NomadKit.forest : NomadKit.error),
          ),
          child: Row(
            children: [
              Icon(
                eval.isPassed ? Icons.verified_rounded : Icons.report_problem_rounded,
                color: eval.isPassed ? NomadKit.forest : NomadKit.error,
                size: 36,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eval.isPassed ? 'KẾT QUẢ: ĐẠT TIÊU CHUẨN THỰC HÀNH' : 'KẾT QUẢ: CẦN LUYỆN LẠI',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: eval.isPassed ? NomadKit.forest : NomadKit.error,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Món: ${eval.recipeName} (${eval.recipeCode} · ${eval.version})',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: NomadKit.ink),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Người đánh giá: ${eval.evaluatorName} · Ngày: ${eval.evaluatedDate}',
                      style: const TextStyle(fontSize: 11, color: NomadKit.secondary),
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
              Text(eval.overallComment, style: const TextStyle(fontSize: 13, color: NomadKit.ink, height: 1.4)),
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
              Text(eval.relearnPlan, style: const TextStyle(fontSize: 13, color: NomadKit.ink, height: 1.4)),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Observation Checklist Table
        const Text(
          'CHECKLIST TIÊU CHÍ QUAN SÁT TẠI QUẦY',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: NomadKit.sandDark, letterSpacing: 0.7),
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
                  c.isPassed ? Icons.check_circle_rounded : Icons.cancel_rounded,
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
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: NomadKit.ink),
                            ),
                          ),
                          if (c.isCrucial)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: NomadKit.warningLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Bắt buộc',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: NomadKit.warning),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(c.standardRequirement, style: const TextStyle(fontSize: 12, color: NomadKit.secondary)),
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
  Widget _buildAdminScoringForm() {
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
                  style: TextStyle(fontSize: 12, color: NomadKit.ink, height: 1.35),
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

              DropdownButtonFormField<String>(
                initialValue: _selectedTrainee,
                isExpanded: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: NomadKit.canvas,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: NomadKit.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: NomadKit.border),
                  ),
                ),
                items: _trainees
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Text(
                          t,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: NomadKit.ink),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedTrainee = v ?? _selectedTrainee),
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

              DropdownButtonFormField<RecipeItem>(
                initialValue: _selectedRecipe,
                isExpanded: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: NomadKit.canvas,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: NomadKit.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: NomadKit.border),
                  ),
                ),
                items: MockDataService.instance.recipes
                    .map(
                      (r) => DropdownMenuItem(
                        value: r,
                        child: Text(
                          '${r.name} (${r.code} · ${r.version})',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: NomadKit.ink),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedRecipe = v ?? _selectedRecipe),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Observation Checklist with interactive Switches
        const Text(
          'CHECKLIST TIÊU CHÍ QUAN SÁT (TICK CHỌN)',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: NomadKit.sandDark, letterSpacing: 0.7),
        ),
        const SizedBox(height: 10),

        ..._criteria.map((c) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: NomadKit.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.isPassed ? NomadKit.border : NomadKit.error.withOpacity(0.5)),
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
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: NomadKit.ink),
                            ),
                          ),
                          if (c.isCrucial)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: NomadKit.warningLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Bắt buộc',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: NomadKit.warning),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(c.standardRequirement, style: const TextStyle(fontSize: 11, color: NomadKit.secondary)),
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
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: NomadKit.sandDark, letterSpacing: 0.6),
        ),
        const SizedBox(height: 8),

        Row(
          children: [
            Expanded(
              child: ChoiceChip(
                label: const Center(
                  child: Text('Đạt yêu cầu', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                ),
                selected: _isPassedResult,
                selectedColor: NomadKit.forest,
                labelStyle: TextStyle(color: _isPassedResult ? Colors.white : NomadKit.ink),
                backgroundColor: NomadKit.surface,
                side: const BorderSide(color: NomadKit.border),
                onSelected: (val) => setState(() => _isPassedResult = true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ChoiceChip(
                label: const Center(
                  child: Text('Cần luyện lại', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                ),
                selected: !_isPassedResult,
                selectedColor: NomadKit.error,
                labelStyle: TextStyle(color: !_isPassedResult ? Colors.white : NomadKit.ink),
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
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: NomadKit.sandDark, letterSpacing: 0.6),
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
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: NomadKit.sandDark, letterSpacing: 0.6),
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
              backgroundColor: _isPassedResult ? NomadKit.forest : NomadKit.sandDark,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            onPressed: _saveEvaluation,
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
