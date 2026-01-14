import 'ai_provider.dart';

/// Simple deterministic mock for tests and offline demos.
class MockAiProvider implements AiProvider {
  final String Function({
    required String prompt,
    double temperature,
    int maxTokens,
  }) _resolver;

  MockAiProvider({
    String Function({
      required String prompt,
      double temperature,
      int maxTokens,
    })? resolver,
  }) : _resolver = resolver ??
            ({
              required String prompt,
              double temperature = 0.2,
              int maxTokens = 512,
            }) {
              final truncated = prompt.length > 200
                  ? '${prompt.substring(0, 200)}...'
                  : prompt;
              return '[MOCK AI] temp=$temperature\n$truncated';
            };

  @override
  Future<String> complete({
    required String prompt,
    double temperature = 0.2,
    int maxTokens = 512,
  }) async {
    return _resolver(
      prompt: prompt,
      temperature: temperature,
      maxTokens: maxTokens,
    );
  }

  @override
  Future<String> chat({
    required List<AiMessage> messages,
    double temperature = 0.2,
    int maxTokens = 512,
  }) async {
    final prompt = messages.map((m) => '${m.role}: ${m.content}').join('\n');
    return _resolver(
      prompt: prompt,
      temperature: temperature,
      maxTokens: maxTokens,
    );
  }
}
