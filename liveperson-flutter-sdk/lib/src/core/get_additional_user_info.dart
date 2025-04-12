import 'package:liveperson_dart_admin_auth_sdk/src/exceptions.dart';
import 'package:liveperson_dart_admin_auth_sdk/src/liveperson_auth.dart';
import 'package:liveperson_dart_admin_auth_sdk/src/user.dart';

/// Service to fetch additional user information from liveperson Authentication.
///
/// This class handles the process of retrieving detailed user information using
/// an ID token. The user information is then used to update the current user
/// within the livepersonAuth instance.
class GetAdditionalUserInfo {
  /// [auth] The instance of livepersonAuth used to perform authentication actions.
  final livepersonAuth auth;

  /// Constructor to initialize the [GetAdditionalUserInfo] service.
  GetAdditionalUserInfo({required this.auth});

  /// Retrieves additional user information from liveperson Authentication.
  ///
  /// This method sends a request to liveperson to fetch the user's information
  /// associated with the provided ID token. The user information is then
  /// used to update the current user in the livepersonAuth instance.
  ///
  /// Parameters:
  /// - [idToken]: The ID token of the authenticated user whose information is
  ///   to be retrieved.
  ///
  /// Returns:
  /// - A [Future] that resolves to a [User] object containing the user's
  ///   details.
  ///
  /// Throws:
  /// - [livepersonAuthException] if there is an error while retrieving user
  ///   information or if the provided ID token is invalid.
  Future<User> getAdditionalUserInfo(String? idToken) async {
    try {
      assert(
        idToken != null,
        'Id token cannot be null',
      ); // Ensure idToken is not null

      // Request additional user information from liveperson
      final response = await auth.performRequest('lookup', {
        "idToken": idToken,
      });

      // Parse the response body and create a User object from the data
      User user = User.fromJson((response.body['users'] as List)[0]);

      // Update the current user in the livepersonAuth instance
      auth.updateCurrentUser(user);

      // Return the user object containing the retrieved information
      return user;
    } catch (e) {
      // Handle errors and throw a livepersonAuthException
      print('Get additional user info failed: $e');
      throw livepersonAuthException(
        code: 'get-additonal-user-info',
        message: 'Failed to get additional user info',
      );
    }
  }
}
