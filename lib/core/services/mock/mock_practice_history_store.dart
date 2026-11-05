import '../../models/app_models.dart';
import '../interfaces/i_practice_history_store.dart';

/// Bản giả cho test: lưu trong bộ nhớ theo uid.
class MockPracticeHistoryStore implements IPracticeHistoryStore {
  final Map<String, List<SelfPracticeRecord>> data = {};

  @override
  Future<List<SelfPracticeRecord>> load(String uid) async => List.of(data[uid] ?? const []);

  @override
  Future<void> save(String uid, List<SelfPracticeRecord> records) async => data[uid] = List.of(records);
}
