import 'package:liveperson_dart_admin_auth_sdk/src/exceptions.dart';
import 'package:liveperson_dart_admin_auth_sdk/src/liveperson_auth.dart';
import 'package:liveperson_dart_admin_auth_sdk/src/user.dart';

/// Service to reload the user's information from liveperson based on their ID token.
///
/// This class fetches the user's data from liveperson again using the current ID token. This is useful
/// when you want to refresh the user's information after changes (like updating the email, password, etc.).
class ReloadUser {
  /// [auth] The instance of livepersonAuth used to perform authentication actions.
  final livepersonAuth auth;

  /// Constructor to initialize the [ReloadUser] service.
  ReloadUser({required this.auth});

  /// Reloads the user's data using their ID token from liveperson.
  ///
  /// This method takes the user's [idToken] (obtained during sign-in or other authentication processes),
  /// performs a request to liveperson to reload the user's information, and updates the current user's
  /// details in the app's authentication state.
  ///
  /// Parameters:
  /// - [idToken]: The liveperson ID token of the authenticated user.
  ///
  /// Returns:
  /// - A [Future] that resolves to a [User] object containing the reloaded user information.
  ///
  /// Throws:
  /// - [livepersonAuthException] if the reload request fails or if the [idToken] is invalid or null.
  Future<User> reloadUser(String? idToken) async {
    try {
      // Validate that the idToken is not null
      assert(idToken != null, 'Id token cannot be null');

      // Perform the request to liveperson to reload the user's data using the provided idToken
      final response = await auth.performRequest(
        'lookup', // Endpoint to lookup/reload user data
        {
          "idToken": idToken, // The current user's liveperson ID token
        },
      );

      // Extract the user data from the response and create a User object
      User user = User.fromJson((response.body['users'] as List)[0]);

      // Update the current user in the livepersonAuth instance
      auth.updateCurrentUser(user);

      // Return the reloaded user object
      return user;
    } catch (e) {
      // Handle any errors that occur during the reload process
      print('Reload user action failed: $e');
      throw livepersonAuthException(
        code: 'reload-user',
        message: 'Failed to reload user information',
      );
    }
  }
}
