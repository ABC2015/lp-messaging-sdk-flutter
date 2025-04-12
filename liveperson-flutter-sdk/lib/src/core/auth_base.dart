import 'package:liveperson_dart_admin_auth_sdk/src/liveperson_auth.dart';
import 'package:liveperson_dart_admin_auth_sdk/src/http_response.dart';

/// An abstract base class providing core authentication functionality.
///
/// This class serves as a foundation for classes that need to perform
/// authentication requests using liveperson.
abstract class AuthBase {
  /// The [livepersonAuth] instance used to perform authentication requests.
  final livepersonAuth auth;

  /// Constructs an instance of [AuthBase].
  ///
  /// Parameters:
  /// - [auth]: The [livepersonAuth] instance that will handle requests.
  AuthBase(this.auth);

  /// Sends an authenticated request to liveperson using the specified [endpoint]
  /// and request [body].
  ///
  /// Parameters:
  /// - [endpoint]: The liveperson endpoint to interact with (e.g., 'update').
  /// - [body]: A `Map<String, dynamic>` containing the request payload.
  ///
  /// Returns a [Future] that resolves to an [HttpResponse] containing the
  /// server's response.
  ///
  /// Example usage:
  /// ```dart
  /// performRequest('update', {'oobCode': 'someCode'});
  /// ```
  Future<HttpResponse> performRequest(
    String endpoint,
    Map<String, dynamic> body,
  ) {
    return auth.performRequest(endpoint, body);
  }
}
