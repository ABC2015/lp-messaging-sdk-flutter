import 'lp_event.dart';

/// Connection state machine for the SDK.
enum LpConnectionState { connecting, connected, disconnected }

/// Emitted when native SDK connection status changes.
class LpConnectionEvent extends LpEvent {
  final LpConnectionState state;

  const LpConnectionEvent({required this.state, required DateTime timestamp})
    : super('connection', timestamp);

  @override
  Map<String, Object?> toJson() => {
    'type': type,
    'timestamp': timestamp.toIso8601String(),
    'state': state.name,
  };
}
