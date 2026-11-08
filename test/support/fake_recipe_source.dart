import 'package:recipehub_mobile/core/models/recipe_models.dart';
import 'package:recipehub_mobile/core/services/i_recipe_source.dart';

/// Fake IRecipeSource dựng đúng DTO của backend – dùng trong test, KHÔNG nằm trong app.
class FakeRecipeSource implements IRecipeSource {
  FakeRecipeSource({this.failuresBeforeSuccess = 0});

  int failuresBeforeSuccess;
  int calls = 0;

  static RecipeDetailResponse detail(String id, String code, String name) => RecipeDetailResponse(
        id: id,
        code: code,
        state: 'Active',
        versionId: 'ver-$id',
        versionNumber: 2,
        versionStatus: 'published',
        name: name,
        description: 'Mô tả $name',
        rowVersion: 1,
        ingredients: [
          RecipeIngredientResponse(
            id: 'i1',
            ingredientId: 'ing1',
            ingredientCode: 'ING-01',
            ingredientName: 'Trà Oolong',
            quantity: 25,
            unitId: 'u1',
            unitCode: 'g',
            sortOrder: 1,
          ),
        ],
        steps: [
          RecipeStepResponse(
            id: '11111111-1111-1111-1111-111111111111',
            publicId: '11111111-1111-1111-1111-111111111111',
            sortOrder: 1,
            title: 'Ủ trà',
            description: 'Ủ 8 phút',
            durationSeconds: 480,
            temperatureCelsius: 92,
            media: const [],
          ),
        ],
        createdAt: DateTime(2026, 10, 1),
        updatedAt: DateTime(2026, 10, 15),
      );

  final Map<String, RecipeDetailResponse> _all = {
    'r1': detail('r1', 'RC-OOL-02', 'Trà Sữa Oolong'),
    'r2': detail('r2', 'RC-CFE-01', 'Cà Phê Muối'),
  };

  @override
  Future<PagedResponse<RecipeSummaryResponse>> searchApproved({String? query, int pageSize = 50}) async {
    calls++;
    if (failuresBeforeSuccess > 0) {
      failuresBeforeSuccess--;
      throw Exception('network down');
    }
    final items = _all.values
        .take(pageSize)
        .map((d) => RecipeSummaryResponse(
              id: d.id,
              code: d.code,
              state: d.state,
              versionId: d.versionId,
              versionNumber: d.versionNumber,
              versionStatus: d.versionStatus,
              name: d.name,
              updatedAt: d.updatedAt,
            ))
        .toList();
    return PagedResponse(items: items, page: 1, pageSize: pageSize, totalCount: items.length);
  }

  @override
  Future<RecipeDetailResponse> getRecipe(String id) async => _all[id]!;
}
