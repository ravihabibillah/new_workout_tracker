---
name: riverpod-viewmodel-patterns
description: Use when writing or debugging Riverpod viewmodels with riverpod_annotation code generation. Covers the build() lifecycle, deferred async loading, copyWith with nullable fields, Timer cleanup, and the build_runner workflow.
---

# Riverpod ViewModel Patterns

Patterns for `riverpod_annotation` viewmodels in Flutter. These solve the most common foot-guns: state mutation during build, nullable copyWith, timer leaks, and stale providers after auth changes.

## Standard ViewModel Shape

```dart
@riverpod
class MyViewModel extends _$MyViewModel {
  @override
  MyState build() {
    Future.microtask(() => _load()); // Defer async work after build returns
    return const MyState(isLoading: true);
  }

  Future<void> _load() async {
    state = state.copyWith(isLoading: true);
    try {
      final data = await ref.read(myRepositoryProvider).fetch();
      state = state.copyWith(data: data, isLoading: false);
    } on Failure catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    }
  }
}
```

After modifying any `@riverpod` annotated class:

```bash
dart run build_runner build --delete-conflicting-outputs
```

`*.g.dart` files are typically gitignored. After cloning a project, always run `build_runner` before building.

## Critical: Defer Async in build()

Never call methods that mutate `state` synchronously inside `build()`. Doing so triggers a "Tried to modify a provider while it was being initialized" error.

Wrap async work in `Future.microtask(() => _load())` so `build()` returns the initial state first, then your loader fires on the next microtask.

## copyWith with Nullable Fields

The standard `??` pattern fails when you want to set a nullable field to `null`. Use the **sentinel pattern**:

```dart
const _sentinel = Object();

class MyState {
  final SomeEntity? activeSession;
  final bool isLoading;
  // ...

  MyState copyWith({
    Object? activeSession = _sentinel,
    bool? isLoading,
  }) {
    return MyState(
      activeSession: identical(activeSession, _sentinel)
          ? this.activeSession
          : activeSession as SomeEntity?,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
```

Without this, `copyWith(activeSession: null)` is indistinguishable from "don't change activeSession". The sentinel `Object()` instance is passed by default, and `identical()` checks whether the caller actually provided a value.

## Timer Cleanup

For periodic timers in viewmodels, store as instance field and cancel via `ref.onDispose()`:

```dart
@riverpod
class WorkoutViewModel extends _$WorkoutViewModel {
  Timer? _restTimer;

  @override
  WorkoutState build() {
    ref.onDispose(() => _restTimer?.cancel());
    return const WorkoutState();
  }

  void startTimer(int seconds) {
    _restTimer?.cancel();
    state = state.copyWith(remaining: seconds);
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final current = state.remaining ?? 0;
      if (current <= 1) {
        timer.cancel();
        state = state.copyWith(remaining: 0);
      } else {
        state = state.copyWith(remaining: current - 1);
      }
    });
  }
}
```

Always `_restTimer?.cancel()` before starting a new one. Multiple periodic timers running simultaneously are a common silent bug.

## Defer Data Loading Until Authenticated

ViewModels that fetch user-scoped data (e.g., per-user Firestore collections) must not load before login. Loading for an unauthenticated user causes permission errors and confusing UX.

**Approach 1**: Check `currentUser` in the load method:

```dart
Future<void> loadPrograms() async {
  final user = ref.read(currentUserProvider);
  if (user == null) return;
  // ... fetch
}
```

**Approach 2**: Trigger the load from the screen on first authenticated build (better for "load on screen open" semantics):

```dart
class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _loaded = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (!_loaded && user != null) {
      _loaded = true;
      Future.microtask(() {
        ref.read(programViewModelProvider.notifier).loadPrograms();
      });
    }
    // ...
  }
}
```

The `_loaded` flag prevents re-triggering on every rebuild.

## Provider Definitions for Repositories

Use a provider to construct the repository so it can be overridden in tests:

```dart
@riverpod
IThingRepository thingRepository(ThingRepositoryRef ref) {
  return ThingRepositoryImpl(
    dataSource: FirebaseThingDataSource(
      firestore: FirebaseFirestore.instance,
      firebaseAuth: FirebaseAuth.instance,
    ),
  );
}
```

Note: `<Name>Ref` typedefs are deprecated in newer riverpod versions in favor of plain `Ref`. Update gradually as the package guides.

## Async Providers for One-shot Reads

For data that doesn't need viewmodel state machinery (e.g., "get program by id"), use a `@riverpod Future<T>` provider:

```dart
@riverpod
Future<ProgramEntity?> programById(ProgramByIdRef ref, String id) async {
  final repo = ref.watch(thingRepositoryProvider);
  return repo.getById(id);
}
```

Read with `await ref.read(programByIdProvider(id).future)` or watch with `ref.watch(programByIdProvider(id))` for `AsyncValue<T>`.

## Verify

```bash
dart run build_runner build --delete-conflicting-outputs
flutter analyze lib/<modified-files>
```
