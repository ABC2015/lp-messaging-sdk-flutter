import 'ai_provider.dart';

enum ModerationLabel {
  safe,
  abusive,
  selfHarm,
  hate,
  spam,
  other,
}

class ModerationResult {
  final ModerationLabel label;
  final double confidence;
  final String? explanation;

  ModerationResult({
    required this.label,
    required this.confidence,
    this.explanation,
  });
}

class ModerationService {
  final AiProvider ai;

  ModerationService(this.ai);

  Future<ModerationResult> moderateText(String text) async {
    final prompt = '''
Classify the following message into one of:
safe, abusive, self_harm, hate, spam, other.

Return a single line in this format:
label=<label>; confidence=<0-1>; explanation=<short reason>

Message:
$text
''';

    final raw = await ai.complete(
      prompt: prompt,
      temperature: 0.0,
      maxTokens: 120,
    );

    return _parseResult(raw);
  }

  ModerationResult _parseResult(String raw) {
    final lower = raw.toLowerCase();
    ModerationLabel label = ModerationLabel.other;
    if (lower.contains('safe')) label = ModerationLabel.safe;
    if (lower.contains('abusive')) label = ModerationLabel.abusive;
    if (lower.contains('self_harm') || lower.contains('self-harm')) {
      label = ModerationLabel.selfHarm;
    }
    if (lower.contains('hate')) label = ModerationLabel.hate;
    if (lower.contains('spam')) label = ModerationLabel.spam;

    final confMatch = RegExp(r'confidence\s*=\s*([0-9.]+)').firstMatch(lower);
    final confidence = confMatch != null
        ? double.tryParse(confMatch.group(1) ?? '') ?? 0.0
        : 0.0;

    String? explanation;
    final explanationMatch =
        RegExp(r'explanation\s*=\s*(.+)$', multiLine: true).firstMatch(raw);
    if (explanationMatch != null) {
      explanation = explanationMatch.group(1)?.trim();
    }

    return ModerationResult(
      label: label,
      confidence: confidence,
      explanation: explanation,
    );
  }
}
