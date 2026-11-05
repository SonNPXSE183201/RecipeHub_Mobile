import 'package:flutter/material.dart';

/// Vai trò người dùng trên Mobile
enum UserRole {
  viewer, // Barista / Nhân viên pha chế tại quầy
  admin,  // Quản lý cửa hàng / Quản lý đào tạo
}

/// Trạng thái nhiệm vụ học
enum TaskStatus {
  notStarted,
  inProgress,
  completed,
}

/// Loại feedback
enum FeedbackType {
  inquiry,    // Hỏi cách làm
  issue,      // Báo vấn đề định lượng/thao tác
  suggestion, // Đề xuất thay đổi
}

/// Trạng thái feedback
enum FeedbackStatus {
  newFeedback,
  inProgress,
  waitingInfo,
  resolved,
  closed,
}

/// Nguyên liệu theo Size
class IngredientPortion {
  final String name;
  final double amount;
  final String unit;
  final String? note;
  final String? warning;

  const IngredientPortion({
    required this.name,
    required this.amount,
    required this.unit,
    this.note,
    this.warning,
  });
}

/// Biến thể Size của công thức
class RecipeSizeOption {
  final String sizeCode; // S, M, L
  final String label;    // Size Nhỏ (350ml), Size Vừa (500ml), Size Lớn (700ml)
  final List<IngredientPortion> ingredients;
  final String servingNotes;

  const RecipeSizeOption({
    required this.sizeCode,
    required this.label,
    required this.ingredients,
    required this.servingNotes,
  });
}

/// Bước pha chế chuẩn
class RecipeStepItem {
  final int stepNumber;
  final String title;
  final String instruction;
  final int videoStartSeconds;
  final int videoEndSeconds;
  final String? temperature;
  final String? durationText;
  final String? linkedSopId;
  final String? linkedSopTitle;

  const RecipeStepItem({
    required this.stepNumber,
    required this.title,
    required this.instruction,
    required this.videoStartSeconds,
    required this.videoEndSeconds,
    this.temperature,
    this.durationText,
    this.linkedSopId,
    this.linkedSopTitle,
  });
}

/// Công thức đồ uống hoàn chỉnh
class RecipeItem {
  final String id;
  final String code;
  final String name;
  final String category; // Cà phê, Trà sữa, Trà trái cây, Đá xay
  final String version;
  final String status;   // Ban hành
  final String publishedDate;
  final String publisher;
  final String description;
  final String standardTime;
  final String standardTemp;
  final bool hasNewerVersion;
  final String? newerVersionNotice;
  final List<RecipeSizeOption> sizes;
  final List<RecipeStepItem> steps;
  final String videoUrl;

  const RecipeItem({
    required this.id,
    required this.code,
    required this.name,
    required this.category,
    required this.version,
    required this.status,
    required this.publishedDate,
    required this.publisher,
    required this.description,
    required this.standardTime,
    required this.standardTemp,
    this.hasNewerVersion = false,
    this.newerVersionNotice,
    required this.sizes,
    required this.steps,
    required this.videoUrl,
  });
}

/// Bước trong SOP
class SopStepItem {
  final int stepNumber;
  final String title;
  final String content;
  final String? note;
  final IconData? icon;

  const SopStepItem({
    required this.stepNumber,
    required this.title,
    required this.content,
    this.note,
    this.icon,
  });
}

/// SOP Quy chuẩn kỹ thuật dùng chung
class SopItem {
  final String id;
  final String code;
  final String title;
  final String category; // Kỹ thuật pha chế, Vệ sinh máy móc, Bảo quản
  final String version;
  final String publishedDate;
  final String summary;
  final List<SopStepItem> steps;
  final List<String> linkedRecipeCodes;

  const SopItem({
    required this.id,
    required this.code,
    required this.title,
    required this.category,
    required this.version,
    required this.publishedDate,
    required this.summary,
    required this.steps,
    required this.linkedRecipeCodes,
  });
}

/// Nhiệm vụ học tập
class LearningTaskItem {
  final String id;
  final String title;
  final String type; // 'Công thức' hoặc 'SOP'
  final String targetCode;
  final String version;
  final String assignedBy;
  final String assignedDate;
  final String dueDate;
  final bool isOverdue;
  final bool isRelearnRequired;
  TaskStatus status;
  double progress; // 0.0 -> 1.0
  final List<String> sections;

  LearningTaskItem({
    required this.id,
    required this.title,
    required this.type,
    required this.targetCode,
    required this.version,
    required this.assignedBy,
    required this.assignedDate,
    required this.dueDate,
    this.isOverdue = false,
    this.isRelearnRequired = false,
    required this.status,
    required this.progress,
    required this.sections,
  });
}

/// Phản hồi của nhân viên
class FeedbackItemModel {
  final String id;
  final String senderName;
  final String senderRole;
  final String storeBranch;
  final FeedbackType type;
  final String content;
  final String targetName; // Tên món hoặc SOP
  final String targetCode;
  final String version;
  final String? stepNote;
  FeedbackStatus status;
  final String createdAt;
  final List<FeedbackReplyModel> replies;
  final String? attachmentUrl; // ảnh đính kèm đã upload lên Firebase Storage

  FeedbackItemModel({
    required this.id,
    required this.senderName,
    required this.senderRole,
    required this.storeBranch,
    required this.type,
    required this.content,
    required this.targetName,
    required this.targetCode,
    required this.version,
    this.stepNote,
    required this.status,
    required this.createdAt,
    required this.replies,
    this.attachmentUrl,
  });
}

class FeedbackReplyModel {
  final String senderName;
  final bool isAdmin;
  final String message;
  final String time;

  const FeedbackReplyModel({
    required this.senderName,
    required this.isAdmin,
    required this.message,
    required this.time,
  });
}

/// Phiên tự luyện với Timer
class SelfPracticeRecord {
  final String id;
  final String recipeName;
  final String recipeCode;
  final String size;
  final int durationSeconds;
  final String notes;
  final String practicedAt;
  final int targetSeconds; // 0 = chưa có chuẩn thời gian
  int get deviationSeconds => targetSeconds == 0 ? 0 : durationSeconds - targetSeconds;

  const SelfPracticeRecord({
    required this.id,
    required this.recipeName,
    required this.recipeCode,
    required this.size,
    required this.durationSeconds,
    required this.notes,
    required this.practicedAt,
    this.targetSeconds = 0,
  });
}

/// Câu hỏi Quiz
class QuizQuestionModel {
  final int id;
  final String question;
  final List<String> options;
  final int correctOptionIndex;
  final String explanation;
  final String reviewSection;

  const QuizQuestionModel({
    required this.id,
    required this.question,
    required this.options,
    required this.correctOptionIndex,
    required this.explanation,
    required this.reviewSection,
  });
}

/// Tiêu chí đánh giá thực hành
class EvaluationCriterion {
  final String id;
  final String name;
  final String standardRequirement;
  bool isPassed;
  final bool isCrucial; // Tiêu chí bắt buộc
  String? notes;

  EvaluationCriterion({
    required this.id,
    required this.name,
    required this.standardRequirement,
    this.isPassed = false,
    this.isCrucial = false,
    this.notes,
  });
}

/// Đánh giá thực hành tại quầy
class PracticalEvaluationRecord {
  final String id;
  final String traineeName;
  final String storeBranch;
  final String evaluatorName;
  final String recipeCode;
  final String recipeName;
  final String version;
  final String evaluatedDate;
  bool isPassed;
  String overallComment;
  String relearnPlan;
  final List<EvaluationCriterion> criteria;

  PracticalEvaluationRecord({
    required this.id,
    required this.traineeName,
    required this.storeBranch,
    required this.evaluatorName,
    required this.recipeCode,
    required this.recipeName,
    required this.version,
    required this.evaluatedDate,
    required this.isPassed,
    required this.overallComment,
    required this.relearnPlan,
    required this.criteria,
  });
}

