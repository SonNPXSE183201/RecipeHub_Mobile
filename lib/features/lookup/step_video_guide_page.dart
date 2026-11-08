import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/nomad_kit.dart';
import '../../core/models/app_models.dart';
import '../../core/utils/navigation.dart';

import 'package:video_player/video_player.dart';

import '../../core/viewmodels/step_video_viewmodel.dart';
import '../sop/sop_detail_page.dart';
import '../../core/viewmodels/training_viewmodel.dart';

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
  late final StepVideoViewModel _playback;
  bool _fullscreen = false;
  int get _activeStepNumber => _playback.activeStepNumber;

  @override
  void initState() {
    super.initState();
    _playback = StepVideoViewModel(
      recipe: widget.recipe,
      initialStepNumber: widget.initialStepNumber,
    )..addListener(_refresh);
    _playback.initialize();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _syncPlaybackToStep(int step) => _playback.selectStep(step);

  @override
  void dispose() {
    if (_fullscreen) unawaited(_restorePortrait());
    _playback.removeListener(_refresh);
    _playback.dispose();
    super.dispose();
  }

  String _time(Duration value) =>
      '${value.inMinutes.toString().padLeft(2, '0')}:${(value.inSeconds % 60).toString().padLeft(2, '0')}';

  Future<void> _restorePortrait() async {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  Future<void> _openFullscreen() async {
    if (_fullscreen || !_playback.hasVideo) return;
    setState(() => _fullscreen = true);
    try {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      if (!mounted) return;
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (fullscreenContext) => Scaffold(
            backgroundColor: Colors.black,
            body: SafeArea(
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      tooltip: 'Thoát toàn màn hình',
                      onPressed: () => Navigator.pop(fullscreenContext),
                      icon: const Icon(
                        Icons.fullscreen_exit_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Expanded(
                    child: AnimatedBuilder(
                      animation: _playback,
                      builder: (_, _) => _videoPlayer(fullscreen: true),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } finally {
      await _restorePortrait();
      _fullscreen = false;
      if (mounted) setState(() {});
    }
  }

  Widget _videoPlayer({bool fullscreen = false}) {
    if (_fullscreen && !fullscreen) return const SizedBox(height: 228);
    final controller = _playback.videoController;
    if (!_playback.loading && !_playback.hasVideo) {
      return Container(
        height: 180,
        width: double.infinity,
        color: const Color(0xFF1C1917),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _playback.videoFailed
                  ? 'Không tải được video'
                  : 'Chưa có video cho món này',
              style: const TextStyle(fontSize: 14, color: Colors.white),
            ),
            if (_playback.videoFailed)
              TextButton.icon(
                onPressed: _playback.initialize,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Thử lại'),
                style: TextButton.styleFrom(foregroundColor: NomadKit.sand),
              ),
          ],
        ),
      );
    }
    final duration = _playback.duration.inMilliseconds.toDouble();
    final picture = _playback.loading || controller == null
        ? const Center(child: CircularProgressIndicator(color: NomadKit.sand))
        : Center(
            child: AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: VideoPlayer(controller),
            ),
          );
    return Container(
      color: const Color(0xFF1C1917),
      child: Column(
        children: [
          if (fullscreen)
            Expanded(child: picture)
          else
            SizedBox(height: 180, width: double.infinity, child: picture),
          if (_playback.hasVideo)
            Row(
              children: [
                IconButton(
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  tooltip: _playback.isPlaying ? 'Tạm dừng' : 'Phát video',
                  onPressed: _playback.loading
                      ? null
                      : _playback.togglePlayback,
                  icon: Icon(
                    _playback.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: Colors.white,
                  ),
                ),
                Text(
                  _time(_playback.position),
                  style: const TextStyle(fontSize: 14, color: Colors.white),
                ),
                Expanded(
                  child: Slider(
                    activeColor: NomadKit.sand,
                    value: _playback.position.inMilliseconds.toDouble().clamp(
                      0,
                      duration,
                    ),
                    max: duration > 0 ? duration : 1,
                    onChanged: _playback.loading
                        ? null
                        : (value) => _playback.seek(
                            Duration(milliseconds: value.round()),
                          ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Text(
                    _time(_playback.duration),
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ),
                if (!fullscreen)
                  IconButton(
                    tooltip: 'Phóng to toàn màn hình',
                    onPressed: _openFullscreen,
                    icon: const Icon(
                      Icons.fullscreen_rounded,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
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
    if (recipe.steps.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Video chuẩn')),
        body: Column(
          children: [
            _videoPlayer(),
            const Expanded(
              child: Center(child: Text('Chưa có hướng dẫn từng bước.')),
            ),
          ],
        ),
      );
    }
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
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: NomadKit.ink,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Video chuẩn: ${recipe.name}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: NomadKit.ink,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _videoPlayer(),

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
                        materialTapTargetSize: MaterialTapTargetSize.padded,
                        avatar: Icon(
                          Icons.play_arrow_rounded,
                          size: 16,
                          color: isActive ? Colors.white : NomadKit.sandDark,
                        ),
                        label: Text(
                          _playback.hasVideo
                              ? 'Bước ${st.stepNumber} (${_time(Duration(seconds: st.videoStartSeconds))})'
                              : 'Bước ${st.stepNumber}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isActive
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: isActive ? Colors.white : NomadKit.ink,
                          ),
                        ),
                        selected: isActive,
                        selectedColor: NomadKit.sand,
                        backgroundColor: NomadKit.canvas,
                        side: BorderSide(
                          color: isActive ? NomadKit.sand : NomadKit.border,
                        ),
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: NomadKit.sand,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'BƯỚC ${currentStep.stepNumber}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            currentStep.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: NomadKit.ink,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: NomadKit.sandLight,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: NomadKit.border),
                          ),
                          child: Text(
                            '${currentStep.stepNumber}/$totalSteps bước',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: NomadKit.sandDark,
                            ),
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
                                'assets/icons/icon_video_guide.png',
                                width: 20,
                                height: 20,
                                filterQuality: FilterQuality.medium,
                                errorBuilder: (ctx, err, stack) => const Icon(
                                  Icons.play_circle_outline,
                                  size: 18,
                                  color: NomadKit.sandDark,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'HƯỚNG DẪN THAO TÁC QUẦY BAR',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: NomadKit.sandDark,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            currentStep.instruction,
                            style: const TextStyle(
                              fontSize: 14,
                              color: NomadKit.ink,
                              height: 1.5,
                            ),
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
                                    errorBuilder: (ctx, err, stack) =>
                                        const Icon(
                                          Icons.thermostat_rounded,
                                          size: 22,
                                          color: NomadKit.ocean,
                                        ),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Nhiệt độ chuẩn',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: NomadKit.secondary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        currentStep.temperature!,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: NomadKit.ink,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (currentStep.temperature != null &&
                            currentStep.durationText != null)
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
                                    errorBuilder: (ctx, err, stack) =>
                                        const Icon(
                                          Icons.timer_outlined,
                                          size: 22,
                                          color: NomadKit.sandDark,
                                        ),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Thời gian chuẩn',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: NomadKit.secondary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        currentStep.durationText!,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: NomadKit.ink,
                                        ),
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
                                errorBuilder: (ctx, err, stack) => const Icon(
                                  Icons.check_circle_outline,
                                  size: 20,
                                  color: NomadKit.forest,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'DỤNG CỤ & TIÊU CHÍ HOÀN THÀNH BƯỚC',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: NomadKit.forest,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Dụng cụ: ${_equipmentForStep(currentStep.stepNumber)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: NomadKit.ink,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _completionCriteriaForStep(currentStep.stepNumber),
                            style: const TextStyle(
                              fontSize: 14,
                              color: NomadKit.secondary,
                              height: 1.4,
                            ),
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
                          final sop = context
                              .read<TrainingViewModel>()
                              .sopByCode(currentStep.linkedSopId ?? '');
                          if (sop == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'SOP liên kết chưa có trong thư viện.',
                                ),
                              ),
                            );
                            return;
                          }
                          go(context, SopDetailPage(sop: sop));
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: NomadKit.oceanLight,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: NomadKit.ocean.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Image.asset(
                                'assets/icons/icon_sop_protocol.png',
                                width: 26,
                                height: 26,
                                filterQuality: FilterQuality.medium,
                                errorBuilder: (ctx, err, stack) => const Icon(
                                  Icons.menu_book_rounded,
                                  color: NomadKit.ocean,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'QUY TRÌNH KỸ THUẬT LIÊN KẾT',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: NomadKit.ocean,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      currentStep.linkedSopTitle ??
                                          'Mở hướng dẫn chi tiết SOP',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: NomadKit.ink,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 14,
                                color: NomadKit.ocean,
                              ),
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
                            minimumSize: const Size(48, 48),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: NomadKit.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            foregroundColor: NomadKit.ink,
                          ),
                          onPressed: hasPrev
                              ? () => _syncPlaybackToStep(_activeStepNumber - 1)
                              : null,
                          icon: const Icon(Icons.arrow_back_rounded, size: 16),
                          label: const Text(
                            'Bước trước',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(48, 48),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: NomadKit.sand,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: hasNext
                              ? () => _syncPlaybackToStep(_activeStepNumber + 1)
                              : null,
                          icon: const Icon(
                            Icons.arrow_forward_rounded,
                            size: 16,
                          ),
                          label: const Text(
                            'Bước tiếp theo',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
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
