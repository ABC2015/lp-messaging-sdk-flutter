import 'package:flutter_test/flutter_test.dart';
import 'package:lp_messaging_sdk_flutter/lp_messaging_sdk_flutter.dart';

void main() {
  test('LpConfig toJson/fromJson roundtrip', () {
    // This verifies our channel payload shape stays stable over time.
    const cfg = LpConfig(
      account: 'acct',
      enableLogging: true,
      extras: {'k': 'v'},
    );

    final json = cfg.toJson();

    // fromJson expects Map<Object?, Object?> since platform channels often use that type.
    final back = LpConfig.fromJson(json.map((k, v) => MapEntry(k, v)));

    expect(back.account, 'acct');
    expect(back.enableLogging, true);
    expect(back.extras['k'], 'v');
  });

  test('LpConversationParams toJson/fromJson roundtrip', () {
    const params = LpConversationParams(
      campaignInfo: 'cmp',
      visitorId: 'visitor',
      customVariables: {'a': 'b'},
    );

    final json = params.toJson();
    final back = LpConversationParams.fromJson(
      json.map((k, v) => MapEntry(k, v)),
    );

    expect(back.campaignInfo, 'cmp');
    expect(back.visitorId, 'visitor');
    expect(back.customVariables['a'], 'b');
  });
}
