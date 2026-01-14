import '../config/lp_config.dart';
import '../core/lp_logger.dart';
import '../transport/lp_http_client.dart';

class LpPushApi {
  LpPushApi({
    required this.config,
    required this.logger,
  }) : _http = LpHttpClient(logger: logger);

  final LpConfig config;
  final LpLogger logger;
  final LpHttpClient _http;

  Future<String> _jwt() async => config.jwtProvider();

  Uri _base(String path) {
    final host = '${config.accountId}.msg.liveperson.net';
    return Uri.https(host, path);
  }

  /// Register push token with LP backend.
  ///
  /// Flutter generates the token; pass it here.
  Future<void> registerToken({
    required String consumerId,
    required String token,
    required String platform, // 'APNS' or 'GCM'
  }) async {
    final jwt = await _jwt();

    final uri = _base('/push/v1/consumers/$consumerId/tokens');

    final body = {
      'deviceId': token,
      'service': platform,
    };

    final resp = await _http.postJson(
      uri,
      headers: {'Authorization': 'jwt $jwt'},
      body: body,
    );

    logger.info('registerToken($consumerId) => $resp');
  }
}
