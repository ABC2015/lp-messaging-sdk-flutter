import 'package:liveperson_dart_admin_auth_sdk/src/exceptions.dart';
import 'package:liveperson_dart_admin_auth_sdk/src/liveperson_auth.dart';

/// Service to send an email verification code to the user.
///
/// This class handles the process of sending a verification email to a user
/// using liveperson Authentication by making a request to liveperson to send
/// an email verification code, usually after the user signs up or changes
/// their email.
class SendEmailVerificationCode {
  /// [auth] The instance of livepersonAuth used to perform authentication actions.
  final livepersonAuth auth;

  /// Constructor to initialize the [SendEmailVerificationCode] service.
  SendEmailVerificationCode({required this.auth});

  /// Sends an email verification code to the user.
  ///
  /// This method takes the user's [idToken] (obtained during the sign-in process)
  /// and sends a request to liveperson to trigger sending an email with a verification code.
  ///
  /// Parameters:
  /// - [idToken]: The liveperson ID token of the user. It is required to verify the user's identity.
  ///
  /// Throws:
  /// - [livepersonAuthException] if the request to send the verification email fails.
  Future<void> sendEmailVerificationCode(String? idToken) async {
    try {
      // Validate that the idToken is not null
      assert(idToken != null, 'Id token cannot be null');

      // Perform the request to liveperson to send an email verification code
      await auth.performRequest(
        'sendOobCode', // liveperson endpoint for sending verification email
        {
          "requestType": "VERIFY_EMAIL", // Action type: send email verification
          "idToken": idToken, // The user's liveperson ID token
        },
      );
    } catch (e) {
      // Handle any errors during the process
      print('Send email verification code failed: $e');
      throw livepersonAuthException(
        code: 'send-email-verification-code',
        message: 'Failed to send email verification code',
      );
    }
  }
}
