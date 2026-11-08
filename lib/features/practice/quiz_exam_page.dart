import '../../core/widgets/personal_learning_blocked.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/training_models.dart';
import '../../core/services/interfaces/i_training_repository.dart';
import '../../core/theme/nomad_kit.dart';
import '../../core/viewmodels/auth_viewmodel.dart';
import '../../core/viewmodels/training_viewmodel.dart';
import '../../core/widgets/load_state_view.dart';

class QuizExamPage extends StatefulWidget {
  const QuizExamPage({super.key, this.quiz});

  /// Bộ đề cần làm; null → người dùng chọn từ danh sách bộ đề.
  final QuizSet? quiz;

  @override
  State<QuizExamPage> createState() => _QuizExamPageState();
}

class _QuizExamPageState extends State<QuizExamPage> {
  final Map<int, int> _userAnswers = {};
  QuizSet? _picked;
  QuizAnswerKey? _key;
  QuizAttempt? _attempt;
  bool _submitting = false;

  bool get _isSubmitted => _attempt != null;

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context)
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

  PreferredSizeWidget _appBar() => AppBar(
    backgroundColor: NomadKit.canvas,
    elevation: 0,
    leading: IconButton(
      icon: const Icon(
        Icons.arrow_back_ios_new_rounded,
        size: 18,
        color: NomadKit.ink,
      ),
      onPressed: () => Navigator.pop(context),
    ),
    title: const Text(
      'Bài kiểm tra kiến thức (Quiz)',
      style: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: NomadKit.ink,
      ),
    ),
  );

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
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Chọn bộ đề',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: NomadKit.ink,
            ),
          ),
          const SizedBox(height: 10),
          for (final q in training.quizzes)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: NomadKit.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: NomadKit.border),
                ),
                child: ListTile(
                  minVerticalPadding: 14,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: Text(
                    q.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: NomadKit.ink,
                    ),
                  ),
                  subtitle: Text(
                    '${q.questions.length} câu',
                    style: const TextStyle(
                      fontSize: 12,
                      color: NomadKit.secondary,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: NomadKit.sandDark,
                  ),
                  onTap: () => setState(() => _picked = q),
                ),
              ),
            ),
        ],
      );
    }
    return Scaffold(
      backgroundColor: NomadKit.canvas,
      appBar: _appBar(),
      body: SafeArea(child: content),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!context.watch<AuthViewModel>().hasPersonalLearning) {
      return const PersonalLearningBlocked();
    }
    final training = context.watch<TrainingViewModel>();
    if (training.attemptsState != LoadState.ready) {
      return Scaffold(
        backgroundColor: NomadKit.canvas,
        appBar: _appBar(),
        body: SafeArea(
          child: training.attemptsState == LoadState.error
              ? LoadStateView.error(
                  message: training.error ?? 'Không tải được lịch sử làm bài.',
                  onRetry: training.retry,
                )
              : const LoadStateView.loading(
                  message: 'Đang tải lịch sử làm bài...',
                ),
        ),
      );
    }
    final quiz = widget.quiz ?? _picked;
    if (quiz == null) return _picker(training);

    final questions = quiz.questions;
    if (questions.isEmpty) {
      return Scaffold(
        backgroundColor: NomadKit.canvas,
        appBar: _appBar(),
        body: const SafeArea(
          child: LoadStateView.empty(
            message: 'Bộ đề này chưa có câu hỏi.',
            icon: Icons.quiz_outlined,
          ),
        ),
      );
    }

    final key = _key;
    final correctCount = _attempt?.score ?? 0;
    bool isCorrect(int i) =>
        key != null &&
        i < key.correct.length &&
        _userAnswers[i] == key.correct[i];
    final isPassed = correctCount >= (questions.length * 0.7);

    return Scaffold(
      backgroundColor: NomadKit.canvas,
      appBar: _appBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Result Card if Submitted
              if (_isSubmitted) ...[
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isPassed
                        ? NomadKit.forestLight
                        : const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isPassed ? NomadKit.forest : NomadKit.error,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        isPassed
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        color: isPassed ? NomadKit.forest : NomadKit.error,
                        size: 44,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isPassed
                            ? 'KẾT QUẢ: ĐẠT YÊU CẦU LÝ THUYẾT'
                            : 'KẾT QUẢ: CHƯA ĐẠT · CẦN ÔN TẬP',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: isPassed ? NomadKit.forest : NomadKit.error,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Điểm số của bạn: $correctCount / ${questions.length} câu đúng',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: NomadKit.ink,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: NomadKit.ink,
                          side: const BorderSide(color: NomadKit.border),
                          minimumSize: const Size(0, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _retryQuiz,
                        child: const Text(
                          'Làm lại bài kiểm tra',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ] else ...[
                // Intro Header
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: NomadKit.sandLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: NomadKit.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.quiz_rounded,
                        color: NomadKit.sandDark,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${quiz.title}: ${questions.length} câu trắc nghiệm theo tiêu chuẩn ban hành.',
                          style: const TextStyle(
                            fontSize: 12,
                            color: NomadKit.ink,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Question Cards
              ...List.generate(questions.length, (qIdx) {
                final q = questions[qIdx];
                final selectedOption = _userAnswers[qIdx];

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: NomadKit.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: NomadKit.border),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x06000000),
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: NomadKit.oceanLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Câu ${qIdx + 1}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: NomadKit.ocean,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (_isSubmitted)
                            Text(
                              isCorrect(qIdx) ? '✓ Đúng' : '✗ Sai',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: isCorrect(qIdx)
                                    ? NomadKit.forest
                                    : NomadKit.error,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      Text(
                        q.text,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: NomadKit.ink,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Options
                      ...List.generate(q.options.length, (optIdx) {
                        final isChosen = selectedOption == optIdx;
                        Color optBorder = NomadKit.border;
                        Color optBg = NomadKit.canvas;

                        if (_isSubmitted) {
                          if (key != null &&
                              qIdx < key.correct.length &&
                              optIdx == key.correct[qIdx]) {
                            optBg = NomadKit.forestLight;
                            optBorder = NomadKit.forest;
                          } else if (isChosen) {
                            optBg = const Color(0xFFFEE2E2);
                            optBorder = NomadKit.error;
                          }
                        } else if (isChosen) {
                          optBg = NomadKit.sandLight;
                          optBorder = NomadKit.sand;
                        }

                        return GestureDetector(
                          onTap: _isSubmitted || _submitting
                              ? null
                              : () =>
                                    setState(() => _userAnswers[qIdx] = optIdx),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: optBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: optBorder,
                                width: isChosen ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  '${String.fromCharCode(65 + optIdx)}.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: isChosen
                                        ? NomadKit.sandDark
                                        : NomadKit.secondary,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    q.options[optIdx],
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isChosen
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: NomadKit.ink,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),

                      // Explanation if Submitted
                      if (_isSubmitted) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: NomadKit.sandLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Image.asset(
                                    'assets/icons/icon_sparkle_ai.png',
                                    width: 14,
                                    height: 14,
                                    filterQuality: FilterQuality.medium,
                                    errorBuilder: (ctx, err, stack) =>
                                        const Icon(
                                          Icons.lightbulb_outline_rounded,
                                          size: 14,
                                          color: NomadKit.sandDark,
                                        ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'GIẢI THÍCH CHI TIẾT:',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: NomadKit.sandDark,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                key != null && qIdx < key.explanations.length
                                    ? key.explanations[qIdx]
                                    : '',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: NomadKit.ink,
                                  height: 1.35,
                                ),
                              ),
                              if (q.reviewSection.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'Tài liệu ôn tập: ${q.reviewSection}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                    color: NomadKit.ocean,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }),

              // Submit Button
              if (!_isSubmitted) ...[
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: NomadKit.sand,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _submitting ? null : () => _submitQuiz(quiz),
                    child: _submitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Nộp bài kiểm tra',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
