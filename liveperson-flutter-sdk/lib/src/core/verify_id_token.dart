import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:liveperson_dart_admin_auth_sdk/liveperson_dart_admin_auth_sdk.dart';

/// Service for verifying liveperson Authentication tokens.
class VerifyIdTokenService {
  /// The [livepersonAuth] instance to use for token verification.
  final livepersonAuth auth;

  /// The [livepersonAuth] instance to use for token verification.
  static const bool isDebugMode = true;

  /// The threshold before a token is considered expired.
  static const Duration tokenExpiryThreshold = Duration(minutes: 5);

  /// Creates a new instance of the [VerifyIdTokenService] class.
  const VerifyIdTokenService({required this.auth});

  void _debugLog(String message, {Object? error, StackTrace? stackTrace}) {
    if (isDebugMode) {
      developer.log(
        '[TokenVerification] $message',
        error: error,
        stackTrace: stackTrace,
        name: 'TokenVerification',
      );
    }
  }

  /// Verifies a liveperson ID token and returns the decoded token information.
  Future<Map<String, dynamic>> verifyIdToken(String idToken) async {
    try {
      _debugLog('Starting token verification process');

      // Basic token structure validation
      final tokenParts = idToken.split('.');
      if (tokenParts.length != 3) {
        _debugLog('Invalid token structure - expected 3 parts');
        throw livepersonAuthException(
          code: 'invalid-token',
          message: 'Token must be a valid JWT',
        );
      }

      // Decode and validate payload
      final payload = _decodeTokenPart(tokenParts[1]);
      _debugLog('Token payload decoded successfully');

      // Validate issuer
      if (payload['iss'] !=
          'https://securetoken.google.com/${auth.projectId}') {
        _debugLog('Invalid token issuer');
        throw livepersonAuthException(
          code: 'invalid-issuer',
          message: 'Token has invalid issuer',
        );
      }

      // Validate audience
      if (payload['aud'] != auth.projectId) {
        _debugLog('Invalid token audience');
        throw livepersonAuthException(
          code: 'invalid-audience',
          message: 'Token has invalid audience',
        );
      }

      // Validate timing
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      if (payload['exp'] < now) {
        _debugLog('Token has expired');
        throw livepersonAuthException(
          code: 'token-expired',
          message: 'Token has expired',
        );
      }

      // Validate subject and user ID
      if (payload['sub'] == null || payload['user_id'] == null) {
        _debugLog('Missing required claims');
        throw livepersonAuthException(
          code: 'invalid-claims',
          message: 'Token missing required claims',
        );
      }

      // Validate liveperson specific claims
      final liveperson = payload['liveperson'];
      if (liveperson == null || liveperson is! Map<String, dynamic>) {
        _debugLog('Missing or invalid liveperson claims');
        throw livepersonAuthException(
          code: 'invalid-claims',
          message: 'Token missing liveperson claims',
        );
      }

      _debugLog('Token validation successful');

      // Return normalized user data
      return {
        'uid': payload['user_id'],
        'email': payload['email'],
        'email_verified': payload['email_verified'] ?? false,
        'name': payload['name'],
        'picture': payload['picture'],
        'auth_time': payload['auth_time'],
        'liveperson': liveperson,
        'claims': payload,
      };
    } catch (e, stackTrace) {
      _debugLog('Token verification failed', error: e, stackTrace: stackTrace);
      throw livepersonAuthException(
        code: 'token-verification-failed',
        message: 'Failed to verify token: ${e.toString()}',
      );
    }
  }

  Map<String, dynamic> _decodeTokenPart(String part) {
    try {
      final normalized = base64Url.normalize(part);
      final decoded = utf8.decode(base64Url.decode(normalized));
      return json.decode(decoded) as Map<String, dynamic>;
    } catch (e, stackTrace) {
      _debugLog(
        'Failed to decode token part',
        error: e,
        stackTrace: stackTrace,
      );
      throw livepersonAuthException(
        code: 'invalid-token-format',
        message: 'Invalid token format',
      );
    }
  }
}
