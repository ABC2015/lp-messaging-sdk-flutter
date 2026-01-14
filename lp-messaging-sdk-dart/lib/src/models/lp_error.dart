class LpError implements Exception {
  const LpError(this.code, this.message, {this.details});

  final String code;
  final String message;
  final Object? details;

  @override
  String toString() =>
      'LpError(code: $code, message: $message, details: $details)';
}
