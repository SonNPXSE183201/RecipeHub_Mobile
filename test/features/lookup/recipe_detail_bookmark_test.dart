import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:recipehub_mobile/core/di/app_services.dart';
import 'package:recipehub_mobile/core/models/app_models.dart';
import 'package:recipehub_mobile/core/services/interfaces/i_recipe_bookmark_store.dart';
import 'package:recipehub_mobile/core/viewmodels/recipe_bookmark_viewmodel.dart';
import 'package:recipehub_mobile/features/lookup/recipe_detail_size_page.dart';

import '../../support/fake_recipe_source.dart';

class _MemoryStore implements IRecipeBookmarkStore {
  final data = <String, Set<String>>{};
  @override
  Future<Set<String>> load(String uid) async => {...?data[uid]};
  @override
  Future<void> save(String uid, Set<String> codes) async =>
      data[uid] = {...codes};
}

const _recipe = RecipeItem(
  id: 'x',
  code: 'TT-01',
  name: 'Trà mẫu',
  category: 'Trà',
  version: '1',
  status: 'Ban hành',
  publishedDate: '',
  publisher: '',
  description: '',
  standardTime: '',
  standardTemp: '',
  sizes: [
    RecipeSizeOption(
      sizeCode: 'M',
      label: 'Vừa',
      ingredients: [],
      servingNotes: '',
    ),
  ],
  steps: [
    RecipeStepItem(
      stepNumber: 1,
      title: 'Khuấy',
      instruction: 'Khuấy đều',
      videoStartSeconds: 0,
      videoEndSeconds: 5,
    ),
  ],
  videoUrl: '',
);

void main() {
  test('RecipeBookmarkViewModel toggles and persists per user', () async {
    final store = _MemoryStore();
    final vm = RecipeBookmarkViewModel(store: store, uid: 'u1');
    await vm.load();
    expect(await vm.toggle('TT-01'), isTrue);
    expect(store.data['u1'], {'TT-01'});
    expect(await vm.toggle('TT-01'), isFalse);
    expect(vm.isBookmarked('TT-01'), isFalse);
  });

  testWidgets('bookmark toggle and per-step feedback button', (tester) async {
    final original = FlutterError.onError;
    FlutterError.onError = (d) {
      if (d.exceptionAsString().contains('overflowed')) return;
      original?.call(d);
    };
    addTearDown(() => FlutterError.onError = original);
    await tester.binding.setSurfaceSize(const Size(430, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final store = _MemoryStore();
    await tester.pumpWidget(
      Provider<AppServices>.value(
        value: AppServices.mock(recipes: FakeRecipeSource()),
        child: MaterialApp(
          home: RecipeDetailSizePage(
            recipe: _recipe,
            bookmarkStore: store,
            bookmarkUid: 'u1',
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.byTooltip('Lưu công thức'));
    await tester.pump();
    expect(store.data['u1'], {'TT-01'});
    expect(find.byTooltip('Bỏ lưu công thức'), findsOneWidget);

    expect(find.byTooltip('Góp ý bước 1'), findsOneWidget);
    expect(find.text('Góp ý công thức'), findsOneWidget);
  });
}
