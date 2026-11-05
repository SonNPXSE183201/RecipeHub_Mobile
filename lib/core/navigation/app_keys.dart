import 'package:flutter/widgets.dart';

/// Keys ổn định cho widget test (test/artemis_e2e_test.dart) và ARTEMIS agent.
class AppKeys {
  AppKeys._();

  // Shell / navigation
  static Key tab(int index) => Key('shell_tab_$index');
  static const notificationBell = Key('shell_notification_bell');
  static const permissionPrimer = Key('permission_primer_dialog');
  static const permissionAllow = Key('permission_allow');
  static const permissionLater = Key('permission_later');

  // M-01 Login
  static const googleSignIn = Key('login_google');
  static const guestSignIn = Key('login_guest');
  static Key roleOption(String role) => Key('login_role_$role'); // viewer | admin
  static const loginError = Key('login_error');

  // Recipe load gate
  static const recipeRetry = Key('recipe_load_retry');
  static const recipeLoadError = Key('recipe_load_error');

  // M-02 Lookup
  static const recipeSearch = Key('lookup_search');
  static Key recipeCard(String recipeId) => Key('lookup_recipe_$recipeId');
  static const lookupResultCount = Key('lookup_result_count');
  static const lookupLimitNotice = Key('lookup_limit_notice');

  // M-14 Practice timer
  static const timerStart = Key('timer_start');
  static const timerStop = Key('timer_stop');
  static const timerSave = Key('timer_save');

  // M-11 Feedback
  static const pickFromGallery = Key('feedback_pick_gallery');
  static const pickFromCamera = Key('feedback_pick_camera');
  static const attachmentUrl = Key('feedback_attachment_url');
  static const feedbackSubmit = Key('feedback_submit');

  // M-10 Notifications
  static const markAllRead = Key('notifications_mark_all_read');

  // M-13 Account
  static const logout = Key('account_logout');
  static const testCrash = Key('account_test_crash');
  static const recordNonFatal = Key('account_record_non_fatal');

  // M-15 Report
  static const exportReport = Key('report_export');
  static const reportUrl = Key('report_url');
}
