import 'dart:math';

import '../models/structured_content.dart';

/// Low-level helpers to build Messaging Window API frames.
///
/// You pass [sendFrame] a JSON map and it will be sent on the WebSocket by
/// whatever owns the connection (LpSession, etc.).
class LpMessagingCommands {
  LpMessagingCommands(this.sendFrame);

  /// Function that actually writes to the WS.
  final void Function(Map<String, dynamic> frame) sendFrame;

  int _nextId = Random().nextInt(1000000);

  String _id() => (++_nextId).toString();

  /// Publish a plain text ContentEvent.
  void sendText({
    required String dialogId,
    required String message,
  }) {
    final frame = {
      'kind': 'req',
      'id': _id(),
      'type': 'ms.PublishEvent',
      'body': {
        'dialogId': dialogId,
        'event': {
          'type': 'ContentEvent',
          'contentType': 'text/plain',
          'message': message,
        },
      },
    };

    sendFrame(frame);
  }

  /// Publish a RichContentEvent (Structured Content).
  void sendRichContent({
    required String dialogId,
    required LpStructuredContent content,
  }) {
    final frame = {
      'kind': 'req',
      'id': _id(),
      'type': 'ms.PublishEvent',
      'body': {
        'dialogId': dialogId,
        'event': {
          'type': 'RichContentEvent',
          'content': content.toJson(),
        },
      },
    };

    sendFrame(frame);
  }

  /// Send quick replies using RichContentEvent wrapper.
  void sendQuickReplies({
    required String dialogId,
    required LpQuickRepliesContent quickReplies,
  }) {
    final frame = {
      'kind': 'req',
      'id': _id(),
      'type': 'ms.PublishEvent',
      'body': {
        'dialogId': dialogId,
        'event': {
          'type': 'RichContentEvent',
          'content': quickReplies.toJson(),
        },
      },
    };

    sendFrame(frame);
  }

  /// Send typing on/off using ChatStateEvent.
  void sendTyping({
    required String dialogId,
    required bool isTyping,
  }) {
    final frame = {
      'kind': 'req',
      'id': _id(),
      'type': 'ms.PublishEvent',
      'body': {
        'dialogId': dialogId,
        'event': {
          'type': 'ChatStateEvent',
          'chatState': isTyping ? 'COMPOSING' : 'ACTIVE',
        },
      },
    };

    sendFrame(frame);
  }

  /// Send Accept / Read receipts for one or more sequences.
  void sendReceipt({
    required String dialogId,
    required List<int> sequences,
    required String status, // 'ACCEPT' | 'READ'
  }) {
    final frame = {
      'kind': 'req',
      'id': _id(),
      'type': 'ms.PublishEvent',
      'body': {
        'dialogId': dialogId,
        'event': {
          'type': 'AcceptStatusEvent',
          'status': status,
          'sequenceList': sequences,
        },
      },
    };

    sendFrame(frame);
  }

  void sendAccept({
    required String dialogId,
    required List<int> sequences,
  }) =>
      sendReceipt(
        dialogId: dialogId,
        sequences: sequences,
        status: 'ACCEPT',
      );

  void sendRead({
    required String dialogId,
    required List<int> sequences,
  }) =>
      sendReceipt(
        dialogId: dialogId,
        sequences: sequences,
        status: 'READ',
      );
}
