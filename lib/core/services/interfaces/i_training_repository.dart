import '../../models/app_models.dart';
import '../../models/training_models.dart';

/// Lỗi đào tạo đã dịch sang tiếng Việt.
class TrainingFailure implements Exception {
  const TrainingFailure(this.message, {this.code = 'unknown'});
  final String message;
  final String code;
  @override
  String toString() => 'TrainingFailure($code): $message';
}

/// Dữ liệu đào tạo trên Firestore: SOP, nhiệm vụ học + tiến độ, quiz, chấm thực hành, danh sách nhân viên.
/// Mọi luồng `watch*` là real-time (Admin sửa trên web → app cập nhật ngay).
abstract class ITrainingRepository {
  // SOP
  Stream<List<SopItem>> watchSops();

  // Nhiệm vụ học
  Stream<List<LearningTaskItem>> watchTasks();
  Stream<Map<String, TaskProgress>> watchProgress(String uid);
  Future<void> setSectionDone({
    required String uid,
    required String taskId,
    required int sectionIndex,
    required int totalSections,
    required bool done,
    required List<int> current,
  });

  // Quiz
  Stream<List<QuizSet>> watchQuizzes();
  Stream<List<QuizAttempt>> watchMyAttempts(String uid);

  /// Ghi bài nộp (không sửa được) rồi mới đọc đáp án để chấm. Trả về (đáp án, bài đã chấm).
  Future<(QuizAnswerKey, QuizAttempt)> submitQuiz({
    required String uid,
    required String userName,
    required QuizSet quiz,
    required List<int> answers,
    required int attemptNo,
  });

  // Chấm thực hành
  Stream<List<PracticalEvaluationRecord>> watchMyEvaluations(String uid);
  Stream<List<PracticalEvaluationRecord>> watchAllEvaluations({
    int limit = 200,
  });
  Stream<List<CriteriaTemplate>> watchCriteriaTemplates();
  Future<void> saveEvaluation(
    PracticalEvaluationRecord record, {
    required String evaluatorUid,
  });

  // Admin: nhân viên + tiến độ của họ
  Stream<List<StaffMember>> watchStaff();
  Future<Map<String, TaskProgress>> progressOf(String uid);
}
