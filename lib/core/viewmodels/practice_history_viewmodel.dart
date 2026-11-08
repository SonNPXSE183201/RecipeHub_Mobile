import 'package:flutter/foundation.dart';

import '../models/app_models.dart';
import '../services/interfaces/i_crash_reporter.dart';
import '../services/interfaces/i_practice_history_store.dart';

/// Lịch sử tự luyện (M-15) của người đang đăng nhập, lưu bền qua [IPracticeHistoryStore].
class PracticeHistoryViewModel extends ChangeNotifier {
  PracticeHistoryViewModel({required this._store, required this._crash});

  /// Sai lệch tối đa (giây) so với thời gian chuẩn để tính là "đạt".
  static const int toleranceSeconds = 5;

  final IPracticeHistoryStore _store;
  final ICrashReporter _crash;
  String? _uid;
  List<SelfPracticeRecord> _records = const [];
  bool _loading = false;
  bool _disposed = false;
  Future<void>? _loadFuture;

  List<SelfPracticeRecord> get records => _records;
  bool get isLoading => _loading;
  int get totalSessions => _records.length;

  int get averageSeconds =>
      _records.isEmpty ? 0 : (_records.fold<int>(0, (s, r) => s + r.durationSeconds) / _records.length).round();

  /// Tỷ lệ (%) lần luyện đạt thời gian chuẩn; lần không có chuẩn (target = 0) không tính vào mẫu số.
  int? get withinTolerancePercent {
    final timed = _records.where((r) => r.targetSeconds > 0).toList();
    if (timed.isEmpty) return null;
    final ok = timed.where((r) => r.deviationSeconds.abs() <= toleranceSeconds).length;
    return (ok * 100 / timed.length).round();
  }

  Future<void> load(String uid) {
    if (_uid == uid && _loadFuture != null) return _loadFuture!;
    _uid = uid;
    return _loadFuture = _load(uid);
  }

  Future<void> _load(String uid) async {
    _loading = true;
    _notify();
    try {
      final loaded = await _store.load(uid);
      if (_uid == uid) _records = loaded;
    } catch (e, s) {
      await _crash.recordError(e, s, reason: 'practice_history_load');
    } finally {
      _loading = false;
      _notify();
    }
  }

  Future<void> add(SelfPracticeRecord record) async {
    // Lưu khi chưa tải xong sẽ ghi đè lịch sử cũ trên máy → chờ load trước.
    final pending = _loadFuture;
    if (pending != null) await pending;
    _records = [record, ..._records];
    _notify();
    final uid = _uid;
    if (uid == null) return;
    try {
      await _store.save(uid, _records);
    } catch (e, s) {
      await _crash.recordError(e, s, reason: 'practice_history_save');
    }
  }

  void clear() {
    _uid = null;
    _loadFuture = null;
    _records = const [];
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
