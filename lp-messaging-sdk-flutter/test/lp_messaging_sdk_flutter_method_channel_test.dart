import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lp_messaging_sdk_flutter/src/method_channel_impl.dart';
import 'package:lp_messaging_sdk_flutter/src/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('lp_messaging_sdk_flutter');
  final log = <MethodCall>[];

  setUp(() {
    channel.setMockMethodCallHandler((call) async {
      log.add(call);
      return null;
    });
    log.clear();
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('initialize calls native method with payload', () async {
    final platform = MethodChannelLpMessaging();
    await platform.initialize(
      const LpNativeInitConfig(
        accountId: 'acct',
        appId: 'com.example.app',
        jwt: 'token',
      ),
    );

    expect(log, hasLength(1));
    expect(log.single.method, 'initialize');

    final args = log.single.arguments as Map?;
    expect(args?['accountId'], 'acct');
    expect(args?['appId'], 'com.example.app');
    expect(args?['jwt'], 'token');
  });

  test('showConversation calls native method', () async {
    final platform = MethodChannelLpMessaging();
    await platform.showConversation(
      auth: const LpAuthConfig(jwt: 'jwt', performStepUp: true),
    );

    expect(log, hasLength(1));
    expect(log.single.method, 'showConversation');

    final args = log.single.arguments as Map?;
    final auth = args?['auth'] as Map?;
    expect(auth?['jwt'], 'jwt');
    expect(auth?['performStepUp'], true);
  });

  test('registerPushToken calls native method', () async {
    final platform = MethodChannelLpMessaging();
    await platform.registerPushToken(
      const LpPushConfig(
        token: 'token',
        auth: LpAuthConfig(jwt: 'jwt'),
      ),
    );

    expect(log, hasLength(1));
    expect(log.single.method, 'registerPushToken');
    final args = log.single.arguments as Map?;
    expect(args?['token'], 'token');
    final auth = args?['auth'] as Map?;
    expect(auth?['jwt'], 'jwt');
  });

  test('getUnreadCount calls native method', () async {
    channel.setMockMethodCallHandler((call) async {
      log.add(call);
      if (call.method == 'getUnreadCount') return 3;
      return null;
    });

    final platform = MethodChannelLpMessaging();
    final count = await platform.getUnreadCount();

    expect(count, 3);
    expect(log.single.method, 'getUnreadCount');
  });
}
