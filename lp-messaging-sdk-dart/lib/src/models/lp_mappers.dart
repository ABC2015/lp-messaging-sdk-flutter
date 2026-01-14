import 'lp_channel.dart';
import 'lp_conversation.dart';
import 'lp_enums.dart';
import 'lp_message.dart';
import 'lp_participant.dart';

LpSourceChannelType parseSourceChannelType(String? raw) {
  switch (raw) {
    case 'whatsapp':
      return LpSourceChannelType.whatsapp;
    case 'tiktok':
      return LpSourceChannelType.tiktok;
    case 'instagram':
      return LpSourceChannelType.instagram;
    case 'apple_messages':
      return LpSourceChannelType.appleMessages;
    case 'sms':
      return LpSourceChannelType.sms;
    case 'facebook':
      return LpSourceChannelType.facebookMessenger;
    case 'mobile':
      return LpSourceChannelType.mobile;
    case 'web':
      return LpSourceChannelType.web;
    default:
      return LpSourceChannelType.other;
  }
}

LpChannel channelFromJson(Map<String, dynamic> json) => LpChannel(
      id: json['id'] as String? ?? 'unknown',
      type: parseSourceChannelType(json['type'] as String?),
      metadata:
          (json['metadata'] as Map<String, dynamic>?) ?? const <String, dynamic>{},
    );

LpChannelType parseParticipantRole(String? raw) {
  switch ((raw ?? '').toLowerCase()) {
    case 'agent':
      return LpChannelType.agent;
    case 'bot':
      return LpChannelType.bot;
    default:
      return LpChannelType.consumer;
  }
}

LpParticipant participantFromJson(Map<String, dynamic> json) => LpParticipant(
      id: json['id'] as String? ?? '',
      role: parseParticipantRole(json['role'] as String?),
      displayName: json['displayName'] as String?,
    );

LpMessage messageFromJson(Map<String, dynamic> json) {
  final payloadJson =
      (json['payload'] as Map<String, dynamic>?) ?? const <String, dynamic>{};
  final payload = LpMessagePayload.fromJson(payloadJson);

  final senderJson = (json['sender'] as Map<String, dynamic>?) ??
      (json['from'] as Map<String, dynamic>?) ??
      const <String, dynamic>{};
  final sender = participantFromJson(senderJson);

  final typeName = json['type'] as String? ?? 'text';
  final type = LpMessageType.values.firstWhere(
    (t) => t.name == typeName,
    orElse: () => LpMessageType.text,
  );

  final createdAtRaw = json['createdAt'] ?? json['sentAt'];
  final createdAt = createdAtRaw is String
      ? DateTime.tryParse(createdAtRaw)
      : createdAtRaw is int
          ? DateTime.fromMillisecondsSinceEpoch(createdAtRaw).toUtc()
          : null;

  return LpMessage(
    id: json['id'] as String? ?? '',
    conversationId: json['conversationId'] as String? ?? '',
    sender: sender,
    type: type,
    text: json['text'] as String? ?? payload.text ?? '',
    createdAt: createdAt ?? DateTime.now().toUtc(),
    payload: payload,
    state: LpMessageState.values.firstWhere(
      (s) => s.name == (json['state'] as String? ?? 'sent'),
      orElse: () => LpMessageState.sent,
    ),
    metadata: json['metadata'] as Map<String, dynamic>?,
  );
}

LpConversation conversationFromJson(Map<String, dynamic> json) {
  final channelJson =
      (json['channel'] as Map<String, dynamic>?) ?? const <String, dynamic>{};
  final participantsJson =
      (json['participants'] as List<dynamic>? ?? const <dynamic>[])
          .cast<Map<String, dynamic>>();
  final messagesJson =
      (json['messages'] as List<dynamic>? ?? const <dynamic>[])
          .cast<Map<String, dynamic>>();
  final messages = messagesJson.map(messageFromJson).toList(growable: false);

  return LpConversation(
    id: json['id'] as String? ?? '',
    state: LpConversationState.values.firstWhere(
      (s) => s.name == (json['state'] as String? ?? 'active'),
      orElse: () => LpConversationState.active,
    ),
    participants: participantsJson.map(participantFromJson).toList(),
    messages: messages,
    channel: channelJson.isEmpty ? null : channelFromJson(channelJson),
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
    metadata: json['metadata'] as Map<String, dynamic>?,
  );
}
