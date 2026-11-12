import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/nomad_kit.dart';
import '../../core/models/app_models.dart';
import '../../core/utils/navigation.dart';
import '../../core/utils/video_time.dart';
import '../../core/widgets/redesign_widgets.dart';

import 'package:video_player/video_player.dart';

import '../../core/viewmodels/step_video_viewmodel.dart';
import '../sop/sop_detail_page.dart';
import '../../core/viewmodels/training_viewmodel.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/rh_motion.dart';

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
        RhPageRoute(
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

  Widget _statusPanel({
    required IconData icon,
    required String title,
    String? subtitle,
  }) {
    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF30231B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 28, color: Colors.white),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ],
      ),
    );
  }

  Widget _videoPlayer({bool fullscreen = false}) {
    if (_fullscreen && !fullscreen) return const SizedBox(height: 228);
    final controller = _playback.videoController;
    if (!_playback.loading && !_playback.hasVideo) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _statusPanel(
            icon: _playback.videoFailed
                ? Icons.error_outline_rounded
                : Icons.videocam_off_outlined,
            title: _playback.videoFailed
                ? 'Chưa tải được video'
                : 'Chưa có video cho món này',
            subtitle: _playback.videoFailed
                ? 'Kiểm tra kết nối rồi thử lại.'
                : 'Hướng dẫn từng bước vẫn có bên dưới.',
          ),
          if (_playback.videoFailed) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: NomadKit.sandDark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _playback.initialize,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text(
                  'Thử tải lại video',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
      );
    }
    if (_playback.loading || controller == null) {
      return _statusPanel(
        icon: Icons.sync_rounded,
        title: 'Đang tải video...',
        subtitle: 'Hướng dẫn từng bước vẫn có bên dưới.',
      );
    }
    final duration = _playback.duration.inMilliseconds.toDouble();
    final picture = Center(
      child: AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: VideoPlayer(controller),
      ),
    );
    final controls = Row(
      children: [
        IconButton(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          tooltip: _playback.isPlaying ? 'Tạm dừng' : 'Phát video',
          onPressed: _playback.loading ? null : _playback.togglePlayback,
          icon: Icon(
            _playback.isPlaying
                ? Icons.pause_rounded
                : Icons.play_arrow_rounded,
            color: fullscreen ? Colors.white : NomadKit.sandDark,
          ),
        ),
        Text(
          formatVideoTime(_playback.position),
          style: TextStyle(
            fontSize: 13,
            color: fullscreen ? Colors.white : NomadKit.ink,
          ),
        ),
        Expanded(
          child: Slider(
            activeColor: NomadKit.sandDark,
            inactiveColor: NomadKit.border,
            value: _playback.position.inMilliseconds.toDouble().clamp(
              0,
              duration,
            ),
            max: duration > 0 ? duration : 1,
            onChanged: _playback.loading
                ? null
                : (value) =>
                      _playback.seek(Duration(milliseconds: value.round())),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Text(
            formatVideoTime(_playback.duration),
            style: TextStyle(
              fontSize: 13,
              color: fullscreen ? Colors.white70 : NomadKit.ink,
            ),
          ),
        ),
        if (!fullscreen)
          IconButton(
            tooltip: 'Phóng to toàn màn hình',
            onPressed: _openFullscreen,
            icon: const Icon(
              Icons.fullscreen_rounded,
              color: NomadKit.sandDark,
            ),
          ),
      ],
    );
    if (fullscreen) {
      return Container(
        color: const Color(0xFF1C1917),
        child: Column(
          children: [
            Expanded(child: picture),
            controls,
          ],
        ),
      );
    }
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 220,
            width: double.infinity,
            color: const Color(0xFF1C1917),
            child: picture,
          ),
        ),
        controls,
      ],
    );
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

    final stepTimestamp = _playback.hasVideo
        ? ' · ${formatVideoTime(Duration(seconds: currentStep.videoStartSeconds))}'
        : '';
    final stepButtons = [
      for (final st in recipe.steps)
        _StepPill(
          label: 'Bước ${st.stepNumber}',
          active: st.stepNumber == _activeStepNumber,
          onTap: () => _syncPlaybackToStep(st.stepNumber),
        ),
    ];

    return Scaffold(
      backgroundColor: NomadKit.canvas,
      body: SafeArea(
        child: Column(
          children: [
            RhBrandHeader(
              trailing: IconButton(
                tooltip: 'Quay lại',
                icon: const Icon(Icons.arrow_back_rounded, color: NomadKit.ink),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'HỌC QUA VIDEO',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: NomadKit.sandDark,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(recipe.name, style: NomadKit.title),
                    const SizedBox(height: 14),
                    _videoPlayer(),
                    const SizedBox(height: 12),
                    stepButtons.length <= 4
                        ? Row(
                            children: [
                              for (var i = 0; i < stepButtons.length; i++) ...[
                                if (i > 0) const SizedBox(width: 8),
                                Expanded(child: stepButtons[i]),
                              ],
                            ],
                          )
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                for (final b in stepButtons)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: SizedBox(width: 84, child: b),
                                  ),
                              ],
                            ),
                          ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: NomadKit.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: NomadKit.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'BƯỚC ${currentStep.stepNumber} / $totalSteps$stepTimestamp',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: NomadKit.sandDark,
                              letterSpacing: 0.4,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(currentStep.title, style: NomadKit.section),
                          const SizedBox(height: 8),
                          Text(currentStep.instruction, style: NomadKit.body),
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

                    // 3. Linked SOP (if available)
                    if (currentStep.linkedSopId != null) ...[
                      InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          final sop = context
                              .read<TrainingViewModel>()
                              .sopByCode(currentStep.linkedSopId ?? '');
                          if (sop == null) {
                            ToastMessenger.of(context).showSnackBar(
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

            // Thanh điều hướng bước.
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: const BoxDecoration(
                color: NomadKit.canvas,
                border: Border(top: BorderSide(color: NomadKit.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(48, 48),
                        side: const BorderSide(color: NomadKit.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        foregroundColor: NomadKit.ink,
                      ),
                      onPressed: hasPrev
                          ? () => _syncPlaybackToStep(_activeStepNumber - 1)
                          : null,
                      child: const Text(
                        'Bước trước',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(48, 48),
                        backgroundColor: NomadKit.sandDark,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: hasNext
                          ? () => _syncPlaybackToStep(_activeStepNumber + 1)
                          : null,
                      child: const Text(
                        'Bước tiếp theo',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
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

class _StepPill extends StatelessWidget {
  const _StepPill({
    required this.label,
    required this.active,
    required this.onTap,
  });
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: active ? NomadKit.sandDark : NomadKit.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: BorderSide(color: active ? NomadKit.sandDark : NomadKit.border),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: SizedBox(
        height: 48,
        child: Center(
          child: Text(
            label,
            maxLines: 1,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: active ? Colors.white : NomadKit.ink,
            ),
          ),
        ),
      ),
    ),
  );
}
