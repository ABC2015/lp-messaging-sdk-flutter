# Contributing

Thanks for your interest in improving the LivePerson Flutter and Dart Messaging SDKs.
This repo includes two SDKs with different scopes; please target changes to the
appropriate package.

## Scope

<<<<<<< HEAD
- `lp-messaging-sdk-flutter`: Flutter plugin that wraps LivePerson native SDKs
- `lp-messaging-sdk-dart`: Pure Dart engine that talks to LivePerson APIs
=======
- [Code of Conduct](CODE_OF_CONDUCT.md)
- [What We Are Looking For](#what-we-are-looking-for)
- [How to Contribute](#how-to-contribute)
- [Getting Started](#getting-started)
- [Pull Request Guidelines](#pull-request-guidelines)
- [Reporting Bugs](#reporting-bugs)
- [Feature Requests](#feature-requests)
- [Improving Documentation](#improving-documentation)
- [Support Tiers](#support-tiers)
- [SDKs and Liveperson Integration](#sdks-and-liveperson-integration)
- [Available Versions](#available-versions)
- [Community](#community)
>>>>>>> main

## How to contribute

1. Open an issue describing the bug, feature, or documentation gap.
2. Keep changes small and focused; include tests when behavior changes.
3. Update documentation if you add or modify public APIs.

## Development setup

1. Fork and clone the repo.
2. Install the Dart and Flutter SDKs as needed.
3. Work within the specific package directory.

## Testing

From the package you changed:

```bash
dart test
```

If you edit the Flutter plugin, also run:

```bash
flutter test
```

## Pull requests

Please include:

- A clear description of the change and why it’s needed
- Any relevant issue links
- Notes on testing and environment

## Reporting bugs

When filing an issue, include:

- Steps to reproduce
- Expected vs actual behavior
- Environment details (OS, Dart/Flutter versions)

## Licensing

<<<<<<< HEAD
By contributing, you agree that your contributions will be licensed under the
project’s existing license terms. See `LICENSE`.
=======
All LivePerson Flutter SDK packages are licensed under BSD-3, except for the *services packages*, which uses the ELv2 license, and are licensed from third party software Liveperson Inc. In short, this means that you can, without limitation, use any of the client packages in your app as long as you do not offer the SDK's or services as a cloud service to 3rd parties (this is typically only relevant for cloud service providers).  See the [LICENSE](LICENSE.md) file for more details.

## Acknowledgments

- Inspired by the simplicity of [Firebase_Dart](#).
- Thanks to the Dart community for continuous support and inspiration.

We would like to extend our gratitude to all the developers and contributors who have made this Firebase Dart SDK possible and continue to support its growth.
>>>>>>> main
