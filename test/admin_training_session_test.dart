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
  final pendingProgress = <Completer<Map<String, TaskProgress>>>[];
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
  Future<Map<String, TaskProgress>> progressOf(String uid) {
    if (!delayProgress) return Future.value({'task-doc-1': _completed});
    final pending = Completer<Map<String, TaskProgress>>();
    pendingProgress.add(pending);
    return pending.future;
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
  }

  Future<void> close() async {
    await Future.wait([
      staffStream.close(),
      taskStream.close(),
      evaluationStream.close(),
      criteriaStream.close(),
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
      // Old progress must also be gone while the new request is pending.
      expect(vm.summaries.single.readingPercent, 0);
      repo.pendingProgress.single.complete({});
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

        repo.pendingProgress.single.complete({'task-doc-1': _completed});
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
        final oldProgress = repo.pendingProgress.single;
        vm.clear();
        vm.start();
        repo.emitData();
        await _flush();
        repo.pendingProgress.last.complete({});
        await _flush();
        expect(vm.summaries.single.readingPercent, 0);

        oldProgress.complete({'task-doc-1': _completed});
        await _flush();
        expect(vm.summaries.single.readingPercent, 0);
        expect(
          repo.pendingProgress,
          hasLength(2),
          reason: 'Do not fetch the next staff member from an expired session',
        );
      },
    );

    test('retry while stopped does not reopen privileged streams', () {
      vm.clear();
      vm.retry();
      expect(repo.starts, 0);
      repo.expectStopped();
    });
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
