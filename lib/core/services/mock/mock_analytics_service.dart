import '../../models/session_models.dart';
import '../interfaces/i_analytics_service.dart';

/// Analytics giả lập: ghi lại event đã chuẩn hóa để TC-09 kiểm chứng.
class MockAnalyticsService implements IAnalyticsService {
  final List<AnalyticsEvent> loggedEvents = [];
  final Map<String, String?> userProperties = {};
  String? userId;

  Set<String> get eventNames => loggedEvents.map((e) => e.name).toSet();

  void _log(String name, Map<String, Object> params) => loggedEvents.add(AnalyticsEvent(name, params));

  @override
  Future<void> setUserId(String? uid) async => userId = uid;

  @override
  Future<void> setUserProperty(String name, String? value) async => userProperties[name] = value;

  @override
  Future<void> logLogin({required String method, required String role}) async =>
      _log('login', {'method': method, 'user_role': role});

  @override
  Future<void> logLogout({required String role, required int sessionMinutes}) async =>
      _log('logout', {'user_role': role, 'session_minutes': sessionMinutes});

  @override
  Future<void> logViewRecipe({
    required String recipeCode,
    required String category,
    required String size,
    required String source,
  }) async =>
      _log('view_recipe', {'recipe_code': recipeCode, 'category': category, 'size': size, 'source': source});

  @override
  Future<void> logStartBrewTimer({
    required String recipeCode,
    required String size,
    required int targetSeconds,
  }) async =>
      _log('start_brew_timer', {'recipe_code': recipeCode, 'size': size, 'target_seconds': targetSeconds});

  @override
  Future<void> logCompleteBrewTimer({
    required String recipeCode,
    required String size,
    required int actualSeconds,
    required int deviationSeconds,
    required bool withinTolerance,
  }) async =>
      _log('complete_brew_timer', {
        'recipe_code': recipeCode,
        'size': size,
        'actual_seconds': actualSeconds,
        'deviation_seconds': deviationSeconds,
        'within_tolerance': withinTolerance,
      });

  @override
  Future<void> logSubmitFeedback({
    required String feedbackType,
    required String targetType,
    required String targetCode,
    required bool hasAttachment,
  }) async =>
      _log('submit_feedback', {
        'feedback_type': feedbackType,
        'target_type': targetType,
        'target_code': targetCode,
        'has_attachment': hasAttachment,
      });

  @override
  Future<void> logExportReportPdf({
    required String reportType,
    required int recordCount,
    required int fileSizeKb,
  }) async =>
      _log('export_report_pdf', {'report_type': reportType, 'record_count': recordCount, 'file_size_kb': fileSizeKb});

  @override
  Future<void> logTriggerTestCrash({required String kind}) async => _log('trigger_test_crash', {'kind': kind});
}
