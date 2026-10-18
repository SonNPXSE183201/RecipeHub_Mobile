import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class AppConfig {
  AppConfig._();

  /// Default Gateway port for RecipeHub YARP Reverse Proxy
  static const int defaultGatewayPort = 5000;

  /// Custom Base URL override (e.g. for testing on physical WiFi device)
  static String? customBaseUrl;

  /// Determines the proper Gateway Base URL based on platform:
  /// - Android Emulator: 10.0.2.2:5000 (standard Android loopback to host)
  /// - iOS Simulator / macOS / Windows / Web: localhost:5000
  /// - Physical device: customBaseUrl if set (e.g., http://192.168.1.15:5000)
  static String get gatewayBaseUrl {
    if (customBaseUrl != null && customBaseUrl!.isNotEmpty) {
      return customBaseUrl!;
    }

    if (kIsWeb) {
      return 'http://localhost:$defaultGatewayPort';
    }

    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:$defaultGatewayPort';
      }
      return 'http://localhost:$defaultGatewayPort';
    } catch (_) {
      return 'http://localhost:$defaultGatewayPort';
    }
  }

  /// Active mock fallback mode when backend is unreachable
  static bool enableOfflineMockFallback = true;
}
