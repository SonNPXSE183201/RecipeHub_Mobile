// Chỉ dùng khi debug: cho phép tool ngoài mở nhanh một màn hình (cổng 8888).
import 'dart:io';
import 'package:flutter/material.dart';

import '../../app.dart';
import '../models/app_models.dart';
import '../services/mock_data_service.dart';

// 17 M-Screens according to requirements-draft.md
import '../../features/auth/login_page.dart';
import '../../features/shell/main_app_shell.dart';
import '../../features/lookup/recipe_detail_size_page.dart';
import '../../features/lookup/step_video_guide_page.dart';
import '../../features/sop/sop_catalog_page.dart';
import '../../features/sop/sop_detail_page.dart';
import '../../features/learning/learning_task_detail_page.dart';
import '../../features/learning/personal_progress_page.dart';
import '../../features/learning/notifications_page.dart';
import '../../features/feedback/create_feedback_page.dart';
import '../../features/practice/self_practice_timer_page.dart';
import '../../features/practice/practice_history_page.dart';
import '../../features/practice/quiz_exam_page.dart';
import '../../features/practice/practical_evaluation_page.dart';
import '../../features/system/loading_transition_page.dart';
import '../../features/system/error_recovery_page.dart';

Future<void> startAutomationServer() async {
  try {
    final server = await HttpServer.bind(InternetAddress.anyIPv4, 8888);
    server.listen((HttpRequest request) async {
      final name = request.uri.queryParameters['name'] ?? '';
      Widget? target;

      if (MockDataService.instance.recipes.isEmpty) {
        request.response
          ..statusCode = HttpStatus.serviceUnavailable
          ..write('Recipes chưa tải từ backend (đăng nhập trước)')
          ..close();
        return;
      }
      final sampleRecipe = MockDataService.instance.recipes.first;
      final sampleSop = MockDataService.instance.sops.first;
      final sampleTask = MockDataService.instance.tasks.first;

      switch (name) {
        // M-01 to M-17 Standard Names
        case 'm01_login':
        case '01_flow1_login_3rows':
          target = const LoginPage();
          break;

        case 'm02_counter_lookup':
        case '04_flow1_recipe_catalog':
        case '15_flow2_viewer_home':
          MockDataService.instance.switchRole(UserRole.viewer);
          target = const MainAppShell(initialTabIndex: 0);
          break;

        case 'm03_recipe_detail_size':
        case '05_flow1_recipe_detail_approved':
          target = RecipeDetailSizePage(recipe: sampleRecipe);
          break;

        case 'm04_step_video_guide':
        case '20_flow2_barista_viewer_speed':
          target = StepVideoGuidePage(recipe: sampleRecipe, initialStepNumber: 1);
          break;

        case 'm05_sop_catalog':
        case '16_flow2_booklet_cover_3d':
          target = const SopCatalogPage();
          break;

        case 'm06_sop_detail':
        case '18_flow2_booklet_page3_recipe':
          target = SopDetailPage(sop: sampleSop);
          break;

        case 'm07_my_learning':
          MockDataService.instance.switchRole(UserRole.viewer);
          target = const MainAppShell(initialTabIndex: 1);
          break;

        case 'm08_learning_task_detail':
          target = LearningTaskDetailPage(task: sampleTask);
          break;

        case 'm09_personal_progress':
          target = const PersonalProgressPage();
          break;

        case 'm10_notifications':
          target = const NotificationsPage();
          break;

        case 'm11_create_feedback':
          target = CreateFeedbackPage(
            initialRecipeCode: sampleRecipe.code,
            initialRecipeName: sampleRecipe.name,
            initialVersion: sampleRecipe.version,
          );
          break;

        case 'm12_my_feedback_list':
          MockDataService.instance.switchRole(UserRole.viewer);
          target = const MainAppShell(initialTabIndex: 2);
          break;

        case 'm13_account_profile':
        case '22_flow3_settings_account':
          MockDataService.instance.switchRole(UserRole.viewer);
          target = const MainAppShell(initialTabIndex: 3);
          break;

        case 'm14_self_practice_timer':
        case '21_flow2_brewing_timer':
          target = const SelfPracticeTimerPage();
          break;

        case 'm15_practice_history':
          target = const PracticeHistoryPage();
          break;

        case 'm16_quiz_exam':
          target = const QuizExamPage();
          break;

        case 'm17_practical_evaluation':
          target = const PracticalEvaluationPage();
          break;

        case 'admin_store_training':
        case '23_flow3_admin_console':
          MockDataService.instance.switchRole(UserRole.admin);
          target = const MainAppShell(initialTabIndex: 1);
          break;

        case '28_system_loading_transition':
          target = const LoadingTransitionPage(message: 'Đang tải tiêu chuẩn đào tạo quầy bar...');
          break;

        case '29_system_error_recovery':
          target = const ErrorRecoveryPage();
          break;
      }

      if (target != null) {
        while (rootNavigatorKey.currentState?.canPop() == true) {
          rootNavigatorKey.currentState?.pop();
        }
        debugScreenOverride.value = target;
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.text
          ..write('OK: $name')
          ..close();
      } else {
        request.response
          ..statusCode = HttpStatus.notFound
          ..write('Unknown screen: $name')
          ..close();
      }
    });
    debugPrint('Automation server started on port 8888');
  } catch (e) {
    debugPrint('Automation server bind error: $e');
  }
}

