# Mobile App

Flutter client for the messaging platform.

## Baseline

- Flutter: 3.47+
- Dart: 3.13+
- Android: modern declarative Flutter Gradle plugin setup
- Android minimum SDK: 24
- iOS minimum target: 15.0

The current feature code still represents the legacy Firebase chat implementation. This modernization checkpoint intentionally updates the toolchain, package baseline, null-safety/code quality, and tests **before** the feature-first architecture refactor.

## Development

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

After dependency resolution, commit the regenerated `pubspec.lock` because this is an application repository.

## Next checkpoint

Introduce the approved app/core/feature-first architecture and repository boundaries while preserving behavior.
