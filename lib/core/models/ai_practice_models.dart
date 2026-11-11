enum RecallState {
  off,
  loading,
  waiting,
  question,
  feedback,
  exhausted,
  empty,
  error,
}

class RecallQuestion {
  RecallQuestion({
    required this.id,
    required this.prompt,
    required List<String> choices,
    required this.correctIndex,
    required this.explanation,
    required this.source,
  }) : choices = List.unmodifiable(choices);
  final String id;
  final String prompt;
  final List<String> choices;
  final int correctIndex;
  final String explanation;
  final String source;
}

class RecallContext {
  RecallContext({
    required this.recipeId,
    required this.recipeName,
    required this.revision,
    required List<RecallQuestion> questions,
    this.note = '',
  }) : questions = List.unmodifiable(questions);
  final String recipeId;
  final String recipeName;
  final String revision;
  final List<RecallQuestion> questions;
  final String note;
}
