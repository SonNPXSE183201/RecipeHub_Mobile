import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../models/app_models.dart';
import '../../models/training_models.dart';
import '../interfaces/i_training_repository.dart';

/// Firestore: `sops`, `learningTasks`, `users/{uid}/taskProgress`, `quizzes` (+ `answerKey`), `quizAttempts`,
/// `evaluations`, `evaluationCriteria`, `users` (Admin). Quyền do `firestore.rules` quyết định.
class FirestoreTrainingRepository implements ITrainingRepository {
  FirestoreTrainingRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;
  static final _date = DateFormat('dd/MM/yyyy');

  static DateTime? _time(Object? v) => v is Timestamp ? v.toDate() : null;
  static String _fmt(DateTime? t) => t == null ? '—' : _date.format(t);
  static List<String> _strings(Object? v) =>
      (v as List<dynamic>? ?? const []).map((e) => '$e').toList();

  static TrainingFailure _map(Object e) {
    if (e is FirebaseException) {
      return switch (e.code) {
        'permission-denied' => const TrainingFailure(
          'Bạn không có quyền xem hoặc ghi dữ liệu này.',
          code: 'permission-denied',
        ),
        'unavailable' => const TrainingFailure(
          'Mất kết nối. Kiểm tra mạng rồi thử lại.',
          code: 'unavailable',
        ),
        'not-found' => const TrainingFailure(
          'Dữ liệu không còn tồn tại.',
          code: 'not-found',
        ),
        'already-exists' => const TrainingFailure(
          'Bài nộp này đã được ghi trước đó.',
          code: 'already-exists',
        ),
        _ => TrainingFailure(
          'Không xử lý được dữ liệu (${e.code}).',
          code: e.code,
        ),
      };
    }
    if (e is TrainingFailure) return e;
    return const TrainingFailure('Có lỗi không mong muốn. Thử lại sau.');
  }

  Stream<T> _guard<T>(Stream<T> s) =>
      s.handleError((Object e) => throw _map(e));

  // ---------------- SOP ----------------
  static SopItem sopFromDoc(String id, Map<String, dynamic> d) {
    final steps = (d['steps'] as List<dynamic>? ?? const [])
        .cast<Map<dynamic, dynamic>>();
    return SopItem(
      id: id,
      code: (d['code'] as String?) ?? id,
      title: (d['title'] as String?) ?? id,
      category: (d['category'] as String?) ?? 'Khác',
      version: (d['version'] as String?) ?? 'v1.0',
      publishedDate: _fmt(_time(d['publishedAt']) ?? _time(d['updatedAt'])),
      summary: (d['summary'] as String?) ?? '',
      linkedRecipeCodes: _strings(d['linkedRecipeCodes']),
      steps: [
        for (var i = 0; i < steps.length; i++)
          SopStepItem(
            stepNumber: (steps[i]['stepNumber'] as num?)?.toInt() ?? i + 1,
            title: '${steps[i]['title'] ?? 'Bước ${i + 1}'}',
            content: '${steps[i]['content'] ?? ''}',
            note: steps[i]['note'] as String?,
            icon: sopIconOf(steps[i]['icon'] as String?),
          ),
      ],
    );
  }

  @override
  Stream<List<SopItem>> watchSops() => _guard(
    _db
        .collection('sops')
        .where('status', isEqualTo: 'published')
        .snapshots()
        .map(
          (s) =>
              s.docs.map((d) => sopFromDoc(d.id, d.data())).toList()
                ..sort((a, b) => a.code.compareTo(b.code)),
        ),
  );

  // ---------------- Nhiệm vụ học ----------------
  static LearningTaskItem taskFromDoc(String id, Map<String, dynamic> d) {
    final assigned = _time(d['assignedAt']) ?? _time(d['updatedAt']);
    final due = _time(d['dueAt']);
    final type = d['type'] == 'recipe' ? 'Công thức' : 'SOP';
    return LearningTaskItem(
      id: id,
      title: (d['title'] as String?) ?? id,
      type: type,
      targetCode: (d['targetCode'] as String?) ?? '',
      version: (d['version'] as String?) ?? 'v1.0',
      assignedBy: (d['assignedByName'] as String?) ?? 'Quản lý đào tạo',
      assignedDate: _fmt(assigned),
      dueDate: _fmt(due),
      isOverdue: due != null && due.isBefore(DateTime.now()),
      isRelearnRequired: d['relearn'] == true,
      status: TaskStatus.notStarted,
      progress: 0,
      sections: _strings(d['sections']),
    );
  }

  @override
  Stream<List<LearningTaskItem>> watchTasks() => _guard(
    _db
        .collection('learningTasks')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map(
          (s) =>
              s.docs.map((d) => taskFromDoc(d.id, d.data())).toList()
                ..sort((a, b) => a.id.compareTo(b.id)),
        ),
  );

  static TaskProgress progressFromDoc(String id, Map<String, dynamic> d) =>
      TaskProgress(
        taskId: id,
        completedSections:
            (d['completedSections'] as List<dynamic>? ?? const [])
                .map((e) => (e as num).toInt())
                .toList(),
        totalSections: (d['totalSections'] as num?)?.toInt() ?? 0,
      );

  @override
  Stream<Map<String, TaskProgress>> watchProgress(String uid) => _guard(
    _db
        .collection('users/$uid/taskProgress')
        .snapshots()
        .map(
          (s) => {
            for (final d in s.docs) d.id: progressFromDoc(d.id, d.data()),
          },
        ),
  );

  @override
  Future<void> setSectionDone({
    required String uid,
    required String taskId,
    required int sectionIndex,
    required int totalSections,
    required bool done,
    required List<int> current,
  }) async {
    final next = {...current};
    done ? next.add(sectionIndex) : next.remove(sectionIndex);
    final list = next.toList()..sort();
    final p = TaskProgress(
      taskId: taskId,
      completedSections: list,
      totalSections: totalSections,
    );
    try {
      await _db.doc('users/$uid/taskProgress/$taskId').set({
        'taskId': taskId,
        'completedSections': list,
        'totalSections': totalSections,
        'status': p.status.name,
        'progress': p.progress,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw _map(e);
    }
  }

  // ---------------- Quiz ----------------
  static QuizSet quizFromDoc(String id, Map<String, dynamic> d) {
    final qs = (d['questions'] as List<dynamic>? ?? const [])
        .cast<Map<dynamic, dynamic>>();
    return QuizSet(
      id: id,
      title: (d['title'] as String?) ?? id,
      targetCode: (d['targetCode'] as String?) ?? '',
      questions: [
        for (var i = 0; i < qs.length; i++)
          QuizQuestionView(
            id: '${qs[i]['id'] ?? 'q${i + 1}'}',
            text: '${qs[i]['text'] ?? ''}',
            options: _strings(qs[i]['options']),
            reviewSection: '${qs[i]['reviewSection'] ?? ''}',
          ),
      ],
    );
  }

  static QuizAttempt attemptFromDoc(Map<String, dynamic> d) => QuizAttempt(
    quizId: (d['quizId'] as String?) ?? '',
    quizTitle: (d['quizTitle'] as String?) ?? '',
    attemptNo: (d['attemptNo'] as num?)?.toInt() ?? 1,
    answers: (d['answers'] as List<dynamic>? ?? const [])
        .map((e) => (e as num).toInt())
        .toList(),
    score:
        (d['score'] as num?)?.toInt() ??
        -1, // lần nộp đầu không lưu điểm (xem submitQuiz)
    total: (d['total'] as num?)?.toInt() ?? 0,
    submittedAt: _time(d['submittedAt']),
  );

  @override
  Stream<List<QuizSet>> watchQuizzes() => _guard(
    _db
        .collection('quizzes')
        .snapshots()
        .map(
          (s) =>
              s.docs.map((d) => quizFromDoc(d.id, d.data())).toList()
                ..sort((a, b) => a.id.compareTo(b.id)),
        ),
  );

  @override
  Stream<List<QuizAttempt>> watchMyAttempts(String uid) => _guard(
    _db
        .collection('quizAttempts')
        .where('uid', isEqualTo: uid)
        .snapshots()
        .map(
          (s) => s.docs.map((d) => attemptFromDoc(d.data())).toList()
            ..sort(
              (a, b) => (b.submittedAt ?? DateTime.now()).compareTo(
                a.submittedAt ?? DateTime.now(),
              ),
            ),
        ),
  );

  @override
  Future<(QuizAnswerKey, QuizAttempt)> submitQuiz({
    required String uid,
    required String userName,
    required QuizSet quiz,
    required List<int> answers,
    required int attemptNo,
  }) async {
    try {
      // Rules chỉ mở đáp án sau khi đã có bài nộp lần 1 và bài nộp không sửa được.
      // Lần 1: ghi bài (chưa có điểm) → đọc đáp án → chấm. Admin chấm lại được từ `answers`.
      // Lần sau: đã đọc được đáp án nên ghi kèm điểm.
      QuizAnswerKey? key;
      if (attemptNo > 1) key = await _readKey(quiz.id);
      final scoreBefore = key == null ? null : _score(key, answers);
      await _db.doc('quizAttempts/${uid}_${quiz.id}_$attemptNo').set({
        'uid': uid,
        'userName': userName,
        'quizId': quiz.id,
        'quizTitle': quiz.title,
        'attemptNo': attemptNo,
        'answers': answers,
        'score': ?scoreBefore,
        'total': quiz.questions.length,
        'submittedAt': FieldValue.serverTimestamp(),
      });
      key ??= await _readKey(quiz.id);
      final score = scoreBefore ?? _score(key, answers);
      return (
        key,
        QuizAttempt(
          quizId: quiz.id,
          quizTitle: quiz.title,
          attemptNo: attemptNo,
          answers: answers,
          score: score,
          total: quiz.questions.length,
          submittedAt: DateTime.now(),
        ),
      );
    } catch (e) {
      throw _map(e);
    }
  }

  static int _score(QuizAnswerKey key, List<int> answers) {
    var s = 0;
    for (var i = 0; i < answers.length && i < key.correct.length; i++) {
      if (answers[i] == key.correct[i]) s++;
    }
    return s;
  }

  Future<QuizAnswerKey> _readKey(String quizId) async {
    final snap = await _db.doc('quizzes/$quizId/answerKey/key').get();
    final d = snap.data() ?? const {};
    return QuizAnswerKey(
      correct: (d['correct'] as List<dynamic>? ?? const [])
          .map((e) => (e as num).toInt())
          .toList(),
      explanations: _strings(d['explanations']),
    );
  }

  // ---------------- Chấm thực hành ----------------
  static PracticalEvaluationRecord evaluationFromDoc(
    String id,
    Map<String, dynamic> d,
  ) {
    final crit = (d['criteria'] as List<dynamic>? ?? const [])
        .cast<Map<dynamic, dynamic>>();
    return PracticalEvaluationRecord(
      id: id,
      traineeUid: (d['traineeUid'] as String?) ?? '',
      traineeName: (d['traineeName'] as String?) ?? 'Chưa cập nhật',
      storeBranch: (d['storeBranch'] as String?) ?? '',
      evaluatorName: (d['evaluatorName'] as String?) ?? 'Chưa cập nhật',
      recipeCode: (d['recipeCode'] as String?) ?? '',
      recipeName: (d['recipeName'] as String?) ?? '',
      version: (d['version'] as String?) ?? '',
      evaluatedDate: _fmt(_time(d['evaluatedAt'])),
      isPassed: d['isPassed'] == true,
      overallComment: (d['overallComment'] as String?) ?? '',
      relearnPlan: (d['relearnPlan'] as String?) ?? '',
      criteria: [
        for (final c in crit)
          EvaluationCriterion(
            id: '${c['id'] ?? ''}',
            name: '${c['name'] ?? ''}',
            standardRequirement: '${c['standardRequirement'] ?? ''}',
            isPassed: c['isPassed'] == true,
            isCrucial: c['isCrucial'] == true,
            notes: c['notes'] as String?,
          ),
      ],
    );
  }

  List<PracticalEvaluationRecord> _evals(
    QuerySnapshot<Map<String, dynamic>> s,
  ) {
    final list =
        s.docs
            .map(
              (d) => (
                evaluationFromDoc(d.id, d.data()),
                _time(d.data()['evaluatedAt']),
              ),
            )
            .toList()
          ..sort(
            (a, b) =>
                (b.$2 ?? DateTime.now()).compareTo(a.$2 ?? DateTime.now()),
          );
    return list.map((e) => e.$1).toList();
  }

  @override
  Stream<List<PracticalEvaluationRecord>> watchMyEvaluations(String uid) =>
      _guard(
        _db
            .collection('evaluations')
            .where('traineeUid', isEqualTo: uid)
            .snapshots()
            .map(_evals),
      );

  @override
  Stream<List<PracticalEvaluationRecord>> watchAllEvaluations({
    int limit = 200,
  }) => _guard(
    _db
        .collection('evaluations')
        .orderBy('evaluatedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(_evals),
  );

  @override
  Stream<List<CriteriaTemplate>> watchCriteriaTemplates() => _guard(
    _db
        .collection('evaluationCriteria')
        .snapshots()
        .map(
          (s) => s.docs.map((d) {
            final data = d.data();
            final crit = (data['criteria'] as List<dynamic>? ?? const [])
                .cast<Map<dynamic, dynamic>>();
            return CriteriaTemplate(
              group: (data['group'] as String?) ?? d.id,
              recipeCodes: _strings(data['recipeCodes']),
              criteria: [
                for (final c in crit)
                  EvaluationCriterion(
                    id: '${c['id'] ?? ''}',
                    name: '${c['name'] ?? ''}',
                    standardRequirement: '${c['standardRequirement'] ?? ''}',
                    isCrucial: c['isCrucial'] == true,
                  ),
              ],
            );
          }).toList(),
        ),
  );

  @override
  Future<void> saveEvaluation(
    PracticalEvaluationRecord r, {
    required String evaluatorUid,
  }) async {
    try {
      await _db.collection('evaluations').add({
        'traineeUid': r.traineeUid,
        'traineeName': r.traineeName,
        'storeBranch': r.storeBranch,
        'evaluatorUid': evaluatorUid,
        'evaluatorName': r.evaluatorName,
        'recipeCode': r.recipeCode,
        'recipeName': r.recipeName,
        'version': r.version,
        'isPassed': r.isPassed,
        'overallComment': r.overallComment,
        'relearnPlan': r.relearnPlan,
        'criteria': [
          for (final c in r.criteria)
            {
              'id': c.id,
              'name': c.name,
              'standardRequirement': c.standardRequirement,
              'isPassed': c.isPassed,
              'isCrucial': c.isCrucial,
              if (c.notes != null && c.notes!.isNotEmpty) 'notes': c.notes,
            },
        ],
        'evaluatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw _map(e);
    }
  }

  // ---------------- Admin: nhân viên ----------------
  @override
  Stream<List<StaffMember>> watchStaff() => _guard(
    _db
        .collection('users')
        .where('role', isEqualTo: 'viewer')
        .snapshots()
        .map(
          (s) => s.docs.where((d) => d.data()['disabled'] != true).map((d) {
            final x = d.data();
            final email = (x['email'] as String?) ?? '';
            final name = (x['displayName'] as String?)?.trim();
            return StaffMember(
              uid: d.id,
              displayName: (name == null || name.isEmpty)
                  ? (email.isEmpty ? 'Chưa cập nhật' : email.split('@').first)
                  : name,
              email: email,
              storeBranch: x['storeBranch'] as String?,
              title: x['title'] as String?,
            );
          }).toList()..sort((a, b) => a.displayName.compareTo(b.displayName)),
        ),
  );

  @override
  Future<Map<String, TaskProgress>> progressOf(String uid) async {
    try {
      final s = await _db.collection('users/$uid/taskProgress').get();
      return {for (final d in s.docs) d.id: progressFromDoc(d.id, d.data())};
    } catch (e) {
      throw _map(e);
    }
  }
}
