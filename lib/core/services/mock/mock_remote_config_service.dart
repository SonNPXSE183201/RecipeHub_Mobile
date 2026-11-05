import 'dart:async';

import '../../models/session_models.dart';
import '../interfaces/i_remote_config_service.dart';

/// Remote Config giả lập – test gọi [publish] như khi đổi giá trị trên Console.
class MockRemoteConfigService implements IRemoteConfigService {
  MockRemoteConfigService({bool enableAiAssist = false, int maxLookupResults = 50})
      : _ai = enableAiAssist,
        _max = maxLookupResults;

  bool _ai;
  int _max;
  ConfigSource _source = ConfigSource.defaults;
  DateTime? _lastFetch;
  final StreamController<RemoteConfigSnapshot> _updates = StreamController<RemoteConfigSnapshot>.broadcast();

  /// Giá trị "đã publish trên Console" chờ fetch.
  bool? _pendingAi;
  int? _pendingMax;

  /// Giả lập Console publish + realtime update (onConfigUpdated → activate).
  void publish({bool? enableAiAssist, int? maxLookupResults, bool realtime = true}) {
    _pendingAi = enableAiAssist ?? _pendingAi;
    _pendingMax = maxLookupResults ?? _pendingMax;
    if (realtime) _activatePending();
  }

  bool _activatePending() {
    final changed = (_pendingAi != null && _pendingAi != _ai) || (_pendingMax != null && _pendingMax != _max);
    _ai = _pendingAi ?? _ai;
    _max = _pendingMax ?? _max;
    _pendingAi = null;
    _pendingMax = null;
    _source = ConfigSource.remote;
    _lastFetch = DateTime.now();
    _updates.add(snapshot);
    return changed;
  }

  @override
  Future<void> initialize() async => _updates.add(snapshot);

  @override
  Future<bool> refresh() async => _activatePending();

  @override
  bool get enableAiAssist => _ai;

  @override
  int get maxLookupResults => _max;

  @override
  RemoteConfigSnapshot get snapshot => RemoteConfigSnapshot(
        enableAiAssist: _ai,
        maxLookupResults: _max,
        source: _source,
        lastFetch: _lastFetch,
        lastStatus: _lastFetch == null ? 'not_fetched' : 'success',
      );

  @override
  Stream<RemoteConfigSnapshot> get onUpdated => _updates.stream;
}
