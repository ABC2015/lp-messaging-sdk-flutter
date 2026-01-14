import 'lp_channel.dart';
import 'lp_enums.dart';
import 'lp_message.dart';
import 'lp_participant.dart';

class LpConversation {
  const LpConversation({
    required this.id,
    required this.state,
    required this.participants,
    this.messages = const [],
    this.channel,
    this.createdAt,
    this.updatedAt,
    this.metadata,
  });

  final String id;
  final LpConversationState state;
  final List<LpParticipant> participants;
  final List<LpMessage> messages;
  final LpChannel? channel;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? metadata;

  LpConversation copyWith({
    LpConversationState? state,
    List<LpParticipant>? participants,
    List<LpMessage>? messages,
    LpChannel? channel,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return LpConversation(
      id: id,
      state: state ?? this.state,
      participants: participants ?? this.participants,
      messages: messages ?? this.messages,
      channel: channel ?? this.channel,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'state': state.name,
      'participants': participants.map((p) => p.toJson()).toList(),
      'messages': messages.map((m) => m.toJson()).toList(),
      if (channel != null) 'channel': channel!.toJson(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory LpConversation.fromJson(Map<String, dynamic> json) {
    final stateName = json['state'] as String? ?? 'active';

    final partsJson = json['participants'] as List<dynamic>? ?? <dynamic>[];
    final parts = partsJson
        .whereType<Map<String, dynamic>>()
        .map(LpParticipant.fromJson)
        .toList();

    final messagesJson = json['messages'] as List<dynamic>? ?? <dynamic>[];
    final messages = messagesJson
        .whereType<Map<String, dynamic>>()
        .map(LpMessage.fromJson)
        .toList();

    return LpConversation(
      id: json['id'] as String? ?? '',
      state: LpConversationState.values.firstWhere(
        (s) => s.name == stateName,
        orElse: () => LpConversationState.active,
      ),
      participants: parts,
      messages: messages,
      channel: json['channel'] is Map<String, dynamic>
          ? LpChannel.fromJson(json['channel'] as Map<String, dynamic>)
          : null,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}
