import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/io.dart';

import '../core/lp_logger.dart';
import 'lp_transport_exceptions.dart';

/// Simple WebSocket wrapper that exposes a stream of JSON frames.
class LpWebSocketClient {
  LpWebSocketClient(this.logger);

  final LpLogger logger;

  IOWebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  final _jsonStreamController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get jsonMessages =>
      _jsonStreamController.stream;

  bool get isConnected => _channel != null;

  Future<void> connect(
    Uri uri, {
    required Map<String, String> headers,
  }) async {
    logger.info('WS connect $uri');

    final channel = IOWebSocketChannel.connect(uri, headers: headers);
    _channel = channel;

    _subscription = channel.stream.listen(
      (dynamic data) {
        if (data is String) {
          logger.debug('WS <- $data');
          try {
            final decoded = jsonDecode(data) as Map<String, dynamic>;
            _jsonStreamController.add(decoded);
          } catch (e, st) {
            logger.error('Failed to decode WS message', e, st);
          }
        }
      },
      onDone: () {
        logger.info('WS closed by server');
        _jsonStreamController.addError(
          LpTransportException('WebSocket closed by server'),
        );
      },
      onError: (Object error, StackTrace st) {
        logger.error('WS error', error, st);
        _jsonStreamController.addError(
          LpTransportException('WebSocket error', cause: error),
        );
      },
      cancelOnError: false,
    );
  }

  Future<void> send(Map<String, dynamic> json) async {
    final ch = _channel;
    if (ch == null) {
      throw LpTransportException('WebSocket not connected');
    }
    final text = jsonEncode(json);
    logger.debug('WS -> $text');
    ch.sink.add(text);
  }

  Future<void> close() async {
    final ch = _channel;
    _channel = null;
    await _subscription?.cancel();
    await ch?.sink.close();
    await _jsonStreamController.close();
  }
}
