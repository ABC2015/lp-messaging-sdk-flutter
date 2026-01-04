import 'lp_event.dart';

/// Emitted when a message is received/sent.
///
/// This is an intentionally small model. Expand as needed
/// (attachments, rich content, metadata).
class LpMessageEvent extends LpEvent {
  final String messageId;
  final String? text;
  final String? sender;

  const LpMessageEvent({
    required this.messageId,
    required DateTime timestamp,
    this.text,
    this.sender,
  }) : super('message', timestamp);

  @override
  Map<String, Object?> toJson() => {
    'type': type,
    'timestamp': timestamp.toIso8601String(),
    'messageId': messageId,
    'text': text,
    'sender': sender,
  };
}
