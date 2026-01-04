import '../events/lp_connection_event.dart';
import '../events/lp_conversation_event.dart';
import '../events/lp_error_event.dart';
import '../events/lp_event.dart';
import '../events/lp_message_event.dart';

/// iOS-specific mapping.
///
/// Kept separate from Android in case payload shapes diverge later.
class IosEventMapper {
  const IosEventMapper();

  LpEvent? fromMap(Map payload) {
    final type = payload['type']?.toString();
    final ts =
        DateTime.tryParse(payload['timestamp']?.toString() ?? '') ??
        DateTime.now();

    switch (type) {
      case 'connection':
        return LpConnectionEvent(
          state: _conn(payload['state']?.toString()),
          timestamp: ts,
        );

      case 'conversation':
        return LpConversationEvent(
          state: _conv(payload['state']?.toString()),
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
          code: payload['code']?.toString() ?? 'native_error',
          message: payload['message']?.toString() ?? 'Native error',
          details: payload['details'],
          timestamp: ts,
        );

      default:
        return null;
    }
  }

  LpConnectionState _conn(String? v) => LpConnectionState.values.firstWhere(
    (e) => e.name == v,
    orElse: () => LpConnectionState.disconnected,
  );

  LpConversationState _conv(String? v) => LpConversationState.values.firstWhere(
    (e) => e.name == v,
    orElse: () => LpConversationState.opened,
  );
}
