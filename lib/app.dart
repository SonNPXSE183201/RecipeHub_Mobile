import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/di/app_services.dart';
import 'core/theme/nomad_kit.dart';
import 'core/viewmodels/app_config_viewmodel.dart';
import 'core/viewmodels/auth_viewmodel.dart';
import 'core/viewmodels/notification_viewmodel.dart';
import 'core/viewmodels/practice_history_viewmodel.dart';
import 'core/viewmodels/recipe_viewmodel.dart';
import 'core/viewmodels/storage_viewmodel.dart';
import 'features/auth/auth_gate.dart';

/// Navigator gốc – dùng cho deep link FCM & automation server (debug).
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// Màn hình ép hiển thị bởi automation server (chỉ debug). null = chạy AuthGate bình thường.
final ValueNotifier<Widget?> debugScreenOverride = ValueNotifier<Widget?>(null);

/// Root widget: MultiProvider (MVVM) + MaterialApp + AuthGate.
class RecipeHubApp extends StatelessWidget {
  const RecipeHubApp({super.key, required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    final s = services;
    return MultiProvider(
      providers: [
        Provider<AppServices>.value(value: s),
        ChangeNotifierProvider(
          create: (_) => AuthViewModel(
            auth: s.auth,
            analytics: s.analytics,
            crash: s.crash,
            profile: s.usesFirebase ? s.profile : null,
            incidents: s.incidents,
          )..start(),
        ),
        ChangeNotifierProvider(create: (_) => AppConfigViewModel(service: s.remoteConfig)..init()),
        ChangeNotifierProvider(create: (_) => RecipeViewModel(source: s.recipes, crash: s.crash)),
        ChangeNotifierProvider(create: (_) => PracticeHistoryViewModel(store: s.practice, crash: s.crash)),
        ChangeNotifierProvider(
          create: (_) => StorageViewModel(
            storage: s.storage,
            picker: s.mediaPicker,
            auth: s.auth,
            analytics: s.analytics,
            crash: s.crash,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => NotificationViewModel(service: s.notifications, crash: s.crash, devices: s.devices),
        ),
      ],
      child: MaterialApp(
        navigatorKey: rootNavigatorKey,
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
        home: ValueListenableBuilder<Widget?>(
          valueListenable: debugScreenOverride,
          builder: (context, override, _) =>
              override == null ? const AuthGate() : KeyedSubtree(key: UniqueKey(), child: override),
        ),
      ),
    );
  }
}
