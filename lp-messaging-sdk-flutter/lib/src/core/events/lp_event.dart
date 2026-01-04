/// Base class for all events emitted by the plugin.
///
/// Why typed events:
/// - Safer than dynamic maps
/// - Easier to evolve without breaking consumers
/// - Enables IDE autocomplete and refactoring
abstract class LpEvent {
  /// Discriminator for event kind ("connection", "message", etc).
  final String type;

  /// When the event was emitted (best effort).
  final DateTime timestamp;

  const LpEvent(this.type, this.timestamp);

  /// Convert into serializable map (useful for logging or forwarding).
  Map<String, Object?> toJson();
}
