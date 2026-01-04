import 'lp_event.dart';

/// Emitted when native side encounters an error that should be surfaced to Dart.
///
/// Note: you might also throw exceptions for direct MethodChannel calls.
/// Events are good for asynchronous failures.
class LpErrorEvent extends LpEvent {
  final String code;
  final String message;
  final Object? details;

  const LpErrorEvent({
    required this.code,
    required this.message,
    required DateTime timestamp,
    this.details,
  }) : super('error', timestamp);

  @override
  Map<String, Object?> toJson() => {
    'type': type,
    'timestamp': timestamp.toIso8601String(),
    'code': code,
    'message': message,
    'details': details?.toString(),
  };
}
