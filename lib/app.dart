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
import 'core/viewmodels/training_viewmodel.dart';
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
        ChangeNotifierProvider(
          create: (_) => AppConfigViewModel(service: s.remoteConfig)..init(),
        ),
        ChangeNotifierProvider(
          create: (_) => RecipeViewModel(source: s.recipes, crash: s.crash),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              PracticeHistoryViewModel(store: s.practice, crash: s.crash),
        ),
        // Dữ liệu đào tạo real-time: bind(uid) khi đăng nhập (AuthGate), clear() khi đăng xuất.
        ChangeNotifierProvider(
          create: (_) => TrainingViewModel(repo: s.training, crash: s.crash),
        ),
        // Giám sát của Admin: start() khi vào màn Admin.
        ChangeNotifierProvider(
          create: (_) =>
              AdminTrainingViewModel(repo: s.training, crash: s.crash),
        ),
        ChangeNotifierProvider(
          create: (_) => StorageViewModel(
            storage: s.storage,
            picker: s.mediaPicker,
            auth: s.auth,
            analytics: s.analytics,
            crash: s.crash,
            fileSaver: s.fileSaver,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => NotificationViewModel(
            service: s.notifications,
            crash: s.crash,
            devices: s.devices,
          ),
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
          fontFamily: 'BeVietnamPro',
          dividerColor: NomadKit.border,
          appBarTheme: const AppBarTheme(
            backgroundColor: NomadKit.canvas,
            foregroundColor: NomadKit.ink,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 52),
              backgroundColor: NomadKit.sandDark,
              foregroundColor: Colors.white,
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 44),
              foregroundColor: NomadKit.ink,
              side: const BorderSide(color: NomadKit.border),
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: NomadKit.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: NomadKit.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: NomadKit.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: NomadKit.sandDark),
            ),
            labelStyle: NomadKit.label,
            hintStyle: NomadKit.body.copyWith(color: NomadKit.secondary),
          ),
        ),
        home: ValueListenableBuilder<Widget?>(
          valueListenable: debugScreenOverride,
          builder: (context, override, _) => override == null
              ? const AuthGate()
              : KeyedSubtree(key: UniqueKey(), child: override),
        ),
      ),
    );
  }
}
