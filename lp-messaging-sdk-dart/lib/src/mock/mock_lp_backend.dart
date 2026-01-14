import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/http.dart';

import '../models/lp_channel.dart';
import '../models/lp_conversation.dart';
import '../models/lp_enums.dart';
import '../models/lp_message.dart';
import '../models/lp_participant.dart';
import '../core/lp_logger.dart';

/// A tiny in-memory "backend" that simulates the HTTP API used by
/// consumer/agent flows for local tests or demos.
///
/// It implements the following POST paths:
///
///  - /api/conversations/start
///  - /api/conversations/get
///  - /api/conversations/send-message
///
///  - /api/agent/conversations/list-active
///  - /api/agent/conversations/accept
///  - /api/agent/conversations/release
///  - /api/agent/conversations/send-message
///
/// This is only for tests / demos; not for production.
class MockLpBackend {
  final Map<String, LpConversation> _conversations = {};
  int _idCounter = 0;

  String _nextId([String prefix = 'id']) => '$prefix-${_idCounter++}';

  /// Handle an incoming HTTP request and produce a Response.
  ///
  /// This is used by [MockHttpClient] (a custom http.Client implementation)
  /// so that your SDK can run without any real network.
  Future<Response> handle(String method, Uri uri, String body) async {
    if (method != 'POST') {
      return Response(
        jsonEncode({'error': 'Only POST is allowed in mock backend'}),
        405,
        headers: {'content-type': 'application/json'},
      );
    }

    final path = uri.path;
    Map<String, dynamic> jsonBody = {};
    if (body.isNotEmpty) {
      try {
        jsonBody = jsonDecode(body) as Map<String, dynamic>;
      } catch (e) {
        return Response(
          jsonEncode({'error': 'Invalid JSON body'}),
          400,
          headers: {'content-type': 'application/json'},
        );
      }
    }

    try {
      if (path == '/api/conversations/start') {
        return _handleStart(jsonBody);
      } else if (path == '/api/conversations/get') {
        return _handleGet(jsonBody);
      } else if (path == '/api/conversations/send-message') {
        return _handleSendMessage(jsonBody, fromRole: LpChannelType.consumer);
      } else if (path == '/api/agent/conversations/list-active') {
        return _handleListActive();
      } else if (path == '/api/agent/conversations/accept') {
        return _handleAccept(jsonBody);
      } else if (path == '/api/agent/conversations/release') {
        return _handleRelease(jsonBody);
      } else if (path == '/api/agent/conversations/send-message') {
        return _handleSendMessage(jsonBody, fromRole: LpChannelType.agent);
      }

      return Response(
        jsonEncode({'error': 'Unknown mock path: $path'}),
        404,
        headers: {'content-type': 'application/json'},
      );
    } catch (e, st) {
      LpLogger().error('Mock backend error for $path', e, st);
      return Response(
        jsonEncode({'error': 'Mock error: $e'}),
        500,
        headers: {'content-type': 'application/json'},
      );
    }
  }

  Response _handleStart(Map<String, dynamic> body) {
    final consumerId = body['consumerId'] as String?;
    final skill = body['skill'] as String?;

    if (consumerId == null || consumerId.trim().isEmpty) {
      return Response(
        jsonEncode({'error': 'consumerId required'}),
        400,
        headers: {'content-type': 'application/json'},
      );
    }

    // Check if there is already an active conversation for this consumer.
    final existing = _conversations.values.where((c) {
      return c.participants.any(
        (p) => p.role == LpChannelType.consumer && p.id == consumerId,
      );
    }).toList();

    if (existing.isNotEmpty) {
      return Response(
        jsonEncode(existing.first.toJson()),
        200,
        headers: {'content-type': 'application/json'},
      );
    }

    final now = DateTime.now().toUtc();
    final conversationId = _nextId('convo');
    final consumer = LpParticipant(
      id: consumerId,
      role: LpChannelType.consumer,
      displayName: 'Consumer $consumerId',
    );

    final channel = LpChannel(
      id: 'channel-web',
      type: LpSourceChannelType.web,
      metadata: {
        if (skill != null) 'skill': skill,
      },
    );

    final convo = LpConversation(
      id: conversationId,
      state: LpConversationState.active,
      participants: [consumer],
      messages: const [],
      channel: channel,
      createdAt: now,
      updatedAt: now,
      metadata: {
        'status': 'open',
      },
    );

    _conversations[conversationId] = convo;

    return Response(
      jsonEncode(convo.toJson()),
      200,
      headers: {'content-type': 'application/json'},
    );
  }

  Response _handleGet(Map<String, dynamic> body) {
    final id = body['conversationId'] as String?;
    if (id == null || id.isEmpty) {
      return Response(
        jsonEncode({'error': 'conversationId required'}),
        400,
        headers: {'content-type': 'application/json'},
      );
    }

    final convo = _conversations[id];
    if (convo == null) {
      return Response(
        jsonEncode({'error': 'conversation not found'}),
        404,
        headers: {'content-type': 'application/json'},
      );
    }

    return Response(
      jsonEncode(convo.toJson()),
      200,
      headers: {'content-type': 'application/json'},
    );
  }

  Response _handleSendMessage(
    Map<String, dynamic> body, {
    required LpChannelType fromRole,
  }) {
    final convoId = body['conversationId'] as String?;
    final text = body['text'] as String?;

    if (convoId == null || convoId.isEmpty) {
      return Response(
        jsonEncode({'error': 'conversationId required'}),
        400,
        headers: {'content-type': 'application/json'},
      );
    }
    if (text == null || text.trim().isEmpty) {
      return Response(
        jsonEncode({'error': 'text required'}),
        400,
        headers: {'content-type': 'application/json'},
      );
    }

    final convo = _conversations[convoId];
    if (convo == null) {
      return Response(
        jsonEncode({'error': 'conversation not found'}),
        404,
        headers: {'content-type': 'application/json'},
      );
    }

    final participant = convo.participants.firstWhere(
      (p) => p.role == fromRole,
      orElse: () => LpParticipant(
        id: fromRole.name,
        role: fromRole,
        displayName: fromRole.name,
      ),
    );

    final now = DateTime.now().toUtc();
    final messageId = _nextId('msg');

    final message = LpMessage(
      id: messageId,
      conversationId: convoId,
      sender: participant,
      type: LpMessageType.text,
      text: text,
      createdAt: now,
      payload: LpMessagePayload(text: text),
      metadata: const {},
    );

    final updatedMessages = [...convo.messages, message];
    final updatedConvo = convo.copyWith(
      messages: updatedMessages,
      updatedAt: now,
    );
    _conversations[convoId] = updatedConvo;

    return Response(
      jsonEncode(message.toJson()),
      200,
      headers: {'content-type': 'application/json'},
    );
  }

  Response _handleListActive() {
    final items = _conversations.values
        .where((c) => c.metadata?['status'] != 'closed')
        .map((c) => c.toJson())
        .toList(growable: false);

    return Response(
      jsonEncode({'items': items}),
      200,
      headers: {'content-type': 'application/json'},
    );
  }

  Response _handleAccept(Map<String, dynamic> body) {
    final id = body['conversationId'] as String?;
    if (id == null || id.isEmpty) {
      return Response(
        jsonEncode({'error': 'conversationId required'}),
        400,
        headers: {'content-type': 'application/json'},
      );
    }

    final convo = _conversations[id];
    if (convo == null) {
      return Response(
        jsonEncode({'error': 'conversation not found'}),
        404,
        headers: {'content-type': 'application/json'},
      );
    }

    // Mark conversation as "assigned" in metadata.
    final updated = convo.copyWith(
      metadata: {
        ...?convo.metadata,
        'status': 'assigned',
      },
    );
    _conversations[id] = updated;

    return Response(
      jsonEncode(updated.toJson()),
      200,
      headers: {'content-type': 'application/json'},
    );
  }

  Response _handleRelease(Map<String, dynamic> body) {
    final id = body['conversationId'] as String?;
    if (id == null || id.isEmpty) {
      return Response(
        jsonEncode({'error': 'conversationId required'}),
        400,
        headers: {'content-type': 'application/json'},
      );
    }

    final convo = _conversations[id];
    if (convo == null) {
      return Response(
        jsonEncode({'error': 'conversation not found'}),
        404,
        headers: {'content-type': 'application/json'},
      );
    }

    final updated = convo.copyWith(
      metadata: {
        ...?convo.metadata,
        'status': 'open',
      },
    );
    _conversations[id] = updated;

    return Response(
      jsonEncode({'ok': true}),
      200,
      headers: {'content-type': 'application/json'},
    );
  }
}

/// http.Client implementation that forwards all requests to [MockLpBackend]
/// in-process, without any real network.
class MockHttpClient extends http.BaseClient {
  final MockLpBackend backend;

  MockHttpClient(this.backend);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final body = request is http.Request ? request.body : '';
    final res = await backend.handle(
      request.method,
      request.url,
      body,
    );

    final stream = Stream<List<int>>.value(utf8.encode(res.body));
    return http.StreamedResponse(
      stream,
      res.statusCode,
      headers: res.headers,
      reasonPhrase: res.reasonPhrase,
    );
  }
}
