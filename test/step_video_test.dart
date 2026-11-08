import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipehub_mobile/core/models/app_models.dart';
import 'package:recipehub_mobile/core/models/recipe_models.dart';
import 'package:recipehub_mobile/core/services/firebase/firestore_recipe_source.dart';
import 'package:recipehub_mobile/core/services/recipe_mapper.dart';
import 'package:recipehub_mobile/core/viewmodels/step_video_viewmodel.dart';
import 'package:recipehub_mobile/features/lookup/step_video_guide_page.dart';
import 'package:video_player/video_player.dart';

RecipeItem _recipe({String url = ''}) => RecipeMapper.fromDetail(
  RecipeDetailResponse.fromJson(
    FirestoreRecipeSource.detailJson('test', {
      'name': 'Trà mẫu',
      'code': 'TT-01',
      'videoUrl': url,
      'steps': [
        {
          'title': 'Chuẩn bị',
          'description': 'Đong nguyên liệu',
          'durationSeconds': 10,
        },
        {
          'title': 'Hoàn thiện',
          'description': 'Khuấy đều',
          'durationSeconds': 20,
        },
      ],
    }),
  ),
);

class _VideoController extends VideoPlayerController {
  _VideoController({this.fail = false})
    : super.networkUrl(Uri.parse('https://example.com/video.mp4'));
  final bool fail;
  Duration? lastSeek;
  bool released = false;

  @override
  Future<void> initialize() async {
    if (fail) throw StateError('network unavailable');
    value = const VideoPlayerValue(
      duration: Duration(seconds: 30),
      isInitialized: true,
      size: Size(640, 360),
    );
  }

  @override
  Future<void> seekTo(Duration position) async {
    lastSeek = position;
    value = value.copyWith(position: position);
  }

  @override
  Future<void> play() async => value = value.copyWith(isPlaying: true);

  @override
  Future<void> pause() async => value = value.copyWith(isPlaying: false);

  @override
  Future<void> dispose() async {
    released = true;
    await super.dispose();
  }
}

void main() {
  test(
    'videoUrl survives Firestore DTO and mapper; absent URL stays empty',
    () {
      expect(
        _recipe(url: 'https://example.com/v.mp4').videoUrl,
        'https://example.com/v.mp4',
      );
      expect(_recipe().videoUrl, '');
    },
  );

  test(
    'real playback seeks steps, follows position, pauses and disposes',
    () async {
      final controller = _VideoController();
      final vm = StepVideoViewModel(
        recipe: _recipe(url: 'https://example.com/v.mp4'),
        controllerFactory: (_) => controller,
      );
      await vm.initialize();
      expect(vm.hasVideo, isTrue);
      expect(vm.isPlaying, isTrue);
      await vm.selectStep(2);
      expect(controller.lastSeek, const Duration(seconds: 10));
      expect(vm.activeStepNumber, 2);
      controller.value = controller.value.copyWith(
        position: const Duration(seconds: 2),
      );
      expect(vm.activeStepNumber, 1);
      await vm.togglePlayback();
      expect(controller.value.isPlaying, isFalse);
      vm.dispose();
      expect(controller.released, isTrue);
    },
  );

  testWidgets(
    'empty URL keeps instructions usable without simulated playback',
    (tester) async {
      final vm = StepVideoViewModel(recipe: _recipe());
      await vm.initialize();
      await tester.pump(const Duration(seconds: 11));
      expect(vm.hasVideo, isFalse);
      expect(vm.activeStepNumber, 1);
      expect(vm.isPlaying, isFalse);
      await vm.selectStep(2);
      expect(vm.activeStepNumber, 2);
      expect(vm.position, Duration.zero);
      expect(vm.duration, Duration.zero);
      vm.dispose();
    },
  );

  testWidgets('network failure keeps instructions usable without playback', (
    tester,
  ) async {
    final controller = _VideoController(fail: true);
    final vm = StepVideoViewModel(
      recipe: _recipe(url: 'https://example.com/v.mp4'),
      controllerFactory: (_) => controller,
    );
    await vm.initialize();
    expect(vm.videoFailed, isTrue);
    expect(vm.hasVideo, isFalse);
    expect(vm.isPlaying, isFalse);
    expect(controller.released, isTrue);
    await vm.selectStep(2);
    expect(vm.activeStepNumber, 2);
    expect(vm.position, Duration.zero);
    await tester.pump(const Duration(seconds: 20));
    expect(vm.activeStepNumber, 2);
    expect(vm.position, Duration.zero);
    vm.dispose();
  });

  test(
    'retry releases failed controller and starts a fresh real video',
    () async {
      final failed = _VideoController(fail: true);
      final ready = _VideoController();
      var attempts = 0;
      final vm = StepVideoViewModel(
        recipe: _recipe(url: 'https://example.com/v.mp4'),
        controllerFactory: (_) => attempts++ == 0 ? failed : ready,
      );
      await vm.initialize();
      expect(vm.videoFailed, isTrue);
      expect(failed.released, isTrue);
      await vm.selectStep(2);
      await vm.initialize();
      expect(attempts, 2);
      expect(vm.hasVideo, isTrue);
      expect(vm.videoFailed, isFalse);
      expect(ready.lastSeek, const Duration(seconds: 10));
      vm.dispose();
    },
  );

  testWidgets('video page only keeps step navigation, no feedback action', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(home: StepVideoGuidePage(recipe: _recipe())),
    );
    expect(find.textContaining('Gửi phản hồi'), findsNothing);
    expect(find.text('Chưa có video cho món này'), findsOneWidget);
    expect(find.textContaining('Mô phỏng'), findsNothing);
    expect(find.byType(Slider), findsNothing);
    expect(find.text('Bước 1'), findsOneWidget);
    expect(find.text('Bước 2'), findsOneWidget);
    expect(find.textContaining('(00:'), findsNothing);
    expect(find.byTooltip('Phóng to toàn màn hình'), findsNothing);
    expect(find.byTooltip('Phản hồi bước này'), findsNothing);
    expect(find.text('Bước trước'), findsOneWidget);
    expect(find.text('Bước tiếp theo'), findsOneWidget);
    await tester.tap(find.text('Bước tiếp theo'));
    await tester.pump();
    expect(find.text('BƯỚC 2'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
