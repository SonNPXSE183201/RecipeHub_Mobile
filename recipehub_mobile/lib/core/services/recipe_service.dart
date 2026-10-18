import '../network/api_client.dart';
import '../models/recipe_models.dart';
import '../config/app_config.dart';

class RecipeService {
  RecipeService._();
  static final RecipeService instance = RecipeService._();

  final _dio = ApiClient.instance.client;

  /// Fetches paginated recipe list from Gateway /api/v1/recipes
  Future<PagedResponse<RecipeSummaryResponse>> searchRecipes({
    String? query,
    String? state,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/api/v1/recipes',
        queryParameters: {
          if (query != null && query.isNotEmpty) 'query': query,
          if (state != null && state.isNotEmpty) 'state': state,
          'page': page,
          'pageSize': pageSize,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        return PagedResponse<RecipeSummaryResponse>.fromJson(
          response.data as Map<String, dynamic>,
          (item) => RecipeSummaryResponse.fromJson(item),
        );
      }
    } catch (e) {
      if (!AppConfig.enableOfflineMockFallback) rethrow;
    }

    // Fallback Mock Data for NomadKit UI when backend is starting or offline
    return _getFallbackMockRecipes(page: page, pageSize: pageSize, query: query);
  }

  /// Fetches full recipe detail with ingredients, steps, and rowVersion
  Future<RecipeDetailResponse> getRecipe(String publicId) async {
    try {
      final response = await _dio.get('/api/v1/recipes/$publicId');
      if (response.statusCode == 200 && response.data != null) {
        return RecipeDetailResponse.fromJson(response.data as Map<String, dynamic>);
      }
    } catch (e) {
      if (!AppConfig.enableOfflineMockFallback) rethrow;
    }

    return _getFallbackMockDetail(publicId);
  }

  PagedResponse<RecipeSummaryResponse> _getFallbackMockRecipes({
    required int page,
    required int pageSize,
    String? query,
  }) {
    final all = [
      RecipeSummaryResponse(
        id: '11111111-1111-1111-1111-111111111111',
        code: 'RC-OOL-02',
        name: 'Trà Sữa Oolong Lài',
        state: 'Active',
        versionId: 'v1111111-1111-1111-1111-111111111111',
        versionNumber: 2,
        versionStatus: 'Approved',
        updatedAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      RecipeSummaryResponse(
        id: '22222222-2222-2222-2222-222222222222',
        code: 'RC-CFE-01',
        name: 'Cà Phê Muối Ô Long',
        state: 'Active',
        versionId: 'v2222222-2222-2222-2222-222222222222',
        versionNumber: 1,
        versionStatus: 'Approved',
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      RecipeSummaryResponse(
        id: '33333333-3333-3333-3333-333333333333',
        code: 'RC-MAT-04',
        name: 'Matcha Kem Trứng Dừa Nướng',
        state: 'Draft',
        versionId: 'v3333333-3333-3333-3333-333333333333',
        versionNumber: 1,
        versionStatus: 'Draft',
        updatedAt: DateTime.now().subtract(const Duration(minutes: 45)),
      ),
      RecipeSummaryResponse(
        id: '44444444-4444-4444-4444-444444444444',
        code: 'RC-LCH-03',
        name: 'Trà Vải Hoa Hồng Băng Tuyết',
        state: 'Draft',
        versionId: 'v4444444-4444-4444-4444-444444444444',
        versionNumber: 3,
        versionStatus: 'Draft',
        updatedAt: DateTime.now().subtract(const Duration(hours: 12)),
      ),
    ];

    final filtered = query != null && query.isNotEmpty
        ? all.where((r) => r.name.toLowerCase().contains(query.toLowerCase()) || r.code.toLowerCase().contains(query.toLowerCase())).toList()
        : all;

    return PagedResponse(
      items: filtered,
      page: page,
      pageSize: pageSize,
      totalCount: filtered.length,
    );
  }

  RecipeDetailResponse _getFallbackMockDetail(String publicId) {
    return RecipeDetailResponse(
      id: publicId,
      code: 'RC-OOL-02',
      name: 'Trà Sữa Oolong Lài',
      state: 'Active',
      versionId: 'v-oolong-lai-02',
      versionNumber: 2,
      versionStatus: 'Approved',
      description: 'Công thức Oolong Lài chuẩn vị đậm trà thơm hoa, vị béo dịu của sữa hạt.',
      rowVersion: 1,
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
      ingredients: [
        RecipeIngredientResponse(
          id: 1,
          ingredientId: 'ing-1',
          ingredientCode: 'ING-TR-01',
          ingredientName: 'Trà Oolong Lài Đặc Biệt',
          quantity: 25.0,
          unitId: 'u-g',
          unitCode: 'g',
          sortOrder: 1,
          stageName: 'Ủ trà cốt',
        ),
        RecipeIngredientResponse(
          id: 2,
          ingredientId: 'ing-2',
          ingredientCode: 'ING-SUA-02',
          ingredientName: 'Sữa Tươi Thanh Trùng',
          quantity: 120.0,
          unitId: 'u-ml',
          unitCode: 'ml',
          sortOrder: 2,
          stageName: 'Đánh sữa',
        ),
        RecipeIngredientResponse(
          id: 3,
          ingredientId: 'ing-3',
          ingredientCode: 'ING-DG-01',
          ingredientName: 'Nước Đường Mía Nâu',
          quantity: 20.0,
          unitId: 'u-ml',
          unitCode: 'ml',
          sortOrder: 3,
          stageName: 'Pha chế',
        ),
      ],
      steps: [
        RecipeStepResponse(
          id: 1,
          publicId: 'step-1',
          sortOrder: 1,
          title: 'Ủ Cốt Trà Oolong',
          description: 'Ủ 25g trà với 200ml nước sôi ở nhiệt độ 92°C trong 8 phút. Lọc bỏ bã trà.',
          durationSeconds: 480,
          temperatureCelsius: 92.0,
          equipment: 'Bình ủ trà chuyên dụng',
          media: [],
        ),
        RecipeStepResponse(
          id: 2,
          publicId: 'step-2',
          sortOrder: 2,
          title: 'Hòa Sữa và Lắc Lạnh',
          description: 'Cho cốt trà, 120ml sữa thanh trùng và 20ml đường vào shaker. Thêm 150g đá bi, lắc đều 15 lần.',
          durationSeconds: 30,
          equipment: 'Shaker Inox',
          media: [],
        ),
      ],
    );
  }
}
