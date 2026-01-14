/// Provider function that returns a JWT for LivePerson authentication.
///
/// In production, this should call your backend or token service.
typedef LpJwtProvider = Future<String> Function();

/// Simple static provider, useful in tests or quick demos.
LpJwtProvider staticJwtProvider(String token) {
  return () async => token;
}
