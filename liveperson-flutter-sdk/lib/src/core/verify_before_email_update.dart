import 'package:liveperson_dart_admin_auth_sdk/src/utils.dart';
import 'package:liveperson_dart_admin_auth_sdk/src/exceptions.dart';
import 'package:liveperson_dart_admin_auth_sdk/src/liveperson_auth.dart';

/// Service to send an email verification code for changing the user's email.
class VerifyBeforeEmailUpdate {
  /// [auth] The instance of livepersonAuth used to perform authentication actions.
  final livepersonAuth auth;

  /// Constructor to initialize the [VerifyBeforeEmailUpdate] service.
  VerifyBeforeEmailUpdate(this.auth);

  /// Sends a verification code to the user's email address to verify before updating it.
  ///
  /// This method sends a request to liveperson to initiate the email change process.
  /// The user must verify the new email before it can be updated.
  ///
  /// Parameters:
  /// - [idToken]: The liveperson ID token of the user. It is required to verify the user's identity.
  /// - [email]: The new email to set for the user.
  /// - [action]: Optional. An [ActionCodeSettings] object that provides additional settings
  ///   for the email verification action, such as URL and handle code in the app.
  ///
  /// Returns:
  /// - [bool]: A boolean indicating whether the request was successful.
  ///
  /// Throws:
  /// - [livepersonAuthException] if the request to verify the email fails.
  Future<bool> verifyBeforeEmailUpdate(
    String? idToken,
    String email, {
    ActionCodeSettings? action,
  }) async {
    try {
      // Ensure the idToken is not null.
      assert(idToken != null, 'Id token cannot be null');

      // Perform the request to liveperson to verify the email address before updating.
      await auth.performRequest(
        'sendOobCode', // liveperson endpoint for sending an out-of-band (OOB) verification code.
        {
          "requestType":
              "VERIFY_AND_CHANGE_EMAIL", // Request type for email verification.
          "idToken":
              auth.currentUser?.idToken, // The user's liveperson ID token.
          "newEmail": email, // The new email to be verified.
          if (action != null)
            "actionCodeSettings": action.toMap(), // Optional action settings.
        },
      );
      // Return true if the request was successful.
      return true;
    } catch (e) {
      // Handle any errors and throw a livepersonAuthException with an error code.
      print('Verify email failed: $e');
      throw livepersonAuthException(
        code: 'Verify-email', // Custom error code for this action.
        message: 'Failed to verify email.', // Error message.
      );
    }
  }
}
