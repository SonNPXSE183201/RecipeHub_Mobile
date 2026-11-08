import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../models/app_models.dart';
import '../interfaces/i_feedback_repository.dart';

/// Firestore `feedback/{id}` + `feedback/{id}/replies/{rid}` (rules: chủ hoặc Admin).
class FirestoreFeedbackRepository implements IFeedbackRepository {
  FirestoreFeedbackRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;
  static final _fmt = DateFormat('dd/MM/yyyy HH:mm');

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('feedback');

  static FeedbackType _type(Object? v) => FeedbackType.values.firstWhere(
    (t) => t.name == v,
    orElse: () => FeedbackType.issue,
  );

  static FeedbackStatus _status(Object? v) => FeedbackStatus.values.firstWhere(
    (t) => t.name == v,
    orElse: () => FeedbackStatus.newFeedback,
  );

  static DateTime? _time(Object? v) => v is Timestamp ? v.toDate() : null;

  static String _display(DateTime? t) =>
      t == null ? 'Đang gửi…' : _fmt.format(t);

  static FeedbackItemModel fromDoc(String id, Map<String, dynamic> d) {
    final created = _time(d['createdAt']);
    return FeedbackItemModel(
      id: id,
      ownerUid: (d['ownerUid'] as String?) ?? '',
      senderName: (d['ownerName'] as String?) ?? 'Chưa cập nhật',
      senderRole: (d['ownerRole'] as String?) ?? 'Barista',
      storeBranch: (d['storeBranch'] as String?) ?? '',
      type: _type(d['type']),
      content: (d['content'] as String?) ?? '',
      targetName: (d['targetName'] as String?) ?? '',
      targetCode: (d['targetCode'] as String?) ?? '',
      version: (d['version'] as String?) ?? '',
      stepNote: d['stepNote'] as String?,
      status: _status(d['status']),
      createdAt: _display(created),
      createdAtTime: created,
      updatedAtTime: _time(d['updatedAt']),
      replies: const [],
      replyCount: (d['replyCount'] as num?)?.toInt() ?? 0,
      attachmentUrl: d['attachmentUrl'] as String?,
      attachmentPath: d['attachmentPath'] as String?,
    );
  }

  static FeedbackReplyModel replyFromDoc(String id, Map<String, dynamic> d) {
    final t = _time(d['createdAt']);
    return FeedbackReplyModel(
      id: id,
      authorUid: (d['authorUid'] as String?) ?? '',
      senderName: (d['authorName'] as String?) ?? 'Chưa cập nhật',
      isAdmin: d['isAdmin'] == true,
      message: (d['message'] as String?) ?? '',
      time: _display(t),
      createdAtTime: t,
    );
  }

  static FeedbackFailure _map(Object e) {
    if (e is FirebaseException) {
      return switch (e.code) {
        'permission-denied' => const FeedbackFailure(
          'Bạn không có quyền với phản hồi này.',
          code: 'permission-denied',
        ),
        'unavailable' => const FeedbackFailure(
          'Mất kết nối. Kiểm tra mạng rồi thử lại.',
          code: 'unavailable',
        ),
        'not-found' => const FeedbackFailure(
          'Phản hồi không còn tồn tại.',
          code: 'not-found',
        ),
        _ => FeedbackFailure(
          'Không xử lý được phản hồi (${e.code}).',
          code: e.code,
        ),
      };
    }
    return const FeedbackFailure('Có lỗi không mong muốn. Thử lại sau.');
  }

  Stream<T> _guard<T>(Stream<T> s) =>
      s.handleError((Object e) => throw _map(e));

  List<FeedbackItemModel> _list(QuerySnapshot<Map<String, dynamic>> s) =>
      s.docs.map((d) => fromDoc(d.id, d.data())).toList();

  @override
  Stream<List<FeedbackItemModel>> watchMine(String uid) => _guard(
    _col
        .where('ownerUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(_list),
  );

  @override
  Stream<List<FeedbackItemModel>> watchAll({int limit = 200}) => _guard(
    _col
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(_list),
  );

  @override
  Stream<FeedbackItemModel?> watchOne(String id) => _guard(
    _col
        .doc(id)
        .snapshots()
        .map((s) => s.exists ? fromDoc(s.id, s.data()!) : null),
  );

  @override
  Stream<List<FeedbackReplyModel>> watchReplies(String feedbackId) => _guard(
    _col
        .doc(feedbackId)
        .collection('replies')
        .orderBy('createdAt')
        .snapshots()
        .map((s) => s.docs.map((d) => replyFromDoc(d.id, d.data())).toList()),
  );

  @override
  Future<String> create(NewFeedback f) async {
    final data = <String, dynamic>{
      'ownerUid': f.ownerUid,
      'ownerName': f.ownerName,
      'ownerRole': f.ownerRole,
      'storeBranch': f.storeBranch,
      'type': f.type.name,
      'content': f.content,
      'targetCode': f.targetCode,
      'targetName': f.targetName,
      'version': f.version,
      if (f.stepNote != null) 'stepNote': f.stepNote,
      if (f.attachmentUrl != null) 'attachmentUrl': f.attachmentUrl,
      if (f.attachmentPath != null) 'attachmentPath': f.attachmentPath,
      'status': FeedbackStatus.newFeedback.name,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'replyCount': 0,
    };
    try {
      final ref = _col.doc();
      try {
        await ref.set(data).timeout(const Duration(seconds: 10));
      } on TimeoutException {
        // Offline: Firestore giữ bản ghi trong hàng đợi và tự đẩy lên khi có mạng; danh sách đã hiện ngay.
      }
      return ref.id;
    } catch (e) {
      throw _map(e);
    }
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
    final parent = _col.doc(feedbackId);
    final batch = _db.batch()
      ..set(parent.collection('replies').doc(), {
        'authorUid': authorUid,
        'authorName': authorName,
        'isAdmin': isAdmin,
        'message': message,
        'createdAt': FieldValue.serverTimestamp(),
      })
      ..update(parent, {
        'replyCount': FieldValue.increment(1),
        'lastReplyAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        if (isAdmin && newStatus != null) 'status': newStatus.name,
      });
    try {
      await batch.commit();
    } catch (e) {
      throw _map(e);
    }
  }

  @override
  Future<void> setStatus(String feedbackId, FeedbackStatus status) async {
    try {
      await _col.doc(feedbackId).update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw _map(e);
    }
  }
}
