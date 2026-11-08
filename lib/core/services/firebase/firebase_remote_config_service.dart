import 'dart:async';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

import '../../models/session_models.dart';
import '../interfaces/i_remote_config_service.dart';

/// Firebase Remote Config – defaults → fetchAndActivate → realtime onConfigUpdated.
class FirebaseRemoteConfigService implements IRemoteConfigService {
  FirebaseRemoteConfigService({FirebaseRemoteConfig? remoteConfig})
      : _rc = remoteConfig ?? FirebaseRemoteConfig.instance;

  final FirebaseRemoteConfig _rc;
  final StreamController<RemoteConfigSnapshot> _updates = StreamController<RemoteConfigSnapshot>.broadcast();
  StreamSubscription<RemoteConfigUpdate>? _realtime;
  bool _ready = false;

  @override
  Future<void> initialize() async {
    try {
      await _rc.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        // Debug: fetch ngay để demo; Release: cache 1 giờ (giải thích chu kỳ tải khi trình diễn).
        minimumFetchInterval: kDebugMode ? Duration.zero : const Duration(hours: 1),
      ));
      await _rc.setDefaults(IRemoteConfigService.defaults);
      _ready = true;
      await _rc.fetchAndActivate();
    } catch (e) {
      debugPrint('[RemoteConfig] fetch failed – using defaults/cache: $e');
    }
    _emit();
    _realtime ??= _rc.onConfigUpdated.listen(
      (update) async {
        final activated = await _rc.activate();
        if (kDebugMode) {
          debugPrint('[RemoteConfig] realtime keys=${update.updatedKeys} activated=$activated '
              'max_lookup_results=$maxLookupResults');
        }
        _emit();
      },
      onError: (Object e) => debugPrint('[RemoteConfig] realtime error: $e'),
    );
  }

  void _emit() => _updates.add(snapshot);

  @override
  Future<bool> refresh() async {
    try {
      final changed = await _rc.fetchAndActivate();
      _emit();
      return changed;
    } catch (e) {
      debugPrint('[RemoteConfig] refresh failed: $e');
      _emit();
      return false;
    }
  }

  @override
  bool get enableAiAssist => _ready
      ? _rc.getBool(IRemoteConfigService.keyEnableAiAssist)
      : IRemoteConfigService.defaults[IRemoteConfigService.keyEnableAiAssist] as bool;

  @override
  bool get showCrashDemo => _ready
      ? _rc.getBool(IRemoteConfigService.keyShowCrashDemo)
      : IRemoteConfigService.defaults[IRemoteConfigService.keyShowCrashDemo] as bool;

  @override
  int get maxLookupResults {
    final raw = _ready
        ? _rc.getInt(IRemoteConfigService.keyMaxLookupResults)
        : IRemoteConfigService.defaults[IRemoteConfigService.keyMaxLookupResults] as int;
    return raw <= 0 ? 50 : raw.clamp(1, 200).toInt();
  }

  @override
  RemoteConfigSnapshot get snapshot {
    ConfigSource source = ConfigSource.defaults;
    String status = 'not_fetched';
    DateTime? lastFetch;
    if (_ready) {
      final value = _rc.getValue(IRemoteConfigService.keyMaxLookupResults);
      source = value.source == ValueSource.valueRemote ? ConfigSource.remote : ConfigSource.defaults;
      status = _rc.lastFetchStatus.name;
      lastFetch = _rc.lastFetchTime.millisecondsSinceEpoch == 0 ? null : _rc.lastFetchTime;
    }
    return RemoteConfigSnapshot(
      enableAiAssist: enableAiAssist,
      maxLookupResults: maxLookupResults,
      source: source,
      lastFetch: lastFetch,
      lastStatus: status,
    );
  }

  @override
  Stream<RemoteConfigSnapshot> get onUpdated => _updates.stream;
}
