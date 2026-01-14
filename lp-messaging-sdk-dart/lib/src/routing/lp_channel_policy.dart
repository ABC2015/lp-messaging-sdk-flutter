import '../models/lp_channel.dart';

class LpChannelPolicy {
  final LpSourceChannelType type;
  final bool allowBot;
  final bool allowHuman;
  final bool highPriority;
  final Duration? slaTarget;
  final Map<String, dynamic> metadata;

  const LpChannelPolicy({
    required this.type,
    this.allowBot = true,
    this.allowHuman = true,
    this.highPriority = false,
    this.slaTarget,
    this.metadata = const {},
  });
}

/// Simple router that returns a [LpChannelPolicy] for a given channel.
class LpChannelRouter {
  final Map<LpSourceChannelType, LpChannelPolicy> _policies;
  final LpChannelPolicy _defaultPolicy;

  LpChannelRouter(
    Map<LpSourceChannelType, LpChannelPolicy> policies, {
    LpChannelPolicy? defaultPolicy,
  })  : _policies = Map.unmodifiable(policies),
        _defaultPolicy = defaultPolicy ??
            const LpChannelPolicy(
              type: LpSourceChannelType.other,
              allowBot: true,
              allowHuman: true,
              highPriority: false,
            );

  LpChannelPolicy forChannelType(LpSourceChannelType type) =>
      _policies[type] ?? _defaultPolicy;
}
