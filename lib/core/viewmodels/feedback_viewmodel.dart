import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/app_models.dart';
import '../services/interfaces/i_crash_reporter.dart';
import '../services/interfaces/i_feedback_repository.dart';

/// Trạng thái danh sách phản hồi.
sealed class FeedbackListState {
  const FeedbackListState();
}

class FeedbackListLoading extends FeedbackListState {
  const FeedbackListLoading();
}

class FeedbackListError extends FeedbackListState {
  const FeedbackListError(this.message);
  final String message;
}

class FeedbackListData extends FeedbackListState {
  const FeedbackListData(this.items);
  final List<FeedbackItemModel> items;
}

/// Bộ lọc trên màn danh sách.
enum FeedbackFilter { all, open, waitingInfo, resolved }

extension FeedbackFilterX on FeedbackFilter {
  String get label => switch (this) {
    FeedbackFilter.all => 'Tất cả',
    FeedbackFilter.open => 'Đang mở',
    FeedbackFilter.waitingInfo => 'Chờ bổ sung',
    FeedbackFilter.resolved => 'Đã xong',
  };

  bool matches(FeedbackStatus s) => switch (this) {
    FeedbackFilter.all => true,
    FeedbackFilter.open =>
      s == FeedbackStatus.newFeedback || s == FeedbackStatus.inProgress,
    FeedbackFilter.waitingInfo => s == FeedbackStatus.waitingInfo,
    FeedbackFilter.resolved =>
      s == FeedbackStatus.resolved || s == FeedbackStatus.closed,
  };
}

/// Danh sách real-time: Barista thấy phản hồi của mình, Admin thấy mọi phản hồi.
class FeedbackListViewModel extends ChangeNotifier {
  FeedbackListViewModel({required this._repo, required this._crash});

  final IFeedbackRepository _repo;
  final ICrashReporter _crash;
  StreamSubscription<List<FeedbackItemModel>>? _sub;
  String? _uid;
  bool _isAdmin = false;
  bool _disposed = false;

  FeedbackListState _state = const FeedbackListLoading();
  FeedbackFilter _filter = FeedbackFilter.all;

  FeedbackListState get state => _state;
  FeedbackFilter get filter => _filter;
  bool get isAdmin => _isAdmin;

  List<FeedbackItemModel> get visible => switch (_state) {
    FeedbackListData(:final items) =>
      items.where((f) => _filter.matches(f.status)).toList(),
    _ => const [],
  };

  int countFor(FeedbackFilter f) => switch (_state) {
    FeedbackListData(:final items) =>
      items.where((x) => f.matches(x.status)).length,
    _ => 0,
  };

  /// Gọi mỗi lần build; chỉ đăng ký lại khi người dùng / vai trò đổi.
  void bind({required String uid, required bool isAdmin}) {
    if (_uid == uid && _isAdmin == isAdmin && _sub != null) return;
    _uid = uid;
    _isAdmin = isAdmin;
    _subscribe();
  }

  void retry() => _subscribe();

  void setFilter(FeedbackFilter f) {
    if (f == _filter) return;
    _filter = f;
    _notify();
  }

  void _subscribe() {
    final uid = _uid;
    if (uid == null) return;
    _sub?.cancel();
    _state = const FeedbackListLoading();
    _notify();
    final stream = _isAdmin ? _repo.watchAll() : _repo.watchMine(uid);
    _sub = stream.listen(
      (items) {
        _state = FeedbackListData(items);
        _notify();
      },
      onError: (Object e, StackTrace s) {
        _crash.recordError(e, s, reason: 'feedback_list_stream');
        _state = FeedbackListError(
          e is FeedbackFailure ? e.message : 'Không tải được phản hồi.',
        );
        _notify();
      },
    );
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _sub?.cancel();
    super.dispose();
  }
}

/// Chi tiết một phản hồi + luồng trả lời (real-time). Admin trả lời và đổi trạng thái.
class FeedbackDetailViewModel extends ChangeNotifier {
  FeedbackDetailViewModel({
    required this._repo,
    required this._crash,
    required this.feedbackId,
    required this.myUid,
    required this.myName,
    required this.isAdmin,
  }) {
    _subscribe();
  }

  final IFeedbackRepository _repo;
  final ICrashReporter _crash;
  final String feedbackId;
  final String myUid;
  final String myName;
  final bool isAdmin;

  StreamSubscription<FeedbackItemModel?>? _itemSub;
  StreamSubscription<List<FeedbackReplyModel>>? _replySub;
  bool _disposed = false;

  FeedbackItemModel? _item;
  List<FeedbackReplyModel> _replies = const [];
  bool _loading = true;
  bool _notFound = false;
  String? _error;
  bool _sending = false;
  String? _actionError;

  FeedbackItemModel? get item => _item;
  List<FeedbackReplyModel> get replies => _replies;
  bool get loading => _loading;
  bool get notFound => _notFound;
  String? get error => _error;
  bool get sending => _sending;
  String? get actionError => _actionError;

  void retry() => _subscribe();

  void _subscribe() {
    _itemSub?.cancel();
    _replySub?.cancel();
    _loading = true;
    _error = null;
    _notify();
    _itemSub = _repo.watchOne(feedbackId).listen((f) {
      _item = f;
      _notFound = f == null;
      _loading = false;
      _notify();
    }, onError: _onError);
    _replySub = _repo.watchReplies(feedbackId).listen((r) {
      _replies = r;
      _notify();
    }, onError: _onError);
  }

  void _onError(Object e, StackTrace s) {
    _crash.recordError(e, s, reason: 'feedback_detail_stream');
    _loading = false;
    _error = e is FeedbackFailure ? e.message : 'Không tải được phản hồi.';
    _notify();
  }

  /// true nếu gửi thành công.
  Future<bool> sendReply(String message, {FeedbackStatus? newStatus}) async {
    final text = message.trim();
    if (text.isEmpty || _sending) return false;
    _sending = true;
    _actionError = null;
    _notify();
    try {
      await _repo.reply(
        feedbackId: feedbackId,
        authorUid: myUid,
        authorName: myName,
        isAdmin: isAdmin,
        message: text,
        newStatus: newStatus,
      );
      return true;
    } catch (e, s) {
      await _crash.recordError(e, s, reason: 'feedback_reply');
      _actionError = e is FeedbackFailure ? e.message : 'Gửi trả lời thất bại.';
      return false;
    } finally {
      _sending = false;
      _notify();
    }
  }

  Future<bool> changeStatus(FeedbackStatus status) async {
    if (!isAdmin || _sending) return false;
    _sending = true;
    _actionError = null;
    _notify();
    try {
      await _repo.setStatus(feedbackId, status);
      return true;
    } catch (e, s) {
      await _crash.recordError(e, s, reason: 'feedback_status');
      _actionError = e is FeedbackFailure
          ? e.message
          : 'Đổi trạng thái thất bại.';
      return false;
    } finally {
      _sending = false;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _itemSub?.cancel();
    _replySub?.cancel();
    super.dispose();
  }
}
