import 'package:flutter/material.dart';
import 'package:recipehub_mobile/core/models/app_models.dart';
import 'package:recipehub_mobile/core/models/training_models.dart';
import 'package:recipehub_mobile/core/services/mock/mock_training_repository.dart';

/// Dữ liệu đào tạo dùng cho test, KHÔNG nằm trong app.
const testSop = SopItem(
  id: 'sop-doc-1',
  code: 'SOP-VS-01',
  title: 'Vệ sinh máy pha',
  category: 'Vệ sinh máy móc',
  version: 'v1.0',
  publishedDate: '01/11/2026',
  summary: 'Quy trình vệ sinh máy pha cuối ca.',
  steps: [
    SopStepItem(
      stepNumber: 1,
      title: 'Xả nước',
      content: 'Xả nước nóng 30 giây.',
      icon: Icons.water_drop_rounded,
    ),
  ],
  linkedRecipeCodes: ['RC-OOL-02'],
);

const testSop2 = SopItem(
  id: 'sop-doc-2',
  code: 'SOP-PC-02',
  title: 'Kỹ thuật lắc trà',
  category: 'Kỹ thuật pha chế',
  version: 'v1.1',
  publishedDate: '02/11/2026',
  summary: 'Lắc đều 12 nhịp.',
  steps: [],
  linkedRecipeCodes: [],
);

LearningTaskItem testTask() => LearningTaskItem(
  id: 'task-doc-1',
  title: 'Học vệ sinh máy pha',
  type: 'SOP',
  targetCode: 'SOP-VS-01',
  version: 'v1.0',
  assignedBy: 'Quản lý',
  assignedDate: '01/11/2026',
  dueDate: '10/11/2026',
  status: TaskStatus.notStarted,
  progress: 0,
  sections: const ['Đọc quy trình', 'Xem video'],
);

const testQuiz = QuizSet(
  id: 'quiz-doc-1',
  title: 'Quiz vệ sinh máy',
  targetCode: 'SOP-VS-01',
  questions: [
    QuizQuestionView(
      id: 'q1',
      text: 'Xả nước bao lâu?',
      options: ['10 giây', '30 giây'],
      reviewSection: 'Bước 1',
    ),
    QuizQuestionView(
      id: 'q2',
      text: 'Nhiệt độ nước?',
      options: ['Lạnh', 'Nóng'],
      reviewSection: 'Bước 2',
    ),
  ],
);

const testQuizKey = QuizAnswerKey(
  correct: [1, 1],
  explanations: ['Xả 30 giây.', 'Dùng nước nóng.'],
);

MockTrainingRepository testTrainingRepo() => MockTrainingRepository(
  sops: const [testSop, testSop2],
  tasks: [testTask()],
  quizzes: const [testQuiz],
  keys: const {'quiz-doc-1': testQuizKey},
);
