import '../network/api_client.dart';
import '../models/content_models.dart';

class ContentService {
  ContentService._();
  static final ContentService instance = ContentService._();

  final _dio = ApiClient.instance.client;

  /// Trigger asynchronous AI image generation via Content Service & Redis Streams
  Future<DraftDetailResponse> createImageDraft({
    required String recipeVersionId,
    String? recipeStepId,
    required String targetKind, // 'final_product' | 'step_instruction'
    String? userBrief,
    int expectedRecipeRevision = 1,
  }) async {
    final response = await _dio.post(
      '/api/v1/content/image-drafts',
      data: {
        'recipeVersionId': recipeVersionId,
        'recipeStepId': ?recipeStepId,
        'targetKind': targetKind,
        'userBrief': ?userBrief,
        'expectedRecipeRevision': expectedRecipeRevision,
      },
    );

    return DraftDetailResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// Poll draft generation status (queued -> processing -> generated)
  Future<DraftDetailResponse> getDraftStatus(String draftId) async {
    final response = await _dio.get('/api/v1/content/image-drafts/$draftId');
    return DraftDetailResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// Promotes a generated draft to a permanent media asset on the recipe step
  Future<void> acceptDraft(String draftId) async {
    await _dio.post('/api/v1/content/image-drafts/$draftId/accept');
  }

  /// Discards a generated draft
  Future<void> discardDraft(String draftId) async {
    await _dio.post('/api/v1/content/image-drafts/$draftId/discard');
  }
}
