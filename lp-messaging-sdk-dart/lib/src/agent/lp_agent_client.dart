import 'dart:async';

import '../api/agent_api.dart';
import '../api/messaging_commands.dart';
import '../api/messaging_rest_api.dart';
import '../config/lp_config.dart';
import '../core/lp_logger.dart';
import '../models/lp_conversation.dart';
import '../models/lp_enums.dart';
import '../models/lp_events.dart';
import '../models/lp_mappers.dart';
import '../models/lp_message.dart';
import '../models/lp_participant.dart';
import '../transport/lp_websocket_client.dart';

/// Agent-facing client: list/accept/resolve conversations, send messages, etc.
class LpAgentClient {
  factory LpAgentClient({
    required LpConfig config,
    LpLogger? logger,
    LpWebSocketClient? wsClient,
  }) {
    final resolvedLogger = logger ?? LpLogger(level: config.logLevel);
    return LpAgentClient._internal(
      config: config,
      logger: resolvedLogger,
      wsClient: wsClient ?? LpWebSocketClient(resolvedLogger),
      agentApi: LpAgentApi(config: config, logger: resolvedLogger),
      restApi: LpMessagingRestApi(config: config, logger: resolvedLogger),
    );
  }

  LpAgentClient._internal({
    required LpConfig config,
    required LpLogger logger,
    required LpWebSocketClient wsClient,
    required LpAgentApi agentApi,
    required LpMessagingRestApi restApi,
  })  : _config = config,
        _logger = logger,
        _wsClient = wsClient,
        _agentApi = agentApi,
        _restApi = restApi {
    _commands = LpMessagingCommands(_sendFrame);
  }

  final LpConfig _config;
  final LpLogger _logger;
  final LpWebSocketClient _wsClient;
  final LpAgentApi _agentApi;
  final LpMessagingRestApi _restApi;
  late final LpMessagingCommands _commands;

  final _events = StreamController<LpAgentEvent>.broadcast();

  Stream<LpAgentEvent> get events => _events.stream;

  /// List active conversations (best-effort via REST).
  Future<List<LpConversation>> listActiveConversations() async {
    return _restApi.listConversations(onlyActive: true);
  }

  /// Accept a conversation (agent).
  Future<void> acceptConversation(String conversationId) async {
    await _agentApi.accept(conversationId);
    _events.add(
      LpConversationAssigned(
        LpConversation(
          id: conversationId,
          state: LpConversationState.active,
          participants: const [],
        ),
      ),
    );
  }

  /// Mark read.
  Future<void> markAsRead(String conversationId, String sequenceId) async {
    await _agentApi.markAsRead(conversationId, sequenceId);
  }

  /// Resolve/close (agent side).
  Future<void> resolve(String conversationId) async {
    await _agentApi.resolve(conversationId);
    _events.add(LpConversationReleased(conversationId));
  }

  /// Query max concurrency and active load.
  Future<Map<String, int>> getConcurrency() => _agentApi.getConcurrency();

  /// Send an agent text message on WS if connected.
  Future<void> sendText({
    required String conversationId,
    required String text,
  }) async {
    _commands.sendText(dialogId: conversationId, message: text);
    _events.add(
      LpAgentMessageAdded(
        conversationId: conversationId,
        message: LpMessage(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          conversationId: conversationId,
          sender: LpParticipant(id: 'agent', role: _config.channelType),
          type: LpMessageType.text,
          text: text,
          createdAt: DateTime.now().toUtc(),
          payload: LpMessagePayload(text: text),
        ),
      ),
    );
  }

  /// Connect WS for agent events, e.g. routing offers, assignment updates.
  Future<void> connectEvents(
    Uri wsUri, {
    required Map<String, String> headers,
  }) async {
    await _wsClient.connect(wsUri, headers: headers);
    _wsClient.jsonMessages.listen(
      _handleWsMessage,
      onError: (Object e) {
        _logger.error('Agent WS error', e, StackTrace.current);
      },
    );
  }

  void _sendFrame(Map<String, dynamic> frame) {
    _wsClient.send(frame);
  }

  void _handleWsMessage(Map<String, dynamic> json) {
    final type = json['type'] as String? ?? '';

    switch (type) {
      case 'routing_offer':
        final convo =
            conversationFromJson(json['conversation'] as Map<String, dynamic>);
        final ttlMs = json['timeToLiveMs'] as int?;
        final ttl = ttlMs != null ? Duration(milliseconds: ttlMs) : null;
        _events.add(
          LpRoutingOfferReceived(conversation: convo, timeToLive: ttl),
        );
        break;
      case 'conversation_assigned':
        final convo =
            conversationFromJson(json['conversation'] as Map<String, dynamic>);
        _events.add(LpConversationAssigned(convo));
        break;
      case 'conversation_released':
        final convoId = json['conversationId'] as String? ?? '';
        if (convoId.isNotEmpty) {
          _events.add(LpConversationReleased(convoId));
        }
        break;
      case 'message_added':
        final convoId = json['conversationId'] as String? ?? '';
        final msg =
            messageFromJson(json['message'] as Map<String, dynamic>? ?? {});
        if (convoId.isNotEmpty) {
          _events.add(
            LpAgentMessageAdded(
              conversationId: convoId,
              message: msg,
            ),
          );
        }
        break;
      default:
        _logger.debug('Unhandled agent WS event: $json');
    }
  }

  Future<void> dispose() async {
    await _events.close();
    await _wsClient.close();
  }
}
