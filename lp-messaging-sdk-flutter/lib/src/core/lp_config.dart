/// SDK initialization configuration.
///
/// This is what the host app provides to initialize the native SDK.
/// Keep it versioned and backwards-compatible where possible.
class LpConfig {
  /// LivePerson account identifier (or whichever key your SDK expects).
  final String account;

  /// Whether plugin should emit debug logs.
  final bool enableLogging;

  /// Additional arbitrary key/values.
  /// Useful for experimentation or SDK options without breaking changes.
  final Map<String, String> extras;

  const LpConfig({
    required this.account,
    this.enableLogging = false,
    this.extras = const {},
  });

  /// Convert to a JSON-safe map for MethodChannel transport.
  Map<String, Object?> toJson() => {
    'account': account,
    'enableLogging': enableLogging,
    'extras': extras,
  };

  /// Parse from platform map (defensive parsing).
  static LpConfig fromJson(Map<Object?, Object?> json) {
    final account = json['account']?.toString() ?? '';
    final enableLogging = json['enableLogging'] == true;

    final extrasRaw = json['extras'];
    final extras = <String, String>{};
    if (extrasRaw is Map) {
      for (final e in extrasRaw.entries) {
        extras[e.key.toString()] = e.value.toString();
      }
    }

    return LpConfig(
      account: account,
      enableLogging: enableLogging,
      extras: extras,
    );
  }
}
