# Mobile App

Flutter client for the messaging platform.

## Baseline

- Flutter: 3.47+
- Dart: 3.13+
- Android minimum SDK: 24
- iOS minimum target: 15.0
- State management: Cubit via flutter_bloc
- Architecture: feature-first Clean Architecture principles

## Structure

```text
lib/
  app/
  core/
    failures/
  features/
    auth/
      data/
      domain/
      presentation/
    chat/
      data/
      domain/
      presentation/
  injection/
```

The UI now depends on domain repository contracts instead of Firebase SDK classes. Firebase is isolated behind data-layer repository implementations and composed centrally in `injection/app_dependencies.dart`.

Cubit is used for asynchronous auth and chat state. The current visual design and legacy Firebase-backed behavior are intentionally preserved while architecture boundaries are introduced.

## Development

```bash
flutter pub get
dart format lib test
flutter analyze
flutter test
flutter run
```

## Next checkpoints

1. Replace the legacy single-room Firebase behavior with the approved conversation model.
2. Add use cases only where they carry real orchestration/business value.
3. Introduce the custom backend adapters without changing presentation/domain contracts.
4. Implement the approved design system and high-fidelity screens.
