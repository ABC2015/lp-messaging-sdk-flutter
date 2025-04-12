import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:liveperson/screens/splash_screen/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:liveperson_dart_admin_auth_sdk/liveperson_dart_admin_auth_sdk.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    late livepersonAuth auth;

    // Web branch (currently not used; uncomment if targeting web)
    /*
    if (kIsWeb) {
      debugPrint('Initializing liveperson for Web...');
      await livepersonApp.initializeAppWithEnvironmentVariables(
        apiKey: 'YOUR_API_KEY',        // Replace with your API key
        authdomain: 'YOUR_AUTH_DOMAIN',// Replace with your Auth Domain
        projectId: 'YOUR_PROJECT_ID',  // Replace with your Project ID
        messagingSenderId: 'YOUR_SENDER_ID', // Replace with your Messaging Sender ID
        bucketName: 'YOUR_BUCKET_NAME', // Replace with your Bucket Name
        appId: 'YOUR_APP_ID',          // Replace with your App ID
      );
      auth = livepersonApp.instance.getAuth();
      debugPrint('liveperson initialized for Web.');
    } else {
    */

    // Mobile branch (for Android/iOS)
    if (Platform.isAndroid || Platform.isIOS) {
      debugPrint('Initializing liveperson for Mobile...');

      // Method 1: Using service account impersonation for GCP
      await livepersonApp.initializeAppWithServiceAccountImpersonationGCP(
        gcpAccessToken:
            'gcp-access-token', // Replace with your GCP access token
        impersonatedEmail:
            'account-to-be-impersonated', // Replace with the target service account email
      );

      // Alternatively, if you want to initialize with a local service account file, you might do:
      String serviceAccountContent =
          await rootBundle.loadString('assets/service_account.json');
      await livepersonApp.initializeAppWithServiceAccount(
          serviceAccountContent: serviceAccountContent);

      auth = livepersonApp.instance.getAuth();
      debugPrint('liveperson initialized for Mobile.');
    }
    // } // End of web branch

    debugPrint('liveperson Auth instance obtained.');

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
