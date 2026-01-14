import '../config/lp_config.dart';
import '../core/lp_logger.dart';
import '../transport/lp_http_client.dart';

class LpAgentApi {
  LpAgentApi({
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

  /// Accept a conversation (agent).
  Future<void> accept(String conversationId) async {
    final token = await _jwt();
    final uri = _base('/agent/v1/conversations/$conversationId/accept');
    await _http.postJson(uri, headers: {'Authorization': 'jwt $token'}, body: {});
    logger.info('accept($conversationId)');
  }

  /// Mark read.
  Future<void> markAsRead(String conversationId, String sequenceId) async {
    final token = await _jwt();
    final uri = _base('/agent/v1/conversations/$conversationId/read/$sequenceId');
    await _http.postJson(uri, headers: {'Authorization': 'jwt $token'}, body: {});
    logger.info('read($conversationId,$sequenceId)');
  }

  /// Resolve/close (agent side).
  Future<void> resolve(String conversationId) async {
    final token = await _jwt();
    final uri = _base('/agent/v1/conversations/$conversationId/resolve');
    await _http.postJson(uri, headers: {'Authorization': 'jwt $token'}, body: {});
    logger.info('resolve($conversationId)');
  }

  /// Query max concurrency and active load.
  Future<Map<String, int>> getConcurrency() async {
    final token = await _jwt();
    final uri = _base('/agent/v1/concurrency');

    final json = await _http.getJson(
      uri,
      headers: {'Authorization': 'jwt $token'},
    );

    return {
      'max': (json['maxConversations'] as num?)?.toInt() ?? 0,
      'active': (json['assignedConversations'] as num?)?.toInt() ?? 0,
    };
  }
}
