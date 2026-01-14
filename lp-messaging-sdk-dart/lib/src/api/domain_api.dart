import '../config/lp_config.dart';
import '../core/lp_logger.dart';
import '../models/lp_error.dart';
import '../transport/lp_http_client.dart';

/// Resolves base URIs for LivePerson services using the Domain API.
///
/// In particular, this is used to get the asyncMessagingEnt domain used
/// for Messaging Window WebSocket.
class LpDomainApi {
  LpDomainApi({
    required this.config,
    required this.http,
    required this.logger,
  });

  final LpConfig config;
  final LpHttpClient http;
  final LpLogger logger;

  /// Resolve the async messaging domain (asyncMessagingEnt).
  ///
  /// Uses api.liveperson.net; you can override using [config.regionHint]
  /// if you have regional domains in your environment.
  Future<String> resolveAsyncMessagingDomain() async {
    // LivePerson's global domain API entry point; this is stable and the
    // baseURI we get back will be region-specific.
    final baseHost = 'api.liveperson.net';

    final uri = Uri.https(
      baseHost,
      '/api/account/${config.accountId}/service/baseURI.json',
      <String, String>{
        'version': '1.0',
        'service': 'asyncMessagingEnt',
      },
    );

    logger.info('Resolving asyncMessagingEnt baseURI via $uri');

    final json = await http.getJson(uri);
    final baseUri = json['baseURI'] as String?;
    if (baseUri == null || baseUri.isEmpty) {
      throw LpError(
        'DOMAIN',
        'Missing baseURI in Domain API response for asyncMessagingEnt',
        details: json,
      );
    }

    logger.info('Resolved async messaging domain: $baseUri');
    return baseUri;
  }
}
