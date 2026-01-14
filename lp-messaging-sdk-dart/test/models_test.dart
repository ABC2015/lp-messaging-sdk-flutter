import 'package:test/test.dart';
import 'package:lp_messaging_sdk_dart/lp_messaging_sdk_dart.dart';

void main() {
  test('LpMessage copyWith works', () {
    final msg = LpMessage(
      id: '1',
      conversationId: 'c1',
      sender: const LpParticipant(id: 'u1', role: LpChannelType.consumer),
      type: LpMessageType.text,
      text: 'hi',
      createdAt: DateTime.utc(2024),
    );

    final updated = msg.copyWith(text: 'hello');
    expect(updated.text, 'hello');
    expect(updated.id, msg.id);
  });
}
