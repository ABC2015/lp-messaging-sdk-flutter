import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/lp_logger.dart';
import '../models/lp_error.dart';
import 'lp_transport_exceptions.dart';

/// Minimal HTTP client with JSON handling and LP-style error surfaces.
class LpHttpClient {
  LpHttpClient({
    required this.logger,
    http.Client? inner,
  }) : _inner = inner ?? http.Client();

  final LpLogger logger;
  final http.Client _inner;

  Future<Map<String, dynamic>> getJson(
    Uri uri, {
    Map<String, String>? headers,
  }) async {
    logger.debug('HTTP GET $uri');
    final response = await _inner.get(uri, headers: headers);
    return _handleResponse(uri, response);
  }

  Future<Map<String, dynamic>> postJson(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    logger.debug('HTTP POST $uri body=$body');
    final encodedBody = body == null ? null : jsonEncode(body);
    final response = await _inner.post(
      uri,
      headers: <String, String>{
        'Content-Type': 'application/json',
        ...?headers,
      },
      body: encodedBody,
    );
    return _handleResponse(uri, response);
  }

  Map<String, dynamic> _handleResponse(Uri uri, http.Response response) {
    logger.debug(
      'HTTP ${response.statusCode} from $uri body=${response.body}',
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return <String, dynamic>{};
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return decoded;
    }

    throw LpTransportException(
      'HTTP ${response.statusCode} from $uri',
      cause: LpError(
        response.statusCode.toString(),
        'HTTP error from $uri',
        details: response.body,
      ),
    );
  }

  void close() {
    _inner.close();
  }
}
