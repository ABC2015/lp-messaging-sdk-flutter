import 'dart:async';

import '../api/domain_api.dart';
import '../api/messaging_commands.dart';
import '../api/messaging_window_api.dart';
import '../config/lp_config.dart';
import '../core/keep_alive_service.dart';
import '../core/lp_logger.dart';
import '../models/lp_enums.dart';
import '../models/lp_error.dart';
import '../models/lp_events.dart';
import '../transport/lp_http_client.dart';
import '../transport/lp_transport_exceptions.dart';
import '../transport/lp_websocket_client.dart';

/// Low-level session: resolves domain, opens WebSocket, translates raw
/// JSON frames into high-level [LpEvent]s.
///
/// This implements the bare minimum of the Messaging Window API:
/// - Request conversation
/// - Send text ContentEvent
/// - Receive text ContentEvents via MessagingEventNotification.
class LpSession {
  LpSession({
    required this.config,
    LpLogger? logger,
  }) : logger = logger ?? LpLogger(level: config.logLevel) {
    _http = LpHttpClient(logger: this.logger);
    _ws = LpWebSocketClient(this.logger);
    _domainApi = LpDomainApi(
      config: config,
      http: _http,
      logger: this.logger,
    );
    _api = MessagingWindowApi(_eventController);
    commands = LpMessagingCommands(_sendFrame);
    keepAlive = LpKeepAliveService(sendFrame: _sendFrame);
  }

  final LpConfig config;
  final LpLogger logger;

  late final LpHttpClient _http;
  late final LpWebSocketClient _ws;
  late final LpDomainApi _domainApi;
  late final MessagingWindowApi _api;

  late final LpMessagingCommands commands;
  late final LpKeepAliveService keepAlive;

  final _eventController = StreamController<LpEvent>.broadcast();

  Stream<LpEvent> get events => _eventController.stream;

  int _reqCounter = 0;
  String? _asyncMessagingDomain;
  bool _connected = false;

  LpConnectionState _connectionState = LpConnectionState.idle;

  LpConnectionState get connectionState => _connectionState;

  Future<void> connect() async {
    if (_connected) return;

    _updateConnectionState(LpConnectionState.connecting);

    _asyncMessagingDomain ??= await _domainApi.resolveAsyncMessagingDomain();
    final token = await config.jwtProvider();

    // For now use consumer path; for agent we could switch based on config.
    final pathSegment =
        config.channelType == LpChannelType.consumer ? 'consumer' : 'agent';

    final uri = Uri.parse(
      'wss://${_asyncMessagingDomain!}/ws_api/account/${config.accountId}/messaging/$pathSegment',
    ).replace(
      queryParameters: <String, String>{
        'v': '3',
      },
    );

    try {
      await _ws.connect(
        uri,
        headers: <String, String>{
          // LivePerson expects "jwt <token>" for consumer mode.
          'Authorization': 'jwt $token',
        },
      );
    } on LpTransportException catch (e, st) {
      logger.error('Failed to open WebSocket', e, st);
      _eventController.add(
        LpErrorEvent(
          LpError('WS_CONNECT', 'Failed to connect WebSocket', details: e),
        ),
      );
      _updateConnectionState(LpConnectionState.disconnected);
      rethrow;
    }

    _connected = true;
    _updateConnectionState(LpConnectionState.connected);
    keepAlive.start();

    _ws.jsonMessages.listen(
      _handleJsonFrame,
      onError: (Object error, StackTrace st) {
        logger.error('WS stream error', error, st);
        _eventController.add(
          LpErrorEvent(
            LpError('WS_STREAM', 'WebSocket stream error', details: error),
          ),
        );
        keepAlive.stop();
        _updateConnectionState(LpConnectionState.disconnected);
      },
      onDone: () {
        keepAlive.stop();
        _updateConnectionState(LpConnectionState.disconnected);
      },
      cancelOnError: false,
    );
  }

  Future<void> disconnect() async {
    _connected = false;
    keepAlive.stop();
    _updateConnectionState(LpConnectionState.disconnected);
    await _ws.close();
    await _eventController.close();
    _http.close();
  }

  void _updateConnectionState(LpConnectionState newState) {
    _connectionState = newState;
    _eventController.add(LpConnectionStateChanged(newState));
  }

  int _nextReqId() => ++_reqCounter;

  /// Request a new conversation for the current user.
  ///
  /// Returns the newly created conversation id.
  Future<String> requestConversation() async {
    final reqId = _nextReqId();
    final body = <String, dynamic>{
      'kind': 'req',
      'id': reqId,
      'type': 'cm.ConsumerRequestConversation',
      'body': <String, dynamic>{},
    };

    await _ws.send(body);

    // For now, we don't wait synchronously for the resp; instead, we infer
    // conversation ID from subsequent MessagingEventNotification events.
    return 'unknown';
  }

  /// Send a plain text ContentEvent message to a conversation.
  Future<void> sendText({
    required String conversationId,
    required String text,
  }) async {
    final reqId = _nextReqId();

    final payload = <String, dynamic>{
      'kind': 'req',
      'id': reqId,
      'type': 'ms.PublishEvent',
      'body': <String, dynamic>{
        'dialogId': conversationId,
        'event': <String, dynamic>{
          'type': 'ContentEvent',
          'contentType': 'text/plain',
          'message': text,
        },
      },
    };

    await _ws.send(payload);
  }

  void _sendFrame(Map<String, dynamic> frame) {
    _ws.send(frame);
  }

  void _handleJsonFrame(Map<String, dynamic> frame) {
    logger.debug('WS frame: $frame');
    _api.handleFrame(frame);
  }
}
