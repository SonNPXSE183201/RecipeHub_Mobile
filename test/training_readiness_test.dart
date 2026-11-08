import 'package:flutter_test/flutter_test.dart';
import 'package:recipehub_mobile/core/models/training_models.dart';
import 'package:recipehub_mobile/core/services/interfaces/i_training_repository.dart';
import 'package:recipehub_mobile/core/services/mock/mock_crash_reporter.dart';
import 'package:recipehub_mobile/core/viewmodels/training_viewmodel.dart';

import 'support/deferred_training_repository.dart';
import 'support/training_fixtures.dart';

Future<void> flushStreams() => Future<void>.delayed(Duration.zero);

void main() {
  late DeferredTrainingRepository repo;
  late TrainingViewModel vm;
  late MockCrashReporter crash;
  final task = testTask();
  final saved = TaskProgress(
    taskId: task.id,
    completedSections: const [0],
    totalSections: task.sections.length,
  );

  setUp(() {
    repo = DeferredTrainingRepository();
    repo.progress['u1'] = {task.id: saved};
    crash = MockCrashReporter();
    vm = TrainingViewModel(repo: repo, crash: crash)..bind('u1');
  });

  tearDown(() async {
    vm.dispose();
    await repo.progressStream.close();
    await repo.attemptsStream.close();
  });

  test('Không ghi đè mục đã học trước snapshot tiến độ đầu tiên', () async {
    await flushStreams();
    expect(vm.progressState, LoadState.loading);
    expect(vm.attemptsState, LoadState.loading);
    expect(
      await vm.toggleSection(task, 1, true),
      'Đang tải tiến độ. Vui lòng đợi trước khi lưu.',
    );
    expect(repo.progressWrites, 0);
    expect(repo.progress['u1']![task.id]!.completedSections, [0]);
    expect(await vm.completeAll(task), isNotNull);
    expect(repo.progressWrites, 0);
  });

  test('Snapshot tiến độ cho phép ghi và giữ mục đã học', () async {
    repo.progressStream.add({task.id: saved});
    await flushStreams();
    expect(vm.progressState, LoadState.ready);
    expect(await vm.toggleSection(task, 1, true), isNull);
    expect(repo.progress['u1']![task.id]!.completedSections, [0, 1]);
  });

  test(
    'Lỗi tiến độ chặn ghi cả khi đã có snapshot, phục hồi khi có dữ liệu',
    () async {
      repo.progressStream.add({task.id: saved});
      await flushStreams();
      repo.progressStream.addError(
        const TrainingFailure('Không tải được tiến độ.'),
      );
      await flushStreams();
      expect(vm.error, 'Không tải được tiến độ.');
      expect(vm.progressState, LoadState.error);
      expect(crash.recordedErrors, hasLength(1));
      expect(
        await vm.toggleSection(task, 1, true),
        'Không tải được tiến độ. Vui lòng thử lại trước khi lưu.',
      );
      expect(await vm.completeAll(task), isNotNull);
      expect(repo.progressWrites, 0);
      repo.progressStream.add({task.id: saved});
      await flushStreams();
      expect(await vm.completeAll(task), isNull);
      expect(repo.progress['u1']![task.id]!.completedSections, [0, 1]);
    },
  );

  test('Snapshot rỗng hợp lệ cho phép đánh dấu mục đầu tiên', () async {
    repo.progressStream.add({});
    await flushStreams();
    expect(await vm.toggleSection(task, 1, true), isNull);
    expect(repo.progressWrites, 1);
  });

  test('Không nộp quiz trước snapshot lịch sử hoặc khi stream lỗi', () async {
    await expectLater(
      () => vm.submitQuiz(testQuiz, [1, 1], userName: 'Nhân viên'),
      throwsA(isA<TrainingFailure>()),
    );
    expect(repo.quizWrites, 0);
    repo.attemptsStream.add([]);
    await flushStreams();
    expect(vm.attemptsState, LoadState.ready);
    repo.attemptsStream.addError(StateError('offline'));
    await flushStreams();
    expect(vm.error, isNotNull);
    expect(vm.attemptsState, LoadState.error);
    await expectLater(
      () => vm.submitQuiz(testQuiz, [1, 1], userName: 'Nhân viên'),
      throwsA(isA<TrainingFailure>()),
    );
    expect(repo.quizWrites, 0);
    repo.attemptsStream.add([]);
    await flushStreams();
    expect(vm.attemptsState, LoadState.ready);
    await vm.submitQuiz(testQuiz, [1, 1], userName: 'Nhân viên');
    expect(repo.quizWrites, 1);
  });

  test('Tính lượt nộp tiếp theo từ snapshot, kể cả lịch sử rỗng', () async {
    repo.attemptsStream.add([]);
    await flushStreams();
    final (_, first) = await vm.submitQuiz(testQuiz, [
      1,
      1,
    ], userName: 'Nhân viên');
    expect(first.attemptNo, 1);
    repo.attemptsStream.add([first]);
    await flushStreams();
    final (_, second) = await vm.submitQuiz(testQuiz, [
      1,
      1,
    ], userName: 'Nhân viên');
    expect(second.attemptNo, 2);
  });

  for (final reset in ['retry', 'clear', 'bind']) {
    test('$reset yêu cầu snapshot mới trước khi ghi', () async {
      repo.progressStream.add({task.id: saved});
      repo.attemptsStream.add([]);
      await flushStreams();
      switch (reset) {
        case 'retry':
          vm.retry();
        case 'clear':
          vm.clear();
          vm.bind('u1');
        case 'bind':
          vm.bind('u2');
      }
      expect(vm.progressState, LoadState.loading);
      expect(vm.attemptsState, LoadState.loading);
      expect(await vm.toggleSection(task, 1, true), isNotNull);
      expect(await vm.completeAll(task), isNotNull);
      await expectLater(
        () => vm.submitQuiz(testQuiz, [1, 1], userName: 'Nhân viên'),
        throwsA(isA<TrainingFailure>()),
      );
      expect(repo.progressWrites, 0);
      expect(repo.quizWrites, 0);
    });
  }
}
