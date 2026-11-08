import '../../models/incident_report.dart';

/// Báo sự cố về Firestore `incidents/` cho web Admin (song song với Crashlytics cho team dev).
/// Không báo lỗi thường (mất mạng tạm thời, người dùng hủy thao tác).
abstract class IIncidentReporter {
  /// Người dùng hiện tại (null khi đăng xuất). Email/uid chỉ lưu trong Firestore có rules, không vào Analytics.
  /// Lần đầu có uid → tự gửi bù các sự cố lưu tạm (rules yêu cầu đã đăng nhập).
  void setUser({String? uid, String? email});

  /// Ghi sự cố (id cố định → ghi lại không trùng). Không ném lỗi ra ngoài; trả `true` nếu đã ghi được.
  Future<bool> report(IncidentReport report);

  /// Lưu tạm cục bộ (dùng trong handler crash, khi app có thể chết trước khi ghi xong).
  Future<void> stashForNextLaunch(IncidentReport report);

  /// Bỏ bản lưu tạm đã ghi được lên server.
  Future<void> removeStashed(String id);

  /// Đánh dấu crash sắp xảy ra đã được báo (nút demo) → lần mở sau không gửi thêm `previous_crash`.
  Future<void> markCrashAlreadyReported();

  /// Ghi nhớ kết quả Crashlytics `didCrashOnPreviousExecution`; việc gửi bù chờ tới khi có người đăng nhập.
  void scheduleFlush({required bool crashedLastRun});

  /// Gửi các bản lưu tạm từ lần chạy trước; nếu Crashlytics báo crash mà không có bản lưu thì
  /// gửi một sự cố `previous_crash`.
  Future<int> flushPending({required bool crashedLastRun});
}
