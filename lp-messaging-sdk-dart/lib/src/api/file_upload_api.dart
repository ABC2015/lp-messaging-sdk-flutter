import 'dart:convert';
import 'dart:io';

import '../config/lp_config.dart';
import '../core/lp_logger.dart';
import '../transport/lp_http_client.dart';

/// Sends binary attachments and rich content.
class LpFileUploadApi {
  LpFileUploadApi({
    required this.config,
    required this.logger,
  }) : _http = LpHttpClient(logger: logger);

  final LpConfig config;
  final LpLogger logger;
  final LpHttpClient _http;

  Future<String> _jwt() async => config.jwtProvider();

  Uri _uploadBase(String path) {
    final host = '${config.accountId}.msg.liveperson.net';
    return Uri.https(host, path);
  }

  /// Upload a file and get back URL + attachment id.
  Future<Map<String, dynamic>> uploadFile({
    required String conversationId,
    required File file,
    required String mimeType,
  }) async {
    final token = await _jwt();

    final uri = _uploadBase('/upload/v1/conversation/$conversationId/file');

    final bytes = await file.readAsBytes();

    final json = await _http.postJson(
      uri,
      headers: {
        'Content-Type': mimeType,
        'Authorization': 'jwt $token',
      },
      body: {'data': base64Encode(bytes)},
    );

    logger.info('uploadFile($conversationId) => $json');
    return {
      'id': json['fileId'],
      'url': json['securedUrl'],
    };
  }

  /// Send a structured content event (e.g. card, quick replies).
  ///
  /// Body must match LP structured content schema.
  Future<void> sendStructured({
    required String conversationId,
    required Map<String, dynamic> content,
  }) async {
    final token = await _jwt();
    final uri = _uploadBase(
      '/messaging/v1/conversations/$conversationId/events',
    );

    final wrapped = {
      'type': 'richContent',
      'content': content,
    };

    final json = await _http.postJson(
      uri,
      headers: {
        'Authorization': 'jwt $token',
      },
      body: wrapped,
    );

    logger.info('sendStructured($conversationId) => $json');
  }
}
