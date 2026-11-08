import 'dart:async';

import 'package:recipehub_mobile/core/models/training_models.dart';
import 'package:recipehub_mobile/core/services/mock/mock_training_repository.dart';

class DeferredTrainingRepository extends MockTrainingRepository {
  final progressStream =
      StreamController<Map<String, TaskProgress>>.broadcast();
  final attemptsStream = StreamController<List<QuizAttempt>>.broadcast();
  int progressWrites = 0;
  int quizWrites = 0;

  @override
  Stream<Map<String, TaskProgress>> watchProgress(String uid) =>
      progressStream.stream;

  @override
  Stream<List<QuizAttempt>> watchMyAttempts(String uid) =>
      attemptsStream.stream;

  @override
  Future<void> setSectionDone({
    required String uid,
    required String taskId,
    required int sectionIndex,
    required int totalSections,
    required bool done,
    required List<int> current,
  }) {
    progressWrites++;
    return super.setSectionDone(
      uid: uid,
      taskId: taskId,
      sectionIndex: sectionIndex,
      totalSections: totalSections,
      done: done,
      current: current,
    );
  }

  @override
  Future<(QuizAnswerKey, QuizAttempt)> submitQuiz({
    required String uid,
    required String userName,
    required QuizSet quiz,
    required List<int> answers,
    required int attemptNo,
  }) {
    quizWrites++;
    return super.submitQuiz(
      uid: uid,
      userName: userName,
      quiz: quiz,
      answers: answers,
      attemptNo: attemptNo,
    );
  }
}
