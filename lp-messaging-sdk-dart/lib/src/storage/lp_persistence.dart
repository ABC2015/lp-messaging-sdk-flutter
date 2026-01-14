import '../models/lp_message.dart';

/// Abstraction for offline storage of pending messages (and later, history).
///
/// You can implement this with Hive, sqflite, or any other store.
abstract class LpPersistence {
  /// Called once before use.
  Future<void> init();

  /// Save a message that still needs to be sent to LP.
  Future<void> savePendingMessage(LpMessage message);

  /// Remove a message that has been successfully sent.
  Future<void> removePendingMessage(String messageId);

  /// Load all pending messages, ordered in send order.
  Future<List<LpMessage>> loadPendingMessages();

  /// Clear all stored data.
  Future<void> clear();
}
