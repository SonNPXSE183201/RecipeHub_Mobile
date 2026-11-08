import '../network/api_client.dart';
import '../models/recipe_models.dart';

class RecipeService {
  RecipeService._();
  static final RecipeService instance = RecipeService._();

  final _dio = ApiClient.instance.client;

  /// Fetches paginated recipe list from Gateway /api/v1/recipes
  Future<PagedResponse<RecipeSummaryResponse>> searchRecipes({
    String? query,
    String? state,
    String? versionStatus,
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _dio.get(
        '/api/v1/recipes',
        queryParameters: {
          if (query != null && query.isNotEmpty) 'query': query,
          if (state != null && state.isNotEmpty) 'state': state,
          if (versionStatus != null && versionStatus.isNotEmpty) 'versionStatus': versionStatus,
          'page': page,
          'pageSize': pageSize,
        },
      );

    return PagedResponse<RecipeSummaryResponse>.fromJson(
      response.data as Map<String, dynamic>,
      (item) => RecipeSummaryResponse.fromJson(item),
    );
  }

  /// Fetches full recipe detail with ingredients, steps, and rowVersion
  Future<RecipeDetailResponse> getRecipe(String publicId) async {
    final response = await _dio.get('/api/v1/recipes/$publicId');
    return RecipeDetailResponse.fromJson(response.data as Map<String, dynamic>);
  }
}
