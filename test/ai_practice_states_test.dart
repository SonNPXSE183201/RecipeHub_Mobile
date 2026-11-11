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

class _Source implements IAiPracticeContextService {
  _Source(this.empty);
  final bool empty;
  @override
  Future<RecallContext> load(String id) async {
    final c = RecipeRecallBuilder.build(
      FakeRecipeSource.detail('r1', 'R1', 'Món thử'),
      [],
    );
    return RecallContext(
      recipeId: c.recipeId,
      recipeName: c.recipeName,
      revision: c.revision,
      questions: empty ? [] : c.questions,
    );
  }

  @override
  Stream<String> watchRevision(RecallContext c) => const Stream.empty();
}

class _Ai implements IAiPracticeService {
  _Ai(this.scenario);
  final String scenario;
  final pending = Completer<List<String>>();
  int calls = 0;
  @override
  Future<List<String>> selectQuestions(RecallContext c) async {
    calls++;
    if (scenario == 'loading') return pending.future;
    if (scenario == 'error') {
      throw const AiPracticeFailure('Chưa kết nối được AI.');
    }
    if (scenario == 'quota') {
      throw const AiPracticeFailure('AI đã hết hạn mức hoặc đang quá tải.');
    }
    return c.questions.take(5).map((q) => q.id).toList();
  }
}

void main() {
  for (final width in [360.0, 412.0]) {
    for (final scenario in ['loading', 'empty', 'error', 'quota', 'waiting']) {
      testWidgets(
        '$width / 1.3 text: $scenario is readable and recovery preserves Timer',
        (tester) async {
          tester.view.physicalSize = Size(width, 915);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final ai = _Ai(scenario);
          final vm = AiPracticeViewModel(
            recipe: RecipeMapper.fromDetail(
              FakeRecipeSource.detail('r1', 'R1', 'Món thử'),
            ),
            source: _Source(scenario == 'empty'),
            ai: ai,
            automaticTicks: false,
          );
          addTearDown(vm.dispose);
          final ready = vm.enableAi();
          await tester.pumpWidget(
            ChangeNotifierProvider.value(
              value: vm,
              child: MaterialApp(
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: const TextScaler.linear(1.3)),
                  child: child!,
                ),
                home: const Scaffold(
                  body: SingleChildScrollView(child: AiRecallCard()),
                ),
              ),
            ),
          );
          await tester.pump();
          if (scenario == 'loading') {
            expect(find.byType(LinearProgressIndicator), findsOneWidget);
            vm.disableAi();
            ai.pending.complete(['invalid']);
            await ready;
            await tester.pump();
            expect(vm.aiState, RecallState.off);
          } else {
            await ready;
            await tester.pump();
            expect(
              vm.aiState,
              scenario == 'empty'
                  ? RecallState.empty
                  : scenario == 'waiting'
                  ? RecallState.waiting
                  : RecallState.error,
            );
            if (scenario == 'error' || scenario == 'quota') {
              vm.toggleTimer();
              final fallback = find.text('Ôn bằng câu hỏi mẫu');
              await tester.ensureVisible(fallback);
              await tester.tap(fallback);
              await tester.pump();
              await tester.pump();
              expect(vm.templateMode, isTrue);
              expect(vm.running, isTrue);
              expect(ai.calls, 1);
            }
          }
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        },
      );
    }
  }
}
