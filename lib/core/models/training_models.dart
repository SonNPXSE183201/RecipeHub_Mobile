import 'package:flutter/material.dart';

import 'app_models.dart';

/// Bộ đề quiz – câu hỏi KHÔNG có đáp án (đáp án ở `quizzes/{id}/answerKey/key`, chỉ mở sau khi nộp).
class QuizSet {
  const QuizSet({
    required this.id,
    required this.title,
    required this.targetCode,
    required this.questions,
  });
  final String id;
  final String title;
  final String targetCode;
  final List<QuizQuestionView> questions;
}

class QuizQuestionView {
  const QuizQuestionView({
    required this.id,
    required this.text,
    required this.options,
    required this.reviewSection,
  });
  final String id;
  final String text;
  final List<String> options;
  final String reviewSection;
}

class QuizAnswerKey {
  const QuizAnswerKey({required this.correct, required this.explanations});
  final List<int> correct;
  final List<String> explanations;
}

/// Một lần nộp bài.
class QuizAttempt {
  const QuizAttempt({
    required this.quizId,
    required this.quizTitle,
    required this.attemptNo,
    required this.answers,
    required this.score,
    required this.total,
    this.submittedAt,
  });
  final String quizId;
  final String quizTitle;
  final int attemptNo;
  final List<int> answers;
  final int score;
  final int total;
  final DateTime? submittedAt;

  /// -1 = lần nộp đầu, điểm chỉ hiện ngay lúc nộp (đáp án mở sau khi bài đã ghi).
  bool get hasScore => score >= 0;
  double get ratio => total == 0 || score < 0 ? 0 : score / total;
}

/// Nhân viên (Barista) trong phạm vi Admin giám sát – từ `users/{uid}`.
class StaffMember {
  const StaffMember({
    required this.uid,
    required this.displayName,
    required this.email,
    this.storeBranch,
    this.title,
  });
  final String uid;
  final String displayName;
  final String email;
  final String? storeBranch;
  final String? title;
}

/// Tiến độ học của 1 nhiệm vụ cho 1 người.
class TaskProgress {
  const TaskProgress({
    required this.taskId,
    required this.completedSections,
    required this.totalSections,
  });
  final String taskId;
  final List<int> completedSections;
  final int totalSections;
  double get progress => totalSections == 0
      ? 0
      : (completedSections.length / totalSections).clamp(0, 1).toDouble();
  TaskStatus get status => completedSections.isEmpty
      ? TaskStatus.notStarted
      : (completedSections.length >= totalSections
            ? TaskStatus.completed
            : TaskStatus.inProgress);
}

/// Mẫu tiêu chí chấm thực hành theo nhóm món – `evaluationCriteria/{group}`.
class CriteriaTemplate {
  const CriteriaTemplate({
    required this.group,
    required this.recipeCodes,
    required this.criteria,
  });
  final String group;
  final List<String> recipeCodes;
  final List<EvaluationCriterion> criteria;
}

/// Tên icon (chuỗi trong Firestore) → IconData.
IconData sopIconOf(String? key) => switch (key) {
  'schedule' => Icons.schedule_rounded,
  'scale' => Icons.scale_rounded,
  'thermostat' => Icons.thermostat_rounded,
  'water_drop' => Icons.water_drop_rounded,
  'coffee_maker' => Icons.coffee_maker_rounded,
  'cleaning' => Icons.cleaning_services_rounded,
  'inventory' => Icons.inventory_2_rounded,
  'warning' => Icons.warning_amber_rounded,
  'checklist' => Icons.checklist_rounded,
  'local_drink' => Icons.local_drink_rounded,
  'ac_unit' => Icons.ac_unit_rounded,
  'timer' => Icons.timer_rounded,
  'filter' => Icons.filter_alt_rounded,
  'sync' => Icons.sync_rounded,
  'grain' => Icons.grain_rounded,
  'speed' => Icons.speed_rounded,
  'blender' => Icons.blender_rounded,
  'restaurant' => Icons.restaurant_rounded,
  _ => Icons.check_circle_outline_rounded,
};
