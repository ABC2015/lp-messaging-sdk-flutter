import 'dart:async';
import 'dart:math';

/// Periodic keep-alive for Messaging Window API using GetClock.
/// Recommended interval: about 30s.
class LpKeepAliveService {
  LpKeepAliveService({
    required this.sendFrame,
    this.interval = const Duration(seconds: 30),
  });

  /// Function that writes JSON frames to the WS.
  final void Function(Map<String, dynamic>) sendFrame;

  final Duration interval;
  Timer? _timer;
  int _nextId = Random().nextInt(1000000);

  String _id() => (++_nextId).toString();

  bool get isRunning => _timer != null;

  void start() {
    if (_timer != null) return;
    _timer = Timer.periodic(interval, (_) => _tick());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void _tick() {
    final frame = {
      'kind': 'req',
      'id': _id(),
      'type': 'GetClock',
    };

    sendFrame(frame);
  }
}
