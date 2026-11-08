import 'dart:async';

import '../../models/app_models.dart';
import '../interfaces/i_feedback_repository.dart';

/// Bản trong bộ nhớ cho test / ARTEMIS khi không có Firebase. Không có dữ liệu mẫu.
class MockFeedbackRepository implements IFeedbackRepository {
  final _items = <FeedbackItemModel>[];
  final _replies = <String, List<FeedbackReplyModel>>{};
  final _changes = StreamController<void>.broadcast();
  int _seq = 0;

  Stream<T> _watch<T>(T Function() read) async* {
    yield read();
    yield* _changes.stream.map((_) => read());
  }

  @override
  Stream<List<FeedbackItemModel>> watchMine(String uid) =>
      _watch(() => _items.where((f) => f.ownerUid == uid).toList());

  @override
  Stream<List<FeedbackItemModel>> watchAll({int limit = 200}) =>
      _watch(() => _items.take(limit).toList());

  @override
  Stream<FeedbackItemModel?> watchOne(String id) =>
      _watch(() => _items.where((f) => f.id == id).firstOrNull);

  @override
  Stream<List<FeedbackReplyModel>> watchReplies(String feedbackId) =>
      _watch(() => List.of(_replies[feedbackId] ?? const []));

  @override
  Future<String> create(NewFeedback f) async {
    final id = 'fb-${++_seq}';
    final now = DateTime.now();
    _items.insert(
      0,
      FeedbackItemModel(
        id: id,
        ownerUid: f.ownerUid,
        senderName: f.ownerName,
        senderRole: f.ownerRole,
        storeBranch: f.storeBranch,
        type: f.type,
        content: f.content,
        targetName: f.targetName,
        targetCode: f.targetCode,
        version: f.version,
        stepNote: f.stepNote,
        status: FeedbackStatus.newFeedback,
        createdAt: 'Vừa xong',
        createdAtTime: now,
        replies: const [],
        attachmentUrl: f.attachmentUrl,
        attachmentPath: f.attachmentPath,
      ),
    );
    _changes.add(null);
    return id;
  }

  @override
  Future<void> reply({
    required String feedbackId,
    required String authorUid,
    required String authorName,
    required bool isAdmin,
    required String message,
    FeedbackStatus? newStatus,
  }) async {
    (_replies[feedbackId] ??= []).add(
      FeedbackReplyModel(
        id: 'r-${++_seq}',
        authorUid: authorUid,
        senderName: authorName,
        isAdmin: isAdmin,
        message: message,
        time: 'Vừa xong',
        createdAtTime: DateTime.now(),
      ),
    );
    if (isAdmin && newStatus != null) await setStatus(feedbackId, newStatus);
    _changes.add(null);
  }

  @override
  Future<void> setStatus(String feedbackId, FeedbackStatus status) async {
    for (final f in _items) {
      if (f.id == feedbackId) f.status = status;
    }
    _changes.add(null);
  }
}
