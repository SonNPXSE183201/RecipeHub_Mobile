import 'package:recipehub_mobile/core/viewmodels/ai_practice_viewmodel.dart';

class FakePracticeClock implements PracticeClock {
  FakePracticeClock(this.now);
  final DateTime Function() now;
  Duration _saved = Duration.zero;
  DateTime? _started;
  @override
  Duration get elapsed =>
      _saved + (_started == null ? Duration.zero : now().difference(_started!));
  @override
  void start() => _started ??= now();
  @override
  void stop() {
    _saved = elapsed;
    _started = null;
  }

  @override
  void reset() {
    _saved = Duration.zero;
    if (_started != null) _started = now();
  }
}
