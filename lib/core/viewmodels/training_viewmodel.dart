import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/app_models.dart';
import '../models/training_models.dart';
import '../services/interfaces/i_crash_reporter.dart';
import '../services/interfaces/i_training_repository.dart';

/// Trạng thái tải của một nguồn dữ liệu.
enum LoadState { loading, ready, error }

/// Dữ liệu đào tạo của người đang đăng nhập (real-time): SOP, nhiệm vụ học + tiến độ, quiz + lịch sử,
/// kết quả chấm thực hành của mình. Sống ở cấp app; `bind(uid)` sau khi đăng nhập, `clear()` khi đăng xuất.
class TrainingViewModel extends ChangeNotifier {
  TrainingViewModel({required this._repo, required this._crash});

  final ITrainingRepository _repo;
  final ICrashReporter _crash;
  final List<StreamSubscription<dynamic>> _subs = [];
  bool _disposed = false;
  String? _uid;

  List<SopItem> _sops = const [];
  List<LearningTaskItem> _tasks = const [];
  Map<String, TaskProgress> _progress = const {};
  List<QuizSet> _quizzes = const [];
  List<QuizAttempt> _attempts = const [];
  List<PracticalEvaluationRecord> _evaluations = const [];

  LoadState _sopState = LoadState.loading;
  LoadState _taskState = LoadState.loading;
  LoadState _quizState = LoadState.loading;
  LoadState _evalState = LoadState.loading;
  String? _error;

  String? get uid => _uid;
  List<SopItem> get sops => _sops;
  LoadState get sopState => _sopState;
  LoadState get taskState => _taskState;
  LoadState get quizState => _quizState;
  LoadState get evaluationState => _evalState;
  String? get error => _error;
  List<QuizSet> get quizzes => _quizzes;
  List<QuizAttempt> get attempts => _attempts;
  List<PracticalEvaluationRecord> get myEvaluations => _evaluations;

  /// Nhiệm vụ đã ghép tiến độ của người dùng.
  List<LearningTaskItem> get tasks => _tasks.map((t) {
    final p = _progress[t.id];
    return LearningTaskItem(
      id: t.id,
      title: t.title,
      type: t.type,
      targetCode: t.targetCode,
      version: t.version,
      assignedBy: t.assignedBy,
      assignedDate: t.assignedDate,
      dueDate: t.dueDate,
      isOverdue: t.isOverdue && (p?.status != TaskStatus.completed),
      isRelearnRequired: t.isRelearnRequired,
      status: p?.status ?? TaskStatus.notStarted,
      progress: p?.progress ?? 0,
      sections: t.sections,
    );
  }).toList();

  List<int> completedSectionsOf(String taskId) =>
      _progress[taskId]?.completedSections ?? const [];

  SopItem? sopByCode(String code) {
    for (final s in _sops) {
      if (s.code == code || s.id == code) return s;
    }
    return null;
  }

  LearningTaskItem? taskById(String id) {
    for (final t in tasks) {
      if (t.id == id) return t;
    }
    return null;
  }

  QuizSet? quizById(String id) {
    for (final q in _quizzes) {
      if (q.id == id) return q;
    }
    return null;
  }

  /// Bộ đề gắn với mã SOP/công thức; null nếu chưa có.
  QuizSet? quizFor(String targetCode) {
    for (final q in _quizzes) {
      if (q.targetCode == targetCode) return q;
    }
    return null;
  }

  List<QuizAttempt> attemptsOf(String quizId) =>
      _attempts.where((a) => a.quizId == quizId).toList();

  /// Tổng hợp cho màn tiến độ cá nhân.
  double get readingProgress {
    final t = tasks;
    if (t.isEmpty) return 0;
    return t.fold<double>(0, (a, x) => a + x.progress) / t.length;
  }

  double get quizAverage {
    final scored = _attempts.where((a) => a.hasScore && a.total > 0).toList();
    if (scored.isEmpty) return 0;
    return scored.fold<double>(0, (a, x) => a + x.ratio) / scored.length;
  }

  int get passedEvaluations => _evaluations.where((e) => e.isPassed).length;

  void bind(String uid) {
    if (_uid == uid && _subs.isNotEmpty) return;
    clear();
    _uid = uid;
    _subscribe();
  }

  void retry() => _subscribe();

  void clear() {
    _cancel();
    _uid = null;
    _sops = const [];
    _tasks = const [];
    _progress = const {};
    _quizzes = const [];
    _attempts = const [];
    _evaluations = const [];
    _sopState = _taskState = _quizState = _evalState = LoadState.loading;
    _notify();
  }

  void _subscribe() {
    final uid = _uid;
    if (uid == null) return;
    _cancel();
    _error = null;
    _sopState = _taskState = _quizState = _evalState = LoadState.loading;
    _notify();
    _subs.add(
      _repo.watchSops().listen(
        (v) {
          _sops = v;
          _sopState = LoadState.ready;
          _notify();
        },
        onError: (Object e, StackTrace s) =>
            _fail(e, s, 'sops', () => _sopState = LoadState.error),
      ),
    );
    _subs.add(
      _repo.watchTasks().listen(
        (v) {
          _tasks = v;
          _taskState = LoadState.ready;
          _notify();
        },
        onError: (Object e, StackTrace s) =>
            _fail(e, s, 'tasks', () => _taskState = LoadState.error),
      ),
    );
    _subs.add(
      _repo.watchProgress(uid).listen((v) {
        _progress = v;
        _notify();
      }, onError: (Object e, StackTrace s) => _fail(e, s, 'progress', () {})),
    );
    _subs.add(
      _repo.watchQuizzes().listen(
        (v) {
          _quizzes = v;
          _quizState = LoadState.ready;
          _notify();
        },
        onError: (Object e, StackTrace s) =>
            _fail(e, s, 'quizzes', () => _quizState = LoadState.error),
      ),
    );
    _subs.add(
      _repo.watchMyAttempts(uid).listen((v) {
        _attempts = v;
        _notify();
      }, onError: (Object e, StackTrace s) => _fail(e, s, 'attempts', () {})),
    );
    _subs.add(
      _repo.watchMyEvaluations(uid).listen(
        (v) {
          _evaluations = v;
          _evalState = LoadState.ready;
          _notify();
        },
        onError: (Object e, StackTrace s) =>
            _fail(e, s, 'evaluations', () => _evalState = LoadState.error),
      ),
    );
  }

  void _fail(Object e, StackTrace s, String what, void Function() mark) {
    _crash.recordError(e, s, reason: 'training_$what');
    _error = e is TrainingFailure
        ? e.message
        : 'Không tải được dữ liệu đào tạo.';
    mark();
    _notify();
  }

  /// Đánh dấu / bỏ đánh dấu một mục học. Trả về thông điệp lỗi hoặc null.
  Future<String?> toggleSection(
    LearningTaskItem task,
    int index,
    bool done,
  ) async {
    final uid = _uid;
    if (uid == null) return 'Phiên đăng nhập đã hết.';
    try {
      await _repo.setSectionDone(
        uid: uid,
        taskId: task.id,
        sectionIndex: index,
        totalSections: task.sections.length,
        done: done,
        current: completedSectionsOf(task.id),
      );
      return null;
    } catch (e, s) {
      await _crash.recordError(e, s, reason: 'training_progress_write');
      return e is TrainingFailure ? e.message : 'Không lưu được tiến độ.';
    }
  }

  /// Đánh dấu hoàn thành mọi mục trong MỘT lần ghi (tránh các lần ghi nối tiếp đè nhau).
  Future<String?> completeAll(LearningTaskItem task) async {
    final uid = _uid;
    if (uid == null) return 'Phiên đăng nhập đã hết.';
    final n = task.sections.length;
    if (n == 0) return null;
    try {
      await _repo.setSectionDone(
        uid: uid,
        taskId: task.id,
        sectionIndex: n - 1,
        totalSections: n,
        done: true,
        current: List<int>.generate(n, (i) => i),
      );
      return null;
    } catch (e, s) {
      await _crash.recordError(e, s, reason: 'training_progress_write');
      return e is TrainingFailure ? e.message : 'Không lưu được tiến độ.';
    }
  }

  /// Nộp bài; trả về (đáp án, bài đã chấm) hoặc ném [TrainingFailure].
  Future<(QuizAnswerKey, QuizAttempt)> submitQuiz(
    QuizSet quiz,
    List<int> answers, {
    required String userName,
  }) {
    final uid = _uid;
    if (uid == null) throw const TrainingFailure('Phiên đăng nhập đã hết.');
    final next =
        attemptsOf(quiz.id)
            .fold<int>(0, (m, a) => a.attemptNo > m ? a.attemptNo : m) +
        1;
    return _repo.submitQuiz(
      uid: uid,
      userName: userName,
      quiz: quiz,
      answers: answers,
      attemptNo: next,
    );
  }

  void _cancel() {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _cancel();
    super.dispose();
  }
}

/// Tổng hợp tiến độ của 1 nhân viên cho màn giám sát Admin.
class StaffSummary {
  const StaffSummary({
    required this.member,
    required this.readingPercent,
    required this.overdueTasks,
    required this.latestEvaluation,
  });
  final StaffMember member;
  final int readingPercent;
  final List<LearningTaskItem> overdueTasks;
  final PracticalEvaluationRecord? latestEvaluation;
}

/// Admin: danh sách Barista thật (`users` role viewer), tiến độ học, kết quả chấm; mẫu tiêu chí chấm.
class AdminTrainingViewModel extends ChangeNotifier {
  AdminTrainingViewModel({required this._repo, required this._crash});

  final ITrainingRepository _repo;
  final ICrashReporter _crash;
  final List<StreamSubscription<dynamic>> _subs = [];
  final Map<String, StreamSubscription<Map<String, TaskProgress>>>
  _progressSubs = {};
  bool _disposed = false;
  bool _started = false;
  int _generation = 0;

  List<StaffMember> _staff = const [];
  List<LearningTaskItem> _tasks = const [];
  List<PracticalEvaluationRecord> _evaluations = const [];
  List<CriteriaTemplate> _criteria = const [];
  final Map<String, Map<String, TaskProgress>> _progress = {};
  LoadState _state = LoadState.loading;
  String? _error;

  LoadState get state => _state;
  String? get error => _error;
  List<StaffMember> get staff => _staff;
  List<PracticalEvaluationRecord> get evaluations => _evaluations;
  List<CriteriaTemplate> get criteriaTemplates => _criteria;

  List<StaffSummary> get summaries => _staff.map((m) {
    final p = _progress[m.uid] ?? const {};
    final total = _tasks.isEmpty
        ? 0
        : (_tasks.fold<double>(0, (a, t) => a + (p[t.id]?.progress ?? 0)) /
                  _tasks.length *
                  100)
              .round();
    final overdue = _tasks
        .where((t) => t.isOverdue && (p[t.id]?.status != TaskStatus.completed))
        .toList();
    PracticalEvaluationRecord? latest;
    for (final e in _evaluations) {
      if (e.traineeUid == m.uid) {
        latest = e;
        break;
      }
    }
    return StaffSummary(
      member: m,
      readingPercent: total,
      overdueTasks: overdue,
      latestEvaluation: latest,
    );
  }).toList();

  /// Tiêu chí theo món: mẫu có recipeCode trùng, nếu không có thì mẫu đầu tiên.
  List<EvaluationCriterion> criteriaFor(String recipeCode) {
    CriteriaTemplate? pick;
    for (final t in _criteria) {
      if (t.recipeCodes.contains(recipeCode)) {
        pick = t;
        break;
      }
    }
    pick ??= _criteria.isEmpty ? null : _criteria.first;
    return [
      for (final c in pick?.criteria ?? const <EvaluationCriterion>[])
        EvaluationCriterion(
          id: c.id,
          name: c.name,
          standardRequirement: c.standardRequirement,
          isCrucial: c.isCrucial,
        ),
    ];
  }

  void start() {
    if (_started || _disposed) return;
    _started = true;
    _subscribe();
  }

  void retry() {
    if (_started && !_disposed) _subscribe();
  }

  /// End the Admin session and discard all privileged data before reuse.
  void clear() {
    _started = false;
    _cancel();
    _staff = const [];
    _tasks = const [];
    _evaluations = const [];
    _criteria = const [];
    _progress.clear();
    _state = LoadState.loading;
    _error = null;
    _notify();
  }

  void _cancel() {
    _generation++;
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
    for (final s in _progressSubs.values) {
      s.cancel();
    }
    _progressSubs.clear();
  }

  bool _isCurrent(int generation) =>
      !_disposed && _started && generation == _generation;

  void _subscribe() {
    _cancel();
    final generation = _generation;
    _state = LoadState.loading;
    _error = null;
    _notify();
    _subs.add(
      _repo.watchStaff().listen((v) {
        if (!_isCurrent(generation)) return;
        _staff = v;
        _syncProgress(generation);
        _state = LoadState.ready;
        _notify();
      }, onError: _fail),
    );
    _subs.add(
      _repo.watchTasks().listen((v) {
        _tasks = v;
        _notify();
      }, onError: _fail),
    );
    _subs.add(
      _repo.watchAllEvaluations().listen((v) {
        _evaluations = v;
        _notify();
      }, onError: _fail),
    );
    _subs.add(
      _repo.watchCriteriaTemplates().listen((v) {
        _criteria = v;
        _notify();
      }, onError: _fail),
    );
  }

  void _syncProgress(int generation) {
    final uids = _staff.map((m) => m.uid).toSet();
    for (final uid in _progressSubs.keys.toList()) {
      if (uids.contains(uid)) continue;
      _progressSubs.remove(uid)?.cancel();
    }
    _progress.removeWhere((uid, _) => !uids.contains(uid));
    for (final uid in uids) {
      if (_progressSubs.containsKey(uid)) continue;
      _progressSubs[uid] = _repo
          .watchProgress(uid)
          .listen(
            (progress) {
              if (!_isCurrent(generation)) return;
              _progress[uid] = progress;
              _notify();
            },
            onError: (Object e, StackTrace s) {
              if (!_isCurrent(generation)) return;
              _crash.recordError(e, s, reason: 'admin_staff_progress');
            },
          );
    }
  }

  /// Lưu phiếu chấm; trả về thông điệp lỗi hoặc null.
  Future<String?> saveEvaluation(
    PracticalEvaluationRecord r, {
    required String evaluatorUid,
  }) async {
    try {
      await _repo.saveEvaluation(r, evaluatorUid: evaluatorUid);
      return null;
    } catch (e, s) {
      await _crash.recordError(e, s, reason: 'evaluation_save');
      return e is TrainingFailure ? e.message : 'Không lưu được phiếu chấm.';
    }
  }

  void _fail(Object e, StackTrace s) {
    _crash.recordError(e, s, reason: 'admin_training_stream');
    _error = e is TrainingFailure
        ? e.message
        : 'Không tải được dữ liệu giám sát.';
    _state = LoadState.error;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    clear();
    super.dispose();
  }
}
