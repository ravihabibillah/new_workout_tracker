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
│   └── utils/               # Validators, global_keys (scaffoldMessengerKey)
├── data/                    # Data layer (Firestore implementation)
│   ├── datasources/remote/  # firebase_*_datasource.dart
│   ├── datasources/local/   # Hive caches (exercise_library_cache, program_cache)
│   ├── models/              # *_model.dart with fromJson/toJson
│   └── repositories/        # *_repository_impl.dart
├── domain/                  # Pure business logic
│   ├── entities/            # *_entity.dart (immutable data classes)
│   ├── repositories/        # i_*_repository.dart (interfaces)
│   └── usecases/            # *_usecase.dart
└── presentation/
    ├── viewmodels/          # *_viewmodel.dart (Riverpod notifiers)
    ├── views/               # Screens organized by feature
    └── widgets/             # Shared widgets (shimmer_loading.dart)
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

See `workout_viewmodel.dart` and `workout_session_entity.dart` for reference.

## Timers in ViewModels

For periodic work (e.g., countdown), store the `Timer` as instance field and cancel it in `ref.onDispose()` to prevent leaks:

```dart
@riverpod
class WorkoutViewModel extends _$WorkoutViewModel {
  Timer? _restTimer;

  @override
  WorkoutState build() {
    ref.onDispose(() => _restTimer?.cancel());
    return const WorkoutState();
  }

  void startRestTimer(int seconds, {bool vibrateOnComplete = false}) {
    _restTimer?.cancel();
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      // ... countdown logic
      if (vibrateOnComplete) {
        final hasVibrator = await Vibration.hasVibrator();
        if (hasVibrator) Vibration.vibrate(duration: 500);
      }
    });
  }
}
```

`Vibration.hasVibrator()` returns `bool` (not `bool?`) — don't add `?? false`.

## Code Generation

After modifying any `@riverpod` provider or `.g.dart`-dependent file:

```bash
dart run build_runner build --delete-conflicting-outputs
```

`*.g.dart` files are gitignored. After cloning, always run `build_runner` before building.

## Firestore Schema

```
exercises/{exerciseId}              # Global exercise library (shared)
exercises_meta/seed                 # Seed marker (seeded once globally)
users/{userId}/
  ├── sessions/{sessionId}          # WorkoutSession (active + completed)
  └── programs/{programId}          # User's workout programs
```

Active sessions: `isCompleted == false` (only one at a time).
History: `isCompleted == true` ordered by `startTime` descending (requires composite index).

Quick workouts: `programId == null`, `isQuickWorkout == true`. The session model handles both with optional `programId`.

## Firestore Indexes

Composite indexes are declared in `firestore.indexes.json` and deployed via:

```bash
firebase deploy --only firestore:indexes --project workout-tracker-ead9b
```

When adding a new query that combines `where` + `orderBy` on different fields, add the index to `firestore.indexes.json` and redeploy.

## Local Cache (Hive)

| Cache | Box | Scope | Strategy |
|-------|-----|-------|----------|
| Exercise library | `exercise_library` | Global | TTL 7 days, background sync |
| Programs | `programs` | Per user | Mutation-driven, clear on logout |

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

## Adding Optional Fields to Existing Entities

For backward compatibility (existing Firestore docs missing the field):

1. In **entity**: add field with sensible default (e.g., `bool useRestTimer = false`).
2. In **model fromJson**: read with `?? defaultValue` (e.g., `json['useRestTimer'] as bool? ?? false`).
3. In **model toJson**: always write the field.
4. Update **copyWith**, **fromEntity**, **toEntity**.
5. Update **repository interface, impl, datasource, usecase** signatures with new optional named params.

## Loading States: Shimmer

Replace `CircularProgressIndicator` with shimmer skeletons for better perceived performance. Use reusable widgets from `presentation/widgets/shimmer_loading.dart`:

- `ShimmerProgramList`, `ShimmerExerciseList`, `ShimmerHistoryList` — list skeletons
- `ShimmerCard`, `ShimmerBox` — building blocks
- `ShimmerWorkoutScreen`, `ShimmerProgressScreen` — full-screen skeletons

Keep `CircularProgressIndicator` only for: splash screen branding, button-internal spinners (small inline loading).

## Icons: Font Awesome

The project uses `font_awesome_flutter` for icons. When migrating from Material Icons:

- Replace `Icon(Icons.X)` → `FaIcon(FontAwesomeIcons.Y)` using the mapping table in commit history.
- **Always set explicit `color`** on `FaIcon` inside colored buttons. `FaIcon` does not inherit `IconTheme` properly — without explicit color, icons may appear invisible against the button background.
- For `prefixIcon` in `TextField`, wrap in `Padding(padding: EdgeInsets.all(12), child: FaIcon(...))` because Font Awesome icons render larger than Material defaults.
- After adding `font_awesome_flutter`, do **`flutter clean` + full rebuild**, not hot reload — fonts need to be re-bundled.

## Snackbars After Navigation/Redirect

Showing a snackbar right after `signOut()` (or any action that triggers GoRouter redirect) fails because the screen unmounts before the snackbar renders. Use a global `ScaffoldMessengerKey`:

1. Define in `core/utils/global_keys.dart`:
   ```dart
   final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
   ```
2. Attach in `MaterialApp.router(scaffoldMessengerKey: scaffoldMessengerKey, ...)`.
3. Use anywhere: `scaffoldMessengerKey.currentState?.showSnackBar(...)`.

Don't define the key in `main.dart` and import `main.dart` from screens — circular imports cause `undefined_identifier` errors.

## Dialog with TextEditingController

Never call `controller.dispose()` after `await showDialog<T>`. Flutter may still rebuild widgets that reference the controller, causing `A TextEditingController was used after being disposed` errors.

**Always extract dialog content with controllers into a separate `StatefulWidget`** so `dispose()` is called by the framework when the dialog widget tree is properly torn down. See `_SaveAsProgramDialog` and `_TimerPickerDialog` in `active_workout_screen.dart`.

## Common Pitfalls

- **TextEditingController for numeric fields:** Use `_SetRowState`-style pattern that syncs from external state changes via `didUpdateWidget` but preserves user input. See `active_workout_screen.dart` `_SetRow`.
- **Auto-select on focus:** For weight/reps fields, attach a `FocusNode` and select all text on focus so the default `0` gets replaced when user types.
- **Keyboard dismissal on multi-line fields:** Add `textInputAction: TextInputAction.done` and wrap body in `GestureDetector(onTap: () => FocusScope.of(context).unfocus())`.
- **GoRouter redirect:** The router watches `authViewModelProvider` and redirects based on auth state. Splash screen has its own timeout fallback.
- **GoRouter URL construction:** Never use route templates as URLs directly (e.g., `AppRoutes.exerciseProgress` contains literal `:exerciseId`). Use `replaceAll(':exerciseId', value)` or build URLs explicitly with `Uri.encodeComponent` for path segments containing spaces or special characters.
- **Close vs Cancel for active workouts:** Use back button (or `WillPopScope: () => true`) for "close and preserve session"; use a separate explicit destructive icon (e.g., trash) for "cancel and delete session". Don't conflate them.
- **Defer data loading until authenticated:** ViewModels triggered by `build()` should check `currentUser` before calling Firestore. Loading programs/sessions for an unauthenticated user causes permission errors. See `program_viewmodel.dart` and the `fix: defer program loading until user is authenticated` commit.
- **Auto-load vs pull-to-refresh:** Don't rely on pull-to-refresh as the only way to load data. Trigger initial load in the screen widget on first authenticated build (with a flag to prevent re-triggers). See `home_screen.dart` `_programsLoaded` pattern.
- **Avoid duplicated members in entities:** When adding fields to entities, especially with sentinel-pattern `copyWith`, double-check there's no field declared twice. Dart compiler errors on duplication are sometimes confusing — keep the entity file alphabetically organized to spot duplicates.

## Edge-to-Edge Display (Android)

To enable edge-to-edge so dark theme background draws behind status/navigation bars:

1. Set `SystemUiOverlayStyle` in `main()` with transparent system bars.
2. In `android/app/src/main/kotlin/.../MainActivity.kt`, call `WindowCompat.setDecorFitsSystemWindows(window, false)` in `onCreate`.
3. Update `android/app/src/main/res/values/styles.xml` and `values-night/styles.xml` to add transparent navigation bar.
4. Set `compileSdkVersion` to at least 35 in `android/app/build.gradle` for `enforceNavigationBarContrast` support.

See the `feat: enable edge-to-edge display for Android` commit.

## Login Button Loading State

Don't reset `_isLoading = false` after successful sign-in. The user's screen will be replaced by GoRouter redirect, so resetting state on a disposed widget is wasteful. Only reset on error:

```dart
Future<void> _signInWithGoogle() async {
  setState(() => _isLoading = true);
  try {
    await ref.read(authViewModelProvider.notifier).signInWithGoogle();
    // Don't reset _isLoading on success: GoRouter redirects to home.
  } catch (e) {
    if (mounted) {
      setState(() => _isLoading = false);
      context.showErrorSnackBar(e.toString());
    }
  }
}
```

## Testing

The project has comprehensive unit tests under `test/`:
- `test/domain/entities/` — entity tests
- `test/data/models/` — model JSON serialization tests
- `test/data/repositories/` — repository tests with mockito
- `test/data/datasources/local/` — Hive cache tests
- `test/presentation/viewmodels/` — viewmodel tests with ProviderContainer

When adding mockito-generated `.mocks.dart` files, run:
```bash
dart run build_runner build --delete-conflicting-outputs
```

Run all tests: `flutter test`. Run specific suite: `flutter test test/data/`.

## Commit Conventions

See root `AGENTS.md`:
- Always ask before committing, suggest message first.
- Stage only relevant files; never `git add .`.
- `*.g.dart` is gitignored — don't try to stage them.
- Conventional commit types: `feat`, `fix`, `refactor`, `chore`, `docs`, `test`, `style`.

## Verify Changes

```bash
flutter analyze lib/<modified-files>
```

When `flutter analyze` output appears truncated in the shell (replaced with `clean — nothing to commit`), redirect to a file:

```bash
flutter analyze lib/ > /tmp/analyze.log 2>&1
```

Then read `/tmp/analyze.log` to see full output.

For widget tests:

```bash
flutter test
```

## Project Identifiers

- Firebase project ID: `workout-tracker-ead9b`
- Android app ID: `1:509205586680:android:bac45da853b64e2e90510d`
- iOS app ID: `1:509205586680:ios:f03c03f671ee824590510d`
