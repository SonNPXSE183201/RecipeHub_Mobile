import 'dart:io';
import 'package:flutter/material.dart';

import 'core/theme/nomad_kit.dart';
import 'features/auth/login_page.dart';
import 'features/auth/register_page.dart';
import 'features/rd_staff/main_nav_shell.dart';
import 'features/rd_staff/recipe_detail_page.dart';
import 'features/rd_staff/recipe_editor_page.dart';
import 'features/rd_staff/recipe_review_page.dart';
import 'features/rd_staff/ingredient_create_page.dart';
import 'features/rd_staff/ingredient_edit_page.dart';
import 'features/rd_staff/batch_export_page.dart';
import 'features/rd_staff/pdf_cover_preview_page.dart';
import 'features/rd_staff/pdf_draft_preview_page.dart';
import 'features/rd_staff/export_history_page.dart';
import 'features/barista/viewer_home_page.dart';
import 'features/barista/booklet_reader_page.dart';
import 'features/barista/barista_viewer_page.dart';
import 'features/barista/brewing_timer_page.dart';
import 'features/admin/admin_console_page.dart';
import 'features/admin/admin_user_management_page.dart';
import 'features/admin/admin_ai_config_page.dart';
import 'features/admin/admin_audit_logs_page.dart';
import 'features/system/loading_transition_page.dart';
import 'features/system/error_recovery_page.dart';

void main() => runApp(const RecipeHubApp());

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final ValueNotifier<Widget> _activeScreen = ValueNotifier<Widget>(const LoginPage());

void _startAutomationServer() async {
  try {
    final server = await HttpServer.bind(InternetAddress.anyIPv4, 8888);
    server.listen((HttpRequest request) async {
      final name = request.uri.queryParameters['name'] ?? '';
      Widget? target;
      switch (name) {
        case '01_flow1_login_3rows':
          target = const LoginPage();
          break;
        case '02_flow1_register':
          target = const RegisterPage();
          break;
        case '03_flow1_dashboard':
          target = const MainNavShell(initialTab: 0);
          break;
        case '04_flow1_recipe_catalog':
          target = const MainNavShell(initialTab: 1);
          break;
        case '05_flow1_recipe_detail_approved':
          target = const RecipeDetailPage(
            title: 'Trà Sữa Oolong Lài',
            code: 'RC-OOL-02',
            version: 'v2',
            isDraft: false,
          );
          break;
        case '06_flow1_recipe_editor_ai':
          target = const RecipeEditorPage();
          break;
        case '07_flow1_recipe_review_lock':
          target = const RecipeReviewPage();
          break;
        case '08_flow1_ingredients_catalog':
          target = const MainNavShell(initialTab: 2);
          break;
        case '09_flow1_add_ingredient':
          target = const IngredientCreatePage();
          break;
        case '10_flow1_edit_ingredient_guard':
          target = const IngredientEditPage(
            name: 'Siro Đào Pomona',
            code: 'ING-001',
            isDiscontinued: false,
          );
          break;
        case '11_flow1_batch_export_select':
          target = const BatchExportPage();
          break;
        case '12_flow1_pdf_cover_preview':
          target = const PdfCoverPreviewPage();
          break;
        case '13_flow1_pdf_draft_watermark':
          target = const PdfDraftPreviewPage();
          break;
        case '14_flow1_export_history':
          target = const ExportHistoryPage();
          break;
        case '15_flow2_viewer_home':
          target = const ViewerHomePage();
          break;
        case '16_flow2_booklet_cover_3d':
          target = const BookletReaderPage(initialPage: 0);
          break;
        case '17_flow2_booklet_toc_drawer':
          target = const BookletReaderPage(initialPage: 0, autoOpenToc: true);
          break;
        case '18_flow2_booklet_page3_recipe':
          target = const BookletReaderPage(initialPage: 2);
          break;
        case '19_flow2_booklet_page7_draft_watermark':
          target = const BookletReaderPage(initialPage: 6);
          break;
        case '20_flow2_barista_viewer_speed':
          target = const BaristaViewerPage();
          break;
        case '21_flow2_brewing_timer':
          target = const BrewingTimerPage();
          break;
        case '22_flow3_settings_account':
          target = const MainNavShell(initialTab: 3);
          break;
        case '23_flow3_admin_console':
          target = const AdminConsolePage();
          break;
        case '24_flow3_admin_users':
          target = const AdminUserManagementPage();
          break;
        case '25_flow3_admin_ai_config':
          target = const AdminAiConfigPage();
          break;
        case '26_flow3_admin_ai_ping_success':
          target = const AdminAiConfigPage(showSuccessDirectly: true);
          break;
        case '27_flow3_admin_audit_logs':
          target = const AdminAuditLogsPage();
          break;
        case '28_system_loading_transition':
          target = const LoadingTransitionPage(message: 'Đang kết xuất bộ tài liệu PDF...');
          break;
        case '29_system_error_recovery':
          target = const ErrorRecoveryPage();
          break;
      }

      if (target != null) {
        while (navigatorKey.currentState?.canPop() == true) {
          navigatorKey.currentState?.pop();
        }
        _activeScreen.value = target;
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

class RecipeHubApp extends StatefulWidget {
  const RecipeHubApp({super.key});

  @override
  State<RecipeHubApp> createState() => _RecipeHubAppState();
}

class _RecipeHubAppState extends State<RecipeHubApp> {
  @override
  void initState() {
    super.initState();
    _startAutomationServer();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        navigatorKey: navigatorKey,
        title: 'RecipeHub',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: NomadKit.canvas,
          colorScheme: ColorScheme.fromSeed(
            seedColor: NomadKit.sand,
            brightness: Brightness.light,
            surface: NomadKit.surface,
            error: NomadKit.error,
          ),
          fontFamily: 'Inter',
        ),
        home: ValueListenableBuilder<Widget>(
          valueListenable: _activeScreen,
          builder: (context, screen, _) => KeyedSubtree(
            key: UniqueKey(),
            child: screen,
          ),
        ),
      );
}
