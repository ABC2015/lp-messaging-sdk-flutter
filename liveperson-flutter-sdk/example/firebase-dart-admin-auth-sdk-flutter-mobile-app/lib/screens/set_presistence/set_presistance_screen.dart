import 'dart:developer';

import 'package:liveperson_dart_admin_auth_sdk/liveperson_dart_admin_auth_sdk.dart';
import 'package:flutter/material.dart';

import 'liveperson_presistance.dart';

class PersistenceSelectorDropdown extends StatefulWidget {
  const PersistenceSelectorDropdown({super.key});

  @override
  State<PersistenceSelectorDropdown> createState() =>
      _PersistenceSelectorDropdownState();
}

class _PersistenceSelectorDropdownState
    extends State<PersistenceSelectorDropdown> {
  String? _selectedPersistence;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
      child: DropdownButton<String>(
        value: _selectedPersistence,
        hint: const Text('Choose Persistence Option'),
        onChanged: (String? newValue) async {
          setState(() {
            _selectedPersistence = newValue;
          });
          if (newValue != null) {
            if (_selectedPersistence != null) {
              try {
                await livepersonApp.livepersonAuth?.setPresistanceMethod(
                    _selectedPersistence!, 'firebasdartadminauthsdk');
                //  log("response of pressitance $response");
              } catch (e) {
                log("response of pressitance $e");
              }
            }
          }
        },
        items: const [
          DropdownMenuItem(
            value: livepersonPersistence.local,
            child: Text('Local'),
          ),
          DropdownMenuItem(
            value: livepersonPersistence.session,
            child: Text('Session'),
          ),
          DropdownMenuItem(
            value: livepersonPersistence.none,
            child: Text('None'),
          ),
        ],
      ),
    ));
  }
}
