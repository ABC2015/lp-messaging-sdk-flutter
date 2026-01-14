/// Which side this client represents.
enum LpChannelType {
  consumer,
  agent,
  bot,
}

/// High-level message content type.
enum LpMessageType {
  text,
  richContent,
  file,
  system,
}

/// Delivery / lifecycle state of a message.
enum LpMessageState {
  sending,
  sent,
  delivered,
  read,
  failed,
}

/// High-level conversation state.
enum LpConversationState {
  newConversation,
  active,
  resolved,
  closed,
}

/// Connection state of the underlying WebSocket.
enum LpConnectionState {
  idle,
  connecting,
  connected,
  reconnecting,
  disconnected,
}

/// Log verbosity.
enum LpLogLevel {
  debug,
  info,
  warning,
  error,
}
