import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/app_models.dart';
import '../device/prefs_practice_history_store.dart';
import '../interfaces/i_practice_history_store.dart';

/// Lịch sử tự luyện trên Firestore `users/{uid}/practiceRecords/{id}` (đồng bộ nhiều máy, Admin xem được).
/// Bản lưu máy ([PrefsPracticeHistoryStore]) làm cache khi offline; bản ghi chỉ thêm mới, không sửa.
class FirestorePracticeHistoryStore implements IPracticeHistoryStore {
  FirestorePracticeHistoryStore({
    FirebaseFirestore? firestore,
    PrefsPracticeHistoryStore? cache,
  }) : _db = firestore ?? FirebaseFirestore.instance,
       _cache = cache ?? PrefsPracticeHistoryStore();

  final FirebaseFirestore _db;
  final PrefsPracticeHistoryStore _cache;
  final Map<String, Set<String>> _remoteIds = {};

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('users/$uid/practiceRecords');

  @override
  Future<List<SelfPracticeRecord>> load(String uid) async {
    final local = await _cache.load(uid);
    try {
      final snap = await _col(uid)
          .orderBy('createdAt', descending: true)
          .limit(200)
          .get();
      final remote = snap.docs
          .map((d) => SelfPracticeRecord.fromJson({...d.data(), 'id': d.id}))
          .toList();
      _remoteIds[uid] = remote.map((r) => r.id).toSet();
      // Bản ghi chỉ có trên máy (tạo lúc offline) → đẩy lên.
      final pending = local
          .where((r) => !_remoteIds[uid]!.contains(r.id))
          .toList();
      for (final r in pending) {
        unawaited(_push(uid, r));
      }
      final merged = [...pending, ...remote];
      await _cache.save(uid, merged);
      return merged;
    } catch (_) {
      return local; // Offline / lỗi: dùng cache.
    }
  }

  @override
  Future<void> save(String uid, List<SelfPracticeRecord> records) async {
    await _cache.save(uid, records);
    final known = _remoteIds[uid] ??= {};
    for (final r in records.where((r) => !known.contains(r.id))) {
      await _push(uid, r);
    }
  }

  Future<void> _push(String uid, SelfPracticeRecord r) async {
    final known = _remoteIds[uid] ??= {};
    if (known.contains(r.id)) return;
    known.add(r.id);
    try {
      await _col(uid)
          .doc(r.id)
          .set({
            'recipeName': r.recipeName,
            'recipeCode': r.recipeCode,
            'size': r.size,
            'durationSeconds': r.durationSeconds,
            'notes': r.notes,
            'practicedAt': r.practicedAt,
            'targetSeconds': r.targetSeconds,
            'createdAt': FieldValue.serverTimestamp(),
          })
          .timeout(const Duration(seconds: 10));
    } on TimeoutException {
      // Firestore giữ trong hàng đợi, tự đẩy khi có mạng.
    } catch (_) {
      known.remove(r.id); // Thử lại ở lần tải sau.
    }
  }
}
