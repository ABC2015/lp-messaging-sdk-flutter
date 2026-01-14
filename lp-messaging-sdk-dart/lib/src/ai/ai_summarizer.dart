import '../models/lp_conversation.dart';
import '../models/lp_enums.dart';
import '../models/lp_message.dart';
import 'ai_provider.dart';

class LpConversationSummarizer {
  final AiProvider ai;

  LpConversationSummarizer(this.ai);

  Future<String> summarize(LpConversation conversation) async {
    final transcript = _buildTranscript(conversation.messages);

    final prompt = '''
You are summarizing a customer support conversation from LivePerson.

Conversation transcript:
$transcript

Summarize this conversation in 3-7 bullet points, focusing on:
- The main problem or request
- Important context (order numbers, dates, products)
- Actions that were taken
- Current status (resolved or not)
- Any follow-up or recommended next steps
''';

    return ai.complete(
      prompt: prompt,
      temperature: 0.3,
      maxTokens: 400,
    );
  }

  String _buildTranscript(List<LpMessage> messages) {
    final buffer = StringBuffer();
    for (final msg in messages) {
      final text = msg.text.isNotEmpty ? msg.text : (msg.payload.text ?? '');
      if (text.trim().isEmpty) continue;
      final speaker =
          msg.sender.role == LpChannelType.consumer ? 'User' : 'Agent';
      buffer.writeln('$speaker: $text');
    }
    return buffer.toString();
  }
}
