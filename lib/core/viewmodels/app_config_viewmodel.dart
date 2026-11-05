import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/session_models.dart';
import '../services/interfaces/i_remote_config_service.dart';

/// Remote Config: `enable_ai_assist`, `max_lookup_results`.
class AppConfigViewModel extends ChangeNotifier {
  AppConfigViewModel({required this._service});

  final IRemoteConfigService _service;
  StreamSubscription<RemoteConfigSnapshot>? _sub;
  bool _disposed = false;

  RemoteConfigSnapshot get snapshot => _service.snapshot;
  bool get enableAiAssist => _service.enableAiAssist;
  int get maxLookupResults => _service.maxLookupResults;

  Future<void> init() async {
    await _service.initialize();
    _sub = _service.onUpdated.listen((_) => _notify());
    _notify();
  }

  Future<bool> refresh() async {
    final changed = await _service.refresh();
    _notify();
    return changed;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _sub?.cancel();
    super.dispose();
  }
}
