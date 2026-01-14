/// Generic AI interface for LLMs and similar services.
///
/// Implementations might call:
/// - LivePerson AI endpoints
/// - OpenAI / Azure / Vertex / etc.
/// - Your own internal models
abstract class AiProvider {
  /// Simple “completion” style call (one-shot prompt).
  Future<String> complete({
    required String prompt,
    double temperature = 0.2,
    int maxTokens = 512,
  });

  /// Chat-style call. Implementations can do whatever they need internally.
  Future<String> chat({
    required List<AiMessage> messages,
    double temperature = 0.2,
    int maxTokens = 512,
  });
}

/// Minimal chat message representation.
class AiMessage {
  final String role; // "system" | "user" | "assistant"
  final String content;

  AiMessage({
    required this.role,
    required this.content,
  });

  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}
