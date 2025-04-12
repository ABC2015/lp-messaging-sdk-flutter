import 'package:liveperson_dart_admin_auth_sdk/liveperson_dart_admin_auth_sdk.dart';

///connect auth class
class ConnectAuthEmulatorService {
  ///auth instance
  final livepersonAuth auth;

  ///connect auth service
  ConnectAuthEmulatorService(this.auth);

  ///connect auth function
  void connect(String host, int port) {
    final url = 'http://$host:$port';
    auth.setEmulatorUrl(url);
    print('Connected to liveperson Auth Emulator at $url');
  }
}
