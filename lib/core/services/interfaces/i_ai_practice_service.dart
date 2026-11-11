import '../../models/ai_practice_models.dart';

abstract class IAiPracticeContextService {
  Future<RecallContext> load(String recipeId);

  /// Emits when the source changes or is withdrawn. No personal data.
  Stream<String> watchRevision(RecallContext context);
}

abstract class IAiPracticeService {
  Future<List<String>> selectQuestions(RecallContext context);
}

class AiPracticeFailure implements Exception {
  const AiPracticeFailure(this.message);
  final String message;
}

/// Explicit unavailable service, not a simulated model.
class UnavailableAiPracticeService implements IAiPracticeService {
  const UnavailableAiPracticeService();
  @override
  Future<List<String>> selectQuestions(
    RecallContext context,
  ) async => throw const AiPracticeFailure(
    'AI chưa được kết nối. Bạn vẫn có thể ôn bằng câu hỏi mẫu từ công thức.',
  );
}
