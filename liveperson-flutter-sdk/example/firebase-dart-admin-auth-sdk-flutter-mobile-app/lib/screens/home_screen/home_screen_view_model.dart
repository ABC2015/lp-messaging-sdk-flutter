import 'package:bot_toast/bot_toast.dart';
import 'package:liveperson_dart_admin_auth_sdk/liveperson_dart_admin_auth_sdk.dart';
import 'package:liveperson/utils/platform_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class HomeScreenViewModel extends ChangeNotifier {
  HomeScreenViewModel() {
    _googleSignIn.onCurrentUserChanged.listen(
      (event) async {
        signInAccount = event;
      },
    );

    refreshUser();
  }

  void refreshUser() {
    displayName = _livepersonSdk?.currentUser?.displayName ?? '';
    displayImage = _livepersonSdk?.currentUser?.photoURL;
    numberOfLinkedProviders =
        _livepersonSdk?.currentUser?.providerUserInfo?.length ?? 0;
    notifyListeners();
  }

  GoogleSignInAccount? signInAccount;
  List<String> scopes = <String>[
    'email',
    'https://www.googleapis.com/auth/contacts.readonly',
  ];

  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: scopes,
    signInOption: SignInOption.standard,
  );
  final livepersonAuth? _livepersonSdk = livepersonApp.livepersonAuth;

  String displayName = '';
  String? displayImage;
  int numberOfLinkedProviders = 0;

  bool loading = false;
  void setLoading(bool load) {
    loading = load;
    notifyListeners();
  }

  Future<void> reloadUser() async {
    try {
      setLoading(true);
      await _livepersonSdk?.reloadUser();
      refreshUser();
      BotToast.showText(text: 'Reload Successful');
    } catch (e) {
      BotToast.showText(text: e.toString());
    } finally {
      setLoading(false);
    }
  }

  bool verificationLoading = false;

  void setVerificationLoading(bool load) {
    verificationLoading = load;
    notifyListeners();
  }

  Future<void> sendEmailVerificationCode(VoidCallback onSuccess) async {
    try {
      setVerificationLoading(true);

      await _livepersonSdk?.sendEmailVerificationCode();

      onSuccess();
      BotToast.showText(text: 'Code Sent');
    } catch (e) {
      BotToast.showText(text: e.toString());
    } finally {
      setVerificationLoading(false);
    }
  }

  bool getAdditionalInfoLoading = false;
  void setAdditionalInfoLoading(bool load) {
    getAdditionalInfoLoading = load;
    notifyListeners();
  }

  Future<void> getAdditionalUserInfo() async {
    try {
      setAdditionalInfoLoading(true);
      await _livepersonSdk?.getAdditionalUserInfo();

      BotToast.showText(text: 'Additional Info Gotten Successfully');
      refreshUser();
    } catch (e) {
      BotToast.showText(text: e.toString());
    } finally {
      setAdditionalInfoLoading(false);
    }
  }

  bool linkProviderLoading = false;
  void setLinkProviderLoading(bool load) {
    linkProviderLoading = load;
    notifyListeners();
  }

  Future<void> linkProvider() async {
    try {
      setLinkProviderLoading(true);

      if (kIsWeb) {
        signInAccount = await _googleSignIn.signInSilently();
      } else {
        signInAccount = await _googleSignIn.signIn();
      }

      var signInAuth = await signInAccount?.authentication;
      await _livepersonSdk?.linkProviderToUser(
        getPlatformId(),
        signInAuth!.idToken!,
      );

      BotToast.showText(text: 'Linking Successful');
      refreshUser();
    } catch (e) {
      BotToast.showText(text: e.toString());
    } finally {
      setLinkProviderLoading(false);
    }
  }
}
