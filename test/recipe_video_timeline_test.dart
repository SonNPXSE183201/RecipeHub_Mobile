import 'package:flutter_test/flutter_test.dart';
import 'package:recipehub_mobile/core/models/recipe_models.dart';
import 'package:recipehub_mobile/core/services/firebase/firestore_recipe_source.dart';
import 'package:recipehub_mobile/core/services/recipe_mapper.dart';

void main() {
  test('video chapter times do not replace physical extraction duration', () {
    final detail = RecipeDetailResponse.fromJson(
      FirestoreRecipeSource.detailJson('recipe', {
        'name': 'Món thử',
        'status': 'published',
        'updatedAt': '2026-11-11T00:00:00Z',
        'steps': [
          {'title': 'Cân', 'videoStartSeconds': 2, 'videoEndSeconds': 6},
          {'title': 'Lắp', 'videoStartSeconds': 6, 'videoEndSeconds': 8},
          {
            'title': 'Chiết',
            'durationSeconds': 28,
            'videoStartSeconds': 8,
            'videoEndSeconds': 13,
          },
          {'title': 'Rót', 'videoStartSeconds': 13, 'videoEndSeconds': 19},
        ],
      }),
    );
    final recipe = RecipeMapper.fromDetail(detail);
    expect(recipe.steps.map((s) => s.videoStartSeconds), [2, 6, 8, 13]);
    expect(recipe.steps.map((s) => s.videoEndSeconds), [6, 8, 13, 19]);
    expect(recipe.steps[2].durationText, '28 giây');
  });

  test('invalid chapter times fall back to existing duration mapping', () {
    final detail = RecipeDetailResponse.fromJson(
      FirestoreRecipeSource.detailJson('recipe', {
        'name': 'Món thử',
        'steps': [
          {
            'title': 'Chiết',
            'durationSeconds': 28,
            'videoStartSeconds': 10,
            'videoEndSeconds': 5,
          },
          {'title': 'Rót'},
        ],
      }),
    );
    final recipe = RecipeMapper.fromDetail(detail);
    expect(recipe.steps[0].videoStartSeconds, 0);
    expect(recipe.steps[0].videoEndSeconds, 28);
    expect(recipe.steps[1].videoStartSeconds, 28);
    expect(recipe.steps[1].videoEndSeconds, 38);
  });
}
