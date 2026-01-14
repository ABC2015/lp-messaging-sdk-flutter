/// Very small diagnostics facade for the SDK.
///
/// You can implement LpDiagnostics to:
/// - Log WS frames
/// - Emit metrics
/// - Record errors
enum LpDiagEventType {
  wsSent,
  wsReceived,
  httpRequest,
  httpResponse,
  error,
  stateChange,
}

class LpDiagEvent {
  final LpDiagEventType type;
  final DateTime timestamp;
  final String message;
  final Map<String, Object?> details;

  LpDiagEvent({
    required this.type,
    required this.message,
    Map<String, Object?>? details,
    DateTime? timestamp,
  })  : details = details ?? const {},
        timestamp = timestamp ?? DateTime.now().toUtc();
}

abstract class LpDiagnostics {
  void onEvent(LpDiagEvent event);
}

/// No-op default implementation.
class LpNoopDiagnostics implements LpDiagnostics {
  const LpNoopDiagnostics();

  @override
  void onEvent(LpDiagEvent event) {
    // intentionally empty
  }
}
