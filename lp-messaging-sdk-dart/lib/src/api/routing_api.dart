import '../config/lp_config.dart';
import '../core/lp_logger.dart';
import '../transport/lp_http_client.dart';

/// LivePerson routing and ACD API:
/// - Transfer conversation to skill / agent
/// - Fetch queue position
/// - Submit CSAT
/// - Get agent availability
class LpRoutingApi {
  LpRoutingApi({
    required this.config,
    required this.logger,
  }) : _http = LpHttpClient(logger: logger);

  final LpConfig config;
  final LpLogger logger;
  final LpHttpClient _http;

  Future<String> _jwt() async => config.jwtProvider();

  Uri _base(String path, [Map<String, dynamic>? qp]) {
    final host = '${config.accountId}.msg.liveperson.net';
    return Uri.https(host, path, qp?.map((k, v) => MapEntry(k, '$v')));
  }

  /// Transfer conversation to another skill.
  Future<void> transferToSkill({
    required String conversationId,
    required String skill,
  }) async {
    final token = await _jwt();
    final uri = _base('/routing/v1/conversation/$conversationId/transfer');

    final json = await _http.postJson(
      uri,
      headers: {'Authorization': 'jwt $token'},
      body: {'skill': skill},
    );

    logger.info('transferToSkill($conversationId,$skill) => $json');
  }

  /// Transfer a conversation directly to a specific agent ID.
  Future<void> transferToAgent({
    required String conversationId,
    required String agentId,
  }) async {
    final token = await _jwt();
    final uri = _base('/routing/v1/conversation/$conversationId/transfer');

    final json = await _http.postJson(
      uri,
      headers: {'Authorization': 'jwt $token'},
      body: {'agentId': agentId},
    );

    logger.info('transferToAgent($conversationId,$agentId) => $json');
  }

  /// Queue health / position.
  Future<int> getQueuePosition(String conversationId) async {
    final token = await _jwt();
    final uri = _base('/routing/v1/conversation/$conversationId/queue');

    final json = await _http.getJson(
      uri,
      headers: {'Authorization': 'jwt $token'},
    );

    return (json['position'] as num?)?.toInt() ?? 0;
  }

  /// Submit CSAT for a conversation.
  Future<void> submitCSAT({
    required String conversationId,
    required int score, // 1-5
    String? verbatim,
  }) async {
    final token = await _jwt();
    final uri = _base('/routing/v1/conversation/$conversationId/csat');

    final body = <String, dynamic>{
      'score': score,
      if (verbatim != null) 'verbatim': verbatim,
    };

    final json = await _http.postJson(
      uri,
      headers: {'Authorization': 'jwt $token'},
      body: body,
    );

    logger.info('submitCSAT($conversationId,$score) => $json');
  }

  /// Agent availability (by skill).
  Future<int> getAgentAvailability(String skill) async {
    final token = await _jwt();
    final uri = _base('/routing/v1/skills/$skill/availability');

    final json = await _http.getJson(
      uri,
      headers: {'Authorization': 'jwt $token'},
    );

    final count = (json['availableAgents'] as num?)?.toInt() ?? 0;
    return count;
  }
}
