# liveperson-dart-admin-sample-app

## Description

A sample app to showcase the process of installing, setting up and using the liveperson-dart-admin-auth-sdk

## Table of Contents

- [Installation](#installation)
- [Usage](#usage)

## Installation

- Add the absolute path of the liveperson-dart-admin-auth-sdk to the sample app's pubspec.yaml file
  ```yaml
  dependencies:
  liveperson_dart_admin_auth_sdk:
    path: /Users/user/Documents/GitLab/liveperson-dart-admin-auth-sdk/liveperson-dart-admin-auth-sdk
  ```

## Usage

    Depending on the platform liveperson-dart-admin-auth-sdk can be initialized via three methods

**Web:**
For Web we use Enviroment Variable

```
import 'package:flutter/material.dart';
import 'package:liveperson_dart_admin_auth_sdk/liveperson_dart_admin_auth_sdk.dart';

    void main() async
    {

        livepersonApp.initializeAppWithEnvironmentVariables(apiKey:'api_key',projectId: 'project_id',);

        livepersonApp.instance.getAuth();

        runApp(const MyApp());
    }

```

- Import the liveperson-dart-admin-auth-sdk and the material app
  ```
  import 'package:flutter/material.dart';
  import 'package:liveperson_dart_admin_auth_sdk/liveperson_dart_admin_auth_sdk.dart';
  ```
- In the main function call the 'livepersonApp.initializeAppWithEnvironmentVariables' and pass in your api key and project id

  ```
    livepersonApp.initializeAppWithEnvironmentVariables(apiKey:'api_key',projectId: 'project_id',);
  ```

- Aftwards call the 'livepersonApp.instance.getAuth()'
  ```
    livepersonApp.instance.getAuth();
  ```
- Then call the 'runApp(const MyApp())' method

  ```
      runApp(const MyApp())

  ```

**Mobile:**
For mobile we can use either [Service Account](#serviceaccount) or [Service account impersonation](#ServiceAccountImpersonation)

## ServiceAccount

    ```
    import 'package:flutter/material.dart';
    import 'package:liveperson_dart_admin_auth_sdk/liveperson_dart_admin_auth_sdk.dart';

    void main() async
    {
        livepersonApp.initializeAppWithServiceAccount(serviceAccountKeyFilePath: 'path_to_json_file');

        livepersonApp.instance.getAuth();
        runApp(const MyApp());
    }
    ```

- Import the liveperson-dart-admin-auth-sdk and the material app

  ```
  import 'package:flutter/material.dart';
  import 'package:liveperson_dart_admin_auth_sdk/liveperson_dart_admin_auth_sdk.dart';
  ```

- In the main function call the 'livepersonApp.initializeAppWithServiceAccount' function and pass the path to your the json file
  ```
   livepersonApp.initializeAppWithServiceAccount(serviceAccountKeyFilePath: 'path_to_json_file');
  ```
- Aftwards call the 'livepersonApp.instance.getAuth()'
  ```
    livepersonApp.instance.getAuth();
  ```
- Then call the 'runApp(const MyApp())' method

  ```
      runApp(const MyApp())

  ```

## ServiceAccountImpersonation

    ```
    import 'package:flutter/material.dart';
    import 'package:liveperson_dart_admin_auth_sdk/liveperson_dart_admin_auth_sdk.dart';

    void main() async
    {
        livepersonApp.initializeAppWithServiceAccountImpersonation(serviceAccountEmail: service_account_email, userEmail: user_email)

        livepersonApp.instance.getAuth();
        runApp(const MyApp());
    }
    ```

- Import the liveperson-dart-admin-auth-sdk and the material app

  ```
  import 'package:flutter/material.dart';
  import 'package:liveperson_dart_admin_auth_sdk/liveperson_dart_admin_auth_sdk.dart';
  ```

- In the main function call the 'livepersonApp.initializeAppWithServiceAccountImpersonation' function and pass the service_account_email and user_email
  ```
    livepersonApp.initializeAppWithServiceAccountImpersonation(serviceAccountEmail: serviceAccountEmail,userEmail:userEmail,)
  ```
- Aftwards call the 'livepersonApp.instance.getAuth()'
  ```
    livepersonApp.instance.getAuth();
  ```
- Then call the 'runApp(const MyApp())' method

  ```
      runApp(const MyApp())

  ```
