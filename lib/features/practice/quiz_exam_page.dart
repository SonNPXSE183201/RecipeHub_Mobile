import '../../core/widgets/personal_learning_blocked.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/training_models.dart';
import '../../core/services/interfaces/i_training_repository.dart';
import '../../core/theme/nomad_kit.dart';
import '../../core/viewmodels/auth_viewmodel.dart';
import '../../core/viewmodels/training_viewmodel.dart';
import '../../core/widgets/load_state_view.dart';
import '../../core/widgets/redesign_widgets.dart';
import '../../core/widgets/app_toast.dart';

class QuizExamPage extends StatefulWidget {
  const QuizExamPage({super.key, this.quiz});

  /// Bộ đề cần làm; null → người dùng chọn từ danh sách bộ đề.
  final QuizSet? quiz;

  @override
  State<QuizExamPage> createState() => _QuizExamPageState();
}

class _QuizExamPageState extends State<QuizExamPage> {
  static const _title = 'Kiểm tra kiến thức';

  final Map<int, int> _userAnswers = {};
  QuizSet? _picked;
  QuizAnswerKey? _key;
  QuizAttempt? _attempt;
  bool _submitting = false;

  bool get _isSubmitted => _attempt != null;

  void _snack(String msg, Color color) {
    ToastMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  Future<void> _submitQuiz(QuizSet quiz) async {
    if (_submitting) return;
    final questions = quiz.questions;
    if (_userAnswers.length < questions.length) {
      _snack(
        'Vui lòng trả lời đầy đủ tất cả câu hỏi trước khi nộp bài.',
        NomadKit.warning,
      );
      return;
    }
    final vm = context.read<TrainingViewModel>();
    final name = context.read<AuthViewModel>().displayName;
    setState(() => _submitting = true);
    try {
      final answers = [
        for (var i = 0; i < questions.length; i++) _userAnswers[i]!,
      ];
      final (key, attempt) = await vm.submitQuiz(quiz, answers, userName: name);
      if (!mounted) return;
      setState(() {
        _key = key;
        _attempt = attempt;
        _submitting = false;
      });
    } on TrainingFailure catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _snack(e.message, NomadKit.error);
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _snack('Không nộp được bài. Vui lòng thử lại.', NomadKit.error);
    }
  }

  void _retryQuiz() {
    setState(() {
      _userAnswers.clear();
      _key = null;
      _attempt = null;
    });
  }

  Widget _stateScaffold(Widget body) =>
      RhFlowScaffold(title: _title, body: body);

  Widget _picker(TrainingViewModel training) {
    final Widget content;
    if (training.quizState == LoadState.loading && training.quizzes.isEmpty) {
      content = const LoadStateView.loading();
    } else if (training.quizState == LoadState.error &&
        training.quizzes.isEmpty) {
      content = LoadStateView.error(
        message: training.error ?? 'Không tải được bộ đề quiz.',
        onRetry: training.retry,
      );
    } else if (training.quizzes.isEmpty) {
      content = const LoadStateView.empty(
        message: 'Chưa có bộ đề quiz nào được phát hành.',
        icon: Icons.quiz_outlined,
      );
    } else {
      content = ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          const Text('Chọn bộ đề', style: NomadKit.title),
          const SizedBox(height: 14),
          for (final q in training.quizzes)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => setState(() => _picked = q),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                  decoration: _cardDecoration,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              q.title,
                              style: NomadKit.body.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${q.questions.length} câu',
                              style: NomadKit.caption,
                            ),
                          ],
                        ),
                      ),
                      const RhChevron(),
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
    }
    return _stateScaffold(content);
  }

  static final _cardDecoration = BoxDecoration(
    color: NomadKit.surface,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: NomadKit.border),
  );

  @override
  Widget build(BuildContext context) {
    if (!context.watch<AuthViewModel>().hasPersonalLearning) {
      return const PersonalLearningBlocked();
    }
    final training = context.watch<TrainingViewModel>();
    if (training.attemptsState != LoadState.ready) {
      return _stateScaffold(
        training.attemptsState == LoadState.error
            ? LoadStateView.error(
                message: training.error ?? 'Không tải được lịch sử làm bài.',
                onRetry: training.retry,
              )
            : const LoadStateView.loading(
                message: 'Đang tải lịch sử làm bài...',
              ),
      );
    }
    final quiz = widget.quiz ?? _picked;
    if (quiz == null) return _picker(training);

    final questions = quiz.questions;
    if (questions.isEmpty) {
      return _stateScaffold(
        const LoadStateView.empty(
          message: 'Bộ đề này chưa có câu hỏi.',
          icon: Icons.quiz_outlined,
        ),
      );
    }
    return _isSubmitted ? _buildResult(quiz) : _buildExam(quiz);
  }

  Widget _buildExam(QuizSet quiz) {
    final questions = quiz.questions;
    return RhFlowScaffold(
      title: _title,
      bottomAction: RhPrimaryButton(
        label: _submitting ? 'Đang nộp bài...' : 'Nộp bài',
        icon: null,
        onPressed: _submitting ? null : () => _submitQuiz(quiz),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bài kiểm tra kiến thức', style: NomadKit.title),
            const SizedBox(height: 12),
            Text(
              '${quiz.title} · ${questions.length} câu hỏi',
              style: NomadKit.label.copyWith(fontWeight: FontWeight.w400),
            ),
            const SizedBox(height: 16),
            for (var qIdx = 0; qIdx < questions.length; qIdx++)
              _questionCard(questions[qIdx], qIdx),
          ],
        ),
      ),
    );
  }

  Widget _questionCard(QuizQuestionView q, int qIdx) {
    final selected = _userAnswers[qIdx];
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Câu ${qIdx + 1}', style: NomadKit.caption),
          const SizedBox(height: 2),
          Text(q.text, style: NomadKit.subtitle),
          const SizedBox(height: 12),
          for (var optIdx = 0; optIdx < q.options.length; optIdx++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _option(
                text: q.options[optIdx],
                chosen: selected == optIdx,
                onTap: _submitting
                    ? null
                    : () => setState(() => _userAnswers[qIdx] = optIdx),
              ),
            ),
        ],
      ),
    );
  }

  Widget _option({
    required String text,
    required bool chosen,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: chosen ? NomadKit.sandLight : NomadKit.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: chosen ? NomadKit.sandDark : NomadKit.border,
            width: chosen ? 1.5 : 1,
          ),
        ),
        child: Text(
          text,
          style: NomadKit.label.copyWith(
            fontWeight: chosen ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildResult(QuizSet quiz) {
    final questions = quiz.questions;
    final key = _key;
    final score = _attempt?.score ?? 0;
    final passed = score >= (questions.length * 0.7);
    bool isCorrect(int i) =>
        key != null &&
        i < key.correct.length &&
        _userAnswers[i] == key.correct[i];
    return RhFlowScaffold(
      title: _title,
      bottomAction: RhPrimaryButton(
        label: 'Làm lại bài kiểm tra',
        icon: null,
        onPressed: _retryQuiz,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'KẾT QUẢ BÀI KIỂM TRA',
              style: NomadKit.caption.copyWith(
                color: NomadKit.sandDark,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 8),
            Text('$score/${questions.length} câu đúng', style: NomadKit.title),
            const SizedBox(height: 8),
            Text(
              passed
                  ? 'Đạt yêu cầu lý thuyết. Xem lại giải thích rồi thử pha một ly theo đúng quy trình.'
                  : 'Chưa đạt, cần ôn tập. Xem lại giải thích rồi làm lại bài kiểm tra.',
              style: NomadKit.label.copyWith(
                color: NomadKit.secondary,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 20),
            for (var i = 0; i < questions.length; i++)
              _resultCard(questions[i], i, correct: isCorrect(i), key: key),
          ],
        ),
      ),
    );
  }

  Widget _resultCard(
    QuizQuestionView q,
    int i, {
    required bool correct,
    required QuizAnswerKey? key,
  }) {
    final explanation = key != null && i < key.explanations.length
        ? key.explanations[i]
        : '';
    final correctIdx = key != null && i < key.correct.length
        ? key.correct[i]
        : null;
    final chosenIdx = _userAnswers[i];
    String optionText(int? idx) =>
        idx != null && idx >= 0 && idx < q.options.length ? q.options[idx] : '';
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Câu ${i + 1} · ${correct ? 'Đúng' : 'Cần xem lại'}',
            style: NomadKit.label.copyWith(
              fontWeight: FontWeight.w600,
              color: correct ? NomadKit.forest : NomadKit.sandDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            q.text,
            style: NomadKit.label.copyWith(fontWeight: FontWeight.w500),
          ),
          if (!correct) ...[
            const SizedBox(height: 4),
            Text(
              'Bạn chọn: ${optionText(chosenIdx)}',
              style: NomadKit.caption.copyWith(color: NomadKit.error),
            ),
            Text(
              'Đáp án đúng: ${optionText(correctIdx)}',
              style: NomadKit.caption.copyWith(color: NomadKit.forest),
            ),
          ],
          if (explanation.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              explanation,
              style: NomadKit.label.copyWith(fontWeight: FontWeight.w400),
            ),
          ],
          if (q.reviewSection.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Tài liệu ôn tập: ${q.reviewSection}',
              style: NomadKit.caption.copyWith(fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }
}
