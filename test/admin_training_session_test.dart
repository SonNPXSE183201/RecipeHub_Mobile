import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:recipehub_mobile/core/di/app_services.dart';
import 'package:recipehub_mobile/core/models/app_models.dart';
import 'package:recipehub_mobile/core/models/training_models.dart';
import 'package:recipehub_mobile/core/services/interfaces/i_training_repository.dart';
import 'package:recipehub_mobile/core/services/mock/mock_crash_reporter.dart';
import 'package:recipehub_mobile/core/services/mock/mock_training_repository.dart';
import 'package:recipehub_mobile/core/viewmodels/app_config_viewmodel.dart';
import 'package:recipehub_mobile/core/viewmodels/auth_viewmodel.dart';
import 'package:recipehub_mobile/core/viewmodels/notification_viewmodel.dart';
import 'package:recipehub_mobile/core/viewmodels/practice_history_viewmodel.dart';
import 'package:recipehub_mobile/core/viewmodels/recipe_viewmodel.dart';
import 'package:recipehub_mobile/core/viewmodels/storage_viewmodel.dart';
import 'package:recipehub_mobile/core/viewmodels/training_viewmodel.dart';
import 'package:recipehub_mobile/features/auth/auth_gate.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_recipe_source.dart';
import 'support/training_fixtures.dart';

const _member = StaffMember(
  uid: 'staff',
  displayName: 'Staff',
  email: 's@test.vn',
);
const _completed = TaskProgress(
  taskId: 'task-doc-1',
  completedSections: [0, 1],
  totalSections: 2,
);

class _TrainingRepository extends MockTrainingRepository {
  final staffStream = StreamController<List<StaffMember>>.broadcast();
  final taskStream = StreamController<List<LearningTaskItem>>.broadcast();
  final evaluationStream =
      StreamController<List<PracticalEvaluationRecord>>.broadcast();
  final criteriaStream = StreamController<List<CriteriaTemplate>>.broadcast();
  final progressStreams =
      <String, List<StreamController<Map<String, TaskProgress>>>>{};
  bool delayProgress = false;
  int starts = 0;

  @override
  Stream<List<StaffMember>> watchStaff() {
    starts++;
    return staffStream.stream;
  }

  @override
  Stream<List<LearningTaskItem>> watchTasks() => taskStream.stream;

  @override
  Stream<List<PracticalEvaluationRecord>> watchAllEvaluations({
    int limit = 200,
  }) => evaluationStream.stream;

  @override
  Stream<List<CriteriaTemplate>> watchCriteriaTemplates() =>
      criteriaStream.stream;

  @override
  Stream<Map<String, TaskProgress>> watchProgress(String uid) {
    final controller = StreamController<Map<String, TaskProgress>>();
    (progressStreams[uid] ??= []).add(controller);
    if (!delayProgress) controller.add({'task-doc-1': _completed});
    return controller.stream;
  }

  void emitData() {
    staffStream.add([_member]);
    taskStream.add([testTask()]);
    evaluationStream.add([
      PracticalEvaluationRecord(
        id: 'evaluation',
        traineeUid: _member.uid,
        traineeName: 'Staff',
        storeBranch: 'Store',
        evaluatorName: 'Admin',
        recipeCode: 'recipe',
        recipeName: 'Recipe',
        version: '1',
        evaluatedDate: '08/11/2026',
        isPassed: true,
        overallComment: '',
        relearnPlan: '',
        criteria: [],
      ),
    ]);
    criteriaStream.add([
      const CriteriaTemplate(group: 'group', recipeCodes: [], criteria: []),
    ]);
  }

  void expectStopped() {
    expect(staffStream.hasListener, isFalse);
    expect(taskStream.hasListener, isFalse);
    expect(evaluationStream.hasListener, isFalse);
    expect(criteriaStream.hasListener, isFalse);
    for (final streams in progressStreams.values) {
      for (final stream in streams) {
        expect(stream.hasListener, isFalse);
      }
    }
  }

  Future<void> close() async {
    await Future.wait([
      staffStream.close(),
      taskStream.close(),
      evaluationStream.close(),
      criteriaStream.close(),
      for (final streams in progressStreams.values)
        for (final stream in streams) stream.close(),
    ]);
  }
}

// Keep recipes loading so these tests exercise AuthGate's session lifecycle.
class _LoadingRecipes extends RecipeViewModel {
  _LoadingRecipes(AppServices s) : super(source: s.recipes, crash: s.crash);

  @override
  Future<void> load({int limit = 50, bool silent = false}) async {}
}

class _SessionAuth extends AuthViewModel {
  _SessionAuth(AppServices s)
    : super(auth: s.auth, analytics: s.analytics, crash: s.crash);

  AuthStatus sessionStatus = AuthStatus.authenticated;
  UserRole grantedRole = UserRole.admin;

  @override
  AuthStatus get status => sessionStatus;

  @override
  UserRole get serverRole => grantedRole;

  void change({required AuthStatus status, required UserRole serverRole}) {
    sessionStatus = status;
    grantedRole = serverRole;
    notifyListeners();
  }
}

Future<void> _flush() => Future<void>.delayed(Duration.zero);

void main() {
  group('AdminTrainingViewModel session', () {
    late _TrainingRepository repo;
    late AdminTrainingViewModel vm;

    setUp(() {
      repo = _TrainingRepository();
      vm = AdminTrainingViewModel(repo: repo, crash: MockCrashReporter());
    });

    tearDown(() async {
      vm.dispose();
      await repo.close();
    });

    test('clear cancels all streams, erases privileged data and allows restart', () async {
      vm.start();
      vm.start();
      expect(repo.starts, 1);
      repo.emitData();
      await _flush();
      expect(vm.summaries.single.readingPercent, 100);
      expect(vm.evaluations, isNotEmpty);
      expect(vm.criteriaTemplates, isNotEmpty);
      repo.staffStream.addError(const TrainingFailure('Access denied'));
      await _flush();
      expect(vm.state, LoadState.error);

      var notifications = 0;
      vm.addListener(() => notifications++);
      vm.clear();
      repo.expectStopped();
      expect(notifications, 1);
      expect(vm.staff, isEmpty);
      expect(vm.summaries, isEmpty);
      expect(vm.evaluations, isEmpty);
      expect(vm.criteriaTemplates, isEmpty);
      expect(vm.error, isNull);
      expect(vm.state, LoadState.loading);

      repo.emitData();
      await _flush();
      expect(vm.staff, isEmpty);
      vm.clear(); // Safe when already stopped.
      repo.delayProgress = true;
      vm.start();
      expect(repo.starts, 2);
      repo.staffStream.add([_member]);
      await _flush();
      // Old tasks were cleared even though the new task stream has not emitted.
      expect(vm.summaries.single.readingPercent, 0);
      expect(vm.state, LoadState.ready);
      repo.taskStream.add([testTask()]);
      await _flush();
      // Old progress must also be gone before the new progress stream emits.
      expect(vm.summaries.single.readingPercent, 0);
      repo.progressStreams[_member.uid]!.last.add({});
      await _flush();
    });

    test(
      'pending progress is ignored after clear without restarting',
      () async {
        repo.delayProgress = true;
        vm.start();
        repo.emitData();
        await _flush();
        vm.clear();
        var notifications = 0;
        vm.addListener(() => notifications++);

        repo.progressStreams[_member.uid]!.single.add({
          'task-doc-1': _completed,
        });
        await _flush();
        expect(vm.staff, isEmpty);
        expect(vm.summaries, isEmpty);
        expect(vm.state, LoadState.loading);
        expect(notifications, 0);
        repo.expectStopped();
      },
    );

    test(
      'old progress cannot repopulate a cleared or restarted session',
      () async {
        repo.delayProgress = true;
        vm.start();
        repo.staffStream.add([
          _member,
          const StaffMember(
            uid: 'other',
            displayName: 'Other',
            email: 'o@test.vn',
          ),
        ]);
        await _flush();
        final oldProgress = repo.progressStreams[_member.uid]!.single;
        vm.clear();
        vm.start();
        repo.emitData();
        await _flush();
        repo.progressStreams[_member.uid]!.last.add({});
        await _flush();
        expect(vm.summaries.single.readingPercent, 0);

        oldProgress.add({'task-doc-1': _completed});
        await _flush();
        expect(vm.summaries.single.readingPercent, 0);
        expect(
          repo.progressStreams[_member.uid],
          hasLength(2),
          reason: 'Restart creates a fresh progress subscription',
        );
      },
    );

    test('retry while stopped does not reopen privileged streams', () {
      vm.clear();
      vm.retry();
      expect(repo.starts, 0);
      repo.expectStopped();
    });

    test('progress updates summaries without another staff event', () async {
      repo.delayProgress = true;
      vm.start();
      repo.emitData();
      await _flush();
      final progress = repo.progressStreams[_member.uid]!.single;
      var notifications = 0;
      vm.addListener(() => notifications++);

      progress.add({
        'task-doc-1': const TaskProgress(
          taskId: 'task-doc-1',
          completedSections: [0],
          totalSections: 2,
        ),
      });
      await _flush();
      expect(vm.summaries.single.readingPercent, 50);
      progress.add({'task-doc-1': _completed});
      await _flush();
      expect(vm.summaries.single.readingPercent, 100);
      progress.add({});
      await _flush();
      expect(vm.summaries.single.readingPercent, 0);
      expect(notifications, 3);
    });

    test(
      'staff changes retain, add and cancel progress subscriptions',
      () async {
        const other = StaffMember(
          uid: 'other',
          displayName: 'Other',
          email: 'other@test.vn',
        );
        vm.start();
        repo.emitData();
        await _flush();
        final original = repo.progressStreams[_member.uid]!.single;
        repo.staffStream.add([other, _member]);
        await _flush();
        expect(repo.progressStreams[_member.uid], hasLength(1));
        expect(original.hasListener, isTrue);
        expect(repo.progressStreams[other.uid]!.single.hasListener, isTrue);

        repo.staffStream.add([other]);
        await _flush();
        expect(original.hasListener, isFalse);
        original.add({'task-doc-1': _completed});
        repo.delayProgress = true;
        repo.staffStream.add([_member, other]);
        await _flush();
        expect(vm.summaries.first.readingPercent, 0);
        expect(repo.progressStreams[_member.uid], hasLength(2));
        repo.staffStream.add([]);
        await _flush();
        expect(vm.summaries, isEmpty);
        for (final streams in repo.progressStreams.values) {
          expect(streams.last.hasListener, isFalse);
        }
      },
    );

    test('retry replaces progress streams and dispose cancels them', () async {
      vm.start();
      repo.emitData();
      await _flush();
      final old = repo.progressStreams[_member.uid]!.single;
      vm.retry();
      expect(old.hasListener, isFalse);
      repo.emitData();
      await _flush();
      expect(repo.progressStreams[_member.uid], hasLength(2));
      // Use a separate instance so tearDown still owns the original VM.
      vm.clear();
      final disposable = AdminTrainingViewModel(
        repo: repo,
        crash: MockCrashReporter(),
      );
      disposable.start();
      repo.emitData();
      await _flush();
      disposable.dispose();
      repo.expectStopped();
    });

    test(
      'progress errors are reported and subsequent updates still arrive',
      () async {
        final crash = MockCrashReporter();
        vm.dispose();
        vm = AdminTrainingViewModel(repo: repo, crash: crash);
        vm.start();
        repo.emitData();
        await _flush();
        final progress = repo.progressStreams[_member.uid]!.single;
        const failure = TrainingFailure('Progress unavailable');
        progress.addError(failure, StackTrace.current);
        await _flush();
        expect(crash.recordedErrors, contains(failure));
        progress.add({});
        await _flush();
        expect(vm.summaries.single.readingPercent, 0);
      },
    );
  });

  for (final signOut in [true, false]) {
    testWidgets(
      'AuthGate clears Admin data on ${signOut ? 'logout' : 'role revocation'} and restarts',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final repo = _TrainingRepository();
        final services = AppServices.mock(
          recipes: FakeRecipeSource(),
          training: repo,
        );
        final auth = _SessionAuth(services);
        final admin = AdminTrainingViewModel(repo: repo, crash: services.crash);
        addTearDown(() async {
          admin.dispose();
          await repo.close();
        });
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthViewModel>(create: (_) => auth),
              ChangeNotifierProvider(
                create: (_) =>
                    AppConfigViewModel(service: services.remoteConfig),
              ),
              ChangeNotifierProvider<RecipeViewModel>(
                create: (_) => _LoadingRecipes(services),
              ),
              ChangeNotifierProvider(
                create: (_) => NotificationViewModel(
                  service: services.notifications,
                  crash: services.crash,
                  devices: services.devices,
                ),
              ),
              ChangeNotifierProvider(
                create: (_) =>
                    TrainingViewModel(repo: repo, crash: services.crash),
              ),
              ChangeNotifierProvider(
                create: (_) => PracticeHistoryViewModel(
                  store: services.practice,
                  crash: services.crash,
                ),
              ),
              ChangeNotifierProvider(
                create: (_) => StorageViewModel(
                  storage: services.storage,
                  picker: services.mediaPicker,
                  auth: services.auth,
                  analytics: services.analytics,
                  crash: services.crash,
                ),
              ),
              ChangeNotifierProvider.value(value: admin),
            ],
            child: const MaterialApp(home: AuthGate()),
          ),
        );
        repo.emitData();
        await tester.pump();
        expect(admin.staff, isNotEmpty);
        expect(repo.starts, 1);

        auth.change(
          status: signOut
              ? AuthStatus.unauthenticated
              : AuthStatus.authenticated,
          serverRole: UserRole.viewer,
        );
        await tester.pump();
        repo.expectStopped();
        expect(admin.staff, isEmpty);
        expect(admin.evaluations, isEmpty);
        expect(admin.criteriaTemplates, isEmpty);

        auth.change(
          status: AuthStatus.authenticated,
          serverRole: UserRole.admin,
        );
        await tester.pump();
        expect(repo.starts, 2);
        repo.emitData();
        await tester.pump();
        expect(admin.staff.single.uid, _member.uid);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
