class LpNativeInitConfig {
  /// LivePerson account / brand id.
  final String accountId;

  /// App ID (Android needs this; typically your package name).
  final String appId;

  /// Optional initial JWT to use for authenticated conversations.
  final String? jwt;

  /// Whether to initialize Monitoring as well.
  final bool monitoringEnabled;

  /// Optional app installation ID for Monitoring.
  final String? appInstallationId;

  /// Enable verbose logging of Android event emissions.
  final bool debugLogging;

  const LpNativeInitConfig({
    required this.accountId,
    required this.appId,
    this.jwt,
    this.monitoringEnabled = false,
    this.appInstallationId,
    this.debugLogging = false,
  });

  Map<String, dynamic> toMap() => {
        'accountId': accountId,
        'appId': appId,
        'jwt': jwt,
        'monitoringEnabled': monitoringEnabled,
        'appInstallationId': appInstallationId,
        'debugLogging': debugLogging,
      };
}

class LpUserProfile {
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final String? email;

  const LpUserProfile({
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.email,
  });

  Map<String, dynamic> toMap() => {
        'firstName': firstName,
        'lastName': lastName,
        'phoneNumber': phoneNumber,
        'email': email,
      };
}

class LpAuthConfig {
  /// Authentication type to match LP IdP configuration.
  final LpAuthType? authType;

  /// JWT for authenticated conversation.
  final String? jwt;

  /// Auth code alternative (code flow).
  final String? authCode;

  /// Whether to perform step-up SSO if required.
  final bool performStepUp;

  const LpAuthConfig({
    this.authType,
    this.jwt,
    this.authCode,
    this.performStepUp = false,
  });

  Map<String, dynamic> toMap() => {
        'authType': authType?.name,
        'jwt': jwt,
        'authCode': authCode,
        'performStepUp': performStepUp,
      };
}

enum LpAuthType {
  implicit,
  code,
}

class LpPushConfig {
  /// Device token (FCM/APNS) as a string.
  final String token;

  /// Optional authentication for registering push for authenticated users.
  final LpAuthConfig? auth;

  const LpPushConfig({
    required this.token,
    this.auth,
  });

  Map<String, dynamic> toMap() => {
        'token': token,
        'auth': auth?.toMap(),
      };
}
