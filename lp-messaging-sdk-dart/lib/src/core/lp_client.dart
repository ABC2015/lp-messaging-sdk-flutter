import '../agent/lp_agent_client.dart';
import '../ai/ai_moderation.dart';
import '../ai/ai_provider.dart';
import '../ai/ai_suggestions.dart';
import '../ai/ai_summarizer.dart';
import '../config/lp_config.dart';
import '../core/lp_logger.dart';
import '../core/lp_messaging_client.dart';
import '../storage/in_memory_store.dart';
import '../storage/lp_persistence.dart';

/// Aggregated client that bundles consumer, agent, AI, and storage.
///
/// Apps can use the lower-level clients directly if they want more control.
class LpClient {
  factory LpClient({
    required LpConfig config,
    LpPersistence? persistence,
    LpLogger? logger,
    AiProvider? aiProvider,
  }) {
    final resolvedLogger = logger ?? LpLogger(level: config.logLevel);
    final resolvedPersistence = persistence ?? InMemoryPersistence();

    return LpClient._internal(
      config: config,
      logger: resolvedLogger,
      persistence: resolvedPersistence,
      consumer: LpMessagingClient(
        config: config,
        persistence: resolvedPersistence,
        logger: resolvedLogger,
      ),
      agent: LpAgentClient(
        config: config,
        logger: resolvedLogger,
      ),
      aiProvider: aiProvider,
    );
  }

  LpClient._internal({
    required this.config,
    required this.logger,
    required this.persistence,
    required this.consumer,
    required this.agent,
    AiProvider? aiProvider,
  }) : aiProvider = aiProvider {
    if (aiProvider != null) {
      summarizer = LpConversationSummarizer(aiProvider);
      suggestions = ReplySuggestionService(aiProvider);
      moderation = ModerationService(aiProvider);
    }
  }

  final LpConfig config;
  final LpLogger logger;
  final LpPersistence persistence;
  final LpMessagingClient consumer;
  final LpAgentClient agent;

  final AiProvider? aiProvider;
  LpConversationSummarizer? summarizer;
  ReplySuggestionService? suggestions;
  ModerationService? moderation;

  Future<void> init() async {
    await persistence.init();
  }
}
