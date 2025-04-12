import 'package:bot_toast/bot_toast.dart';
import 'package:liveperson_dart_admin_auth_sdk/liveperson_dart_admin_auth_sdk.dart';
import 'package:flutter/material.dart';

class SignInWithCustomTokenViewModel extends ChangeNotifier {
  bool loading = false;
  void setLoading(bool load) {
    loading = load;
    notifyListeners();
  }

  Future<void> signInWithCustomToken(String uid, VoidCallback onSuccess) async {
    try {
      setLoading(true);

      await livepersonApp.livepersonAuth?.signInWithCustomToken(uid);

      onSuccess();
    } catch (e) {
      BotToast.showText(text: e.toString());
    }
    setLoading(false);
  }
}
