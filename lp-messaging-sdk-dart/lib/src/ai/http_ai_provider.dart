import 'dart:convert';

import 'package:http/http.dart' as http;

import 'ai_provider.dart';

/// Generic HTTP-based AI provider.
///
/// You configure:
/// - [endpoint]   : URI of your AI service
/// - [model]      : model identifier (if applicable)
/// - [apiKey]     : bearer key or token (if applicable)
///
/// Payload/body structure is intentionally simple and generic.
class HttpAiProvider implements AiProvider {
  final Uri endpoint;
  final String model;
  final String? apiKey;
  final Map<String, String> defaultHeaders;
  final http.Client _client;

  HttpAiProvider({
    required this.endpoint,
    required this.model,
    this.apiKey,
    Map<String, String>? defaultHeaders,
    http.Client? client,
  })  : defaultHeaders = defaultHeaders ?? const {},
        _client = client ?? http.Client();

  Map<String, String> _headers() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...defaultHeaders,
    };
    if (apiKey != null && apiKey!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $apiKey';
    }
    return headers;
  }

  @override
  Future<String> complete({
    required String prompt,
    double temperature = 0.2,
    int maxTokens = 512,
  }) async {
    final body = {
      'mode': 'complete',
      'model': model,
      'prompt': prompt,
      'temperature': temperature,
      'max_tokens': maxTokens,
    };

    final res = await _client.post(
      endpoint,
      headers: _headers(),
      body: jsonEncode(body),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('AI HTTP error ${res.statusCode}: ${res.body}');
    }

    final decoded = jsonDecode(res.body);
    if (decoded is Map<String, dynamic>) {
      return decoded['text'] as String? ??
          decoded['reply'] as String? ??
          decoded['choices']?[0]?['text'] as String? ??
          decoded['choices']?[0]?['message']?['content'] as String? ??
          res.body;
    }

    return res.body;
  }

  @override
  Future<String> chat({
    required List<AiMessage> messages,
    double temperature = 0.2,
    int maxTokens = 512,
  }) async {
    final body = {
      'mode': 'chat',
      'model': model,
      'messages': messages.map((m) => m.toJson()).toList(),
      'temperature': temperature,
      'max_tokens': maxTokens,
    };

    final res = await _client.post(
      endpoint,
      headers: _headers(),
      body: jsonEncode(body),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('AI HTTP error ${res.statusCode}: ${res.body}');
    }

    final decoded = jsonDecode(res.body);
    if (decoded is Map<String, dynamic>) {
      return decoded['reply'] as String? ??
          decoded['text'] as String? ??
          decoded['choices']?[0]?['message']?['content'] as String? ??
          decoded['choices']?[0]?['text'] as String? ??
          res.body;
    }

    return res.body;
  }

  void close() => _client.close();
}
