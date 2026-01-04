/// A typed exception for plugin consumers.
///
/// Good practice:
/// - Use stable error codes
/// - Keep user-readable message separate from machine-readable code
class LpSdkException implements Exception {
  final String code;
  final String message;
  final Object? details;

  const LpSdkException({
    required this.code,
    required this.message,
    this.details,
  });

  @override
  String toString() => 'LpSdkException($code): $message ${details ?? ''}';
}

/// Known error codes (keep these stable as part of public API).
class LpErrorCodes {
  static const String nativeError = 'native_error';
  static const String invalidArguments = 'invalid_arguments';
  static const String notInitialized = 'not_initialized';
}
