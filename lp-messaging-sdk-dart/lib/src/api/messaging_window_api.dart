import 'dart:async';

import '../models/lp_conversation.dart';
import '../models/lp_enums.dart';
import '../models/lp_events.dart';
import '../models/lp_message.dart';
import '../models/lp_participant.dart';
import '../models/lp_error.dart';
import '../models/structured_content.dart';

/// Decode LP WebSocket notifications into structured Dart events.
///
/// This keeps logic out of the raw session.
class MessagingWindowApi {
  final StreamController<LpEvent> eventSink;

  MessagingWindowApi(this.eventSink);

  /// Entry point that processes a raw JSON frame.
  void handleFrame(Map<String, dynamic> frame) {
    final kind = frame['kind'] as String? ?? '';
    final type = frame['type'] as String? ?? '';

    if (kind == 'notification' && type == 'ms.MessagingEventNotification') {
      _handleMessagingEventNotification(frame);
      return;
    }

    if (kind == 'notification' &&
        type == 'cqm.ExConversationChangeNotification') {
      _handleConvMetadataChange(frame);
      return;
    }

    if (kind == 'resp') {
      _handleResponse(frame);
      return;
    }
  }

  void _handleResponse(Map<String, dynamic> frame) {
    final code = frame['code'] as int? ?? 200;
    if (code >= 400) {
      eventSink.add(
        LpErrorEvent(
          LpError('WS_RESP_ERR', 'LP response error', details: frame),
        ),
      );
    }
  }

  void _handleConvMetadataChange(Map<String, dynamic> frame) {
    final body = frame['body'] as Map<String, dynamic>? ?? {};
    final convs = body['changes'] as List<dynamic>? ?? [];

    for (final raw in convs) {
      final item = raw as Map<String, dynamic>;
      final convJson = item['result'] as Map<String, dynamic>? ?? {};
      final convId = convJson['convId'] as String? ?? '';
      if (convId.isEmpty) continue;

      // Extract minimal participants + state.
      final statuses = convJson['status'] as Map<String, dynamic>? ?? {};
      final isClosed = (statuses['closed'] as bool?) ?? false;

      final participants = <LpParticipant>[];
      final jsonParts = convJson['participants'] as List<dynamic>? ?? [];
      for (final p in jsonParts) {
        final mp = p as Map<String, dynamic>;
        final pid = mp['id'] as String? ?? '';
        final roleStr = (mp['role'] as String? ?? '').toUpperCase();
        final role = roleStr == 'CONSUMER'
            ? LpChannelType.consumer
            : LpChannelType.agent;
        participants.add(LpParticipant(id: pid, role: role));
      }

      final conv = LpConversation(
        id: convId,
        state: isClosed
            ? LpConversationState.closed
            : LpConversationState.active,
        participants: participants,
        createdAt: DateTime.tryParse(convJson['startTs']?.toString() ?? ''),
        updatedAt: DateTime.now().toUtc(),
      );

      eventSink.add(LpConversationUpdated(conv));
    }
  }

  void _handleMessagingEventNotification(Map<String, dynamic> frame) {
    final body = frame['body'] as Map<String, dynamic>? ?? {};
    final dialogId = body['dialogId'] as String? ?? '';
    if (dialogId.isEmpty) return;

    final eventsJson = body['event'] as List<dynamic>? ?? <dynamic>[];
    final originatorId = body['originatorId'] as String? ?? '';
    final originatorRole =
        (body['originatorRole'] as String? ?? 'CONSUMER').toUpperCase();
    final senderRole = originatorRole == 'CONSUMER'
        ? LpChannelType.consumer
        : LpChannelType.agent;

    for (final raw in eventsJson) {
      final e = raw as Map<String, dynamic>;
      final type = e['type'] as String? ?? '';

      // Content event
      if (type == 'ContentEvent') {
        final ctype = e['contentType'] as String? ?? 'text/plain';
        final message = e['message'] as String? ?? '';

        if (ctype == 'text/plain') {
          eventSink.add(
            LpMessageReceived(
              LpMessage(
                id: (e['sequence'] ?? DateTime.now().microsecondsSinceEpoch)
                    .toString(),
                conversationId: dialogId,
                sender: LpParticipant(
                  id: originatorId,
                  role: senderRole,
                ),
                type: LpMessageType.text,
                text: message,
                createdAt: DateTime.now().toUtc(),
                payload: LpMessagePayload(text: message),
              ),
            ),
          );
        }
      }

      // Rich content
      if (type == 'RichContentEvent') {
        final content = e['content'] as Map<String, dynamic>? ?? {};
        eventSink.add(
          LpMessageReceived(
            LpMessage(
              id: (e['sequence'] ?? DateTime.now().microsecondsSinceEpoch)
                  .toString(),
              conversationId: dialogId,
              sender: LpParticipant(
                id: originatorId,
                role: senderRole,
              ),
              type: LpMessageType.richContent,
              text: '',
              createdAt: DateTime.now().toUtc(),
              payload: _payloadFromRichContent(content),
            ),
          ),
        );
      }

      // Accept
      if (type == 'AcceptStatusEvent') {
        final seq = e['sequence']?.toString();
        if (seq != null) {
          eventSink.add(
            LpMessageStateChanged(
              LpMessage(
                id: seq,
                conversationId: dialogId,
                sender: LpParticipant(id: originatorId, role: senderRole),
                type: LpMessageType.text,
                text: '',
                createdAt: DateTime.now().toUtc(),
                state: LpMessageState.delivered,
                payload: const LpMessagePayload(),
              ),
            ),
          );
        }
      }

      // Read
      if (type == 'ReadStatusEvent') {
        final seq = e['sequence']?.toString();
        if (seq != null) {
          eventSink.add(
            LpMessageStateChanged(
              LpMessage(
                id: seq,
                conversationId: dialogId,
                sender: LpParticipant(id: originatorId, role: senderRole),
                type: LpMessageType.text,
                text: '',
                createdAt: DateTime.now().toUtc(),
                state: LpMessageState.read,
                payload: const LpMessagePayload(),
              ),
            ),
          );
        }
      }

      // Typing
      if (type == 'ChatStateEvent') {
        final chatState = (e['chatState'] as String? ?? '').toUpperCase();
        final isTyping = chatState == 'COMPOSING';
        eventSink.add(
          LpTypingIndicator(conversationId: dialogId, isTyping: isTyping),
        );
      }
    }
  }

  LpMessagePayload _payloadFromRichContent(Map<String, dynamic> content) {
    final type = content['type'] as String? ?? '';
    if (type == 'quickReplies') {
      final replies = content['replies'] as List<dynamic>? ?? const [];
      final items = <LpQuickReply>[];
      for (var i = 0; i < replies.length; i += 1) {
        final reply = replies[i] as Map<String, dynamic>? ?? const {};
        final button = reply['button'] as Map<String, dynamic>? ?? const {};
        final title = button['title'] as String? ?? '';
        final actions = button['click']?['actions'] as List<dynamic>? ?? const [];
        final action = actions.isNotEmpty
            ? actions.first as Map<String, dynamic>? ?? const {}
            : const <String, dynamic>{};
        final payload = action['text'] as String?;
        if (title.isEmpty) continue;
        items.add(
          LpQuickReply(
            id: '${i + 1}',
            title: title,
            payload: payload,
          ),
        );
      }
      return LpMessagePayload(
        quickReplies: items,
        structuredContent: content,
      );
    }

    return LpMessagePayload(structuredContent: content);
  }
}
