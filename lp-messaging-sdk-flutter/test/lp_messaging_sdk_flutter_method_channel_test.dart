import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lp_messaging_sdk_flutter/lp_messaging_sdk_flutter_method_channel.dart';
import 'package:lp_messaging_sdk_flutter/src/core/lp_config.dart';
import 'package:lp_messaging_sdk_flutter/src/core/lp_conversation_params.dart';

void main() {
  // Ensures Flutter binding is available for MethodChannel mocking.
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('lp_messaging_sdk_flutter/methods');

  final log = <MethodCall>[];

  setUp(() {
    // Intercepts calls from our MethodChannel implementation so we can assert correctness.
    channel.setMockMethodCallHandler((call) async {
      log.add(call);
      return null; // We return null for void methods
    });
    log.clear();
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('initialize calls native method with payload', () async {
    final platform = MethodChannelLpMessagingSdkFlutter();
    await platform.initialize(const LpConfig(account: 'acct'));

    expect(log, hasLength(1));
    expect(log.single.method, 'initialize');

    // Optional: validate payload includes required keys
    final args = log.single.arguments as Map?;
    expect(args?['account'], 'acct');
  });

  test('showConversation calls native method', () async {
    final platform = MethodChannelLpMessagingSdkFlutter();
    await platform.showConversation(
      const LpConversationParams(campaignInfo: 'cmp'),
    );

    expect(log, hasLength(1));
    expect(log.single.method, 'showConversation');

    final args = log.single.arguments as Map?;
    expect(args?['campaignInfo'], 'cmp');
  });
}
