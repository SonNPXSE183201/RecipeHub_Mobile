import '../models/recipe_models.dart';
import 'recipe_service.dart';

/// Nguồn công thức (API thật). Interface để test thay bằng fake, không mock trong app.
abstract class IRecipeSource {
  Future<PagedResponse<RecipeSummaryResponse>> searchApproved({String? query, int pageSize = 50});
  Future<RecipeDetailResponse> getRecipe(String id);
}

class GatewayRecipeSource implements IRecipeSource {
  GatewayRecipeSource([RecipeService? service]) : _service = service ?? RecipeService.instance;
  final RecipeService _service;

  @override
  Future<PagedResponse<RecipeSummaryResponse>> searchApproved({String? query, int pageSize = 50}) =>
      _service.searchRecipes(query: query, versionStatus: 'published', pageSize: pageSize);

  @override
  Future<RecipeDetailResponse> getRecipe(String id) => _service.getRecipe(id);
}
