import 'package:flutter/material.dart';
import '../../core/theme/nomad_kit.dart';
import '../../core/services/mock_data_service.dart';

class QuizExamPage extends StatefulWidget {
  const QuizExamPage({super.key});

  @override
  State<QuizExamPage> createState() => _QuizExamPageState();
}

class _QuizExamPageState extends State<QuizExamPage> {
  final Map<int, int> _userAnswers = {};
  bool _isSubmitted = false;

  void _submitQuiz() {
    final questions = MockDataService.instance.quizQuestions;
    if (_userAnswers.length < questions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng trả lời đầy đủ tất cả câu hỏi trước khi nộp bài.'),
          backgroundColor: NomadKit.warning,
        ),
      );
      return;
    }

    setState(() => _isSubmitted = true);
  }

  void _retryQuiz() {
    setState(() {
      _userAnswers.clear();
      _isSubmitted = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final questions = MockDataService.instance.quizQuestions;

    int correctCount = 0;
    if (_isSubmitted) {
      for (final q in questions) {
        if (_userAnswers[q.id] == q.correctOptionIndex) {
          correctCount++;
        }
      }
    }

    final isPassed = correctCount >= (questions.length * 0.7);

    return Scaffold(
      backgroundColor: NomadKit.canvas,
      appBar: AppBar(
        backgroundColor: NomadKit.canvas,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: NomadKit.ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Bài kiểm tra kiến thức (Quiz)',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: NomadKit.ink),
        ),
      ),
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
                    color: isPassed ? NomadKit.forestLight : const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isPassed ? NomadKit.forest : NomadKit.error),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        isPassed ? Icons.check_circle_rounded : Icons.cancel_rounded,
                        color: isPassed ? NomadKit.forest : NomadKit.error,
                        size: 44,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isPassed ? 'KẾT QUẢ: ĐẠT YÊU CẦU LÝ THUYẾT' : 'KẾT QUẢ: CHƯA ĐẠT · CẦN ÔN TẬP',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: isPassed ? NomadKit.forest : NomadKit.error,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Điểm số của bạn: $correctCount / ${questions.length} câu đúng',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: NomadKit.ink),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Nguyên tắc BR-01: Đạt bài kiểm tra kiến thức không tương đương đạt thực hành thao tác tại quầy bar.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: NomadKit.secondary, height: 1.35),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: NomadKit.ink,
                          side: const BorderSide(color: NomadKit.border),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _retryQuiz,
                        child: const Text('Làm lại bài kiểm tra', style: TextStyle(fontWeight: FontWeight.w700)),
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
                    children: const [
                      Icon(Icons.quiz_rounded, color: NomadKit.sandDark, size: 22),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Bộ câu hỏi gồm 3 câu trắc nghiệm kiểm tra định lượng, nhiệt độ và SOP kỹ thuật theo tiêu chuẩn ban hành.',
                          style: TextStyle(fontSize: 12, color: NomadKit.ink, height: 1.35),
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
                final selectedOption = _userAnswers[q.id];

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: NomadKit.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: NomadKit.border),
                    boxShadow: const [
                      BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: NomadKit.oceanLight, borderRadius: BorderRadius.circular(6)),
                            child: Text('Câu ${qIdx + 1}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: NomadKit.ocean)),
                          ),
                          const Spacer(),
                          if (_isSubmitted)
                            Text(
                              selectedOption == q.correctOptionIndex ? '✓ Đúng' : '✗ Sai',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: selectedOption == q.correctOptionIndex ? NomadKit.forest : NomadKit.error,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      Text(
                        q.question,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: NomadKit.ink, height: 1.35),
                      ),
                      const SizedBox(height: 12),

                      // Options
                      ...List.generate(q.options.length, (optIdx) {
                        final isChosen = selectedOption == optIdx;
                        Color optBorder = NomadKit.border;
                        Color optBg = NomadKit.canvas;

                        if (_isSubmitted) {
                          if (optIdx == q.correctOptionIndex) {
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
                          onTap: _isSubmitted
                              ? null
                              : () {
                                  setState(() => _userAnswers[q.id] = optIdx);
                                },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: optBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: optBorder, width: isChosen ? 1.5 : 1),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  '${String.fromCharCode(65 + optIdx)}.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: isChosen ? NomadKit.sandDark : NomadKit.secondary,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    q.options[optIdx],
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isChosen ? FontWeight.w700 : FontWeight.w500,
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
                                    errorBuilder: (ctx, err, stack) => const Icon(Icons.lightbulb_outline_rounded, size: 14, color: NomadKit.sandDark),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text('GIẢI THÍCH CHI TIẾT:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: NomadKit.sandDark)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(q.explanation, style: const TextStyle(fontSize: 12, color: NomadKit.ink, height: 1.35)),
                              const SizedBox(height: 6),
                              Text('Tài liệu ôn tập: ${q.reviewSection}', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: NomadKit.ocean)),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    onPressed: _submitQuiz,
                    child: const Text('Nộp bài kiểm tra', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
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
