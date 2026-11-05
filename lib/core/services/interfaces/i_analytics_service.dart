/// Google Analytics for Firebase boundary – 7 sự kiện chuẩn (docs/analytics-plan.md).
/// Không truyền PII (email / họ tên) vào bất kỳ tham số nào.
abstract class IAnalyticsService {
  Future<void> setUserId(String? uid);

  Future<void> setUserProperty(String name, String? value);

  /// 1. `login`
  Future<void> logLogin({required String method, required String role});

  /// 2. `logout`
  Future<void> logLogout({required String role, required int sessionMinutes});

  /// 3. `view_recipe`
  Future<void> logViewRecipe({
    required String recipeCode,
    required String category,
    required String size,
    required String source,
  });

  /// 4. `start_brew_timer`
  Future<void> logStartBrewTimer({
    required String recipeCode,
    required String size,
    required int targetSeconds,
  });

  /// 5. `complete_brew_timer`
  Future<void> logCompleteBrewTimer({
    required String recipeCode,
    required String size,
    required int actualSeconds,
    required int deviationSeconds,
    required bool withinTolerance,
  });

  /// 6. `submit_feedback`
  Future<void> logSubmitFeedback({
    required String feedbackType,
    required String targetType,
    required String targetCode,
    required bool hasAttachment,
  });

  /// 7. `export_report_pdf`
  Future<void> logExportReportPdf({
    required String reportType,
    required int recordCount,
    required int fileSizeKb,
  });

  /// 8. `trigger_test_crash` – bấm nút kiểm thử sự cố ({kind: fatal | non_fatal}).
  Future<void> logTriggerTestCrash({required String kind});
}
