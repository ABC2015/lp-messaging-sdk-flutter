import 'package:bot_toast/bot_toast.dart';
import 'package:liveperson_dart_admin_auth_sdk/liveperson_dart_admin_auth_sdk.dart';
import 'package:flutter/material.dart';

class VerifyBeforeEmailUpdateViewModel extends ChangeNotifier {
  final livepersonAuth? _livepersonSdk = livepersonApp.livepersonAuth;
  bool loading = false;

  void setLoading(bool load) {
    loading = load;
    notifyListeners();
  }

  Future<void> verifyBeforeEmailUpdate(
    String newEmail, {
    ActionCodeSettings? actionCode,
    required VoidCallback onFinished,
  }) async {
    try {
      setLoading(true);
      await _livepersonSdk?.verifyBeforeEmailUpdate(newEmail,
          action: actionCode);
      BotToast.showText(text: 'Verification email has been sent to $newEmail');
      onFinished();
    } catch (e) {
      BotToast.showText(text: e.toString());
    } finally {
      setLoading(false);
    }
  }
}
