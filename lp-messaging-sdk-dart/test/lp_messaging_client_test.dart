import 'package:test/test.dart';
import 'package:lp_messaging_sdk_dart/lp_messaging_sdk_dart.dart';

void main() {
  test('Client queues message when offline', () async {
    final config = LpConfig(
      accountId: '123',
      jwtProvider: staticJwtProvider('dummy'),
    );
    final store = InMemoryPersistence();
    final client = LpMessagingClient(config: config, persistence: store);

    await client.init();
    await client.startConversation();
    await client.sendText('hello');

    final pending = await store.loadPendingMessages();
    expect(pending.length, 1);
  });
}
