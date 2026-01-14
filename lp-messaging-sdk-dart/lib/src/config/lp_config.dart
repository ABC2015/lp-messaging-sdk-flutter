import '../models/lp_enums.dart';
import 'lp_jwt_provider.dart';

/// Static configuration for connecting to a LivePerson account.
class LpConfig {
  const LpConfig({
    required this.accountId,
    required this.jwtProvider,
    this.brandId,
    this.regionHint,
    this.channelType = LpChannelType.consumer,
    this.logLevel = LpLogLevel.info,
  });

  /// LivePerson account / site ID (e.g. "12345678").
  final String accountId;

  /// Optional brand ID, if your LP account uses multiple brands.
  final String? brandId;

  /// Optional region hint, e.g. "va", "eu", etc.
  final String? regionHint;

  /// Whether this SDK instance represents a consumer, agent, or bot.
  final LpChannelType channelType;

  /// Default logging level.
  final LpLogLevel logLevel;

  /// Async provider for JWT tokens (consumer or agent/bot).
  final LpJwtProvider jwtProvider;

  LpConfig copyWith({
    String? accountId,
    String? brandId,
    String? regionHint,
    LpChannelType? channelType,
    LpLogLevel? logLevel,
    LpJwtProvider? jwtProvider,
  }) {
    return LpConfig(
      accountId: accountId ?? this.accountId,
      brandId: brandId ?? this.brandId,
      regionHint: regionHint ?? this.regionHint,
      channelType: channelType ?? this.channelType,
      logLevel: logLevel ?? this.logLevel,
      jwtProvider: jwtProvider ?? this.jwtProvider,
    );
  }
}
