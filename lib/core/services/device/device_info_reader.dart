import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Thông tin máy + bản app, đọc một lần rồi cache. Không chứa định danh cá nhân.
class DeviceSnapshot {
  const DeviceSnapshot({
    required this.platform,
    required this.model,
    required this.osVersion,
    required this.appVersion,
    required this.buildNumber,
  });

  final String platform;
  final String model;
  final String osVersion;
  final String appVersion;
  final String buildNumber;

  static const unknown =
      DeviceSnapshot(platform: 'android', model: 'unknown', osVersion: 'unknown', appVersion: '0.0.0', buildNumber: '0');
}

class DeviceInfoReader {
  DeviceInfoReader._();

  static DeviceSnapshot? _cache;

  static Future<DeviceSnapshot> read() async {
    if (_cache != null) return _cache!;
    try {
      final pkg = await PackageInfo.fromPlatform();
      final info = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final a = await info.androidInfo;
        _cache = DeviceSnapshot(
          platform: 'android',
          model: a.model,
          osVersion: 'Android ${a.version.release} (API ${a.version.sdkInt})',
          appVersion: pkg.version,
          buildNumber: pkg.buildNumber,
        );
      } else if (Platform.isIOS) {
        final i = await info.iosInfo;
        _cache = DeviceSnapshot(
          platform: 'ios',
          model: i.utsname.machine,
          osVersion: 'iOS ${i.systemVersion}',
          appVersion: pkg.version,
          buildNumber: pkg.buildNumber,
        );
      } else {
        _cache = DeviceSnapshot(
          platform: 'android',
          model: Platform.operatingSystem,
          osVersion: Platform.operatingSystemVersion,
          appVersion: pkg.version,
          buildNumber: pkg.buildNumber,
        );
      }
    } catch (_) {
      _cache = DeviceSnapshot.unknown;
    }
    return _cache!;
  }
}
