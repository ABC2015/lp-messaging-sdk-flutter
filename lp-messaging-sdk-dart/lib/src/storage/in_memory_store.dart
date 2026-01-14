import '../models/lp_message.dart';
import 'lp_persistence.dart';

/// Simple in-memory persistence implementation.
///
/// Useful for tests and for environments where local persistence is
/// not needed (or as a starting point before wiring Hive).
class InMemoryPersistence implements LpPersistence {
  final Map<String, LpMessage> _pending = <String, LpMessage>{};

  @override
  Future<void> init() async {
    // nothing to initialize
  }

  @override
  Future<void> savePendingMessage(LpMessage message) async {
    _pending[message.id] = message;
  }

  @override
  Future<void> removePendingMessage(String messageId) async {
    _pending.remove(messageId);
  }

  @override
  Future<List<LpMessage>> loadPendingMessages() async {
    final messages = _pending.values.toList();
    messages.sort(
      (a, b) => a.createdAt.compareTo(b.createdAt),
    );
    return messages;
  }

  @override
  Future<void> clear() async {
    _pending.clear();
  }
}
