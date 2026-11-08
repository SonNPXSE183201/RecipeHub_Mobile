import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

import '../../models/session_models.dart';
import '../interfaces/i_analytics_service.dart';

/// Google Analytics for Firebase – mọi tham số đi qua [AnalyticsEvent.sanitize] (không PII).
class FirebaseAnalyticsService implements IAnalyticsService {
  FirebaseAnalyticsService({FirebaseAnalytics? analytics}) : _fa = analytics ?? FirebaseAnalytics.instance;

  final FirebaseAnalytics _fa;

  Future<void> _log(String name, Map<String, Object> params) async {
    final event = AnalyticsEvent(name, params);
    try {
      await _fa.logEvent(name: event.name, parameters: event.parameters);
      if (kDebugMode) debugPrint('[Analytics] $event');
    } catch (e) {
      debugPrint('[Analytics] logEvent failed: $e');
    }
  }

  @override
  Future<void> setUserId(String? uid) => _fa.setUserId(id: uid);

  @override
  Future<void> setUserProperty(String name, String? value) => _fa.setUserProperty(name: name, value: value);

  @override
  Future<void> logLogin({required String method, required String role}) =>
      _log('login', {'method': method, 'user_role': role});

  @override
  Future<void> logLogout({required String role, required int sessionMinutes}) =>
      _log('logout', {'user_role': role, 'session_minutes': sessionMinutes});

  @override
  Future<void> logViewRecipe({
    required String recipeCode,
    required String category,
    required String size,
    required String source,
  }) =>
      _log('view_recipe', {'recipe_code': recipeCode, 'category': category, 'size': size, 'source': source});

  @override
  Future<void> logStartBrewTimer({
    required String recipeCode,
    required String size,
    required int targetSeconds,
  }) =>
      _log('start_brew_timer', {'recipe_code': recipeCode, 'size': size, 'target_seconds': targetSeconds});

  @override
  Future<void> logCompleteBrewTimer({
    required String recipeCode,
    required String size,
    required int actualSeconds,
    required int deviationSeconds,
    required bool withinTolerance,
  }) =>
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
  }) =>
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
  }) =>
      _log('export_report_pdf', {'report_type': reportType, 'record_count': recordCount, 'file_size_kb': fileSizeKb});

  @override
  Future<void> logTriggerTestCrash({required String kind}) => _log('trigger_test_crash', {'kind': kind});
}
