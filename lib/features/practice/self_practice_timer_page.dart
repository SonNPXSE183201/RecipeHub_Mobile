import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/nomad_kit.dart';
import '../../core/viewmodels/practice_history_viewmodel.dart';
import '../../core/models/app_models.dart';
import '../../core/di/app_services.dart';
import '../../core/navigation/app_keys.dart';
import '../../core/services/mock_data_service.dart';
import '../../core/utils/navigation.dart';
import 'practice_history_page.dart';

class SelfPracticeTimerPage extends StatefulWidget {
  const SelfPracticeTimerPage({
    super.key,
    this.initialRecipe,
    this.initialSizeCode,
  });

  final RecipeItem? initialRecipe;
  final String? initialSizeCode;

  @override
  State<SelfPracticeTimerPage> createState() => _SelfPracticeTimerPageState();
}

class _SelfPracticeTimerPageState extends State<SelfPracticeTimerPage> {
  late RecipeItem _selectedRecipe;
  late String _selectedSizeCode;

  int _secondsElapsed = 0;
  bool _isRunning = false;
  Timer? _timer;

  final TextEditingController _notesCtrl = TextEditingController();
  bool _startLogged = false;

  /// Chuẩn thời gian (giây) suy ra từ `standardTime` của công thức, 0 nếu không có.
  int get _targetSeconds => int.tryParse(RegExp(r'\d+').firstMatch(_selectedRecipe.standardTime)?.group(0) ?? '') ?? 0;

  @override
  void initState() {
    super.initState();
    _selectedRecipe = widget.initialRecipe ?? MockDataService.instance.recipes.first; // AuthGate chỉ mở Shell khi đã có công thức
    _selectedSizeCode = widget.initialSizeCode ?? _selectedRecipe.sizes.first.sizeCode;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
      setState(() => _isRunning = false);
    } else {
      setState(() => _isRunning = true);
      if (!_startLogged) {
        _startLogged = true;
        context.read<AppServices>().analytics.logStartBrewTimer(
              recipeCode: _selectedRecipe.code,
              size: _selectedSizeCode,
              targetSeconds: _targetSeconds,
            );
      }
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        setState(() => _secondsElapsed++);
      });
    }
  }

  void _resetTimer() {
    _timer?.cancel();
    _startLogged = false;
    setState(() {
      _secondsElapsed = 0;
      _isRunning = false;
    });
  }

  void _savePracticeRecord() {
    if (_secondsElapsed == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng bấm giờ thực hành trước khi lưu.'),
          backgroundColor: NomadKit.warning,
        ),
      );
      return;
    }

    final newRecord = SelfPracticeRecord(
      id: 'pr-${DateTime.now().millisecondsSinceEpoch}',
      recipeName: _selectedRecipe.name,
      recipeCode: _selectedRecipe.code,
      size: 'Khẩu phần chuẩn (500ml)',
      durationSeconds: _secondsElapsed,
      notes: _notesCtrl.text.trim().isEmpty ? 'Tự luyện hoàn thành tốt.' : _notesCtrl.text.trim(),
      practicedAt: DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
      targetSeconds: _targetSeconds,
    );

    context.read<PracticeHistoryViewModel>().add(newRecord);
    context.read<AppServices>().analytics.logCompleteBrewTimer(
          recipeCode: newRecord.recipeCode,
          size: _selectedSizeCode,
          actualSeconds: _secondsElapsed,
          deviationSeconds: newRecord.deviationSeconds,
          withinTolerance: _targetSeconds == 0 || newRecord.deviationSeconds.abs() <= 5,
        );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã lưu phiên tự luyện vào lịch sử cá nhân.'),
        backgroundColor: NomadKit.forest,
      ),
    );

    go(context, const PracticeHistoryPage());
  }

  @override
  Widget build(BuildContext context) {
    final allRecipes = MockDataService.instance.recipes;
    final currentSizeOption = _selectedRecipe.sizes.firstWhere(
      (s) => s.sizeCode == _selectedSizeCode,
      orElse: () => _selectedRecipe.sizes.first,
    );

    final minutes = (_secondsElapsed ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsElapsed % 60).toString().padLeft(2, '0');

    return Scaffold(
      backgroundColor: NomadKit.canvas,
      appBar: AppBar(
        backgroundColor: NomadKit.canvas,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: NomadKit.ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Tự luyện & Bấm giờ quầy bar',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: NomadKit.ink),
        ),
        actions: [
          IconButton(
            tooltip: 'Lịch sử tự luyện',
            icon: const Icon(Icons.history_rounded, size: 22, color: NomadKit.sandDark),
            onPressed: () => go(context, const PracticeHistoryPage()),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Recipe Picker
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: NomadKit.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: NomadKit.border),
                        boxShadow: const [
                          BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 2)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('CHỌN MÓN LUYỆN TẬP', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: NomadKit.sandDark, letterSpacing: 0.6)),
                          const SizedBox(height: 8),

                          DropdownButtonFormField<RecipeItem>(
                            initialValue: _selectedRecipe,
                            isExpanded: true,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: NomadKit.canvas,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: NomadKit.border)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: NomadKit.border)),
                            ),
                            items: allRecipes.map((r) {
                              return DropdownMenuItem(
                                value: r,
                                child: Text('${r.name} (${r.code} · ${r.version})', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: NomadKit.ink)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedRecipe = val;
                                  _selectedSizeCode = val.sizes.first.sizeCode;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Timer Display Card
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
                      decoration: BoxDecoration(
                        color: NomadKit.surface,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: NomadKit.border),
                        boxShadow: const [
                          BoxShadow(color: Color(0x0A000000), blurRadius: 14, offset: Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text('ĐỒNG HỒ BẤM GIỜ THAO TÁC', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: NomadKit.sandDark, letterSpacing: 0.8)),
                          const SizedBox(height: 10),
                          Text(
                            '$minutes:$seconds',
                            style: const TextStyle(fontSize: 54, fontWeight: FontWeight.w900, fontFamily: 'monospace', color: NomadKit.ink),
                          ),
                          const SizedBox(height: 14),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 144,
                                height: 44,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _isRunning ? const Color(0xFFEF4444) : NomadKit.sand,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    side: BorderSide.none,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(horizontal: 14),
                                  ),
                                  key: AppKeys.timerStart,
                                  onPressed: _toggleTimer,
                                  icon: Icon(_isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 19),
                                  label: Text(
                                    _isRunning ? 'Tạm dừng' : 'Bấm giờ',
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 112,
                                height: 44,
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: NomadKit.ink,
                                    backgroundColor: NomadKit.canvas,
                                    side: const BorderSide(color: NomadKit.border, width: 1.2),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                  ),
                                  onPressed: _resetTimer,
                                  icon: const Icon(Icons.refresh_rounded, size: 17, color: NomadKit.secondary),
                                  label: const Text('Đặt lại', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Rule Banner (BR-09)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: NomadKit.sandLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: NomadKit.border),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Icon(Icons.shield_outlined, size: 18, color: NomadKit.sandDark),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Nguyên tắc BR-09: Thời gian tự luyện dùng để theo dõi sự tự tin và tiến bộ cá nhân. Hệ thống không tự động chấm đạt dựa trên tốc độ và không xếp hạng thi đua giữa các nhân viên.',
                              style: TextStyle(fontSize: 11, color: NomadKit.sandDark, height: 1.35),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Portion Quick Reference
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'ĐỊNH LƯỢNG NGUYÊN LIỆU THAM KHẢO',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: NomadKit.sandDark, letterSpacing: 0.7),
                        ),
                        Text(
                          'Chuẩn ${_selectedRecipe.standardTime}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: NomadKit.secondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: NomadKit.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: NomadKit.border),
                      ),
                      child: Column(
                        children: currentSizeOption.ingredients.map((ing) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(ing.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: NomadKit.ink)),
                                Text(
                                  '${ing.amount.toString().replaceAll('.0', '')} ${ing.unit}',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: NomadKit.sandDark),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Personal Practice Notes
                    const Text(
                      'GHI CHÚ RÚT KINH NGHIỆM CÁ NHÂN',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: NomadKit.sandDark, letterSpacing: 0.7),
                    ),
                    const SizedBox(height: 8),

                    TextField(
                      controller: _notesCtrl,
                      maxLines: 3,
                      style: const TextStyle(fontSize: 13, color: NomadKit.ink),
                      decoration: InputDecoration(
                        hintText: 'Ví dụ: Lần sau cần cắt cam mỏng hơn, giữ lạnh cốt cà phê đúng 4°C...',
                        hintStyle: const TextStyle(fontSize: 12, color: NomadKit.secondary),
                        filled: true,
                        fillColor: NomadKit.surface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: NomadKit.border)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: NomadKit.border)),
                        contentPadding: const EdgeInsets.all(14),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Pinned Bottom Action Bar with Balanced Save Practice Button
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
              decoration: const BoxDecoration(
                color: NomadKit.surface,
                border: Border(top: BorderSide(color: NomadKit.border)),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 120,
                    height: 48,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: NomadKit.sandDark,
                        backgroundColor: NomadKit.sandLight,
                        side: const BorderSide(color: NomadKit.border, width: 1.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      onPressed: () => go(context, const PracticeHistoryPage()),
                      icon: const Icon(Icons.history_rounded, size: 17),
                      label: const Text(
                        'Lịch sử',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: NomadKit.forest,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                          side: BorderSide.none,
                        ),
                        key: AppKeys.timerSave,
                        onPressed: _savePracticeRecord,
                        icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                        label: const Text(
                          'Lưu lần luyện tập',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
