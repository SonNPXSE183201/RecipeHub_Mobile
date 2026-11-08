import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:recipehub_mobile/core/di/app_services.dart';
import 'package:recipehub_mobile/core/models/app_models.dart';
import 'package:recipehub_mobile/features/lookup/recipe_detail_size_page.dart';

import '../../support/fake_recipe_source.dart';

RecipeItem _recipe({required String videoUrl}) => RecipeItem(
  id: 'test',
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
  sizes: const [
    RecipeSizeOption(
      sizeCode: 'M',
      label: 'Size vừa',
      ingredients: [],
      servingNotes: '',
    ),
  ],
  steps: const [
    RecipeStepItem(
      stepNumber: 1,
      title: 'Hoàn thiện',
      instruction: 'Khuấy đều',
      videoStartSeconds: 75,
      videoEndSeconds: 90,
    ),
  ],
  videoUrl: videoUrl,
);

void main() {
  for (final hasVideo in [true, false]) {
    testWidgets(
      hasVideo
          ? 'video milestone at 75 seconds displays 01:15'
          : 'recipe without video hides video milestones',
      (tester) async {
        // Font test vẽ mỗi ký tự thành ô 1em nên tràn layout chỉ có trong test: bỏ qua riêng lỗi overflow.
        final original = FlutterError.onError;
        FlutterError.onError = (d) {
          if (d.exceptionAsString().contains('overflowed')) return;
          original?.call(d);
        };
        addTearDown(() => FlutterError.onError = original);
        await tester.binding.setSurfaceSize(const Size(430, 1000));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          Provider<AppServices>.value(
            value: AppServices.mock(recipes: FakeRecipeSource()),
            child: MaterialApp(
              home: RecipeDetailSizePage(
                recipe: _recipe(
                  videoUrl: hasVideo ? 'https://example.com/video.mp4' : '',
                ),
              ),
            ),
          ),
        );

        expect(
          find.text('Mốc video: 01:15'),
          hasVideo ? findsOneWidget : findsNothing,
        );
        expect(find.text('Mốc video: 00:75'), findsNothing);
        if (!hasVideo) {
          expect(find.textContaining('Mốc video:'), findsNothing);
        }
      },
    );
  }
}
