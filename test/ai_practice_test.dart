import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:recipehub_mobile/core/models/ai_practice_models.dart';
import 'package:recipehub_mobile/core/services/ai/recipe_recall_builder.dart';
import 'package:recipehub_mobile/core/services/interfaces/i_ai_practice_service.dart';
import 'package:recipehub_mobile/core/services/recipe_mapper.dart';
import 'package:recipehub_mobile/core/viewmodels/ai_practice_viewmodel.dart';
import 'package:recipehub_mobile/features/practice/widgets/ai_recall_card.dart';

import 'support/fake_recipe_source.dart';

class _Clock implements PracticeClock {
  Duration time = Duration.zero;
  bool running = false;
  @override
  Duration get elapsed => time;
  @override
  void start() => running = true;
  @override
  void stop() => running = false;
  @override
  void reset() => time = Duration.zero;
  void advance(int seconds) {
    if (running) time += Duration(seconds: seconds);
  }
}

class _Context implements IAiPracticeContextService {
  _Context() {
    final c = RecipeRecallBuilder.build(
      FakeRecipeSource.detail('r1', 'R1', 'Trà'),
      const [],
    );
    final q = c.questions.first;
    context = RecallContext(
      recipeId: c.recipeId,
      recipeName: c.recipeName,
      revision: c.revision,
      questions: [
        q,
        RecallQuestion(
          id: 'second',
          prompt: 'Câu tiếp theo',
          choices: q.choices,
          correctIndex: q.correctIndex,
          explanation: q.explanation,
          source: q.source,
        ),
      ],
    );
  }
  late final RecallContext context;
  final updates = StreamController<String>.broadcast();
  @override
  Future<RecallContext> load(String id) async => context;
  @override
  Stream<String> watchRevision(RecallContext context) => updates.stream;
}

class _Ai implements IAiPracticeService {
  int calls = 0;
  Completer<List<String>>? pending;
  @override
  Future<List<String>> selectQuestions(RecallContext context) async {
    calls++;
    return pending != null
        ? pending!.future
        : context.questions.map((q) => q.id).toList();
  }
}

void main() {
  test('questions carry source values and unique choices, not a score', () {
    final c = RecipeRecallBuilder.build(
      FakeRecipeSource.detail('r1', 'R1', 'Trà'),
      const [],
    );
    final q = c.questions.first;
    expect(q.choices[q.correctIndex], '25 g');
    expect(q.choices.toSet().length, q.choices.length);
    expect(q.source, contains('Trà'));
    expect(q.explanation, contains('25 g'));
  });
  late _Clock clock;
  late _Context source;
  late _Ai ai;
  late AiPracticeViewModel vm;
  setUp(() {
    clock = _Clock();
    source = _Context();
    ai = _Ai();
    vm = AiPracticeViewModel(
      recipe: RecipeMapper.fromDetail(
        FakeRecipeSource.detail('r1', 'R1', 'Trà'),
      ),
      source: source,
      ai: ai,
      clock: clock,
      automaticTicks: false,
    );
  });
  tearDown(() async {
    vm.dispose();
    await source.updates.close();
  });
  testWidgets(
    'question card keeps pause accessible, locks answer and shows source',
    (tester) async {
      tester.view.physicalSize = const Size(360, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await vm.enableAi();
      vm.toggleTimer();
      clock.advance(10);
      vm.tick();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: vm,
          child: const MaterialApp(
            home: Scaffold(body: SingleChildScrollView(child: AiRecallCard())),
          ),
        ),
      );
      expect(find.text('00:10'), findsOneWidget);
      await tester.tap(find.text('Tạm dừng'));
      await tester.pump();
      expect(vm.running, isFalse);
      await tester.tap(find.text('Tiếp tục bấm giờ'));
      await tester.pump();
      final q = vm.question!;
      final choice = find.byKey(ValueKey('recall_choice_${q.correctIndex}'));
      await tester.ensureVisible(choice);
      await tester.tap(choice);
      await tester.pump();
      expect(find.text('Đúng rồi!'), findsOneWidget);
      expect(find.text('Nguồn: ${q.source}'), findsOneWidget);
      expect(tester.widget<OutlinedButton>(choice).onPressed, isNull);
      expect(vm.running, isTrue);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  test('10s first, 20s after feedback, only one question while timer keeps running', () async {
    await vm.enableAi();
    vm.toggleTimer();
    clock.advance(9);
    vm.tick();
    expect(vm.question, isNull);
    clock.advance(1);
    vm.tick();
    expect(vm.question, isNotNull);
    final q = vm.question!;
    clock.advance(70);
    vm.tick();
    expect(vm.question, same(q));
    vm.answer(q.correctIndex);
    expect(vm.isCorrect, isTrue);
    expect(clock.running, isTrue);
    vm.continuePractice();
    clock.advance(19);
    vm.tick();
    expect(vm.question, isNull);
    clock.advance(1);
    vm.tick();
    expect(vm.question, isNotNull);
    expect(ai.calls, 1);
  });
  test(
    'pause freezes elapsed, reset clears feedback and reuses validated batch',
    () async {
      await vm.enableAi();
      vm.toggleTimer();
      clock.advance(10);
      vm.tick();
      vm.answer(1);
      vm.answer(0);
      expect(vm.selectedIndex, 1);
      vm.toggleTimer();
      clock.advance(100);
      vm.tick();
      expect(vm.seconds, 10);
      vm.reset();
      expect(vm.seconds, 0);
      expect(vm.question, isNull);
      expect(vm.selectedIndex, isNull);
      vm.toggleTimer();
      clock.advance(10);
      vm.tick();
      expect(vm.question, isNotNull);
      expect(ai.calls, 1);
    },
  );
  test('changing recipe discards response arriving from old recipe', () async {
    ai.pending = Completer();
    final pending = vm.enableAi();
    await Future<void>.delayed(Duration.zero);
    vm.changeRecipe(
      RecipeMapper.fromDetail(FakeRecipeSource.detail('r2', 'R2', 'Cà phê')),
    );
    ai.pending!.complete(source.context.questions.map((q) => q.id).toList());
    await pending;
    expect(vm.recipe.id, 'r2');
    expect(vm.question, isNull);
    expect(vm.seconds, 0);
    expect(vm.aiEnabled, isFalse);
  });
  test(
    'invalid references fail closed; explicit template mode remains available',
    () async {
      ai.pending = Completer()..complete(['foreign-ref']);
      await vm.enableAi();
      expect(vm.aiState, RecallState.error);
      await vm.enableAi(templates: true);
      vm.toggleTimer();
      clock.advance(10);
      vm.tick();
      expect(vm.question, isNotNull);
      expect(vm.templateMode, isTrue);
    },
  );
  test(
    'source revision invalidates questions without stopping timer',
    () async {
      await vm.enableAi();
      vm.toggleTimer();
      source.updates.add('changed');
      await Future<void>.delayed(Duration.zero);
      clock.advance(10);
      vm.tick();
      expect(vm.question, isNull);
      expect(vm.aiState, RecallState.error);
      expect(clock.running, isTrue);
    },
  );

  test('collapsed and paused states never queue questions', () async {
    await vm.enableAi();
    vm.toggleTimer();
    vm.setCollapsed(true);
    clock.advance(100);
    vm.tick();
    expect(vm.question, isNull);
    vm.setCollapsed(false);
    vm.tick();
    expect(vm.question, isNotNull);
    vm.pause();
    vm.continuePractice();
    clock.advance(50);
    vm.tick();
    expect(vm.question, isNull);
    vm.toggleTimer();
    clock.advance(20);
    vm.tick();
    expect(vm.question, isNotNull);
    vm.continuePractice();
    clock.advance(100);
    vm.tick();
    expect(vm.aiState, RecallState.exhausted);
  });
  test('disable re-enable reuses batch and still observes source', () async {
    await vm.enableAi();
    vm.disableAi();
    await vm.enableAi();
    expect(ai.calls, 1);
    source.updates.add('withdrawn');
    await Future<void>.delayed(Duration.zero);
    expect(vm.aiState, RecallState.error);
    vm.reset();
    expect(vm.aiState, RecallState.empty);
  });
  test('invalid or repeated answer cannot alter locked feedback', () async {
    vm.answer(0);
    await vm.enableAi();
    vm.toggleTimer();
    clock.advance(10);
    vm.tick();
    vm.answer(-1);
    vm.answer(99);
    expect(vm.selectedIndex, isNull);
    vm.showHint();
    expect(vm.hint, isTrue);
    vm.answer(vm.question!.correctIndex);
    vm.answer((vm.question!.correctIndex + 1) % 4);
    expect(vm.isCorrect, isTrue);
    vm.continuePractice();
    expect(vm.hint, isFalse);
  });
  test('retry is capped and disposed pending response is ignored', () async {
    ai.pending = Completer()..complete(['invalid']);
    for (var i = 0; i < 4; i++) {
      await vm.enableAi();
    }
    expect(ai.calls, 3);
    expect(vm.canRetry, isFalse);
    await vm.enableAi(templates: true);
    expect(vm.templateMode, isTrue);
    final lateAi = _Ai()..pending = Completer<List<String>>();
    final lateVm = AiPracticeViewModel(
      recipe: vm.recipe,
      source: source,
      ai: lateAi,
      automaticTicks: false,
    );
    final future = lateVm.enableAi();
    await Future<void>.delayed(Duration.zero);
    lateVm.dispose();
    lateAi.pending!.complete(['invalid']);
    await future;
  });
}
