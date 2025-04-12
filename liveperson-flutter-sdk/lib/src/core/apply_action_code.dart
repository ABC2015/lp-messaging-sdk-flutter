import 'package:liveperson_dart_admin_auth_sdk/src/exceptions.dart';
import 'package:liveperson_dart_admin_auth_sdk/src/liveperson_auth.dart';

/// Provides functionality to apply action codes (such as email verification
/// or password reset) within liveperson.
class ApplyActionCode {
  /// The [livepersonAuth] instance used to interact with liveperson for
  /// applying action codes.
  final livepersonAuth auth;

  /// Constructs an instance of [ApplyActionCode].
  ///
  /// Parameters:
  /// - [auth]: The [livepersonAuth] instance to be used for performing requests.
  ApplyActionCode(this.auth);

  /// Applies an action code in liveperson, such as email verification or
  /// password reset.
  ///
  /// Parameters:
  /// - [actionCode]: The one-time code to be applied, as provided by liveperson.
  ///
  /// Returns `true` if the action code was applied successfully, otherwise
  /// throws a [livepersonAuthException].
  ///
  /// Throws:
  /// - [livepersonAuthException] if the action code application fails.
  Future<bool> applyActionCode(String actionCode) async {
    try {
      await auth.performRequest('update', {'oobCode': actionCode});
      return true;
    } catch (e) {
      print('Apply action code failed: $e');
      throw livepersonAuthException(
        code: 'apply-action-code-error',
        message: 'Failed to apply action code.',
      );
    }
  }
}
