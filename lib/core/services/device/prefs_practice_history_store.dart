import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/app_models.dart';
import '../interfaces/i_practice_history_store.dart';

/// SharedPreferences, mỗi uid một khóa; giữ tối đa [maxRecords] bản ghi mới nhất.
class PrefsPracticeHistoryStore implements IPracticeHistoryStore {
  static const int maxRecords = 200;

  static String keyFor(String uid) => 'rh_practice_history_v1_$uid';

  @override
  Future<List<SelfPracticeRecord>> load(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(keyFor(uid)) ?? const <String>[];
    final out = <SelfPracticeRecord>[];
    for (final s in raw) {
      try {
        out.add(SelfPracticeRecord.fromJson(jsonDecode(s) as Map<String, dynamic>));
      } catch (_) {
        // Bỏ qua bản ghi hỏng thay vì làm hỏng cả lịch sử.
      }
    }
    return out;
  }

  @override
  Future<void> save(String uid, List<SelfPracticeRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      keyFor(uid),
      records.take(maxRecords).map((r) => jsonEncode(r.toJson())).toList(),
    );
  }
}
