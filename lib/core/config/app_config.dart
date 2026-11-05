import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class AppConfig {
  AppConfig._();

  /// Default Gateway port for RecipeHub YARP Reverse Proxy
  static const int defaultGatewayPort = 5000;

  /// Chi nhánh demo (không phải PII). Dùng làm user property / nhãn báo cáo.
  static const String storeBranch = 'RecipeHub Coffee - Chi nhánh Quận 1';
  static const String storeCode = 'hcm01';

  /// Override qua `--dart-define=API_BASE_URL=http://192.168.1.15:5000`
  /// (máy thật cùng Wi-Fi với máy chạy Gateway).
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// Custom Base URL override (runtime)
  static String? customBaseUrl;

  /// Determines the proper Gateway Base URL based on platform:
  /// - Android Emulator: 10.0.2.2:5000 (standard Android loopback to host)
  /// - iOS Simulator / macOS / Windows / Web: localhost:5000
  /// - Physical device: customBaseUrl if set (e.g., http://192.168.1.15:5000)
  static String get gatewayBaseUrl {
    if (customBaseUrl != null && customBaseUrl!.isNotEmpty) {
      return customBaseUrl!;
    }
    if (_envBaseUrl.isNotEmpty) return _envBaseUrl;

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

  /// Dữ liệu công thức luôn lấy từ Gateway thật. Không còn mock fallback:
  /// lỗi mạng được ném ra để ViewModel hiển thị trạng thái error + retry.
  static const bool enableOfflineMockFallback = false;
}
