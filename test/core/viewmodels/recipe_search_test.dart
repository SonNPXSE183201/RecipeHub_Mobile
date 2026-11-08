import 'package:flutter_test/flutter_test.dart';
import 'package:recipehub_mobile/core/services/mock/mock_crash_reporter.dart';
import 'package:recipehub_mobile/core/services/recipe_mapper.dart';
import 'package:recipehub_mobile/core/viewmodels/recipe_viewmodel.dart';

import '../../support/fake_recipe_source.dart';

void main() {
  test('the shared predicate keeps all recipes for an empty query', () {
    final recipe = RecipeMapper.fromDetail(
      FakeRecipeSource.detail('r1', 'RC-OOL-02', 'Trà Sữa Oolong'),
    );
    expect(RecipeViewModel.matchesQuery(recipe, '   '), isTrue);
  });

  group('RecipeViewModel.searchAll', () {
    late RecipeViewModel vm;

    setUp(() {
      // Returns broad candidates, like a server matching only the first word.
      vm = RecipeViewModel(
        source: FakeRecipeSource(),
        crash: MockCrashReporter(),
      );
    });

    tearDown(() => vm.dispose());

    test('rejects a candidate matching only the first word', () async {
      expect(await vm.searchAll('tra muoi'), isEmpty);
    });

    test('matches the full name without accents and ignores case', () async {
      final results = await vm.searchAll('  TRA SUA  ');
      expect(results.map((r) => r.code), ['RC-OOL-02']);
    });

    test('matches an accented query against the normalized name', () async {
      final results = await vm.searchAll('CÀ PHÊ MUỐI');
      expect(results.map((r) => r.code), ['RC-CFE-01']);
    });

    test('matches a code substring without case sensitivity', () async {
      final results = await vm.searchAll('cfe-01');
      expect(results.map((r) => r.code), ['RC-CFE-01']);
    });

    test('does not return recipes already loaded locally', () async {
      await vm.load();
      expect(await vm.searchAll('tra sua'), isEmpty);
    });

    test('does not search for a blank query', () async {
      expect(await vm.searchAll('   '), isEmpty);
    });
  });
}
