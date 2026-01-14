import 'package:hive/hive.dart';

import '../models/lp_message.dart';
import 'lp_persistence.dart';

/// Hive-based offline queue.
/// Persists unsent messages between app launches.
class HivePersistence implements LpPersistence {
  HivePersistence(this.boxName);

  final String boxName;
  Box<Map>? _box;

  @override
  Future<void> init() async {
    _box = await Hive.openBox<Map>(boxName);
  }

  @override
  Future<void> savePendingMessage(LpMessage message) async {
    await _box!.put(message.id, message.toJson());
  }

  @override
  Future<void> removePendingMessage(String messageId) async {
    await _box!.delete(messageId);
  }

  @override
  Future<List<LpMessage>> loadPendingMessages() async {
    final values = _box!.values;
    return values
        .map((e) => LpMessage.fromJson(Map<String, dynamic>.from(e)))
        .toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  @override
  Future<void> clear() async {
    await _box!.clear();
  }
}
