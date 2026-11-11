import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/ai_practice_models.dart';
import '../models/app_models.dart';
import '../services/interfaces/i_ai_practice_service.dart';
import '../services/interfaces/i_analytics_service.dart';
import '../services/ai/recipe_recall_builder.dart';

abstract class PracticeClock {
  Duration get elapsed;
  void start();
  void stop();
  void reset();
}

class StopwatchPracticeClock implements PracticeClock {
  final _watch = Stopwatch();
  @override
  Duration get elapsed => _watch.elapsed;
  @override
  void start() => _watch.start();
  @override
  void stop() => _watch.stop();
  @override
  void reset() => _watch.reset();
}

class AiPracticeViewModel extends ChangeNotifier {
  AiPracticeViewModel({
    required RecipeItem recipe,
    required this.source,
    required this.ai,
    this.analytics,
    PracticeClock? clock,
    bool automaticTicks = true,
    this.firstDelay = const Duration(seconds: 10),
    this.nextDelay = const Duration(seconds: 20),
    // Keep the public argument `recipe` while enforcing recipe changes via changeRecipe.
    // ignore: prefer_initializing_formals
  }) : _recipe = recipe,
       clock = clock ?? StopwatchPracticeClock() {
    if (automaticTicks) {
      _ticker = Timer.periodic(
        const Duration(milliseconds: 250),
        (_) => tick(),
      );
    }
  }
  final IAiPracticeContextService source;
  final IAiPracticeService ai;
  final IAnalyticsService? analytics;
  final PracticeClock clock;
  final Duration firstDelay, nextDelay;
  RecipeItem _recipe;
  RecipeItem get recipe => _recipe;
  Timer? _ticker;
  StreamSubscription<String>? _revision;
  bool _disposed = false;
  bool _startLogged = false;
  bool running = false,
      aiEnabled = false,
      templateMode = false,
      collapsed = false,
      hint = false;
  int _generation = 0, _nextIndex = 0, _tries = 0;
  Duration _due = const Duration(seconds: 10);
  RecallContext? _context;
  List<RecallQuestion> _batch = [];
  RecallQuestion? question;
  int? selectedIndex;
  String? error;
  RecallState aiState = RecallState.off;
  int get seconds => clock.elapsed.inSeconds;
  bool get hasSession => running || seconds > 0;
  bool? get isCorrect =>
      selectedIndex == null ? null : selectedIndex == question?.correctIndex;
  String get sourceNote => _context?.note ?? '';
  bool get canRetry => _tries < 3;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void toggleTimer() {
    running = !running;
    running ? clock.start() : clock.stop();
    if (running && !_startLogged) {
      _startLogged = true;
      unawaited(
        analytics?.logStartBrewTimer(
          recipeCode: recipe.code,
          size: recipe.sizes.length == 1
              ? recipe.sizes.single.sizeCode
              : 'standard',
          targetSeconds: 0,
        ),
      );
    }
    tick();
  }

  void recordSaved() {
    unawaited(
      analytics?.logCompleteBrewTimer(
        recipeCode: recipe.code,
        size: recipe.sizes.length == 1
            ? recipe.sizes.single.sizeCode
            : 'standard',
        actualSeconds: seconds,
        deviationSeconds: 0,
        withinTolerance: true,
      ),
    );
  }

  void pause() {
    if (running) {
      running = false;
      clock.stop();
      _notify();
    }
  }

  void tick() {
    if (_disposed) return;
    if (running &&
        aiEnabled &&
        !collapsed &&
        question == null &&
        aiState == RecallState.waiting &&
        clock.elapsed >= _due) {
      if (_nextIndex < _batch.length) {
        question = _batch[_nextIndex++];
        selectedIndex = null;
        hint = false;
        aiState = RecallState.question;
      } else {
        aiState = RecallState.exhausted;
      }
    }
    _notify();
  }

  Future<void> enableAi({bool templates = false}) async {
    if (_disposed ||
        aiState == RecallState.loading ||
        (!templates && !canRetry)) {
      return;
    }
    if (_batch.isNotEmpty && templateMode == templates) {
      aiEnabled = true;
      collapsed = false;
      aiState = question == null
          ? RecallState.waiting
          : selectedIndex == null
          ? RecallState.question
          : RecallState.feedback;
      _due = clock.elapsed + firstDelay;
      _notify();
      return;
    }
    final gen = ++_generation;
    aiEnabled = true;
    collapsed = false;
    templateMode = templates;
    error = null;
    question = null;
    selectedIndex = null;
    _batch = [];
    _nextIndex = 0;
    aiState = RecallState.loading;
    _notify();
    if (!templates) _tries++;
    try {
      final context = await source
          .load(recipe.id)
          .timeout(const Duration(seconds: 15));
      if (_disposed || gen != _generation) return;
      _context = context;
      if (context.questions.isEmpty) {
        aiState = RecallState.empty;
        _notify();
        return;
      }
      final refs = templates
          ? context.questions.take(5).map((q) => q.id).toList()
          : await ai
                .selectQuestions(context)
                .timeout(const Duration(seconds: 15));
      if (_disposed || gen != _generation) return;
      _batch = RecipeRecallBuilder.validate(context, refs);
      _nextIndex = 0;
      _due = clock.elapsed < firstDelay ? firstDelay : clock.elapsed;
      aiState = RecallState.waiting;
      await _revision?.cancel();
      if (_disposed || gen != _generation) return;
      _revision = source
          .watchRevision(context)
          .listen(
            (_) => _invalidate(context),
            onError: (Object _) => _invalidate(context),
          );
      tick();
    } catch (e) {
      if (_disposed || gen != _generation) return;
      error = e is AiPracticeFailure ? e.message : 'Chưa chuẩn bị được câu hỏi có nguồn. Hãy thử lại hoặc ôn bằng câu hỏi mẫu.';
      aiState = RecallState.error;
      _notify();
    }
  }

  void _invalidate(RecallContext context) {
    if (_disposed || _context != context) return;
    _generation++;
    unawaited(_revision?.cancel());
    _revision = null;
    _batch = [];
    _context = null;
    question = null;
    selectedIndex = null;
    error = 'Công thức/SOP đã thay đổi hoặc chưa thể xác minh. Tải lại nguồn trước khi ôn tiếp.';
    aiState = RecallState.error;
    _notify();
  }

  void answer(int choice) {
    final q = question;
    if (q == null ||
        selectedIndex != null ||
        choice < 0 ||
        choice >= q.choices.length) {
      return;
    }
    selectedIndex = choice;
    aiState = RecallState.feedback;
    _notify();
  }

  void showHint() {
    hint = true;
    _notify();
  }

  void continuePractice() {
    if (question == null) return;
    question = null;
    selectedIndex = null;
    hint = false;
    _due = clock.elapsed + nextDelay;
    aiState = _nextIndex < _batch.length
        ? RecallState.waiting
        : RecallState.exhausted;
    _notify();
  }

  void setCollapsed(bool value) {
    collapsed = value;
    _notify();
  }

  void disableAi() {
    _generation++;
    aiEnabled = false;
    if (aiState == RecallState.loading) {
      _batch = [];
      question = null;
    }
    aiState = RecallState.off;
    _notify();
  }

  void reset() {
    pause();
    _startLogged = false;
    clock.reset();
    _nextIndex = 0;
    question = null;
    selectedIndex = null;
    hint = false;
    _due = firstDelay;
    if (aiState != RecallState.loading) {
      aiState = !aiEnabled
          ? RecallState.off
          : _batch.isNotEmpty
          ? RecallState.waiting
          : RecallState.empty;
    }
    _notify();
  }

  void changeRecipe(RecipeItem value) {
    _generation++;
    unawaited(_revision?.cancel());
    _revision = null;
    pause();
    clock.reset();
    _recipe = value;
    _startLogged = false;
    _context = null;
    _batch = [];
    question = null;
    selectedIndex = null;
    _tries = 0;
    _nextIndex = 0;
    aiEnabled = false;
    templateMode = false;
    hint = false;
    error = null;
    aiState = RecallState.off;
    _due = firstDelay;
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _ticker?.cancel();
    unawaited(_revision?.cancel());
    clock.stop();
    super.dispose();
  }
}
