import '../../models/incident_report.dart';
import '../interfaces/i_incident_reporter.dart';

/// Bản giả cho test: giữ sự cố trong bộ nhớ.
class MockIncidentReporter implements IIncidentReporter {
  final List<IncidentReport> reported = [];
  final List<IncidentReport> stashed = [];
  String? uid;
  String? email;
  bool crashAlreadyReported = false;
  bool? pendingFlush;
  int flushCount = 0;

  @override
  void setUser({String? uid, String? email}) {
    this.uid = uid;
    this.email = email;
    final crashed = pendingFlush;
    if (uid != null && crashed != null) {
      pendingFlush = null;
      flushPending(crashedLastRun: crashed);
    }
  }

  @override
  void scheduleFlush({required bool crashedLastRun}) {
    pendingFlush = crashedLastRun;
    if (uid != null) setUser(uid: uid, email: email);
  }

  @override
  Future<bool> report(IncidentReport report) async {
    if (reported.any((r) => r.id == report.id)) return true; // id cố định → không trùng
    reported.add(report);
    return true;
  }

  @override
  Future<void> stashForNextLaunch(IncidentReport report) async => stashed.add(report);

  @override
  Future<void> removeStashed(String id) async => stashed.removeWhere((r) => r.id == id);

  @override
  Future<void> markCrashAlreadyReported() async => crashAlreadyReported = true;

  @override
  Future<int> flushPending({required bool crashedLastRun}) async {
    flushCount++;
    final skip = crashAlreadyReported;
    crashAlreadyReported = false;
    final pending = List.of(stashed);
    stashed.clear();
    for (final r in pending) {
      await report(r);
    }
    if (crashedLastRun && pending.isEmpty && !skip) {
      reported.add(IncidentReport(kind: IncidentKind.fatal, source: IncidentSource.previousCrash, message: 'previous crash'));
      return 1;
    }
    return pending.length;
  }
}
