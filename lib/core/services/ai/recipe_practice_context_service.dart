import 'dart:async';

import '../../models/ai_practice_models.dart';
import '../../models/app_models.dart';
import '../i_recipe_source.dart';
import '../interfaces/i_training_repository.dart';
import '../interfaces/i_ai_practice_service.dart';
import 'recipe_recall_builder.dart';

class RecipePracticeContextService implements IAiPracticeContextService {
  RecipePracticeContextService(this.recipes, this.training);
  final IRecipeSource recipes;
  final ITrainingRepository training;
  @override
  Future<RecallContext> load(String recipeId) async {
    final detail = await recipes.getRecipe(recipeId);
    final sops = await training.watchSops().first.timeout(
      const Duration(seconds: 12),
    );
    return RecipeRecallBuilder.build(detail, sops);
  }

  @override
  Stream<String> watchRevision(RecallContext context) {
    final changes = StreamController<String>();
    StreamSubscription<Object?>? recipeSub, sopSub;
    Timer? poll;
    var checking = false;
    Future<void> check() async {
      if (checking || changes.isClosed) return;
      checking = true;
      try {
        final next = await load(context.recipeId);
        if (!changes.isClosed && next.revision != context.revision) {
          changes.add(next.revision);
        }
      } catch (_) {
        // Failed revalidation: fail closed for AI, without touching the Timer.
        if (!changes.isClosed) changes.add('unavailable');
      } finally {
        checking = false;
      }
    }

    changes.onListen = () {
      final src = recipes;
      if (src is ILiveRecipeSource) {
        recipeSub = (src as ILiveRecipeSource)
            .watchPublishedDetails(limit: 500)
            .listen((items) {
              if (!items.any((d) => d.id == context.recipeId)) {
                changes.add('withdrawn');
              } else {
                unawaited(check());
              }
            }, onError: (Object e) => changes.add('unavailable'));
      } else {
        poll = Timer.periodic(
          const Duration(seconds: 30),
          (_) => unawaited(check()),
        );
      }
      sopSub = training.watchSops().listen(
        (List<SopItem> _) => unawaited(check()),
        onError: (Object e) => changes.add('unavailable'),
      );
    };
    changes.onCancel = () async {
      poll?.cancel();
      await recipeSub?.cancel();
      await sopSub?.cancel();
    };
    return changes.stream;
  }
}
