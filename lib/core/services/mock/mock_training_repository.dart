import 'dart:async';

import '../../models/app_models.dart';
import '../../models/training_models.dart';
import '../interfaces/i_training_repository.dart';

/// Bản trong bộ nhớ cho test / ARTEMIS khi không có Firebase. Rỗng mặc định; test tự nạp qua constructor.
class MockTrainingRepository implements ITrainingRepository {
  MockTrainingRepository({
    List<SopItem>? sops,
    List<LearningTaskItem>? tasks,
    List<QuizSet>? quizzes,
    Map<String, QuizAnswerKey>? keys,
    List<StaffMember>? staff,
    List<CriteriaTemplate>? criteria,
  }) : sops = [...?sops],
       tasks = [...?tasks],
       quizzes = [...?quizzes],
       keys = {...?keys},
       staff = [...?staff],
       criteria = [...?criteria];

  final List<SopItem> sops;
  final List<LearningTaskItem> tasks;
  final List<QuizSet> quizzes;
  final Map<String, QuizAnswerKey> keys;
  final List<StaffMember> staff;
  final List<CriteriaTemplate> criteria;
  final List<PracticalEvaluationRecord> evaluations = [];
  final Map<String, Map<String, TaskProgress>> progress = {};
  final Map<String, List<QuizAttempt>> attempts = {};
  final _changes = StreamController<void>.broadcast();

  void notifyChanged() => _changes.add(null);

  Stream<T> _watch<T>(T Function() read) async* {
    yield read();
    yield* _changes.stream.map((_) => read());
  }

  @override
  Stream<List<SopItem>> watchSops() => _watch(() => List.of(sops));

  @override
  Stream<List<LearningTaskItem>> watchTasks() => _watch(() => List.of(tasks));

  @override
  Stream<Map<String, TaskProgress>> watchProgress(String uid) =>
      _watch(() => Map.of(progress[uid] ?? const {}));

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
    (progress[uid] ??= {})[taskId] = TaskProgress(
      taskId: taskId,
      completedSections: next.toList()..sort(),
      totalSections: totalSections,
    );
    notifyChanged();
  }

  @override
  Stream<List<QuizSet>> watchQuizzes() => _watch(() => List.of(quizzes));

  @override
  Stream<List<QuizAttempt>> watchMyAttempts(String uid) =>
      _watch(() => List.of(attempts[uid] ?? const []));

  @override
  Future<(QuizAnswerKey, QuizAttempt)> submitQuiz({
    required String uid,
    required String userName,
    required QuizSet quiz,
    required List<int> answers,
    required int attemptNo,
  }) async {
    final key =
        keys[quiz.id] ?? const QuizAnswerKey(correct: [], explanations: []);
    var score = 0;
    for (var i = 0; i < answers.length && i < key.correct.length; i++) {
      if (answers[i] == key.correct[i]) score++;
    }
    final a = QuizAttempt(
      quizId: quiz.id,
      quizTitle: quiz.title,
      attemptNo: attemptNo,
      answers: answers,
      score: score,
      total: quiz.questions.length,
      submittedAt: DateTime.now(),
    );
    (attempts[uid] ??= []).insert(0, a);
    notifyChanged();
    return (key, a);
  }

  @override
  Stream<List<PracticalEvaluationRecord>> watchMyEvaluations(String uid) =>
      _watch(() => evaluations.where((e) => e.traineeUid == uid).toList());

  @override
  Stream<List<PracticalEvaluationRecord>> watchAllEvaluations({
    int limit = 200,
  }) => _watch(() => evaluations.take(limit).toList());

  @override
  Stream<List<CriteriaTemplate>> watchCriteriaTemplates() =>
      _watch(() => List.of(criteria));

  @override
  Future<void> saveEvaluation(
    PracticalEvaluationRecord record, {
    required String evaluatorUid,
  }) async {
    evaluations.insert(0, record);
    notifyChanged();
  }

  @override
  Stream<List<StaffMember>> watchStaff() => _watch(() => List.of(staff));

  @override
  Future<Map<String, TaskProgress>> progressOf(String uid) async =>
      Map.of(progress[uid] ?? const {});
}
