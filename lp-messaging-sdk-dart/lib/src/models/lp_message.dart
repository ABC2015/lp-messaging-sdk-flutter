import 'lp_enums.dart';
import 'lp_participant.dart';
import 'structured_content.dart';

/// Full payload for a message: text, structured content, attachments, metadata.
class LpMessagePayload {
  final String? text;
  final List<LpQuickReply> quickReplies;
  final List<LpCard> cards;
  final List<LpAttachment> attachments;
  final Map<String, dynamic> custom;
  final Map<String, dynamic>? structuredContent;

  const LpMessagePayload({
    this.text,
    this.quickReplies = const [],
    this.cards = const [],
    this.attachments = const [],
    this.custom = const {},
    this.structuredContent,
  });

  Map<String, dynamic> toJson() => {
        if (text != null) 'text': text,
        if (quickReplies.isNotEmpty)
          'quickReplies': quickReplies.map((q) => q.toJson()).toList(),
        if (cards.isNotEmpty) 'cards': cards.map((c) => c.toJson()).toList(),
        if (attachments.isNotEmpty)
          'attachments': attachments.map((a) => a.toJson()).toList(),
        if (custom.isNotEmpty) 'custom': custom,
        if (structuredContent != null) 'structuredContent': structuredContent,
      };

  static LpMessagePayload fromJson(Map<String, dynamic> json) {
    final quickReplies = (json['quickReplies'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(LpQuickReply.fromJson)
        .toList(growable: false);

    final cards = (json['cards'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(LpCard.fromJson)
        .toList(growable: false);

    final attachments = (json['attachments'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(LpAttachment.fromJson)
        .toList(growable: false);

    final custom =
        (json['custom'] as Map<String, dynamic>?) ?? const <String, dynamic>{};

    return LpMessagePayload(
      text: json['text'] as String?,
      quickReplies: quickReplies,
      cards: cards,
      attachments: attachments,
      custom: custom,
      structuredContent: json['structuredContent'] as Map<String, dynamic>?,
    );
  }
}

class LpMessage {
  const LpMessage({
    required this.id,
    required this.conversationId,
    required this.sender,
    required this.type,
    required this.text,
    required this.createdAt,
    this.payload = const LpMessagePayload(),
    this.state = LpMessageState.sent,
    this.metadata,
  });

  /// Local or server-generated ID. For inbound messages this will usually be
  /// derived from LP sequence / event id.
  final String id;

  final String conversationId;

  final LpParticipant sender;

  final LpMessageType type;

  final String text;

  final DateTime createdAt;

  final LpMessagePayload payload;

  final LpMessageState state;

  final Map<String, dynamic>? metadata;

  LpMessage copyWith({
    String? id,
    String? conversationId,
    LpParticipant? sender,
    LpMessageType? type,
    String? text,
    DateTime? createdAt,
    LpMessagePayload? payload,
    LpMessageState? state,
    Map<String, dynamic>? metadata,
  }) {
    return LpMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      sender: sender ?? this.sender,
      type: type ?? this.type,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      payload: payload ?? this.payload,
      state: state ?? this.state,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'conversationId': conversationId,
      'sender': sender.toJson(),
      'type': type.name,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
      'payload': payload.toJson(),
      'state': state.name,
      'metadata': metadata,
    };
  }

  factory LpMessage.fromJson(Map<String, dynamic> json) {
    final typeName = json['type'] as String? ?? 'text';
    final stateName = json['state'] as String? ?? 'sent';

    return LpMessage(
      id: json['id'] as String? ?? '',
      conversationId: json['conversationId'] as String? ?? '',
      sender: LpParticipant.fromJson(
        (json['sender'] as Map<String, dynamic>? ?? <String, dynamic>{}),
      ),
      type: LpMessageType.values.firstWhere(
        (t) => t.name == typeName,
        orElse: () => LpMessageType.text,
      ),
      text: json['text'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
              DateTime.now().toUtc(),
      payload: LpMessagePayload.fromJson(
        (json['payload'] as Map<String, dynamic>? ?? const <String, dynamic>{}),
      ),
      state: LpMessageState.values.firstWhere(
        (s) => s.name == stateName,
        orElse: () => LpMessageState.sent,
      ),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}
