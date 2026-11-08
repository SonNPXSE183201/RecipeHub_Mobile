import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

import '../models/app_models.dart';

/// Owns real playback; step instructions remain usable without a video.
class StepVideoViewModel extends ChangeNotifier {
  StepVideoViewModel({
    required this.recipe,
    int initialStepNumber = 1,
    VideoPlayerController Function(Uri)? controllerFactory,
  }) : _controllerFactory =
           controllerFactory ?? VideoPlayerController.networkUrl {
    activeStepNumber =
        recipe.steps.any((s) => s.stepNumber == initialStepNumber)
        ? initialStepNumber
        : recipe.steps.firstOrNull?.stepNumber ?? 1;
  }

  final RecipeItem recipe;
  final VideoPlayerController Function(Uri) _controllerFactory;
  VideoPlayerController? videoController;
  bool _disposed = false;
  bool _ready = false;
  bool loading = false;
  bool isPlaying = false;
  bool videoFailed = false;
  late int activeStepNumber;
  Duration position = Duration.zero;

  bool get hasVideo => _ready && !videoFailed && videoController != null;

  RecipeStepItem? get currentStep =>
      recipe.steps.where((s) => s.stepNumber == activeStepNumber).firstOrNull;

  Duration get duration =>
      hasVideo ? videoController!.value.duration : Duration.zero;

  Future<void> initialize() async {
    if (_disposed || loading || hasVideo) return;
    final url = recipe.videoUrl.trim();
    if (url.isEmpty) return;
    loading = true;
    videoFailed = false;
    notifyListeners();
    try {
      final controller = _controllerFactory(Uri.parse(url));
      videoController = controller;
      controller.addListener(_onVideoChanged);
      await controller.initialize();
      if (_disposed || videoController != controller) return;
      if (controller.value.hasError) throw StateError('Video unavailable');
      await controller.seekTo(
        Duration(seconds: currentStep?.videoStartSeconds ?? 0),
      );
      if (_disposed || videoController != controller) return;
      _ready = true;
      loading = false;
      await controller.play();
      if (!_disposed && videoController == controller) {
        _onVideoChanged();
      }
    } catch (_) {
      if (!_disposed) _markVideoFailed();
    }
  }

  void _onVideoChanged() {
    if (_disposed || videoController == null) return;
    final value = videoController!.value;
    if (value.hasError) {
      _markVideoFailed();
      return;
    }
    if (!_ready) return;
    position = value.position;
    isPlaying = value.isPlaying;
    _syncStep();
    notifyListeners();
  }

  void _markVideoFailed() {
    loading = false;
    videoFailed = true;
    _ready = false;
    isPlaying = false;
    position = Duration.zero;
    final controller = videoController;
    videoController = null;
    controller?.removeListener(_onVideoChanged);
    if (controller != null) unawaited(controller.dispose());
    notifyListeners();
  }

  void _syncStep() {
    final seconds = position.inMilliseconds / 1000;
    for (final step in recipe.steps) {
      if (seconds >= step.videoStartSeconds && seconds < step.videoEndSeconds) {
        activeStepNumber = step.stepNumber;
        return;
      }
    }
  }

  Future<void> seek(Duration target) async {
    if (_disposed || !hasVideo) return;
    position = Duration(
      milliseconds: target.inMilliseconds.clamp(0, duration.inMilliseconds),
    );
    _syncStep();
    notifyListeners();
    try {
      await videoController?.seekTo(position);
    } catch (_) {
      if (!_disposed) _markVideoFailed();
    }
  }

  Future<void> selectStep(int number) async {
    if (_disposed) return;
    final step = recipe.steps.where((s) => s.stepNumber == number).firstOrNull;
    if (step == null) return;
    activeStepNumber = step.stepNumber;
    if (hasVideo) {
      await seek(Duration(seconds: step.videoStartSeconds));
    } else {
      notifyListeners();
    }
  }

  Future<void> togglePlayback() async {
    if (_disposed || !hasVideo) return;
    try {
      if (isPlaying) {
        await videoController?.pause();
      } else {
        await videoController?.play();
      }
    } catch (_) {
      if (!_disposed) _markVideoFailed();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    videoController?.removeListener(_onVideoChanged);
    final controller = videoController;
    videoController = null;
    if (controller != null) unawaited(controller.dispose());
    super.dispose();
  }
}
