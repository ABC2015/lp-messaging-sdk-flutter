import 'dart:async';

import '../config/lp_config.dart';
import '../core/lp_logger.dart';
import '../models/lp_conversation.dart';
import '../models/lp_enums.dart';
import '../models/lp_events.dart';
import '../models/lp_message.dart';
import '../models/lp_participant.dart';
import '../storage/lp_persistence.dart';
import 'lp_session.dart';

/// High-level client that apps will use.
///
/// Wraps [LpSession] and [LpPersistence] to provide:
/// - connect / disconnect
/// - startConversation
/// - sendText with offline queue
/// - unified event stream (messages, connection, errors, etc.).
class LpMessagingClient {
  LpMessagingClient({
    required LpConfig config,
    required LpPersistence persistence,
    LpLogger? logger,
  })  : _config = config,
        _persistence = persistence,
        _logger = logger ?? LpLogger(level: config.logLevel) {
    _session = LpSession(config: _config, logger: _logger);
    _sessionSub = _session.events.listen(_onSessionEvent);
  }

  final LpConfig _config;
  final LpPersistence _persistence;
  final LpLogger _logger;

  late final LpSession _session;
  late final StreamSubscription<LpEvent> _sessionSub;

  final _eventsController = StreamController<LpEvent>.broadcast();
  Stream<LpEvent> get events => _eventsController.stream;

  bool _connected = false;

  /// Map of active conversations.
  final Map<String, LpConversation> _conversations = {};

  String? _activeConversationId;

  List<LpConversation> get activeConversations =>
      _conversations.values.toList();

  LpConversation? get activeConversation => _activeConversationId == null
      ? null
      : _conversations[_activeConversationId];

  Future<void> init() async {
    await _persistence.init();
  }

  Future<void> connect() async {
    await _session.connect();
    _connected = true;
    _eventsController.add(
      const LpConnectionStateChanged(LpConnectionState.connected),
    );
    await _flushPendingMessages();
  }

  Future<void> disconnect() async {
    _connected = false;
    await _session.disconnect();
    await _sessionSub.cancel();
    await _eventsController.close();
  }

  /// Start a new conversation. Returns the local [LpConversation] object.
  Future<LpConversation> startConversation() async {
    // Only request conversation on the wire when connected.
    if (_connected) {
      await _session.requestConversation();
    }

    final tempId = 'conv-${DateTime.now().microsecondsSinceEpoch}';
    final conv = LpConversation(
      id: tempId,
      state: LpConversationState.newConversation,
      participants: <LpParticipant>[
        LpParticipant(
          id: 'me',
          role: _config.channelType,
        ),
      ],
      createdAt: DateTime.now().toUtc(),
    );

    _conversations[conv.id] = conv;
    _activeConversationId = conv.id;
    _eventsController.add(LpConversationUpdated(conv));

    return conv;
  }

  /// Send a text message on the active conversation.
  Future<void> sendText(String text) async {
    final convId = _activeConversationId;
    if (convId == null) {
      throw StateError(
        'No active conversation. Call startConversation() first.',
      );
    }

    final localId = DateTime.now().microsecondsSinceEpoch.toString();

    final message = LpMessage(
      id: localId,
      conversationId: convId,
      sender: LpParticipant(
        id: 'me',
        role: _config.channelType,
      ),
      type: LpMessageType.text,
      text: text,
      createdAt: DateTime.now().toUtc(),
      payload: LpMessagePayload(text: text),
      state: _connected ? LpMessageState.sending : LpMessageState.failed,
    );

    // Immediately surface message to UI.
    _eventsController.add(LpMessageReceived(message));

    // Persist for offline resend.
    await _persistence.savePendingMessage(message);

    if (_connected) {
      await _session.sendText(conversationId: convId, text: text);
      final sent = message.copyWith(state: LpMessageState.sent);
      await _persistence.removePendingMessage(localId);
      _eventsController.add(LpMessageStateChanged(sent));
    }
  }

  void _onSessionEvent(LpEvent event) {
    // Connection mirror
    if (event is LpConnectionStateChanged) {
      _eventsController.add(event);
      _connected = event.state == LpConnectionState.connected;
      return;
    }

    // Conversation metadata
    if (event is LpConversationUpdated) {
      final conv = event.conversation;
      _conversations[conv.id] = conv;
      _activeConversationId ??= conv.id;
      _eventsController.add(event);
      return;
    }

    // Message
    if (event is LpMessageReceived) {
      final msg = event.message;
      // Ensure conversation exists in map, and append message.
      final existing = _conversations[msg.conversationId];
      final base = existing ??
          LpConversation(
            id: msg.conversationId,
            state: LpConversationState.active,
            participants: <LpParticipant>[
              LpParticipant(id: 'me', role: _config.channelType),
            ],
            createdAt: DateTime.now().toUtc(),
          );
      final updated = base.copyWith(
        messages: [...base.messages, msg],
        updatedAt: DateTime.now().toUtc(),
      );
      _conversations[msg.conversationId] = updated;
      _activeConversationId ??= msg.conversationId;
      _eventsController.add(event);
      return;
    }

    // Message state changes
    if (event is LpMessageStateChanged) {
      final msg = event.message;
      final existing = _conversations[msg.conversationId];
      if (existing != null) {
        final updatedMessages = existing.messages.map((m) {
          if (m.id == msg.id) return msg;
          return m;
        }).toList(growable: false);
        _conversations[msg.conversationId] =
            existing.copyWith(messages: updatedMessages);
      }
      _eventsController.add(event);
      return;
    }

    // Typing
    if (event is LpTypingIndicator) {
      _eventsController.add(event);
      return;
    }

    // Errors
    if (event is LpErrorEvent) {
      _eventsController.add(event);
      return;
    }
  }

  Future<void> _flushPendingMessages() async {
    final pending = await _persistence.loadPendingMessages();

    for (final msg in pending) {
      try {
        await _session.sendText(
          conversationId: msg.conversationId,
          text: msg.text,
        );
        await _persistence.removePendingMessage(msg.id);

        final sent = msg.copyWith(
          state: LpMessageState.sent,
        );
        _eventsController.add(LpMessageStateChanged(sent));
      } catch (e, st) {
        _logger.error(
          'Failed to flush pending message ${msg.id}',
          e,
          st,
        );
      }
    }
  }
}
