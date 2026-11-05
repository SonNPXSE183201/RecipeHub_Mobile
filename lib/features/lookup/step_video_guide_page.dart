import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/nomad_kit.dart';
import '../../core/models/app_models.dart';
import '../../core/utils/navigation.dart';
import '../feedback/create_feedback_page.dart';
import '../sop/sop_detail_page.dart';
import '../../core/services/mock_data_service.dart';

class StepVideoGuidePage extends StatefulWidget {
  const StepVideoGuidePage({
    super.key,
    required this.recipe,
    this.initialStepNumber = 1,
  });

  final RecipeItem recipe;
  final int initialStepNumber;

  @override
  State<StepVideoGuidePage> createState() => _StepVideoGuidePageState();
}

class _StepVideoGuidePageState extends State<StepVideoGuidePage> {
  late int _activeStepNumber;
  bool _isPlaying = true;
  bool _isVideoErrorFallback = false;
  int _currentPlaybackSeconds = 0;
  Timer? _playbackTimer;

  @override
  void initState() {
    super.initState();
    _activeStepNumber = widget.initialStepNumber;
    _syncPlaybackToStep(_activeStepNumber);
    _startSimulatedVideoTimer();
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    super.dispose();
  }

  void _syncPlaybackToStep(int stepNum) {
    final step = widget.recipe.steps.firstWhere(
      (s) => s.stepNumber == stepNum,
      orElse: () => widget.recipe.steps.first,
    );
    setState(() {
      _activeStepNumber = stepNum;
      _currentPlaybackSeconds = step.videoStartSeconds;
    });
  }

  void _startSimulatedVideoTimer() {
    _playbackTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isPlaying && !_isVideoErrorFallback) {
        setState(() {
          _currentPlaybackSeconds++;
          if (_currentPlaybackSeconds > 60) {
            _currentPlaybackSeconds = 0;
          }
          for (final st in widget.recipe.steps) {
            if (_currentPlaybackSeconds >= st.videoStartSeconds &&
                _currentPlaybackSeconds < st.videoEndSeconds) {
              if (_activeStepNumber != st.stepNumber) {
                _activeStepNumber = st.stepNumber;
              }
              break;
            }
          }
        });
      }
    });
  }

  void _togglePlayPause() {
    setState(() => _isPlaying = !_isPlaying);
  }

  String _completionCriteriaForStep(int stepNumber) {
    switch (stepNumber) {
      case 1:
        return 'Cốt Cold Brew trong suốt, đúng định lượng 100 ml tại vạch ca đong Inox, nhiệt độ bảo quản đạt 4°C.';
      case 2:
        return 'Hỗn hợp nước cốt cam vàng và syrup quế hòa quyện đồng nhất, thơm dịu, không lắng cặn đáy ly.';
      case 3:
        return 'Đá viên bi đầy cách miệng ly 1.5 cm, tạo nền nâng đỡ vững chắc cho tầng cà phê phía trên.';
      default:
        return 'Thành phẩm phân 2 tầng màu rõ rệt, lát cam vàng sấy đặt cân đối trên bề mặt đá.';
    }
  }

  String _equipmentForStep(int stepNumber) {
    switch (stepNumber) {
      case 1:
        return 'Ca đong chuẩn Inox 250 ml · Bình ủ lạnh Toddy';
      case 2:
        return 'Jigger đong 2 đầu (20/40 ml) · Muỗng khuấy bar';
      case 3:
        return 'Xúc đá Inox tiêu chuẩn · Ly thủy tinh 500 ml';
      default:
        return 'Kẹp gắp trang trí Inox · Khay phục vụ quầy bar';
    }
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;
    final totalSteps = recipe.steps.length;
    final currentStep = recipe.steps.firstWhere(
      (s) => s.stepNumber == _activeStepNumber,
      orElse: () => recipe.steps.first,
    );
    final hasPrev = _activeStepNumber > 1;
    final hasNext = _activeStepNumber < totalSteps;

    return Scaffold(
      backgroundColor: NomadKit.canvas,
      appBar: AppBar(
        backgroundColor: NomadKit.canvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: NomadKit.ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Video chuẩn: ${recipe.name}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: NomadKit.ink),
        ),
        actions: [
          IconButton(
            tooltip: 'Phản hồi bước này',
            icon: Image.asset(
              'assets/icons/icon_feedback_pencil.png',
              width: 22,
              height: 22,
              filterQuality: FilterQuality.medium,
              errorBuilder: (ctx, err, stack) => const Icon(Icons.feedback_outlined, size: 20, color: NomadKit.sandDark),
            ),
            onPressed: () {
              go(
                context,
                CreateFeedbackPage(
                  initialRecipeCode: recipe.code,
                  initialRecipeName: recipe.name,
                  initialVersion: recipe.version,
                  initialStepNumber: currentStep.stepNumber,
                  initialStepTitle: currentStep.title,
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Video Player Section / Fallback Container
            if (!_isVideoErrorFallback) ...[
              Container(
                width: double.infinity,
                height: 228,
                color: const Color(0xFF1C1917),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Mock Video Frame Background
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.35),
                              Colors.black.withOpacity(0.75),
                            ],
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 54),
                              Text(
                                'Video chuẩn chuỗi: ${recipe.name} · ${recipe.version}',
                                style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.85)),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Đang phát Bước ${currentStep.stepNumber}: ${currentStep.title}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Play/Pause Center Tap
                    Positioned(
                      top: 42,
                      child: GestureDetector(
                        onTap: _togglePlayPause,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: NomadKit.sand.withOpacity(0.28),
                            shape: BoxShape.circle,
                            border: Border.all(color: NomadKit.sand, width: 1.5),
                          ),
                          child: Icon(
                            _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            size: 34,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    // Video Controls Overlay (Bottom)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        color: Colors.black.withOpacity(0.65),
                        child: Row(
                          children: [
                            Text(
                              '00:${_currentPlaybackSeconds.toString().padLeft(2, '0')}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'monospace'),
                            ),
                            const Text(' / 01:00', style: TextStyle(fontSize: 12, color: Colors.white70, fontFamily: 'monospace')),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 3,
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                                  activeTrackColor: NomadKit.sand,
                                  inactiveTrackColor: Colors.white24,
                                  thumbColor: NomadKit.sand,
                                ),
                                child: Slider(
                                  value: _currentPlaybackSeconds.toDouble().clamp(0.0, 60.0),
                                  min: 0,
                                  max: 60,
                                  onChanged: (val) {
                                    setState(() => _currentPlaybackSeconds = val.toInt());
                                  },
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.report_problem_outlined, size: 18, color: Colors.amber),
                              tooltip: 'Mô phỏng lỗi video -> Đọc chữ dự phòng',
                              onPressed: () {
                                setState(() => _isVideoErrorFallback = true);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF2F2),
                  border: Border(bottom: BorderSide(color: NomadKit.error)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_off_rounded, color: NomadKit.error, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Video tạm thời không khả dụng',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: NomadKit.error),
                          ),
                          Text(
                            'Chế độ đọc chữ dự phòng được kích hoạt. Bạn vẫn có thể thực hiện pha chế bình thường.',
                            style: TextStyle(fontSize: 11, color: NomadKit.ink, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _isVideoErrorFallback = false),
                      child: const Text('Thử tải lại', style: TextStyle(fontWeight: FontWeight.w700, color: NomadKit.sandDark)),
                    ),
                  ],
                ),
              ),
            ],

            // Step Selector Scroller
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: NomadKit.surface,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: recipe.steps.map((st) {
                    final isActive = st.stepNumber == _activeStepNumber;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        avatar: Icon(
                          Icons.play_arrow_rounded,
                          size: 16,
                          color: isActive ? Colors.white : NomadKit.sandDark,
                        ),
                        label: Text(
                          'Bước ${st.stepNumber} (00:${st.videoStartSeconds.toString().padLeft(2, '0')})',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                            color: isActive ? Colors.white : NomadKit.ink,
                          ),
                        ),
                        selected: isActive,
                        selectedColor: NomadKit.sand,
                        backgroundColor: NomadKit.canvas,
                        side: BorderSide(color: isActive ? NomadKit.sand : NomadKit.border),
                        showCheckmark: false,
                        onSelected: (val) {
                          if (val) _syncPlaybackToStep(st.stepNumber);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            const Divider(height: 1, color: NomadKit.border),

            // Step Detail Body (Balanced vertical distribution)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Step Number, Title & Progress Indicator
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: NomadKit.sand,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'BƯỚC ${currentStep.stepNumber}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            currentStep.title,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: NomadKit.ink),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: NomadKit.sandLight,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: NomadKit.border),
                          ),
                          child: Text(
                            '${currentStep.stepNumber}/$totalSteps bước',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: NomadKit.sandDark),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 1. Instruction Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
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
                          Row(
                            children: [
                              Image.asset(
                                'assets/icons/icon_video_guide.png',
                                width: 20,
                                height: 20,
                                filterQuality: FilterQuality.medium,
                                errorBuilder: (ctx, err, stack) => const Icon(Icons.play_circle_outline, size: 18, color: NomadKit.sandDark),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'HƯỚNG DẪN THAO TÁC QUẦY BAR',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: NomadKit.sandDark, letterSpacing: 0.6),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            currentStep.instruction,
                            style: const TextStyle(fontSize: 14, color: NomadKit.ink, height: 1.5),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 2. Technical Parameters (Temp, Time)
                    Row(
                      children: [
                        if (currentStep.temperature != null)
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: NomadKit.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: NomadKit.border),
                              ),
                              child: Row(
                                children: [
                                  Image.asset(
                                    'assets/icons/icon_thermometer_cold.png',
                                    width: 26,
                                    height: 26,
                                    filterQuality: FilterQuality.medium,
                                    errorBuilder: (ctx, err, stack) => const Icon(Icons.thermostat_rounded, size: 22, color: NomadKit.ocean),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Nhiệt độ chuẩn', style: TextStyle(fontSize: 11, color: NomadKit.secondary)),
                                      const SizedBox(height: 2),
                                      Text(
                                        currentStep.temperature!,
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: NomadKit.ink),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (currentStep.temperature != null && currentStep.durationText != null)
                          const SizedBox(width: 12),
                        if (currentStep.durationText != null)
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: NomadKit.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: NomadKit.border),
                              ),
                              child: Row(
                                children: [
                                  Image.asset(
                                    'assets/icons/icon_timer_brew.png',
                                    width: 26,
                                    height: 26,
                                    filterQuality: FilterQuality.medium,
                                    errorBuilder: (ctx, err, stack) => const Icon(Icons.timer_outlined, size: 22, color: NomadKit.sandDark),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Thời gian chuẩn', style: TextStyle(fontSize: 11, color: NomadKit.secondary)),
                                      const SizedBox(height: 2),
                                      Text(
                                        currentStep.durationText!,
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: NomadKit.ink),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // 3. Equipment & Completion Criteria Card (from recipe_step schema)
                    Container(
                      width: double.infinity,
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
                                'assets/icons/icon_check_circle.png',
                                width: 22,
                                height: 22,
                                filterQuality: FilterQuality.medium,
                                errorBuilder: (ctx, err, stack) => const Icon(Icons.check_circle_outline, size: 20, color: NomadKit.forest),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'DỤNG CỤ & TIÊU CHÍ HOÀN THÀNH BƯỚC',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: NomadKit.forest, letterSpacing: 0.5),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Dụng cụ: ${_equipmentForStep(currentStep.stepNumber)}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: NomadKit.ink),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _completionCriteriaForStep(currentStep.stepNumber),
                            style: const TextStyle(fontSize: 13, color: NomadKit.secondary, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 4. Linked SOP (if available)
                    if (currentStep.linkedSopId != null) ...[
                      InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          final sop = MockDataService.instance.sops.firstWhere(
                            (s) => s.id == currentStep.linkedSopId,
                            orElse: () => MockDataService.instance.sops.first,
                          );
                          go(context, SopDetailPage(sop: sop));
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: NomadKit.oceanLight,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: NomadKit.ocean.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Image.asset(
                                'assets/icons/icon_sop_protocol.png',
                                width: 26,
                                height: 26,
                                filterQuality: FilterQuality.medium,
                                errorBuilder: (ctx, err, stack) => const Icon(Icons.menu_book_rounded, color: NomadKit.ocean, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'QUY TRÌNH KỸ THUẬT LIÊN KẾT',
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: NomadKit.ocean, letterSpacing: 0.5),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      currentStep.linkedSopTitle ?? 'Mở hướng dẫn chi tiết SOP',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: NomadKit.ink),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: NomadKit.ocean),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Pinned Bottom Action Bar (Step Navigation + Feedback)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: const BoxDecoration(
                color: NomadKit.surface,
                border: Border(top: BorderSide(color: NomadKit.border)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: NomadKit.border),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            foregroundColor: NomadKit.ink,
                          ),
                          onPressed: hasPrev ? () => _syncPlaybackToStep(_activeStepNumber - 1) : null,
                          icon: const Icon(Icons.arrow_back_rounded, size: 16),
                          label: const Text('Bước trước', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: NomadKit.sand,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: hasNext ? () => _syncPlaybackToStep(_activeStepNumber + 1) : null,
                          icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                          label: const Text('Bước tiếp theo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: const BorderSide(color: NomadKit.sandDark),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        foregroundColor: NomadKit.sandDark,
                      ),
                      onPressed: () {
                        go(
                          context,
                          CreateFeedbackPage(
                            initialRecipeCode: recipe.code,
                            initialRecipeName: recipe.name,
                            initialVersion: recipe.version,
                            initialStepNumber: currentStep.stepNumber,
                            initialStepTitle: currentStep.title,
                          ),
                        );
                      },
                      icon: Image.asset(
                        'assets/icons/icon_feedback_pencil.png',
                        width: 18,
                        height: 18,
                        filterQuality: FilterQuality.medium,
                        errorBuilder: (ctx, err, stack) => const Icon(Icons.feedback_outlined, size: 18),
                      ),
                      label: Text(
                        'Gửi phản hồi cho Bước ${currentStep.stepNumber}',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
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
