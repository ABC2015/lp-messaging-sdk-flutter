import '../events/lp_connection_event.dart';
import '../events/lp_conversation_event.dart';
import '../events/lp_error_event.dart';
import '../events/lp_event.dart';
import '../events/lp_message_event.dart';
import 'android_event_mapper.dart';
import 'ios_event_mapper.dart';

/// Maps raw EventChannel payloads into typed Dart events.
///
/// Expected wire format:
/// - Prefer: { "platform": "android"|"ios", "payload": { ... } }
/// - Fallback: allow payload directly if platform wrapper is not present
class EventMapper {
  const EventMapper();

  LpEvent? fromNative(dynamic raw) {
    if (raw is! Map) return null;

    // Some implementations wrap payload with platform info.
    final platform = raw['platform']?.toString();
    final payload = (raw['payload'] is Map) ? raw['payload'] as Map : raw;

    if (platform == 'android') {
      return const AndroidEventMapper().fromMap(payload);
    }
    if (platform == 'ios') {
      return const IosEventMapper().fromMap(payload);
    }

    // Unknown platform: attempt a generic mapping.
    return _generic(payload);
  }

  /// Generic mapping used when platform hint isn't provided.
  /// Keep this compatible with both iOS and Android payload shapes.
  LpEvent? _generic(Map payload) {
    final type = payload['type']?.toString();
    final ts =
        DateTime.tryParse(payload['timestamp']?.toString() ?? '') ??
        DateTime.now();

    switch (type) {
      case 'connection':
        final state = payload['state']?.toString() ?? 'disconnected';
        return LpConnectionEvent(
          state: LpConnectionState.values.firstWhere(
            (e) => e.name == state,
            orElse: () => LpConnectionState.disconnected,
          ),
          timestamp: ts,
        );

      case 'conversation':
        final state = payload['state']?.toString() ?? 'opened';
        return LpConversationEvent(
          state: LpConversationState.values.firstWhere(
            (e) => e.name == state,
            orElse: () => LpConversationState.opened,
          ),
          timestamp: ts,
        );

      case 'message':
        return LpMessageEvent(
          messageId: payload['messageId']?.toString() ?? '',
          text: payload['text']?.toString(),
          sender: payload['sender']?.toString(),
          timestamp: ts,
        );

      case 'error':
        return LpErrorEvent(
          code: payload['code']?.toString() ?? 'unknown',
          message: payload['message']?.toString() ?? 'Unknown error',
          details: payload['details'],
          timestamp: ts,
        );

      default:
        // Unknown event type: ignore for forwards compatibility.
        return null;
    }
  }
}
