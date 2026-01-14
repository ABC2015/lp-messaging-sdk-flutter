import 'lp_conversation.dart';
import 'lp_enums.dart';
import 'lp_message.dart';
import 'lp_error.dart';

/// Base class for all events emitted by the SDK.
abstract class LpEvent {
  const LpEvent();
}

/// Base class for agent-side events.
abstract class LpAgentEvent extends LpEvent {
  const LpAgentEvent();
}

/// Connection state changed (e.g. connecting to connected).
class LpConnectionStateChanged extends LpEvent {
  const LpConnectionStateChanged(this.state);

  final LpConnectionState state;
}

/// A conversation's metadata or lifecycle changed.
class LpConversationUpdated extends LpEvent {
  const LpConversationUpdated(this.conversation);

  final LpConversation conversation;
}

/// A new message was received (from local or remote).
class LpMessageReceived extends LpEvent {
  const LpMessageReceived(this.message);

  final LpMessage message;
}

/// Delivery/read state of a message changed.
class LpMessageStateChanged extends LpEvent {
  const LpMessageStateChanged(this.message);

  final LpMessage message;
}

/// Typing indicator in a conversation.
class LpTypingIndicator extends LpEvent {
  const LpTypingIndicator({
    required this.conversationId,
    required this.isTyping,
  });

  final String conversationId;
  final bool isTyping;
}

/// Any error surfaced by the SDK.
class LpErrorEvent extends LpEvent {
  const LpErrorEvent(this.error);

  final LpError error;
}

/// New routing offer for an agent.
class LpRoutingOfferReceived extends LpAgentEvent {
  const LpRoutingOfferReceived({
    required this.conversation,
    this.timeToLive,
  });

  final LpConversation conversation;
  final Duration? timeToLive;
}

/// Conversation assigned to the agent.
class LpConversationAssigned extends LpAgentEvent {
  const LpConversationAssigned(this.conversation);

  final LpConversation conversation;
}

/// Conversation released from the agent.
class LpConversationReleased extends LpAgentEvent {
  const LpConversationReleased(this.conversationId);

  final String conversationId;
}

/// New message in a conversation visible to the agent.
class LpAgentMessageAdded extends LpAgentEvent {
  const LpAgentMessageAdded({
    required this.conversationId,
    required this.message,
  });

  final String conversationId;
  final LpMessage message;
}
