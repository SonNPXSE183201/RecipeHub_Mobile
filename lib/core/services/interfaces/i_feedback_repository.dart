import '../../models/app_models.dart';

/// Lỗi phản hồi đã dịch sang câu tiếng Việt cho người dùng.
class FeedbackFailure implements Exception {
  const FeedbackFailure(this.message, {this.code = 'unknown'});
  final String message;
  final String code;
  @override
  String toString() => 'FeedbackFailure($code): $message';
}

/// Phản hồi Barista ↔ Admin (Firestore `feedback/{id}` + `replies`). Mọi luồng đọc là real-time.
abstract class IFeedbackRepository {
  /// Phản hồi do [uid] gửi, mới nhất trước.
  Stream<List<FeedbackItemModel>> watchMine(String uid);

  /// Mọi phản hồi (chỉ Admin – rules từ chối viewer), mới nhất trước.
  Stream<List<FeedbackItemModel>> watchAll({int limit = 200});

  /// Một phản hồi; null nếu không tồn tại.
  Stream<FeedbackItemModel?> watchOne(String id);

  /// Luồng trả lời theo thời gian tăng dần.
  Stream<List<FeedbackReplyModel>> watchReplies(String feedbackId);

  /// Trả về id phản hồi vừa tạo.
  Future<String> create(NewFeedback input);

  /// Ghi trả lời + bộ đếm trong một batch; Admin có thể đổi trạng thái cùng lúc.
  Future<void> reply({
    required String feedbackId,
    required String authorUid,
    required String authorName,
    required bool isAdmin,
    required String message,
    FeedbackStatus? newStatus,
  });

  /// Chỉ Admin.
  Future<void> setStatus(String feedbackId, FeedbackStatus status);
}
