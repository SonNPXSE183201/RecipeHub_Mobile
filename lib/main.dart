import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'core/bootstrap/firebase_bootstrap.dart';
import 'core/dev/automation_server.dart';
import 'core/di/app_services.dart';
import 'core/services/i_recipe_source.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final firebaseReady = await FirebaseBootstrap.initialize();
  // Firebase chưa cấu hình (desktop/test) → services mock, công thức vẫn lấy từ Gateway thật.
  final services = firebaseReady ? AppServices.firebase() : AppServices.mock(recipes: GatewayRecipeSource());
  if (firebaseReady) unawaited(FirebaseBootstrap.attachIncidentReporter(services.incidents));
  if (kDebugMode && !kIsWeb && !Platform.environment.containsKey('FLUTTER_TEST')) {
    startAutomationServer();
  }
  runApp(RecipeHubApp(services: services));
}
