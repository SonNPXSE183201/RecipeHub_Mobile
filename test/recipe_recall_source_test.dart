import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:recipehub_mobile/core/models/app_models.dart';
import 'package:recipehub_mobile/core/models/recipe_models.dart';
import 'package:recipehub_mobile/core/services/ai/recipe_recall_builder.dart';
import 'package:recipehub_mobile/core/services/ai/recipe_practice_context_service.dart';
import 'package:recipehub_mobile/core/services/firebase/firestore_recipe_source.dart';
import 'package:recipehub_mobile/core/services/mock/mock_training_repository.dart';

import 'support/fake_recipe_source.dart';

Map<String, dynamic> recipeData() => {
  'name': 'Món thử',
  'status': 'published',
  'versionNumber': 1,
  'updatedAt': '2026-11-11T00:00:00Z',
  'ingredients': [
    {'name': 'Trà', 'quantity': 25, 'unit': 'g'},
  ],
  'steps': [
    {'title': 'Chuẩn bị', 'description': 'Chuẩn bị nguyên liệu.'},
    {'title': 'Pha', 'description': 'Pha theo công thức.'},
    {'title': 'Hoàn thiện', 'description': 'Hoàn thiện ly.'},
  ],
  'sopCodes': ['SOP-LINKED'],
};
const linked = SopItem(
  id: 'linked',
  code: 'SOP-LINKED',
  title: 'Thao tác chuẩn',
  category: '',
  version: 'v1',
  publishedDate: '',
  summary: '',
  steps: [
    SopStepItem(
      stepNumber: 1,
      title: 'Trước pha',
      content: 'Chuẩn bị dụng cụ sạch.',
    ),
    SopStepItem(
      stepNumber: 2,
      title: 'Sau pha',
      content: 'Vệ sinh dụng cụ.',
      note: 'Theo SOP.',
    ),
  ],
  linkedRecipeCodes: [],
);
void main() {
  test('explicit SOP links and source references produce unique choices', () {
    final d = RecipeDetailResponse.fromJson(
      FirestoreRecipeSource.detailJson('r1', recipeData()),
    );
    final c = RecipeRecallBuilder.build(d, [linked]);
    expect(c.questions.where((q) => q.id.startsWith('sop:')).length, 2);
    expect(c.questions.where((q) => q.id.startsWith('step:')).length, 2);
    for (final q in c.questions) {
      expect(q.choices.toSet().length, q.choices.length);
      expect(q.correctIndex, inInclusiveRange(0, q.choices.length - 1));
    }
    expect(RecipeRecallBuilder.build(d, []).revision, isNot(c.revision));
    expect(() => RecipeRecallBuilder.validate(c, []), throwsFormatException);
    expect(
      () => RecipeRecallBuilder.validate(c, [
        c.questions.first.id,
        c.questions.first.id,
      ]),
      throwsFormatException,
    );
    expect(
      () => RecipeRecallBuilder.validate(c, ['foreign']),
      throwsFormatException,
    );
    expect(RecipeRecallBuilder.validate(c, [c.questions.first.id]).length, 1);
  });
  test('multiple portions never silently pick the first portion', () {
    final raw = recipeData()
      ..['sizes'] = [
        {
          'code': 'M',
          'label': 'M',
          'ingredients': [
            {'name': 'Trà', 'quantity': 25, 'unit': 'g'},
          ],
        },
        {
          'code': 'L',
          'label': 'L',
          'ingredients': [
            {'name': 'Trà', 'quantity': 40, 'unit': 'g'},
          ],
        },
      ];
    final c = RecipeRecallBuilder.build(
      RecipeDetailResponse.fromJson(
        FirestoreRecipeSource.detailJson('r1', raw),
      ),
      [],
    );
    expect(c.questions.where((q) => q.id.startsWith('ingredient:')), isEmpty);
    expect(c.note, isNotEmpty);
    raw['sizes'] = [
      {
        'code': 'M',
        'ingredients': [
          {'name': 'Trà', 'quantity': 25, 'unit': 'g'},
        ],
      },
    ];
    final single = RecipeRecallBuilder.build(
      RecipeDetailResponse.fromJson(
        FirestoreRecipeSource.detailJson('r1', raw),
      ),
      [],
    );
    expect(single.questions.first.explanation, contains('25 g'));
  });
  test('unpublished and missing quantities never become facts', () {
    final raw = recipeData()
      ..['ingredients'] = [
        {'name': 'Trà', 'unit': 'g'},
      ];
    final c = RecipeRecallBuilder.build(
      RecipeDetailResponse.fromJson(
        FirestoreRecipeSource.detailJson('r1', raw),
      ),
      [],
    );
    expect(c.questions.any((q) => q.id.startsWith('ingredient:')), isFalse);
    raw['status'] = 'draft';
    expect(
      RecipeRecallBuilder.build(
        RecipeDetailResponse.fromJson(
          FirestoreRecipeSource.detailJson('r1', raw),
        ),
        [linked],
      ).questions,
      isEmpty,
    );
  });
  test(
    'Firebase context invalidates after a published recipe is withdrawn',
    () async {
      final db = FakeFirebaseFirestore();
      await db.doc('recipes/r1').set(recipeData());
      final service = RecipePracticeContextService(
        FirestoreRecipeSource(firestore: db),
        MockTrainingRepository(sops: [linked]),
      );
      final c = await service.load('r1');
      expect(c.questions, isNotEmpty);
      final changed = Completer<String>();
      final sub = service.watchRevision(c).listen((v) {
        if (!changed.isCompleted) changed.complete(v);
      });
      await Future<void>.delayed(Duration.zero);
      await db.doc('recipes/r1').update({'status': 'hidden'});
      expect(
        await changed.future.timeout(const Duration(seconds: 2)),
        isNotEmpty,
      );
      await sub.cancel();
    },
  );
  test('nonlive source observer cancels cleanly', () async {
    final service = RecipePracticeContextService(
      FakeRecipeSource(),
      MockTrainingRepository(),
    );
    final c = await service.load('r1');
    final sub = service.watchRevision(c).listen((_) {});
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();
  });
}
