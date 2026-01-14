import '../models/lp_conversation.dart';
import '../models/lp_enums.dart';
import '../models/lp_message.dart';
import 'ai_provider.dart';

class ReplySuggestion {
  final String text;
  final String? rationale;

  ReplySuggestion({
    required this.text,
    this.rationale,
  });
}

class ReplySuggestionService {
  final AiProvider ai;

  ReplySuggestionService(this.ai);

  Future<List<ReplySuggestion>> suggestReplies(
    LpConversation conversation,
  ) async {
    final lastUserMessage = _lastUserMessage(conversation.messages);
    if (lastUserMessage == null) return const [];

    final transcript = conversation.messages
        .map((m) {
          final text = m.text.isNotEmpty ? m.text : (m.payload.text ?? '');
          final who = m.sender.role == LpChannelType.consumer ? 'User' : 'Agent';
          return '$who: $text';
        })
        .join('\n');

    final prompt = '''
You are assisting a LivePerson agent.

Recent conversation:
$transcript

Generate 3 short, polite reply suggestions to the user's LAST message.
- Keep each suggestion under 2-3 sentences.
- Use a helpful, professional tone.
- Do NOT invent order IDs or personal data.
Return them as plain bullet points, no extra commentary.
''';

    final raw = await ai.complete(
      prompt: prompt,
      temperature: 0.6,
      maxTokens: 300,
    );

    final lines = raw
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final suggestions = <ReplySuggestion>[];
    for (final line in lines) {
      final cleaned = line.replaceFirst(RegExp(r'^[-*]\s*'), '');
      if (cleaned.isEmpty) continue;
      suggestions.add(ReplySuggestion(text: cleaned));
    }

    return suggestions;
  }

  LpMessage? _lastUserMessage(List<LpMessage> messages) {
    for (var i = messages.length - 1; i >= 0; i -= 1) {
      final msg = messages[i];
      if (msg.sender.role != LpChannelType.consumer) continue;
      final text = msg.text.isNotEmpty ? msg.text : (msg.payload.text ?? '');
      if (text.trim().isNotEmpty) return msg;
    }
    return null;
  }
}
