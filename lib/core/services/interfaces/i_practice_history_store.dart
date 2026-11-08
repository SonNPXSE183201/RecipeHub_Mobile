import '../../models/app_models.dart';

/// Lưu lịch sử tự luyện theo từng người dùng (không mất khi tắt app).
abstract class IPracticeHistoryStore {
  Future<List<SelfPracticeRecord>> load(String uid);

  Future<void> save(String uid, List<SelfPracticeRecord> records);
}
