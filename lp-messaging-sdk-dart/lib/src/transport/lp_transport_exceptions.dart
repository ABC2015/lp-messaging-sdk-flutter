class LpTransportException implements Exception {
  LpTransportException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => 'LpTransportException(message: $message, cause: $cause)';
}
