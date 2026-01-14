import '../config/lp_config.dart';
import '../core/lp_logger.dart';
import '../models/lp_conversation.dart';
import '../models/lp_enums.dart';
import '../models/lp_message.dart';
import '../models/lp_participant.dart';
import '../models/structured_content.dart';
import '../transport/lp_http_client.dart';

/// Wraps LivePerson Messaging REST API.
/// https://developers.liveperson.com/mobile-app-messaging-sdk-rest-api-overview.html
///
/// Implements:
/// - list conversations
/// - fetch messages in a conversation
/// - close/resolve conversation
class LpMessagingRestApi {
  LpMessagingRestApi({
    required this.config,
    required this.logger,
  }) : _http = LpHttpClient(logger: logger);

  final LpConfig config;
  final LpLogger logger;
  final LpHttpClient _http;

  /// Build base URI for messaging domain.
  Uri _base(String path, [Map<String, dynamic>? qp]) {
    final host = '${config.accountId}.messaging.liveperson.net';
    return Uri.https(host, path, qp?.map((k, v) => MapEntry(k, '$v')));
  }

  Future<String> _jwt() async => config.jwtProvider();

  /// List conversations (open or closed).
  ///
  /// `limit` is number of convs, `offset` is paging offset.
  Future<List<LpConversation>> listConversations({
    int limit = 20,
    int offset = 0,
    bool onlyActive = true,
  }) async {
    final token = await _jwt();

    final qp = {
      'offset': offset.toString(),
      'limit': limit.toString(),
      if (onlyActive) 'status': 'OPEN',
    };

    final uri = _base('/v1/conversations', qp);
    final json = await _http.getJson(uri, headers: {
      'Authorization': 'jwt $token',
    });

    final convs = <LpConversation>[];

    final data = json['conversations'] as List<dynamic>? ?? [];
    for (final raw in data) {
      final mp = raw as Map<String, dynamic>;

      final id = mp['conversationId']?.toString() ?? '';
      final state = ((mp['state'] ?? 'OPEN') == 'OPEN')
          ? LpConversationState.active
          : LpConversationState.closed;

      final partsJson = mp['participants'] as List<dynamic>? ?? [];
      final participants = partsJson.map((p) {
        final pid = p['id'] as String? ?? '';
        final roleName = (p['role'] as String? ?? '').toUpperCase();
        final role = roleName == 'CONSUMER'
            ? LpChannelType.consumer
            : LpChannelType.agent;
        return LpParticipant(id: pid, role: role);
      }).toList();

      convs.add(
        LpConversation(
          id: id,
          state: state,
          participants: participants,
          createdAt: DateTime.tryParse(mp['startTs']?.toString() ?? ''),
          updatedAt: DateTime.tryParse(mp['endTs']?.toString() ?? ''),
        ),
      );
    }

    return convs;
  }

  /// Pull transcript for a conversation (last N messages).
  Future<List<LpMessage>> getMessages(
    String conversationId, {
    int limit = 50,
    int offset = 0,
  }) async {
    final token = await _jwt();

    final qp = {
      'start': offset.toString(),
      'limit': limit.toString(),
    };

    final uri = _base('/v1/conversations/$conversationId/messages', qp);

    final json = await _http.getJson(uri, headers: {
      'Authorization': 'jwt $token',
    });

    final msgs = <LpMessage>[];

    final data = json['messages'] as List<dynamic>? ?? [];
    for (final raw in data) {
      final mp = raw as Map<String, dynamic>;

      final type = (mp['type'] as String? ?? 'ContentEvent').trim();
      if (type == 'ContentEvent' || type == 'RichContentEvent') {
        final text = mp['message']?.toString() ?? '';
        final senderRole =
            (mp['originatorRole']?.toString() ?? 'CONSUMER').toUpperCase();
        final richContent = mp['content'] is Map<String, dynamic>
            ? mp['content'] as Map<String, dynamic>
            : null;

        msgs.add(
          LpMessage(
            id: mp['sequence']?.toString() ??
                DateTime.now().millisecondsSinceEpoch.toString(),
            conversationId: conversationId,
            sender: LpParticipant(
              id: mp['originatorId']?.toString() ?? '',
              role: senderRole == 'CONSUMER'
                  ? LpChannelType.consumer
                  : LpChannelType.agent,
            ),
            type: type == 'RichContentEvent'
                ? LpMessageType.richContent
                : LpMessageType.text,
            text: text,
            createdAt: DateTime.tryParse(mp['serverTs']?.toString() ?? '') ??
                DateTime.now().toUtc(),
            payload: type == 'RichContentEvent' && richContent != null
                ? _payloadFromRichContent(richContent)
                : LpMessagePayload(text: text.isEmpty ? null : text),
          ),
        );
      }
    }

    return msgs;
  }

  /// Close or resolve a conversation.
  Future<void> closeConversation(String conversationId) async {
    final token = await _jwt();

    final uri = _base('/v1/conversations/$conversationId/close');

    final json = await _http.postJson(
      uri,
      headers: {
        'Authorization': 'jwt $token',
      },
      body: {},
    );

    // Return OK if call succeeds; errors are thrown by _http.
    logger.info('closeConversation($conversationId) => $json');
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
