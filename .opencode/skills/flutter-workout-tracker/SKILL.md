---
name: flutter-workout-tracker
description: Use when working on this Flutter workout tracker app. Covers project architecture (Clean Architecture with Riverpod), Firestore data layer, code generation workflow, and conventions for adding features like viewmodels, repositories, and screens.
---

# Flutter Workout Tracker

A Flutter app for tracking workouts, programs, and progress. Uses Firebase (Auth + Firestore), Riverpod for state management, GoRouter for navigation, and Clean Architecture.

## Architecture

Clean Architecture with three layers under `lib/`:

```
lib/
├── core/                    # Shared utilities, constants, errors, router
│   ├── constants/           # AppColors, AppStrings, AppSizes
│   ├── errors/              # Failure, ServerException
│   ├── extensions/          # context_extensions.dart (snackbar helpers)
│   ├── router/              # GoRouter configuration
│   └── utils/               # Validators
├── data/                    # Data layer (Firestore implementation)
│   ├── datasources/remote/  # firebase_*_datasource.dart
│   ├── models/              # *_model.dart with fromJson/toJson
│   └── repositories/        # *_repository_impl.dart
├── domain/                  # Pure business logic
│   ├── entities/            # *_entity.dart (immutable data classes)
│   ├── repositories/        # i_*_repository.dart (interfaces)
│   └── usecases/            # *_usecase.dart
└── presentation/
    ├── viewmodels/          # *_viewmodel.dart (Riverpod notifiers)
    └── views/               # Screens organized by feature
```

## State Management

Uses `riverpod_annotation` with code generation. Every viewmodel:

```dart
@riverpod
class MyViewModel extends _$MyViewModel {
  @override
  MyState build() {
    Future.microtask(() => _load()); // Defer async work after build returns
    return const MyState(isLoading: true);
  }
}
```

**Critical:** Never call methods that mutate `state` directly inside `build()`. Wrap in `Future.microtask()` so build returns first. See `progress_viewmodel.dart` for the pattern.

## copyWith with nullable fields

When a state field needs to be set to null (like clearing `activeSession`), the standard `??` pattern fails. Use the sentinel pattern:

```dart
const _sentinel = Object();

WorkoutState copyWith({
  Object? activeSession = _sentinel,
  ...
}) {
  return WorkoutState(
    activeSession: identical(activeSession, _sentinel)
        ? this.activeSession
        : activeSession as WorkoutSessionEntity?,
    ...
  );
}
```

See `workout_viewmodel.dart` for reference.

## Code Generation

After modifying any `@riverpod` provider or `.g.dart`-dependent file:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Or watch mode while developing:

```bash
dart run build_runner watch --delete-conflicting-outputs
```

## Firestore Schema

```
users/{userId}/
  ├── sessions/{sessionId}        # WorkoutSession (active + completed)
  ├── programs/{programId}        # User's workout programs
  └── exercises/{exerciseId}      # User's exercise library
```

Active sessions: `isCompleted == false` (only one at a time).
History: `isCompleted == true` ordered by `startTime` descending (requires composite index).

## Firestore Indexes

Composite indexes are declared in `firestore.indexes.json` and deployed via:

```bash
firebase deploy --only firestore:indexes --project workout-tracker-ead9b
```

When adding a new query that combines `where` + `orderBy` on different fields, add the index to `firestore.indexes.json` and redeploy.

## Adding a New Feature

1. **Entity** in `domain/entities/` — pure Dart class, no Firebase imports.
2. **Repository interface** in `domain/repositories/i_*_repository.dart`.
3. **Model** in `data/models/` extending the entity with `fromJson`/`toJson`.
4. **Datasource** in `data/datasources/remote/firebase_*_datasource.dart` — wraps Firestore calls, throws `ServerException`.
5. **Repository impl** in `data/repositories/*_repository_impl.dart` — catches exceptions, throws `Failure`.
6. **Usecase** (optional) in `domain/usecases/` for complex business logic.
7. **ViewModel** in `presentation/viewmodels/` with `@riverpod`.
8. **Screen** in `presentation/views/<feature>/`.
9. **Route** in `core/router/app_router.dart`.
10. Run `build_runner` to generate `.g.dart` files.

## Common Pitfalls

- **TextEditingController for numeric fields:** Wrap in `_SetRowState`-style pattern that syncs from external state changes via `didUpdateWidget` but preserves user input. See `active_workout_screen.dart:396`.
- **Auto-select on focus:** For weight/reps fields, attach a `FocusNode` and select all text on focus so the default `0` gets replaced when user types.
- **Keyboard dismissal on multi-line fields:** Add `textInputAction: TextInputAction.done` and wrap body in `GestureDetector(onTap: () => FocusScope.of(context).unfocus())`.
- **GoRouter redirect:** The router watches `authViewModelProvider` and redirects based on auth state. Splash screen has its own timeout fallback.

## Verify Changes

```bash
flutter analyze lib/<modified-files>
```

For widget tests:

```bash
flutter test
```

## Project Identifiers

- Firebase project ID: `workout-tracker-ead9b`
- Android app ID: `1:509205586680:android:bac45da853b64e2e90510d`
- iOS app ID: `1:509205586680:ios:f03c03f671ee824590510d`
