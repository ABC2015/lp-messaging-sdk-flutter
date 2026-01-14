import 'package:flutter_test/flutter_test.dart';
import 'package:lp_messaging_sdk_flutter/src/models.dart';

void main() {
  test('LpNativeInitConfig toMap includes required fields', () {
    const cfg = LpNativeInitConfig(
      accountId: 'acct',
      appId: 'com.example.app',
      jwt: 'token',
      monitoringEnabled: true,
    );

    final map = cfg.toMap();
    expect(map['accountId'], 'acct');
    expect(map['appId'], 'com.example.app');
    expect(map['jwt'], 'token');
    expect(map['monitoringEnabled'], true);
  });

  test('LpAuthConfig toMap includes optional fields', () {
    const auth = LpAuthConfig(
      jwt: 'jwt',
      authCode: 'code',
      performStepUp: true,
    );

    final map = auth.toMap();
    expect(map['jwt'], 'jwt');
    expect(map['authCode'], 'code');
    expect(map['performStepUp'], true);
  });

  test('LpUserProfile toMap includes provided fields', () {
    const profile = LpUserProfile(
      firstName: 'Ada',
      lastName: 'Lovelace',
      phoneNumber: '123',
      email: 'ada@example.com',
    );

    final map = profile.toMap();
    expect(map['firstName'], 'Ada');
    expect(map['lastName'], 'Lovelace');
    expect(map['phoneNumber'], '123');
    expect(map['email'], 'ada@example.com');
  });
}
