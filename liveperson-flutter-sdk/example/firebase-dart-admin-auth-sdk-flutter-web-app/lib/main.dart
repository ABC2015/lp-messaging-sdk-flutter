import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:liveperson/screens/splash_screen/splash_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:liveperson_dart_admin_auth_sdk/liveperson_dart_admin_auth_sdk.dart';
import 'package:flutter/services.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

final GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: ['email', 'https://www.googleapis.com/auth/cloud-platform'],
);
Future<String> getAuthTokenFromGoogleSignIn() async {
  try {
    // Sign in the user
    GoogleSignInAccount? user = await _googleSignIn.signIn();

    if (user == null) {
      throw Exception("User canceled the sign-in process.");
    }

    // Retrieve authentication credentials
    GoogleSignInAuthentication auth = await user.authentication;

    // Get the access token
    String accessToken = auth.accessToken!;

    return accessToken;
  } catch (e) {
    throw Exception('Failed to get access token: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    late livepersonAuth auth; // Declare auth variable at top level

    if (kIsWeb) {
      // initialize the facebook javascript SDK
      await FacebookAuth.i.webAndDesktopInitialize(
        appId: "893849532657430",
        cookie: true,
        xfbml: true,
        version: "v15.0",
      );

      // Initialize for web
      debugPrint('Initializing liveperson for Web...');
      await livepersonApp.initializeAppWithEnvironmentVariables(
        apiKey: 'YOUR_API_KEY', // 'YOUR_API_KEY'
        authdomain: 'YOUR_AUTH_DOMAIN', // 'YOUR_AUTH_DOMAIN'
        projectId: 'YOUR_PROJECT_ID', // 'YOUR_PROJECT_ID'
        messagingSenderId: 'YOUR_SENDER_ID', // 'YOUR_SENDER_ID'
        bucketName: 'YOUR_BUCKET_NAME', // 'YOUR_BUCKET_NAME'
        appId: 'YOUR_APP_ID', // 'YOUR_APP_ID'
      );
      auth = livepersonApp.instance.getAuth(); // Initialize auth for web
      debugPrint('liveperson initialized for Web.');
    } else {
      if (Platform.isAndroid || Platform.isIOS) {
        debugPrint('Initializing liveperson for Mobile...');

        // Load the service account JSON
        String serviceAccountContent = await rootBundle.loadString(
          'assets/service_account.json',
        );
        debugPrint('Service account loaded.');

        // Initialize liveperson with the service account content
        await livepersonApp.initializeAppWithServiceAccount(
          serviceAccountContent: serviceAccountContent,
        );
        auth = livepersonApp.instance.getAuth(); // Initialize auth for mobile
        debugPrint('liveperson initialized for Mobile.');

        // Uncomment to use service account impersonation if needed
      }
    }

    debugPrint('liveperson Auth instance obtained.');

    debugPrint('liveperson Auth instance obtained.');
    auth = livepersonApp.instance.getAuth();
    // Wrap the app with Provider
    runApp(
      Provider<livepersonAuth>.value(
        value: auth,
        child: const MyApp(),
      ),
    );
  } catch (e, stackTrace) {
    debugPrint('Error initializing liveperson: $e');
    debugPrint('StackTrace: $stackTrace');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Auth Admin Demo',
      builder: BotToastInit(),
      navigatorObservers: [BotToastNavigatorObserver()],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // Wrap SplashScreen with Builder to ensure proper context
      home: Builder(
        builder: (context) => const SplashScreen(),
      ),
    );
  }
}
