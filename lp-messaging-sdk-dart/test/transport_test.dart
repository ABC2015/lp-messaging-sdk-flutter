import 'package:test/test.dart';
import 'package:lp_messaging_sdk_dart/src/transport/lp_transport_exceptions.dart';

void main() {
  test('Transport exception toString', () {
    final ex = LpTransportException('oops', cause: 'underlying');
    expect(ex.toString(), contains('oops'));
  });
}
