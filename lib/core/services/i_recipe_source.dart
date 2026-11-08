import '../models/recipe_models.dart';
import 'recipe_service.dart';

/// Nguồn công thức (API thật). Interface để test thay bằng fake, không mock trong app.
abstract class IRecipeSource {
  Future<PagedResponse<RecipeSummaryResponse>> searchApproved({String? query, int pageSize = 50});
  Future<RecipeDetailResponse> getRecipe(String id);
}

/// Nguồn đọc được trọn chi tiết món trong một lần (Firestore) – tránh đọc lại từng món (N+1).
abstract class IBulkRecipeSource {
  Future<List<RecipeDetailResponse>> loadPublishedDetails({int limit = 50});
}

/// Không có mạng và chưa có dữ liệu đệm (thay vì báo nhầm "chưa có món").
class RecipeOfflineException implements Exception {
  const RecipeOfflineException();
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
